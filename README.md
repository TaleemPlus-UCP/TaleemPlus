# TaleemPlus 🚀
[![TaleemPlus CI/CD](https://github.com/TaleemPlus-UCP/TaleemPlus/actions/workflows/main.yml/badge.svg)](https://github.com/TaleemPlus-UCP/TaleemPlus/actions/workflows/main.yml)

**The All-in-One AI-Powered Academy Management System**

TaleemPlus is a modern, cross-platform (Android, iOS, & Web) application designed to digitize academy operations. It provides specialized portals for Administrators, Teachers, Students, and Parents, enhanced with 100% offline Artificial Intelligence for automated grading, test generation, and performance insights.

---

## 🌟 Key Features

### 🏢 Admin Portal (Command Center)
*   **User Management:** Centralized control to add, edit, and approve staff and students.
*   **Bulk Fee Generation:** Create monthly challans for entire classes with a single tap.
*   **Class Management:** Create classes, assign multiple subjects to teachers, and manage enrollments.
*   **AI Analytics:** Predict student "At-Risk" levels and monitor academy revenue trends using local ML.
*   **Announcements:** Broadcast important notices to specific roles or the whole academy.

### 👨‍🏫 Teacher Portal (Digital Classroom)
*   **Classroom Hub:** Share study resources (Notes/Links) and answer student queries in real-time.
*   **AI Smart Grader:** Grade handwritten student papers 100% offline using OCR and keyword matching.
*   **AI Test Generator:** Scan textbook pages to auto-generate MCQs, Short, and Long questions.
*   **Attendance Marking:** Digital presence tracking for all assigned classes.
*   **Performance Tracking:** Enter and monitor student test scores.

### 🎓 Student Portal (Learning Console)
*   **My Classroom Hub:** View subject-wise resources, track subject-specific attendance, and discuss topics with teachers.
*   **AI Summarizer:** Generate concise summaries from large study notes 100% offline.
*   **Performance Analytics:** Visual progress charts and detailed test reports.
*   **Fee Status:** Real-time tracking of paid and pending challans.

### 👪 Parent Portal (Child Monitoring)
*   **Multi-Child Support:** Link multiple children to a single parent dashboard.
*   **Journey Monitoring:** Real-time visibility into children's attendance, marks, and fee dues.
*   **Direct Support:** Easy access to academy contact information and broadcasts.

---

## 🤖 AI & ML Capabilities (100% Offline)

*   **Google ML Kit (Deep Learning):** High-precision OCR used for digitizing physical notes and answer sheets.
*   **Heuristic NLP Algorithms:** Rule-based logic for automated test paper generation and extractive text summarization.
*   **TFLite Inference:** On-device execution of a custom classification model for student performance prediction.
*   **Keyword Matcher:** Intelligent scoring system for grading short answers based on teacher-defined rubrics.

---

## 🛠️ Tech Stack

*   **Frontend:** Flutter (Dart) - Responsive UI for Mobile & Web.
*   **State Management:** Provider.
*   **Backend:** Firebase (Authentication, Firestore, Hosting).
*   **AI/ML:** Google ML Kit, TensorFlow Lite, Heuristic Logic.
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
