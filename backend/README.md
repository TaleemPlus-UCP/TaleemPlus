# TaleemPlus Backend

Node.js / Express / TypeScript / Prisma / PostgreSQL backend for the TaleemPlus academy management app, replacing the Firebase (Auth + Firestore) backend used by the Flutter client.

This backend is being built **module by module**. This README will grow as each module lands.

## Status

| Module | Status |
|---|---|
| Project scaffold | Done |
| Auth (register/login/refresh/logout, forgot/reset password, security-question recovery, academy join-by-code, RBAC middleware, audit logging) | Done |
| Users & admin approval workflow (pending list, approve/reject, list/search by role, admin-create, update, soft-delete — all academy-scoped) | Done |
| Classes & sections (section CRUD + roster, subject offerings, teacher-scoped reads) | Done |
| Attendance (day-sheet mark/upsert, monthly + yearly views) | Done |
| Timetable (slots + breaks, server-side conflict detection, role-scoped views) | Done |
| Announcements & Notifications (role-targeted broadcast, in-app notification fan-out) | Done |
| Fee Challans (section-scoped batch generation + single-student ad-hoc creation, Decimal money, role-scoped views) | Done |
| Quizzes & Marks (relational questions, server-side AI Smart Grader, gradebook, at-risk/revenue insights) | Done |
| OCR Documents + AI Test Generator + AI Notes Summarizer | Done |
| File upload (Cloudinary) | Not started |
| Realtime (Socket.IO) | Not started |
| Swagger docs | Auth endpoints documented; grows per module |
| Deployment (PM2/Nginx/Railway/Render/VPS) | Not started — deferred until more modules exist |

## Prerequisites

- Node.js 20+ and npm (already installed on this machine)
- PostgreSQL 17 running locally as a Windows service (already installed)
- No Docker/WSL required or used anywhere in this project

## First-time setup

```bash
cd backend
npm install
npx prisma generate
```

