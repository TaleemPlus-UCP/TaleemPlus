# TaleemPlus — REST API Specification (`v1`)

> **Base URL:** `/api/v1`  
> **Format:** JSON (`Content-Type: application/json`)  
> **Auth Header:** `Authorization: Bearer <access_token>`

---

## 1. Authentication Endpoints (`/api/v1/auth`)

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/auth/register-admin` | `POST` | Public | Register new academy & admin account (`accountStatus: ACTIVE`). |
| `/auth/register-user` | `POST` | Public | Join academy using `academyCode` (`accountStatus: PENDING`). |
| `/auth/login` | `POST` | Public | Authenticate email/password. Returns JWT access token (15m) & refresh token (7d). |
| `/auth/refresh` | `POST` | Public | Exchange refresh token for new access token. |
| `/auth/logout` | `POST` | Signed In | Revoke refresh token and invalidate session. |
| `/auth/me` | `GET` | Signed In | Get current authenticated user profile. |
| `/auth/password-reset` | `POST` | Public | Initiate password reset request. |

---

## 2. User & Approval Endpoints (`/api/v1/users`)

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/users/pending` | `GET` | Admin | List pending user accounts for the academy. |
| `/users/:id/approve` | `PUT` | Admin | Approve pending user account (`accountStatus -> ACTIVE`). |
| `/users/:id/reject` | `PUT` | Admin | Reject pending user account (`accountStatus -> REJECTED`). |
| `/users/by-role` | `GET` | Admin/Staff | Query users by role (`teacher`, `student`, `parent`). |
| `/users/:parentId/link-child` | `POST` | Admin/Parent | Link student UID to parent account. |

---

## 3. Academic Structure & Class Endpoints (`/api/v1/classes`)

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/classes` | `GET` | Approved | List all classes for current tenant academy. |
| `/classes` | `POST` | Admin | Create new class & section roster with teacher assignment. |
| `/classes/:id` | `DELETE` | Admin | Delete class (cascades to attendance records). |
| `/classes/:id/enroll` | `POST` | Admin | Enroll students into class section with roll numbers. |

---

## 4. Attendance Endpoints (`/api/v1/attendance`)

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/attendance/mark` | `POST` | Staff | Mark/edit daily student attendance (`PRESENT`, `ABSENT`, `LATE`). |
| `/attendance/student/:studentId` | `GET` | Approved | Fetch day-by-day attendance history for student/child. |
| `/attendance/class/:classId` | `GET` | Staff | Fetch class section attendance for a specific date. |

---

## 5. Fee Challans & Analytics (`/api/v1/fees`)

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/fees/challans/generate` | `POST` | Admin | Bulk-generate monthly fee challans for class section. |
| `/fees/challans/student/:studentId` | `GET` | Approved | Fetch student's fee challan list & payment status. |
| `/fees/challans/:id/pay` | `PUT` | Admin | Mark fee challan as `PAID`. |
| `/fees/ledger/stats` | `GET` | Admin | Get fee collection ledger statistics (paid/pending/overdue %). |

---

## 6. Quiz & Gradebook Endpoints (`/api/v1/quizzes`)

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/quizzes` | `GET` | Approved | Fetch quizzes for class section. |
| `/quizzes` | `POST` | Staff | Create new quiz with embedded questions & grading keywords. |
| `/quizzes/:id/marks` | `POST` | Staff | Upsert student test mark record (`TestMarkModel`). |
| `/quizzes/marks/student/:studentId` | `GET` | Approved | Fetch student's complete gradebook test results. |

---

## 7. Resources, Queries & Notifications

| Endpoint | Method | Role | Description |
|---|---|---|---|
| `/resources` | `GET`, `POST` | Approved/Staff | Fetch or publish classroom study material resources. |
| `/queries` | `GET`, `POST`, `PUT` | Approved/Staff | Submit student query or reply with teacher answer. |
| `/notifications` | `GET`, `PUT` | Approved | Fetch recipient notifications or mark as read. |
| `/announcements` | `GET`, `POST` | Approved/Staff | Fetch broadcast announcements or post new notice. |
