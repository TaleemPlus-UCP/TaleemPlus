# TaleemPlus API v2 Specification

> **Base URL:** `/api/v2`  
> **Protocol:** HTTPS / HTTP REST JSON  
> **Authentication:** Bearer JWT Access Token (`Authorization: Bearer <token>`)

---

## 1. System Endpoints

### Health Check
* **GET `/health`**
* **Response (200 OK):**
  ```json
  {
    "status": "ok",
    "service": "TaleemPlus Backend Service",
    "timestamp": "2026-10-30T00:00:00.000Z"
  }
  ```

### API Version & Metadata
* **GET `/api/v2/version`**
* **Response (200 OK):**
  ```json
  {
    "success": true,
    "data": {
      "api_version": "2.0.0",
      "service": "TaleemPlus Enterprise Backend",
      "environment": "production",
      "database": "PostgreSQL + Prisma",
      "release_date": "2026-10-30",
      "supported_roles": ["ADMIN", "TEACHER", "STUDENT", "PARENT"]
    }
  }
  ```

---

## 2. Authentication (`/api/v2/auth`)

* **POST `/api/v2/auth/register-admin`** — Register new academy tenant & admin account.
* **POST `/api/v2/auth/register-user`** — Join academy using unique academy code (`TP-XXXXX`).
* **POST `/api/v2/auth/login`** — Authenticate email/password. Returns JWT access token (15m) + refresh token (7d).
* **POST `/api/v2/auth/refresh`** — Exchange refresh token for new access token.
* **GET `/api/v2/auth/me`** — Fetch current authenticated user profile.

---

## 3. Core Modules
* **Users & Approvals:** `/api/v2/users/pending`, `/api/v2/users/:id/approve`, `/api/v2/users/by-role`
* **Classes & Sections:** `/api/v2/classes`, `/api/v2/classes/:id/enroll`
* **Attendance:** `/api/v2/attendance/mark`, `/api/v2/attendance/student/:studentId`
* **Fees & Challans:** `/api/v2/fees/challans/generate`, `/api/v2/fees/ledger/stats`
* **Quizzes & Marks:** `/api/v2/quizzes`, `/api/v2/quizzes/marks`
* **Resources & Queries:** `/api/v2/resources`, `/api/v2/queries`
* **Timetable:** `/api/v2/timetable`
