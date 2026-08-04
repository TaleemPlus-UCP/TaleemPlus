# TaleemPlus 🚀
[![TaleemPlus CI/CD](https://github.com/TaleemPlus-UCP/TaleemPlus/actions/workflows/main.yml/badge.svg)](https://github.com/TaleemPlus-UCP/TaleemPlus/actions/workflows/main.yml)

**The All-in-One AI-Powered Academy Management System**

TaleemPlus is a modern, cross-platform (Android, iOS, & Web) application designed to digitize academy operations. It provides specialized portals for Administrators, Teachers, Students, and Parents, enhanced with 100% offline Artificial Intelligence for automated grading, test generation, and performance insights.

---

## 🌟 Key Features

### 🏢 Admin Portal (Command Center)
*   **User Management:** Add, edit, and approve staff and students — including class-wise student enrollment with unique roll numbers and searchable, multi-child parent↔student linking.
*   **Academic Structure:** Admin-configurable levels and groups (defaults to Matric — Science/Arts and Intermediate — FSc Pre-Medical/FSc Pre-Engineering/ICS/ICom/FA), used everywhere classes are selected across admissions, attendance, fees, and reports.
*   **Class & Section Management:** Create class+section rosters, view enrolled students, and manage teacher assignments per section.
*   **Timetable Scheduling:** Class-wise and section-wise scheduling that proactively hides teachers already booked at a chosen time slot.
*   **Fee Management:** Class+section-wise bulk challan generation, a read-only class+section fee analytics ledger (paid/pending/overdue/collection %), and an academy-wide unpaid-students view.
*   **Class Reports:** Generate and delete point-in-time class+section snapshots covering attendance and fee standing.
*   **AI Analytics:** Predict fee-delay risk and forecast student performance from real fee-ledger records using trained on-device ML models (see below).
*   **Announcements:** Broadcast important notices to specific roles or the whole academy.
*   **Dashboard at a Glance:** Role-specific stat cards for staff/student/parent counts, fee summary, today's attendance, and announcements.

### 👨‍🏫 Teacher Portal (Digital Classroom)
*   **My Classes, Resources, and Queries:** Dedicated dashboard entries for subject-wise attendance, shared classroom resources, and student queries.
*   **AI Test Generator:** Scan textbook pages to auto-generate MCQ/Short/Long questions, grouped into sections with an auto-computed Total Marks and a matching sectioned PDF export.
*   **Subject-wise Attendance Marking:** Digital presence tracking, with edit support, for every assigned class.
*   **OCR → Resource Publishing:** Scanned documents land automatically in OCR Documents; publish selected ones straight to a class's Shared Resources — no manual resource uploads.
*   **Performance Tracking:** Enter, edit, and delete individual student test scores.

### 🎓 Student Portal (Learning Console)
*   **My Classroom Hub:** View subject-wise resources, and discuss topics with teachers.
*   **Day-by-Day Attendance:** Attendance history grouped by date, showing every subject attended that day at a glance — shared with the parent portal's child attendance view.
*   **AI Summarizer:** TextRank-based extractive summaries from large study notes, 100% offline.
*   **Performance Analytics:** Visual progress charts and detailed test reports.
*   **Fee Status:** Real-time tracking of paid and pending challans.

### 👪 Parent Portal (Child Monitoring)
*   **Multi-Child Support:** Link multiple children to a single parent dashboard (by an admin at account creation, or self-service from the parent dashboard).
*   **Journey Monitoring:** Real-time visibility into children's day-by-day attendance, marks, and fee dues.
*   **Direct Support:** Easy access to academy contact information and broadcasts.

---

## 🤖 AI & ML Capabilities (100% Offline)

*   **Google ML Kit (Deep Learning):** High-precision OCR used for digitizing physical notes and answer sheets.
*   **Trained On-Device ML Models:** A logistic-regression fee-delay-risk model and a linear-regression performance-forecast model, trained in Python (`ml_training/`) and ported to plain Dart — no TensorFlow Lite runtime dependency.
*   **TextRank Summarization:** Unsupervised graph-based sentence ranking (Mihalcea & Tarau, 2004) for extractive note summarization — no training data required.
*   **TF-IDF Cosine-Similarity Grading:** Grades short/long answers by vector-space similarity to teacher-defined keywords, weighted by how distinctive each keyword is across the quiz's own questions.
*   **Heuristic NLP Algorithms:** Rule-based logic for automated test paper generation (question extraction from scanned notes).

---

## 🛠️ Tech Stack

*   **Frontend:** Flutter (Dart) - Responsive UI for Mobile & Web.
*   **State Management:** Provider.
*   **Backend:** Firebase (Authentication, Firestore, Hosting).
*   **AI/ML:** Google ML Kit, scikit-learn-trained models ported to Dart, TextRank, TF-IDF cosine similarity, Heuristic Logic.
*   **Utilities:** Local Auth (Biometrics), PDF Printing/Sharing, fl_chart.

---

## 🚀 CI/CD & DevOps

The project includes a **GitHub Actions** pipeline that automatically:
1.  Analyzes the code for errors.
2.  Runs unit and integration tests.
3.  Builds the **Android Release APK**.
4.  Builds the **Web Version** ready for deployment.

---

## 💻 Getting Started

### Prerequisites
*   Flutter SDK (v3.22.x or later)
*   Dart SDK (v3.x)
*   Firebase Account

### Installation
1.  Clone the repository:
    ```bash
    git clone https://github.com/TaleemPlus-UCP/TaleemPlus.git
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Configure Firebase:
    ```bash
    flutterfire configure
    ```
4.  Run the application:
    *   **Mobile:** `flutter run`
    *   **Web:** `flutter run -d chrome`

---

## 📄 License
This project is developed as a **Final Year Project (FYP)** for BSCS (Spring 23). All rights reserved.

---
**TaleemPlus** — *Empowering Academies through Intelligent Automation.*
