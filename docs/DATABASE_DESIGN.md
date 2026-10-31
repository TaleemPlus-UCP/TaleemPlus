# TaleemPlus — PostgreSQL Database & Prisma Schema Design

> **Database Engine:** PostgreSQL 14+  
> **ORM Layer:** Prisma ORM 5.x  
> **Multi-Tenancy Scoping:** Foreign Key `academyId` referencing `academies(id)` across all tenant tables.

---

## 1. Entity Relationship Overview

```mermaid
erDiagram
    Academy ||--o{ User : "belongs to tenant"
    Academy ||--o{ Class : "manages"
    Academy ||--o{ FeeChallan : "issues"
    User ||--o{ Class : "teaches (Primary Teacher)"
    Class ||--o{ Section : "contains"
    Class ||--o{ StudentEnrollment : "enrolls"
    User ||--o{ StudentEnrollment : "student"
    User ||--o{ ParentStudentRelationship : "parent"
    User ||--o{ ParentStudentRelationship : "child"
    Class ||--o{ AttendanceRecord : "tracks"
    User ||--o{ AttendanceRecord : "student"
    Class ||--o{ Quiz : "conducts"
    Quiz ||--o{ QuizQuestion : "contains"
    Quiz ||--o{ TestMark : "grades"
    User ||--o{ TestMark : "student"
    User ||--o{ RefreshToken : "owns"
```

---

## 2. PostgreSQL Tables & Prisma Models

### Table 1: `academies`
* `id` String (UUID, PK)
* `code` String (Unique, e.g. `TP-A1B2C`)
* `name` String
* `address` String?
* `phone` String?
* `logo` String?
* `createdAt` DateTime, `updatedAt` DateTime

### Table 2: `users`
* `id` String (UUID, PK)
* `email` String (Unique)
* `passwordHash` String
* `fullName` String
* `phoneNumber` String?
* `role` Enum (`ADMIN`, `TEACHER`, `STUDENT`, `PARENT`)
* `accountStatus` Enum (`ACTIVE`, `PENDING`, `REJECTED`)
* `academyId` String (FK -> `academies.id`)
* `assignedSections` String[] (JSON/Array of section codes)
* `createdAt` DateTime, `updatedAt` DateTime

### Table 3: `parent_student_relationships`
* `id` String (UUID, PK)
* `parentId` String (FK -> `users.id`)
* `studentId` String (FK -> `users.id`)
* `createdAt` DateTime

### Table 4: `classes`
* `id` String (UUID, PK)
* `academyId` String (FK -> `academies.id`)
* `className` String (e.g. "9th Grade")
* `section` String (e.g. "A")
* `subject` String
* `primaryTeacherId` String? (FK -> `users.id`)
* `createdAt` DateTime, `updatedAt` DateTime

### Table 5: `student_enrollments`
* `id` String (UUID, PK)
* `classId` String (FK -> `classes.id`)
* `studentId` String (FK -> `users.id`)
* `rollNumber` String?
* `createdAt` DateTime

### Table 6: `attendance_records`
* `id` String (UUID, PK, Unique Index: `classId_studentId_logDate`)
* `academyId` String (FK -> `academies.id`)
* `classId` String (FK -> `classes.id`)
* `studentId` String (FK -> `users.id`)
* `logDate` String (YYYY-MM-DD)
* `status` Enum (`PRESENT`, `ABSENT`, `LATE`)
* `markedById` String (FK -> `users.id`)
* `recordedAt` DateTime

### Table 7: `fee_challans`
* `id` String (UUID, PK)
* `academyId` String (FK -> `academies.id`)
* `challanNumber` String (Unique)
* `studentId` String (FK -> `users.id`)
* `studentName` String
* `fatherName` String?
* `classLabel` String
* `rollNumber` String?
* `issueDate` DateTime
* `dueDate` DateTime
* `monthlyFee` Decimal(10,2)
* `admissionFee` Decimal(10,2)
* `examFee` Decimal(10,2)
* `transportFee` Decimal(10,2)
* `fine` Decimal(10,2)
* `totalAmount` Decimal(10,2)
* `status` Enum (`PENDING`, `PAID`, `OVERDUE`)
* `createdAt` DateTime, `updatedAt` DateTime

### Table 8: `announcements`
* `id` String (UUID, PK)
* `academyId` String (FK -> `academies.id`)
* `title` String
* `message` String
* `targetRoles` String[] (JSON/Array)
* `createdById` String (FK -> `users.id`)
* `createdAt` DateTime, `updatedAt` DateTime

### Table 9: `quizzes`
* `id` String (UUID, PK)
* `academyId` String (FK -> `academies.id`)
* `classId` String (FK -> `classes.id`)
* `classLabel` String
* `title` String
* `subject` String
* `month` String?
* `session` String?
* `chapter` String?
* `difficulty` String?
* `totalMarks` Int
* `testDate` DateTime?
* `instructions` String?
* `createdById` String (FK -> `users.id`)
* `createdAt` DateTime

### Table 10: `quiz_questions`
* `id` String (UUID, PK)
* `quizId` String (FK -> `quizzes.id`, Cascade Delete)
* `text` String
* `type` String ("mcq" | "short")
* `options` String[] (JSON/Array)
* `correctIndex` Int?
* `marks` Int
* `gradingKeywords` String[] (JSON/Array)

### Table 11: `test_marks`
* `id` String (UUID, PK, Unique Index: `quizId_studentId`)
* `academyId` String (FK -> `academies.id`)
* `quizId` String (FK -> `quizzes.id`)
* `studentId` String (FK -> `users.id`)
* `studentName` String
* `classId` String (FK -> `classes.id`)
* `subject` String
* `month` String?
* `marksObtained` Double Precision
* `totalMarks` Double Precision
* `percentage` Double Precision
* `gradeLetter` String
* `teacherFeedback` String?
* `updatedAt` DateTime

### Table 12: `shared_resources`
* `id` String (UUID, PK)
* `academyId` String (FK -> `academies.id`)
* `classId` String (FK -> `classes.id`)
* `teacherId` String (FK -> `users.id`)
* `title` String
* `description` String?
* `fileUrl` String
* `createdAt` DateTime

### Table 13: `student_queries`
* `id` String (UUID, PK)
* `academyId` String (FK -> `academies.id`)
* `classId` String (FK -> `classes.id`)
* `studentId` String (FK -> `users.id`)
* `teacherId` String? (FK -> `users.id`)
* `question` String
* `answer` String?
* `isResolved` Boolean
* `createdAt` DateTime, `answeredAt` DateTime?

### Table 14: `ocr_documents`
* `id` String (UUID, PK)
* `createdById` String (FK -> `users.id`)
* `title` String
* `extractedText` String
* `createdAt` DateTime

### Table 15: `notifications`
* `id` String (UUID, PK)
* `academyId` String (FK -> `academies.id`)
* `recipientId` String (FK -> `users.id`)
* `title` String
* `message` String
* `type` String
* `isRead` Boolean
* `createdAt` DateTime

### Table 16: `timetable_slots`
* `id` String (UUID, PK)
* `academyId` String (FK -> `academies.id`)
* `classId` String (FK -> `classes.id`)
* `section` String
* `dayOfWeek` String
* `startTime` String
* `endTime` String
* `subject` String
* `teacherId` String (FK -> `users.id`)
* `createdAt` DateTime

### Table 17: `refresh_tokens`
* `id` String (UUID, PK)
* `userId` String (FK -> `users.id`, Cascade Delete)
* `token` String (Unique, Hashed)
* `expiresAt` DateTime
* `revoked` Boolean
* `createdAt` DateTime
