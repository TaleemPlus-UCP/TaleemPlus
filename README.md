# TaleemPlus 🚀

[![TaleemPlus CI/CD](https://github.com/TaleemPlus-UCP/TaleemPlus/actions/workflows/main.yml/badge.svg)](https://github.com/TaleemPlus-UCP/TaleemPlus/actions/workflows/main.yml)

**The All-in-One AI-Powered Academy Management System**

TaleemPlus is a modern, cross-platform (Android, iOS & Web) application that digitizes academy operations end-to-end. It provides dedicated portals for Administrators, Teachers, Students, and Parents, backed by a REST API and enhanced with 100% on-device Artificial Intelligence for automated grading, test generation, and performance insights.

---

## 🌟 Key Features

### 🏢 Admin Portal (Command Center)
* **User Management:** Centralized control to approve, edit, and manage staff and student accounts.
* **Class Scheduling & Timetable:** Build class sections, assign subject offerings, and manage a conflict-checked weekly timetable.
* **Bulk Fee Generation:** Create monthly challans for entire class sections in one action, or an ad-hoc challan for a single student.
* **AI Analytics:** Predict student "at-risk" levels and monitor academy revenue trends using on-device heuristics.
* **Announcements:** Broadcast notices to specific roles or the whole academy, with automatic in-app notification fan-out.

### 👨‍🏫 Teacher Portal (Digital Classroom)
* **Classroom Hub:** Share study resources (notes/links) and answer student queries.
* **AI Smart Grader:** Grade handwritten answers offline using OCR (Google ML Kit) + keyword-matching against teacher-defined rubrics.
* **AI Test Generator:** Scan textbook pages to auto-generate MCQ, short-answer, and long-answer questions.
* **Attendance Marking:** Day-sheet marking with monthly and yearly views per student.
* **Performance Tracking:** Enter quiz/test scores through a relational gradebook.

### 🎓 Student Portal (Learning Console)
* **My Classroom Hub:** View subject-wise resources and discuss topics with teachers.
* **AI Summarizer:** Generate concise, offline summaries from study notes.
* **Performance Analytics:** Visual progress charts and detailed test reports.
* **Fee Status:** Real-time tracking of paid and pending challans.

### 👪 Parent Portal (Child Monitoring)
* **Multi-Child Support:** Link multiple children to a single parent account.
* **Journey Monitoring:** Real-time visibility into each child's attendance, marks, and fee dues.
* **Direct Support:** Quick access to academy contact information and broadcasts.

---

## 🤖 AI & ML Capabilities (100% On-Device)

* **Google ML Kit (Deep Learning):** High-precision OCR for digitizing physical notes and answer sheets.
* **Heuristic NLP Algorithms:** Rule-based logic for automated test-paper generation and extractive text summarization.
* **TFLite Inference:** On-device classification model for student performance prediction.
* **Keyword Matcher:** Scoring engine for grading short answers against teacher-defined rubrics.

All AI/ML inference runs on-device in the Flutter app — the backend never sees raw OCR images, only already-extracted text.

---

## 🏗️ Architecture

```
Flutter app (Android / iOS / Web)
        │  REST + JWT (access/refresh tokens)
        ▼
Node.js / Express / TypeScript API  ──►  PostgreSQL (Prisma ORM)
```

* **Client:** Flutter (Dart), single codebase for Android, iOS, and Web.
* **API:** Node.js/Express, deployed as serverless functions.
* **Database:** PostgreSQL, provisioned separately from the API host.
* **Auth:** Self-issued JWT access/refresh tokens with rotation-on-use and theft detection — no third-party auth provider.
* **Web hosting:** the built Flutter web bundle is static-hosted separately from the API.

There is no Firebase dependency anywhere in this stack — the project originally used Firebase (Auth + Firestore + Hosting) and was fully migrated off it in favor of an owned Postgres schema and REST API. See [`backend/README.md`](backend/README.md) for the module-by-module rationale behind that migration.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter (Dart) — Provider for state management |
| **Backend** | Node.js, Express, TypeScript |
| **ORM / Migrations** | Prisma |
| **Database** | PostgreSQL |
| **Auth** | Self-issued JWT (access + refresh), bcrypt password hashing |
| **AI/ML** | Google ML Kit, TensorFlow Lite, heuristic NLP (all on-device) |
| **Other** | Local Auth (biometrics), PDF printing/sharing, fl_chart |

---

## 🚀 CI/CD & DevOps

A single GitHub Actions pipeline (`.github/workflows/main.yml`) runs on every push/PR to `main`:

1. **Flutter QA** — `dart format`, `flutter analyze`, `flutter test`.
2. **Backend QA** — ESLint, TypeScript build, and the Jest suite against a real Postgres service container.
3. **Android Release** — builds a split-per-ABI release APK and a Play Store `.aab`, uploaded as build artifacts.
4. **Web Deployment** — builds the Flutter web bundle and deploys it to static hosting.

Pushing a `v*` tag additionally runs a **Create GitHub Release** job that attaches the APK(s) and AAB from that run to a published GitHub Release with auto-generated release notes.

---

## 💻 Getting Started

### Prerequisites
* Flutter SDK (stable channel) + Dart SDK (`>=3.0.0`)
* Node.js 20+ and npm
* A PostgreSQL database (local, or a hosted instance such as Neon)

### 1. Clone the repository
```bash
git clone https://github.com/TaleemPlus-UCP/TaleemPlus.git
cd TaleemPlus
```

### 2. Backend
```bash
cd backend
npm install
cp .env.example .env      # fill in DATABASE_URL, JWT secrets, etc.
npx prisma migrate deploy
npm run dev                # API listens on http://localhost:4000
```
Full backend setup, module status, and design notes: [`backend/README.md`](backend/README.md). Deploying the backend to production: [`backend/DEPLOYMENT.md`](backend/DEPLOYMENT.md).

### 3. Flutter app
```bash
flutter pub get

# Point the app at your backend (defaults to an Android-emulator-only
# localhost alias if omitted — required for a real device or a
# non-default backend host):
flutter run --dart-define=API_BASE_URL=http://<your-backend-host>/api/v1
```

---

## 📄 License
This project is developed as a **Final Year Project (FYP)** for BSCS (Spring 23). All rights reserved.

---
**TaleemPlus** — *Empowering Academies through Intelligent Automation.*
