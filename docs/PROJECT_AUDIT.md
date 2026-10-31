# TaleemPlus — Complete Project Audit

> **Date:** October 2026  
> **Auditor:** Senior Software Architect & Migration Lead  
> **Target Scope:** Firebase to Node.js + Express + PostgreSQL (Prisma) Full-Stack Migration

---

## 1. Executive Summary

TaleemPlus is an educational ERP & academy management system designed for cross-platform deployment (Android, iOS, Web). It provides specialized portals for **Admins**, **Teachers**, **Students**, and **Parents**. Currently, the system relies on Firebase Authentication and Cloud Firestore for authentication and cloud data persistence, alongside local SQLite (`sqflite`) for legacy offline storage and on-device machine learning models for offline AI capabilities.

This audit evaluates the codebase's existing state, identifies technical debt, documents all active dependencies and database queries, and defines the requirements for a clean migration to a standalone Node.js + PostgreSQL backend architecture.

---

## 2. Codebase Inventory

### 2.1 Technology Stack (Pre-Migration)
* **Frontend Framework:** Flutter `3.47.9` (Dart `3.13.7`), targeting Mobile & Web.
* **State Management:** `provider ^6.1.2` (`ChangeNotifier` & `ChangeNotifierProxyProvider`).
* **Authentication:** Firebase Auth `^5.1.0`.
* **Primary Database:** Cloud Firestore `^5.0.1` (`academy_id` multi-tenant key).
* **Local Database:** SQLite `sqflite ^2.3.3` (`taleemplus_v2.db` schema v6).
* **On-Device AI & ML:** Google ML Kit `google_mlkit_text_recognition ^0.13.0`, pure Dart ports for Logistic Regression (`fee_risk_model.dart`), Linear Regression (`performance_index_model.dart`), TextRank summarizer (`text_rank_summarizer.dart`), and TF-IDF Cosine similarity grader (`tfidf_grader.dart`).
* **UI Visualization & PDF:** `fl_chart ^0.68.0`, `pdf ^3.13.0`, `printing ^5.13.0`, `qr_flutter ^4.1.0`.

---

## 3. Data Collection & Multi-Tenancy Scoping

### 3.1 Firestore Collection Audit
1. `users`: Stores user profiles linked to Firebase Auth `uid`. Fields: `uid`, `full_name`, `email`, `role` (`admin`|`teacher`|`student`|`parent`), `account_status` (`active`|`pending`|`rejected`), `academy_id`, `academy_code`, `linked_children`.
2. `announcements`: Broadcast announcements. Fields: `id`, `academy_id`, `title`, `message`, `target_roles`, `created_by_uid`, `created_at`.
3. `classes`: Class & Section rosters. Fields: `id`, `academy_id`, `class_name`, `section`, `primary_teacher_id`, `student_ids`.
4. `attendance_records`: Attendance logs. Fields: `id` (`{classId}_{studentId}_{yyyy-MM-dd}`), `academy_id`, `class_id`, `student_id`, `log_date`, `status` (`present`|`absent`|`late`).
5. `fee_challans`: Monthly printable fee challans. Fields: `id`, `academy_id`, `challan_number`, `student_id`, `monthly_fee`, `admission_fee`, `exam_fee`, `transport_fee`, `fine`, `status` (`pending`|`paid`|`overdue`), `due_date`.
6. `quizzes`: Quiz headers & questions. Fields: `id`, `academy_id`, `class_id`, `title`, `subject`, `total_marks`, `questions` (embedded array).
7. `test_marks`: Gradebook marks. Fields: `id` (`{quizId}_{studentUid}`), `academy_id`, `quiz_id`, `student_id`, `marks_obtained`, `total_marks`, `percentage`, `grade_letter`.
8. `learning_resources`: Study material attachments. Fields: `id`, `academy_id`, `class_id`, `teacher_id`, `title`, `file_url`.
9. `student_queries`: Discussion Q&A threads. Fields: `id`, `academy_id`, `class_id`, `student_id`, `teacher_id`, `question`, `answer`, `is_resolved`.
10. `notifications`: User notifications. Fields: `id`, `academy_id`, `recipient_id`, `title`, `message`, `is_read`.
11. `ocr_documents`: Private scanned OCR documents. Fields: `id`, `created_by_uid`, `title`, `extracted_text`.

---

## 4. Technical Debt & Anti-Patterns Identified

1. **Dual Fee System:** `fee_invoices` table exists in local `sqflite` alongside Cloud Firestore `fee_challans`. The backend migration will standardize all fee tracking on PostgreSQL `fee_challans`.
2. **Plaintext Password Caching:** `shared_preferences` caches plaintext passwords under `saved_pass_v1` for biometric re-login. The migration will replace this with secure JWT refresh token storage.
3. **Unused Scaffolding:** `QuizSubmissionModel` exists in `quiz_submission_model.dart` without active Firestore repository writes.
4. **Firebase SDK Tight Coupling:** Provider classes directly reference Firestore types (`Timestamp`, `DocumentSnapshot`). All providers will be refactored to consume pure Dart data models returned by REST API services.

---

## 5. Migration Directives

1. **Backend Infrastructure:** Standalone Node.js + Express REST API (`taleemplus_backend/`) connected to PostgreSQL via Prisma ORM.
2. **Security:** JWT Access Tokens (15m expiry) + Refresh Tokens (7d expiry with rotation), bcrypt password hashing (`rounds=10`), multi-tenant middleware enforcing `academyId`.
3. **Frontend Compatibility:** All 4 role portals (Admin, Teacher, Student, Parent) will function seamlessly via the new REST API Client.
4. **Preserved AI Engines:** All on-device ML and OCR engines will be kept 100% intact on the client side.
