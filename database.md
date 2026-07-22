# TaleemPlus — Database

TaleemPlus uses two independent stores: **Cloud Firestore** (the primary, multi-tenant backend for almost all app data) and a small **local sqflite database** (used only for two admin-side conveniences). There is no bidirectional sync engine between the two — see [Architecture.md](Architecture.md#8-local-vs-cloud-storage-split).

## 1. Firestore — collections overview

All collections are **top-level** (no subcollections). Every document except `ocr_documents` carries an `academy_id` field, which is the multi-tenant partition key enforced by `firestore.rules` (see [security.md](security.md)).

| Collection | Backing model | Scope | Written by |
|---|---|---|---|
| `users` | `AppUser` | per-user (readable by any signed-in user; see security.md) | signup, admin approval/edit |
| `announcements` | `Announcement` | same-academy | admin/teacher (staff) |
| `quizzes` | `QuizModel` (embeds `QuizQuestion[]`) | same-academy | teacher/admin |
| `test_marks` | `TestMarkModel` | same-academy | teacher/admin (delete: admin only) |
| `attendance_records` | `AttendanceRecord` | same-academy | teacher/admin |
| `classes` | `ClassEntity` | same-academy | admin only |
| `learning_resources` | `SharedResource` | same-academy | teacher/admin |
| `student_queries` | `StudentQuery` | same-academy | create: any approved user; update: staff |
| `ocr_documents` | `OcrDocumentModel` | **owner-private** (no `academy_id`) | any approved user (own docs only) |
| `fee_challans` | `FeeChallanModel` | same-academy | admin only |
| `fee_invoices` | — | same-academy (rule exists defensively; not actually written by app code) | admin only |
| `notifications` | `NotificationModel` | **recipient-private** | create: approved user; read/update: recipient only |

## 2. Collection schemas

### `users/{uid}` — `AppUser`
The canonical, Firebase-Auth-linked profile for every role.

| Field | Type | Notes |
|---|---|---|
| `uid` | string | Firebase Auth UID (also the doc ID) |
| `full_name`, `email`, `phone_number` | string | |
| `role` | string | `admin` \| `teacher` \| `student` \| `parent` |
| `account_status` | string | `pending` \| `active` \| `rejected` — gates approval (`isApproved`) |
| `academy_id` | string | tenant key — equals own `uid` for admins |
| `academy_name`, `academy_address`, `academy_phone`, `academy_logo`, `academy_code` | string | academy branding, set by the admin who created the tenant |
| `created_at`, `joining_date` | timestamp | |
| `assigned_sections` | `List<String>` | teacher's assigned class sections |
| `linked_children` | `List<String>` | parent → student UID links |

### `announcements/{id}` — `Announcement`
`id, academy_id, title, message, target_roles (List<String>, "all" supported), created_by_uid, created_by_name, created_at, updated_at`.
On create, `AnnouncementService` fans out a `NotificationModel` to every approved user in the targeted role(s) (best-effort — failure doesn't block the announcement itself).

### `quizzes/{id}` — `QuizModel` (embeds `QuizQuestion[]`)
`id, academy_id, class_id, class_label, title, subject, month, session, chapter, difficulty, total_marks, test_date, instructions, created_by_uid, created_by_name, created_at, questions`.

`QuizQuestion`: `id, text, type (mcq | short), options, correct_index, marks, grading_keywords (List<String>)` — `grading_keywords` are teacher-authored per question and consumed by the AI Smart Grader (see [prompt.md](prompt.md)).

### `test_marks/{quizId}_{studentUid}` — `TestMarkModel`
The canonical gradebook record — deterministic ID = one row per student per quiz (upsert pattern).
`id, academy_id, quiz_id, student_id, student_name, class_id, subject (denormalized), month (denormalized), marks_obtained, total_marks, percentage, grade_letter, teacher_feedback, updated_at`.
`calculateGrade(percentage)`: A+ ≥90, A ≥80, B ≥70, C ≥60, D ≥50, else F. (This formula is duplicated in `QuizSubmissionModel` — see below.)

### `attendance_records/{classId}_{studentId}_{yyyy-MM-dd}` — `AttendanceRecord`
Deterministic ID enables upsert-per-day-per-student.
`id, academy_id, class_id, student_id, student_name, log_date, status (present | absent | late), marked_by_uid, recorded_at`.

### `classes/{id}` — `ClassEntity`
Class/section with embedded enrollment (no separate enrollment collection).
`id, academy_id, class_name, section, subject, primary_teacher_id, primary_teacher_name, primary_teacher_email, student_ids (List<String>), student_names (Map<uid, name>), created_at`.
Deleting a class cascades to delete its `attendance_records` (scoped by `academy_id`).

### `learning_resources/{id}` — `SharedResource`
`id, academy_id, class_id, teacher_id, teacher_name, title, description, file_url, created_at`.

### `student_queries/{id}` — `StudentQuery`
`id, academy_id, class_id, student_id, student_name, teacher_id, question, answer, is_resolved, created_at, answered_at`.

### `ocr_documents/{id}` — `OcrDocumentModel`
**No `academy_id`** — deliberately owner-scoped rather than tenant-scoped.
`id, title, extracted_text, created_by_uid, created_by_name, created_at`.

### `fee_challans/{id}` — `FeeChallanModel`
The primary, Firestore-backed, PDF-printable fee document actually used throughout the app.
`id, academy_id, challan_number, student_id, student_name, father_name, class_label, roll_number, issue_date, due_date, monthly_fee, admission_fee, exam_fee, transport_fee, fine, status (pending | paid | overdue), created_at, updated_at`.
`total_amount` = sum of all fee components; QR code on the printed PDF encodes `Challan:<no>|Student:<id>|Amount:<total>`.

### `notifications/{id}` — `NotificationModel`
`id, academy_id, recipient_id, title, message, type (approval | fee | attendance | result | announcement), is_read, created_at`.

### `QuizSubmissionModel` / `AnswerModel`
Defined in `quiz_model.dart` (`quiz_submission_model.dart`) with a deterministic ID scheme (`{quizId}_{studentUid}`) and its own `calculateGrade()`, but **no `quiz_submissions` collection is actually written by any service/repository in the current codebase** — this model appears to be scaffolding for a future in-app quiz-taking flow that was never wired up (the actual student-facing "quiz" screen is a static "take it on paper" notice — see [prompt.md](prompt.md)).

## 3. Firestore composite indexes (`firestore.indexes.json`)

| Collection | Index fields | Backs |
|---|---|---|
| `notifications` | `academy_id ASC, recipient_id ASC, created_at DESC` | `NotificationService.watchForUser` |
| `announcements` | `academy_id ASC, created_at DESC` | declared defensively; service currently sorts client-side to avoid requiring it |
| `attendance_records` | `academy_id ASC, student_id ASC, log_date DESC` | `AttendanceRepository.watchForStudent` |
| `fee_challans` | `academy_id ASC, student_id ASC, billing_month ASC, created_at DESC` | declared defensively; repository currently filters/sorts client-side |

## 4. Local database — sqflite (`lib/data/local/db_helper.dart`)

`DbHelper` is a singleton opening `taleemplus_v2.db` (schema `version: 6`). Per its own code comment, it is used **only for admin-side data that doesn't need cross-device sync** — everything else (auth/users, classes, attendance, announcements, etc.) lives in Firestore.

```sql
CREATE TABLE IF NOT EXISTS members (
  id          TEXT PRIMARY KEY,
  academy_id  TEXT NOT NULL,
  full_name   TEXT NOT NULL,
  email       TEXT,
  phone       TEXT,
  role        TEXT NOT NULL,
  extra       TEXT,
  status      TEXT NOT NULL DEFAULT 'active',
  created_at  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS fee_invoices (
  id                      TEXT PRIMARY KEY,
  academy_id              TEXT NOT NULL DEFAULT '',
  student_id              TEXT NOT NULL,
  student_name            TEXT NOT NULL,
  gross_amount_due        REAL NOT NULL,
  accumulated_amount_paid REAL NOT NULL DEFAULT 0,
  billing_month           TEXT NOT NULL,
  due_date                TEXT NOT NULL,
  paid_on                 TEXT,
  status                  TEXT NOT NULL DEFAULT 'unpaid',
  created_at              TEXT NOT NULL
);
```

`DbHelper.clearAll()` truncates both tables. `MemberRepository` reads/writes `members`; `FeeRepository` reads/writes `fee_invoices`.

### `MemberProvider` merge behavior
`MemberProvider.load(academyId)` reads local `members` rows **and** Firestore `users` (via `AuthService.getApprovedByRole`), converts Firestore `AppUser`s into `AcademyMember` view objects, and merges the two lists **in memory, by email key** (Firestore entries win on collision). Nothing is written back in either direction — this is a display-time merge, not a sync engine.

### Known duplication / drift
- `fee_invoices` (sqflite, `FeeInvoice` model) and `fee_challans` (Firestore, `FeeChallanModel`) are two independent, non-synced fee data models. The real UI (challan generation, PDF printing, parent/student fee views) uses **`fee_challans`**; the sqflite `fee_invoices` table appears to be a superseded/legacy path, still covered by a unit test (`test/unit/fee_invoice_test.dart`) but not exercised by any current screen flow beyond the legacy `FeeLedgerScreen`/`FeeProvider`.

## 5. Local-only settings (`shared_preferences`)

Not a structured "database," but worth documenting alongside it:

| Key | Purpose |
|---|---|
| `remember_me`, `saved_email` | login screen "remember me" (plaintext email only) |
| `user_theme_preference` | persisted light/dark/system theme choice |
| `biometric_enabled` | whether biometric unlock is turned on |
| `saved_pass_v1` | plaintext password cached for biometric re-login (see [security.md](security.md) for the associated risk) |