Copy `.env.example` to `.env` and fill in real values (a working `.env` already exists in this repo checkout for local development — **do not commit it**, it's gitignored).

### Local database

A dedicated Postgres role/database were created for this app (not the `postgres` superuser):

```
Database: taleemplus_dev
Role:     taleemplus_app
```

Run migrations:

```bash
npm run prisma:migrate      # dev: creates/applies a new migration from schema.prisma
npm run prisma:deploy       # prod/CI: applies existing migrations only, no schema diffing
```

Seed demo data (an academy + one ACTIVE user per role — admin/teacher/student/parent, all sharing the password printed in the console):

```bash
npm run prisma:seed
```

## Running

```bash
npm run dev      # tsx watch — auto-reloads on save
npm run build    # tsc -> dist/
npm start        # node dist/server.js  (run build first)
```

The API listens on `http://localhost:4000` by default (`PORT` in `.env`). Interactive Swagger docs: `http://localhost:4000/docs`. Health check: `GET /health`.

## Testing

Tests run against a **separate** database (`taleemplus_test`, same role) via `.env.test`, never the dev database. `tests/globalSetup.js` applies migrations to it automatically before the suite runs; `tests/setup.ts` truncates all tables before every test and refuses to run at all if `DATABASE_URL` doesn't look like a test database.

```bash
npm test
npm run test:watch
```

## Email in development

No SMTP is configured yet. Until `SMTP_HOST` is set in `.env`, outgoing email (password reset, etc.) is written to `backend/logs/dev-emails/*.html` instead of being sent, so the full flow can be tested offline. Open the generated file in a browser to see the email content and grab the reset link/token. In production, `SMTP_HOST` is mandatory — the API will refuse to start an email send without it.

## Project layout

```
src/
  config/        env loading, winston logger, Prisma client singleton, Swagger spec
  constants/     roles, HTTP status codes, audit action names
  exceptions/    AppError hierarchy (BadRequest/Unauthorized/Forbidden/NotFound/Conflict/...)
  types/         shared TypeScript types (JWT payload, Express Request augmentation)
  utils/         jwt, password hashing, token hashing, duration parsing, academy code gen, response envelope, async handler
  middlewares/   authenticate, authorize (RBAC), validate (zod), rate limiters, centralized error handler
  validators/    zod request schemas per module
  repositories/  Prisma data-access, one per model
  services/      business logic (auth, tokens, email)
  controllers/   thin HTTP layer — parses request, calls a service, sends a response
  routes/        Express routers + Swagger JSDoc annotations
  app.ts         Express app wiring (helmet/cors/rate-limit/routes/error handler)
  server.ts      process entrypoint — DB connect, listen, graceful shutdown
prisma/
  schema.prisma  current models: Academy, User, ParentChildLink, RefreshToken, PasswordResetToken, SecurityQuestion, AuditLog
  seed.ts        demo data
tests/
  auth.test.ts   Auth module test suite (Jest + supertest)
```

## Notable design decisions vs. the legacy Firestore schema

- **Academy is a real table**, not fields duplicated onto every `users/{uid}` document. Multi-tenancy is still `academyId` on `User`, same partitioning concept as the old `academy_id`.
- **Refresh tokens are opaque random strings, stored only as a SHA-256 hash**, with rotation-on-use and theft detection: reusing an already-rotated refresh token revokes every session for that user.
- **Security-question answers are hashed with bcrypt** (which embeds its own salt) rather than the legacy app's own `sha256(salt + answer)` scheme, and the whole recovery collection moves server-side instead of being a publicly-readable-by-email Firestore collection.
- **Soft delete** (`deletedAt` on `User`) instead of hard deletes, so audit history and FK integrity survive account removal.
- Password reset and security-question recovery both **revoke every refresh token for the user**, forcing re-login on all devices — the legacy app had no equivalent for its email-reset flow.
- **Class enrollment is a real join table (`SectionEnrollment`), not a mirrored array.** The legacy Firestore app stored a `ClassSection`'s roster as `student_ids`/`student_names` arrays, then had to manually copy that roster onto every subject offering (`classes` doc) that shared the same section, batch-updating all of them on every enrollment change and batch-cascading three collections by hand on delete (see `class_repository.dart`/`class_section_repository.dart`). Here, a `ClassOffering` just references `sectionId`; every offering under a section reads the same roster live via the join, so there is nothing to keep in sync, and `ON DELETE CASCADE` handles what used to be manual batched deletes.
- **Attendance adds monthly and yearly views that the legacy app never had.** The Firestore app only ever showed a flat, reverse-chronological list of every attendance record for a student (`student_attendance_screen.dart`). `GET /attendance/students/:id/monthly` (daily records + present/absent/late counts and percentage for one month) and `GET /attendance/students/:id/yearly` (a 12-month breakdown for a whole year) are new, purpose-built for a month-wise/year-wise view, per explicit request during this migration.
- **Timetable slots reference a `ClassOffering` instead of denormalizing class/section/subject/teacher onto every slot.** The legacy `TimetableSlot` copied `classId`/`className`/`section`/`subject`/`teacherId`/`teacherName` directly onto the document; here a slot just holds `offeringId` and everything else is derived via the join. Double-booking conflict detection (teacher, room, or section, considering day-of-week + time overlap + effective-date-range overlap together) is now enforced **server-side** at create/update time — the legacy app only checked this client-side (`TimetableProvider.findConflict`) before saving, so a second device or a direct API call could still race past it.
- **Announcement targeting drops the legacy app's magic `"all"` string.** `Announcement.targetRoles` is a real `UserRole[]` restricted to TEACHER/STUDENT/PARENT, with a separate `isForAll` boolean instead of a sentinel value inside the roles array. Posting an announcement fans out an in-app `Notification` row to every ACTIVE user in the targeted role(s) (excluding the poster), mirroring the legacy app's best-effort `_notifyTargets`. The Module 2 user-approval/rejection flow was also retrofitted here to write a matching in-app notification (it previously only sent an email, since the Notification model didn't exist yet when that module was built).
- **Fee challans use real `billingYear`/`billingMonth` integer columns with a `(studentId, billingYear, billingMonth)` unique constraint**, replacing the legacy app's fragile convention of parsing a 3-letter month abbreviation out of `challan_number` (e.g. `"CH-JUL-..."`) to detect "already billed this month" — with no year in that string at all, generating a January challan twice a year apart would have silently skipped the second year. Money fields are `Decimal(10,2)`, never `Float`. Batch generation uses `createMany({ skipDuplicates: true })` against that unique constraint instead of the legacy app's scan-then-write (a real, if narrow, race condition). `classLabelSnapshot` is intentionally denormalized — a challan is a historical financial document and should keep showing the class a student was billed in even if they change sections later, unlike the live-joined class rosters elsewhere in this schema. The legacy model's `fatherName` (which actually reused the unrelated `academyName` field as a hack) and `rollNumber` (`classId.substring(0,4)`, meaningless) were dropped; roll number is read live from `student.extraInfo` instead. Fee-challan reads are now scoped to admin/self/linked-parent only — the legacy Firestore rule technically let *any* approved same-academy user (including a teacher) read every challan, which no actual screen relied on; that's tightened here rather than carried forward. **`POST /fee-challans`** (single-student ad-hoc creation) was added during the Flutter migration, after `generate`'s section-wide-only design turned out not to cover the legacy app's separate local-SQLite "Fee Ledger" feature (ad-hoc, one hand-picked student, one custom amount) — the user chose to consolidate that feature onto this backend rather than leave it as a disconnected, never-synced local table. It derives `classLabelSnapshot` from the student's first enrolled section (best-effort; a student isn't required to belong to one) and shares the same `(studentId, billingYear, billingMonth)` uniqueness with `generate`. There is still no delete endpoint for a challan (financial records are corrected via status, not removed) — the legacy Fee Ledger's "delete invoice" button was dropped for the same reason.
- **OCR documents are owner-scoped, not academy-scoped** — the legacy Firestore `ocr_documents` collection was deliberately the one exception to academy-based tenant isolation (see database.md/security.md), and that's preserved exactly: only the creator can ever read/update/delete their own scans, with no admin override.
- **The AI Test Generator and AI Notes Summarizer are ported as pure, stateless functions** (`utils/aiHeuristics.ts`), faithfully replicating the exact Dart heuristics in `prompt.md` §3–4 — including the documented case-sensitive `"law"`/`"theorem"`/`"equation"` keyword check for difficulty estimation, which is a verbatim port of the legacy quirk, not something quietly "fixed." Test Generator output (`POST /ai/test-generator/generate`) is shaped to feed directly into `POST /quizzes`' `questions` array. OCR itself is not reimplemented server-side — it stays a Flutter/Google-ML-Kit, on-device-only concern; these endpoints only ever receive already-OCR'd text.
- **Quiz questions are real rows (`QuizQuestion`), not an embedded JSON array** — each has an `order` column preserving the teacher-authored sequence, and can be referenced directly by id (the AI Smart Grader endpoint targets one question by id). `TestMark` drops the legacy model's denormalized `subject`/`month` fields ("for AI", per a code comment) since both are one join away via `quiz`; `totalMarks` is still snapshotted per-mark (a quiz's total could change after grading starts) and `percentage`/`gradeLetter` are always computed server-side, never trusted from the client. **The AI Smart Grader formula itself is ported verbatim** from `prompt.md` (`suggested = questionMarks * matchedKeywords / totalKeywords`) into `utils/grading.ts`, exposed as a stateless `POST /quizzes/:id/questions/:qId/grade-suggestion` endpoint that takes client-supplied OCR text and returns a score suggestion — OCR itself stays a Flutter/ML-Kit-only concern, out of the backend's scope. **Students/parents never receive quiz questions at all** — only `Quiz`-reading routes are staff-only (`requireRoles('ADMIN','TEACHER')`) since a question payload includes the MCQ answer key and grading keywords; results are read exclusively through the Marks endpoints, which serialize only `marksObtained`/`percentage`/`gradeLetter`/`quiz.{title,subject,testDate}` and never the question list. Admin AI Insights (at-risk students, revenue forecast) are ported as the same fixed-threshold aggregations described in `prompt.md` §5, not a trained model.

## Known follow-ups (not yet done)

- Prisma is pinned at v5.20–5.22; a v7 major upgrade is available but deliberately deferred until the module set stabilizes.
- PM2/Nginx configs and the Railway/Render/VPS deployment guide are deferred until more modules exist — no point writing a process manager config for one module.
- No self-service profile update endpoint yet (`PATCH /users/me`) — only admin-on-behalf-of-user updates exist so far.
- OCR itself (Google ML Kit) is and remains a Flutter-only, on-device concern — there is no server-side OCR endpoint, and none is planned.
- **This completes the backend module list derived from the existing Flutter app.** What's left is the other half of the original migration: replacing every Firebase call in `lib/` with these REST endpoints (API service layer, token storage/refresh, repository layer, retry/error handling — per the "Flutter Integration" section of the original brief), plus deployment configs (PM2/Nginx/Railway/Render/VPS), which were deliberately deferred until the module set stabilized.
- Student/Parent read-only views into their own classes (as opposed to admin/teacher management) aren't built yet — likely folded into a future "My Classroom" module.
- No endpoint yet to create a `ParentChildLink` (parent-links-to-child) — the attendance access-control logic already respects it once a link exists, but linking itself will land with the Parent Portal module.
