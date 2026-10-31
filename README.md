# TaleemPlus 🚀 — Complete Technical Documentation & README

> **The All-in-One Offline-First AI-Powered Academy Management System**  
> *Cross-Platform Mobile & Web SaaS Application for Academies & Educational Institutes*

---

## 📋 Table of Contents
1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Project Requirements](#3-project-requirements)
4. [Installation and Setup](#4-installation-and-setup)
5. [Complete Project Directory Structure](#5-complete-project-directory-structure)
6. [Application Architecture](#6-application-architecture)
7. [Application Entry Point and Execution Flow](#7-application-entry-point-and-execution-flow)
8. [Feature-by-Feature Documentation](#8-feature-by-feature-documentation)
9. [File-by-File Reference](#9-file-by-file-reference)
10. [UI and Screen Documentation](#10-ui-and-screen-documentation)
11. [Database and Data Management](#11-database-and-data-management)
12. [API and Backend Documentation](#12-api-and-backend-documentation)
13. [Dependencies and Configuration](#13-dependencies-and-configuration)
14. [Navigation Map](#14-navigation-map)
15. [How to Modify the Project](#15-how-to-modify-the-project)
16. [Debugging and Troubleshooting](#16-debugging-and-troubleshooting)
17. [Testing](#17-testing)
18. [Security](#18-security)
19. [Known Issues and Technical Debt](#19-known-issues-and-technical-debt)
20. [Development Roadmap](#20-development-roadmap)
21. [Glossary](#21-glossary)
22. [Project Documentation Limitations](#22-project-documentation-limitations)

---

## 1. Project Overview

### Project Name & Application Identification
* **Project Name:** TaleemPlus (`taleemplus_app`)
* **Android Application ID / Package Name:** `com.example.taleem_plus`
* **Version:** `0.5.1+1` (SDK Target: Flutter `>=3.0.0 <4.0.0`)
* **Project Type:** Multi-Tenant Cross-Platform Educational ERP & SaaS (Android, iOS, Web)

### Application Purpose & Core Value Proposition
**TaleemPlus** is an offline-first, AI-enhanced academy management system created to digitize physical educational institutes, private academies, and tuition centers. It unifies administrative operations, teacher workflows, student learning consoles, and parent monitoring into four role-based portals while executing all AI/ML logic **100% on-device** (zero cloud-AI runtime dependencies).

### Problem It Solves
1. **Administrative Overhead:** Automates class structure setup, section allocation, teacher scheduling, automated timetable collision detection, and bulk monthly fee challan generation.
2. **Manual Grading & Test Creation Bottlenecks:** Replaces hours of manual paper setting and grading with AI-driven test paper generation from scanned notes and automated short-answer scoring.
3. **Student Retention & Risk Identification:** Provides data-driven insights into fee default risks and student performance drops using custom on-device machine learning models.
4. **Parent-Academy Communication Gap:** Replaces informal messaging with multi-child progress tracking, real-time day-by-day attendance views, fee ledger visibility, and direct broadcast notifications.

### Target Users & Role Portals
* **Administrators (`admin`):** Full control over users, approval requests, academic structure, classes, timetable, fee ledgers, PDF challans, and AI analytics.
* **Teachers (`teacher`):** Attendance marking, AI paper generation, AI paper grading, OCR resource scanning/publishing, query handling, and mark entry.
* **Students (`student`):** Classroom resource access, day-by-day attendance records, AI note summarization, test result progress charts, and fee status tracking.
* **Parents (`parent`):** Multi-child linked monitoring for attendance, test marks, fee challans, and direct contact with academy management.

### Current Implementation Status
Fully implemented, verified, and operational on Android, iOS, and Web platforms. Includes complete unit tests for core ML/NLP algorithms, integration tests for UI bootstrap, and automated CI/CD pipeline deployment to Firebase Hosting and GitHub Releases.

---

## 2. Technology Stack

| Layer / Category | Technology | Version / Specification | Project Role & Implementation Details |
|---|---|---|---|
| **Programming Languages** | **Dart** | `^3.0.0` | Primary language for Flutter cross-platform UI, business logic, ML models, and algorithms. |
| | **Kotlin** | JVM Target `17` | Native Android runner integration (`MainActivity.kt`, `build.gradle.kts`). |
| | **Python** | `3.9+` | Used in `ml_training/` for synthetic data generation and scikit-learn model training. |
| **Framework** | **Flutter** | `>=3.22.x` | Cross-platform UI toolkit targeting Mobile (Android/iOS) and Web. |
| **UI Design & Styling** | **Material Design 3** | Material 3 enabled | Adaptable UI with `AppTheme` (Mobile) and SaaS-optimized `AppWebTheme` (Web with Google Fonts 'Inter'). |
| | **Data Visualization** | `fl_chart ^0.68.0` | Renders performance charts and fee breakdown graphs across Admin, Student, and Parent dashboards. |
| **State Management** | **Provider** | `provider ^6.1.2` | `ChangeNotifier` & `ChangeNotifierProxyProvider` pattern separating UI, business logic, and data. |
| **Cloud Backend** | **Firebase Core** | `firebase_core ^3.1.0` | App initialization and global configuration. |
| | **Firebase Auth** | `firebase_auth ^5.1.0` | User sign-in, account creation, password reset, and session verification. |
| | **Cloud Firestore** | `cloud_firestore ^5.0.1` | Primary multi-tenant NoSQL database (`academy_id` partition key). |
| | **Firebase Hosting** | Hosting CLI | Automated web deployment (`taleemplus-40755.web.app`). |
| **Local Storage** | **SQLite (`sqflite`)** | `sqflite ^2.3.3` | Local database (`taleemplus_v2.db` v6) backing admin `members` and legacy `fee_invoices`. |
| | **Shared Preferences** | `shared_preferences ^2.5.5` | Persists user theme mode, "Remember Me" email, biometric toggle, and cached credentials. |
| **On-Device AI & ML** | **Google ML Kit** | `google_mlkit_text_recognition ^0.13.0` | On-device deep-learning OCR for scanning printed textbooks, hand-written notes, and answer sheets. |
| | **Fee Risk Model** | Custom Dart Port | On-device Logistic Regression predicting fee-delay risk probabilities (`lib/logic/fee_risk_model.dart`). |
| | **Performance Model** | Custom Dart Port | On-device Linear Regression predicting student academic performance index (`lib/logic/performance_index_model.dart`). |
| | **TextRank NLP** | Heuristic Algorithm | Extractive graph-based note summarizer (`lib/logic/text_rank_summarizer.dart`). |
| | **TF-IDF Engine** | Heuristic Algorithm | Cosine-similarity weighted short-answer paper grading engine (`lib/logic/tfidf_grader.dart`). |
| **Biometrics & Security** | **Local Auth** | `local_auth ^2.3.0` | Hardware biometric verification (Fingerprint / Face ID unlock). |
| **PDF & Printing** | **Dart PDF & Printing** | `pdf ^3.13.0`, `printing ^5.13.0` | Generates printable PDF fee challans with QR codes, test paper prints, and report snapshots. |
| **Build & CI/CD** | **Gradle** | `8.x` (AGP `8.x`) | Android build system utilizing Kotlin Gradle DSL (`.gradle.kts`). |
| | **GitHub Actions** | Workflow (`main.yml`) | Automated formatting, analysis, testing, Android release APK build, and Web deployment. |

---

## 3. Project Requirements

### Software & Environment Requirements
* **Flutter SDK:** Version `3.22.0` or higher (compatible with Dart `3.x`).
* **Dart SDK:** Included with Flutter SDK (`>=3.0.0 <4.0.0`).
* **Java Development Kit (JDK):** JDK 17 (Required for Android Gradle compilation compatibility).
* **Android Studio:** Android Studio Ladybug (2024.2.1+) or newer with Flutter & Dart plugins installed.
* **Android SDK:** Compile SDK `34` (Android 14), Min SDK `21` (Android 5.0 Lollipop), Target SDK `34`.
* **Git:** For source control and repository cloning.
* **Python (Optional):** Python `3.9+` with `pandas` and `scikit-learn` (only needed if re-running scripts in `ml_training/`).

---

## 4. Installation and Setup

Follow these steps to set up the development environment and run **TaleemPlus** on a new machine:

### Step 1: Clone the Repository
```bash
git clone https://github.com/TaleemPlus-UCP/TaleemPlus.git
cd TaleemPlus
```

### Step 2: Install Flutter Dependencies
Run the following command to download and link all required Dart and Flutter packages:
```bash
flutter pub get
```

### Step 3: Configure Firebase Services
1. Ensure you have the [Firebase CLI](https://firebase.google.com/docs/cli) and [FlutterFire CLI](https://firebase.google.com/docs/cli/flutterfire) installed.
2. Log in to Firebase:
   ```bash
   firebase login
   ```
3. Configure FlutterFire for your project:
   ```bash
   flutterfire configure
   ```
   *This command auto-generates `lib/firebase_options.dart` and places `google-services.json` into `android/app/`.*

### Step 4: Configure Android Build Requirements
Ensure JDK 17 is configured in Android Studio under **Settings > Build, Execution, Deployment > Build Tools > Gradle > Gradle JDK**.

### Step 5: Run the Application
* **To run on an Android Device / Emulator:**
  ```bash
  flutter run
  ```
* **To run on Google Chrome (Web Mode):**
  ```bash
  flutter run -d chrome
  ```

### Step 6: Build Debug & Release APKs
* **Build Debug APK:**
  ```bash
  flutter build apk --debug
  ```
  *Output Path:* `build/app/outputs/flutter-apk/app-debug.apk`
* **Build Split Release APKs:**
  ```bash
  flutter build apk --release --split-per-abi
  ```
  *Output Path:* `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`, `app-arm64-v8a-release.apk`, `app-x86_64-release.apk`

---

## 5. Complete Project Directory Structure

```text
TaleemPlus/
├── .github/
│   └── workflows/
│       └── main.yml                  # GitHub Actions CI/CD pipeline configuration
├── android/
│   ├── app/
│   │   ├── src/
│   │   │   ├── debug/AndroidManifest.xml
│   │   │   ├── main/
│   │   │   │   ├── kotlin/com/example/taleem_plus/MainActivity.kt
│   │   │   │   ├── res/              # App launcher icons, drawables, XML launcher themes
│   │   │   │   └── AndroidManifest.xml # Android permissions and activity configurations
│   │   │   └── profile/AndroidManifest.xml
│   │   ├── build.gradle.kts          # App-level Gradle config (plugins, SDK versions, signing)
│   │   └── proguard-rules.pro        # ProGuard obfuscation & keep rules
│   ├── gradle/wrapper/               # Gradle wrapper properties and jar
│   ├── build.gradle.kts              # Project-level Gradle config (repositories, Java 17 enforce)
│   ├── gradle.properties             # JVM arguments and AndroidX properties
│   └── settings.gradle.kts           # Plugin management and repository settings
├── assets/
│   ├── images/                       # App icons, logos, and illustration assets
│   └── ml_models/                    # ML model artifacts placeholder directory
├── integration_test/
│   └── example_test.dart             # Flutter integration test for app startup & login UI
├── ios/                              # Native iOS runner project configurations
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart    # AppRoutes, UserRole enum, DbKeys, AppRules
│   │   ├── theme/
│   │   │   ├── app_colors.dart       # Material color palettes (Primary, Secondary, Surface, Danger)
│   │   │   ├── app_theme.dart        # Mobile light and dark ThemeData configurations
│   │   │   └── theme_extensions.dart # Custom ThemeExtension helpers for UI components
│   │   ├── utils/
│   │   │   └── validators.dart       # Form field validation functions (Email, Password, Phone)
│   │   └── web/
│   │       ├── web_breakpoints.dart  # Responsive layout breakpoint thresholds
│   │       └── web_theme.dart        # Inter-font SaaS Web ThemeData light and dark configurations
│   ├── data/
│   │   ├── local/
│   │   │   └── db_helper.dart        # sqflite SQLite helper for admin members & fee invoices
│   │   ├── models/                   # Plain Dart Data Models with toMap() & fromMap()
│   │   │   ├── academic_structure.dart # Level (Matric/Inter) and Group (Science/Arts/FSc) models
│   │   │   ├── academy_member.dart   # Admin member view object
│   │   │   ├── announcement.dart     # System broadcast announcement data structure
│   │   │   ├── app_user.dart         # Canonical AppUser profile model matching Firestore users/{uid}
│   │   │   ├── attendance_record.dart# Daily attendance log entry data model
│   │   │   ├── class_entity.dart     # Class & section roster model with student UID lists
│   │   │   ├── class_report_model.dart # Point-in-time class snapshot report model
│   │   │   ├── class_section.dart    # Independent section entity model
│   │   │   ├── fee_challan_model.dart# Printable fee challan data model (amounts, status, due date)
│   │   │   ├── notification_model.dart# Recipient-scoped push/in-app notification model
│   │   │   ├── quiz_model.dart       # Quiz entity & embedded QuizQuestion list models
│   │   │   ├── quiz_submission_model.dart # Student quiz submission response model
│   │   │   ├── shared_resource.dart  # Classroom learning resource attachment model
│   │   │   ├── student_query.dart    # Student-to-teacher Q&A discussion thread model
│   │   │   ├── test_mark_model.dart  # Gradebook mark record model (marks, percentage, letter grade)
│   │   │   └── timetable_slot.dart   # Timetable schedule slot entity with collision properties
│   │   ├── remote/                   # Stateless Firestore & Firebase API wrappers
│   │   │   ├── academic_structure_service.dart
│   │   │   ├── announcement_service.dart
│   │   │   ├── auth_service.dart     # FirebaseAuth wrapper & user profile Firestore manager
│   │   │   ├── challan_pdf_service.dart # PDF fee challan generator with QR code rendering
│   │   │   ├── classroom_service.dart
│   │   │   ├── notification_service.dart
│   │   │   ├── pdf_generator_service.dart # PDF test paper & monthly report generator
│   │   │   ├── quiz_service.dart
│   │   │   └── timetable_service.dart
│   │   └── repositories/             # Data Repositories linking Firestore and UI logic
│   │       ├── attendance_repository.dart
│   │       ├── class_report_repository.dart
│   │       ├── class_repository.dart
│   │       ├── class_section_repository.dart
│   │       ├── fee_challan_repository.dart
│   │       └── member_repository.dart
│   ├── features/                     # UI Screen Layouts grouped by Portal/Domain
│   │   ├── admin/                    # Admin Portal Screens
│   │   │   ├── screens/
│   │   │   │   ├── academic_structure_screen.dart # Level & group management
│   │   │   │   ├── challan_generation_screen.dart # Bulk fee challan generator
│   │   │   │   ├── class_fee_status_screen.dart   # Section fee breakdown
│   │   │   │   ├── class_reports_screen.dart      # Class snapshot report screen
│   │   │   │   ├── timetable_management_screen.dart # Interactive schedule grid
│   │   │   │   └── unpaid_students_screen.dart    # Defaulter tracking screen
│   │   │   ├── admin_ai_prediction_screen.dart    # AI fee risk & performance insights
│   │   │   ├── admin_dashboard.dart                # Main Admin Portal navigation container
│   │   │   ├── admin_quiz_list_screen.dart         # Academy-wide test list
│   │   │   ├── announcements_screen.dart          # Broadcast creation screen
│   │   │   ├── approval_requests_screen.dart       # User account approval console
│   │   │   ├── class_management_screen.dart        # Class setup & teacher assignment
│   │   │   ├── class_sections_screen.dart          # Section roster manager
│   │   │   ├── fee_ledger_screen.dart              # Academy fee collection analytics
│   │   │   └── user_management_screen.dart         # User creation, editing, child linking
│   │   ├── auth/                     # Authentication Screens
│   │   │   ├── login_screen.dart     # Email/password & biometric login screen
│   │   │   ├── signup_screen.dart    # Register academy / Join academy flow
│   │   │   └── splash_screen.dart    # Animated startup session restoration screen
│   │   ├── ocr/                      # OCR & Text Scanner Feature
│   │   │   ├── models/ocr_document_model.dart
│   │   │   ├── screens/
│   │   │   │   ├── ocr_document_view_screen.dart
│   │   │   │   ├── ocr_history_screen.dart
│   │   │   │   └── ocr_scanner_screen.dart     # ML Kit camera/gallery OCR scanner
│   │   │   └── services/
│   │   │       ├── ocr_firestore_service.dart
│   │   │       ├── ocr_publish_service.dart
│   │   │       └── ocr_service.dart            # Wraps google_mlkit_text_recognition
│   │   ├── parent/                   # Parent Portal Screens
│   │   │   ├── screens/
│   │   │   │   ├── academy_contact_screen.dart
│   │   │   │   ├── all_challans_screen.dart
│   │   │   │   ├── child_alerts_screen.dart
│   │   │   │   ├── child_overview_screen.dart  # Multi-child tabbed monitoring
│   │   │   │   ├── child_timetable_screen.dart
│   │   │   │   └── student_challan_screen.dart
│   │   │   └── parent_dashboard.dart           # Main Parent Portal navigation container
│   │   ├── quiz/                     # Quiz & Grading Shared Screens
│   │   │   └── screens/
│   │   │       ├── ai_paper_grader_screen.dart # TF-IDF automated test paper grader
│   │   │       ├── create_quiz_screen.dart    # Manual & AI question test paper generator
│   │   │       ├── mark_entry_screen.dart      # Teacher gradebook entry screen
│   │   │       ├── monthly_report_screen.dart  # Student monthly performance view
│   │   │       ├── quiz_results_screen.dart   # Individual test result breakdown
│   │   │       ├── student_test_report_screen.dart
│   │   │       ├── take_quiz_screen.dart       # On-paper test instructions screen
│   │   │       └── teacher_quiz_list_screen.dart
│   │   ├── shared/                   # Role-Agnostic Common Screens
│   │   │   ├── notifications_screen.dart     # Notification inbox view
│   │   │   ├── timetable_view.dart           # Read-only schedule grid widget
│   │   │   └── view_announcements_screen.dart # Student/Parent announcement feed
│   │   ├── student/                  # Student Portal Screens
│   │   │   ├── screens/
│   │   │   │   ├── ai_summarizer_screen.dart   # TextRank offline note summarizer
│   │   │   │   ├── my_classroom_hub.dart       # Subject resources & discussion threads
│   │   │   │   ├── my_timetable_screen.dart
│   │   │   │   ├── student_attendance_screen.dart # Day-by-day attendance history
│   │   │   │   ├── student_fee_screen.dart     # Personal fee challans view
│   │   │   │   ├── student_progress_chart_screen.dart # Performance line charts
│   │   │   │   └── teacher_details_screen.dart
│   │   │   └── student_dashboard.dart          # Main Student Portal navigation container
│   │   └── teacher/                  # Teacher Portal Screens
│   │       ├── screens/
│   │       │   ├── classroom_management_screen.dart
│   │       │   └── my_timetable_screen.dart
│   │       ├── attendance_marking_screen.dart  # Class attendance digital roll call
│   │       ├── teacher_announcements_screen.dart
│   │       ├── teacher_classes_screen.dart
│   │       └── teacher_dashboard.dart          # Main Teacher Portal navigation container
│   ├── logic/                        # Provider State Management & AI Algorithms
│   │   ├── academic_structure_provider.dart
│   │   ├── admin_ai_provider.dart    # Orchestrates AI analytics calculation over Firestore
│   │   ├── attendance_provider.dart
│   │   ├── auth_provider.dart        # Authentication & current user state owner
│   │   ├── class_provider.dart
│   │   ├── class_section_provider.dart
│   │   ├── fee_analytics_service.dart
│   │   ├── fee_risk_model.dart       # Pure Dart Logistic Regression model
│   │   ├── member_provider.dart      # Merges local sqflite members and Firestore users
│   │   ├── parent_provider.dart      # Multi-child data loader for parents
│   │   ├── performance_index_model.dart # Pure Dart Linear Regression model
│   │   ├── quiz_provider.dart
│   │   ├── session_provider.dart     # Inactivity auto-logout & biometric unlock owner
│   │   ├── text_rank_summarizer.dart # Pure Dart TextRank graph algorithm implementation
│   │   ├── tfidf_grader.dart         # Pure Dart TF-IDF cosine-similarity grading logic
│   │   ├── theme_provider.dart       # Light/Dark theme state manager
│   │   └── timetable_provider.dart
│   ├── widgets/                      # Reusable Custom UI Components
│   │   ├── web/                      # Responsive Web Components (Tables, Cards)
│   │   │   ├── web_cards.dart
│   │   │   └── web_data_table.dart
│   │   ├── academy_relink_dialog.dart
│   │   ├── admin_extra_stats_row.dart
│   │   ├── app_widgets.dart
│   │   ├── dashboard_stat_card.dart
│   │   ├── gradient_background.dart
│   │   ├── latest_announcement_card.dart
│   │   ├── parent_stats_row.dart
│   │   ├── role_dashboard_scaffold.dart # (Legacy placeholder scaffold)
│   │   ├── security_question_dialog.dart
│   │   ├── student_picker_field.dart
│   │   ├── student_roster_dialog.dart
│   │   ├── teacher_stats_row.dart
│   │   └── theme_toggle_widget.dart
│   └── main.dart                     # Application Bootstrap & Root Route Configuration
├── ml_training/                      # Python Training Workspace for Offline Models
│   ├── data/
│   │   └── synthetic_dataset.csv     # Synthetic dataset (800 student records)
│   ├── export_tflite.py              # Reference script for model conversion
│   ├── generate_synthetic_data.py    # Generates realistic synthetic dataset
│   ├── requirements.txt              # Python requirements (pandas, scikit-learn)
│   └── train_risk_model.py           # Trains models & prints Dart coefficients
├── test/                             # Unit Test Suite
│   ├── fee_risk_model_test.dart
│   ├── performance_index_model_test.dart
│   ├── text_rank_summarizer_test.dart
│   └── tfidf_grader_test.dart
├── web/                              # Flutter Web static entry points & assets
├── Architecture.md                   # System Architecture Documentation
├── database.md                       # Firestore & SQLite Database Schema Specs
├── errorhandling.md                  # System Error Handling Patterns
├── firebase.json                     # Firebase CLI project configuration
├── firestore.indexes.json            # Firestore composite index definitions
├── firestore.rules                   # Production Firestore Security Rules
├── phases.md                         # Historical Development Milestones
├── prompt.md                         # Detailed AI/ML Heuristic Specification
├── pubspec.yaml                      # Flutter Dependency Manifest
└── security.md                       # Security Architecture & Rules Specification
```

---

## 6. Application Architecture

TaleemPlus implements a multi-tenant, layered **Provider-based MVVM (Model-View-ViewModel)** architecture pattern:

```mermaid
flowchart TD
    subgraph Client UI Layer ("Flutter UI (features/*)")
        AdminUI[Admin Dashboard & Screens]
        TeacherUI[Teacher Dashboard & Screens]
        StudentUI[Student Dashboard & Screens]
        ParentUI[Parent Dashboard & Screens]
    end

    subgraph State Management Layer ("Provider Logic (logic/*)")
        AuthProvider[AuthProvider]
        SessionProvider[SessionProvider]
        FeeProvider[Fee/Class Providers]
        AdminAiProvider[AdminAiProvider]
    end

    subgraph On-Device AI Engine ("100% Offline AI (logic/*)")
        FeeRiskModel[FeeRiskModel (Logistic Reg)]
        PerfModel[PerformanceIndexModel (Linear Reg)]
        TextRank[TextRankSummarizer]
        TfIdf[TfIdfGrader Engine]
        MLKit[Google ML Kit OCR]
    end

    subgraph Data & Storage Layer ("Data Repositories (data/*)")
        RemoteServices[Firestore Services (data/remote/*)]
        LocalDB[sqflite DbHelper (taleemplus_v2.db)]
        SharedPrefs[Shared Preferences]
    end

    subgraph Cloud Backend ("Firebase Cloud Infrastructure")
        FirebaseAuth[Firebase Auth]
        Firestore[Cloud Firestore (Partitioned by academy_id)]
    end

    %% Flow Connections
    AdminUI --> AdminAiProvider
    TeacherUI --> FeeProvider
    StudentUI --> AuthProvider
    ParentUI --> AuthProvider

    AdminAiProvider --> FeeRiskModel
    AdminAiProvider --> PerfModel
    TeacherUI --> MLKit
    TeacherUI --> TfIdf
    StudentUI --> TextRank

    AuthProvider --> RemoteServices
    FeeProvider --> RemoteServices
    SessionProvider --> SharedPrefs

    RemoteServices --> FirebaseAuth
    RemoteServices --> Firestore
    FeeProvider --> LocalDB
```

### Multi-Tenancy Architecture (`academy_id`)
* **Tenant Isolation:** Every data document across Cloud Firestore (except user-private OCR documents) is explicitly scoped by an `academy_id` string field.
* **Tenant Root:** For an **Admin**, `academy_id == auth.uid`. For Teachers, Students, and Parents, `academy_id` is assigned to the admin's UID upon joining via an academy code (`TP-XXXXX`).
* **Server-Side Enforcement:** Enforced rigidly at the database level by `firestore.rules` using the `sameAcademy(docAcademyId)` security function.

---

## 7. Application Entry Point and Execution Flow

1. **Bootstrap Initialization (`lib/main.dart`):**
   * Executes `WidgetsFlutterBinding.ensureInitialized()`.
   * Initializes Firebase via `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
   * Mounts a root `MultiProvider` registering 11 feature providers and 2 proxy providers (`ParentProvider` and `SessionProvider`).
2. **App Launch & Theme Application:**
   * Launches `TaleemPlusApp`. Evaluates runtime platform via `kIsWeb`. If web, applies `AppWebTheme` (Inter Google Font, SaaS responsive tables); if mobile, applies standard `AppTheme`.
3. **Splash Screen Bootstrap (`lib/features/auth/splash_screen.dart`):**
   * Calls `AuthProvider.tryRestoreSession()`.
   * Checks for an existing Firebase Auth session. If present, fetches `users/{uid}` from Firestore.
   * Verifies `account_status == "active"`. If active, navigates directly to `user.role.dashboardRoute`. If pending, rejected, or unauthenticated, redirects to `LoginScreen`.
4. **Session Activity Tracking:**
   * The root widget wraps `MaterialApp` in a pointer `Listener` and `NavigatorObserver` linked to `SessionProvider`.
   * Resets a 5-minute inactivity timer on every tap or route transition. On timeout, triggers forced sign-out and redirects to `LoginScreen`.

---

## 8. Feature-by-Feature Documentation

### 1. Account Creation & Role-Based Sign-In
* **Purpose:** Secure authentication supporting Admin tenant creation and user signup via unique academy codes.
* **Mechanism:** Admins register a new academy generating a `TP-XXXXX` code and `active` status. Teachers/Students/Parents sign up using the code, creating a `pending` account that requires Admin approval.
* **Biometric Authentication:** Supports hardware fingerprint/face unlock via `local_auth`. Validates cached credentials against Firebase Auth prior to unlock.
* **Key Files:** `lib/features/auth/login_screen.dart`, `signup_screen.dart`, `splash_screen.dart`, `lib/data/remote/auth_service.dart`, `lib/logic/session_provider.dart`.

### 2. Admin Command Center & Management
* **User Approval Console:** Displays pending registrations with one-tap Approve/Reject buttons fanning out status notifications (`approval_requests_screen.dart`).
* **Academic Structure & Classes:** Configure academic levels (Matric, Inter) and groups (Science, Arts, Pre-Medical, ICS). Assign primary teachers and enroll student rosters (`academic_structure_screen.dart`, `class_management_screen.dart`).
* **Interactive Timetable Scheduler:** Multi-slot weekly scheduling with built-in teacher double-booking detection (`timetable_management_screen.dart`).
* **Fee Management & Ledger:** Generate bulk monthly challans, track collection percentages, view unpaid student defaulters, and print PDF challans with QR codes (`challan_generation_screen.dart`, `fee_ledger_screen.dart`).

### 3. AI Insights & Risk Prediction (100% Offline)
* **Fee-Delay Risk Predictor:** Uses a logistic regression model (`lib/logic/fee_risk_model.dart`) trained on attendance rate, average payment delay days, and late payment counts to calculate a 0–100% default probability score.
* **Academic Performance Forecaster:** Uses a linear regression model (`lib/logic/performance_index_model.dart`) trained on quiz averages, attendance rates, and fee standings to output a predicted performance index score.
* **Key Files:** `lib/features/admin/admin_ai_prediction_screen.dart`, `lib/logic/admin_ai_provider.dart`.

### 4. Teacher Digital Classroom & AI Test Suite
* **Digital Attendance Roll Call:** Mark and edit daily subject attendance (Present/Absent/Late) for assigned sections (`attendance_marking_screen.dart`).
* **AI Test Paper Generator:** Scans physical textbook pages via Google ML Kit OCR, extracts questions using heuristic rules, auto-calculates total marks, and exports printable PDF test papers (`create_quiz_screen.dart`).
* **AI Smart Paper Grader:** Grades student short-answer responses against teacher-defined keywords using TF-IDF cosine-similarity weighting (`ai_paper_grader_screen.dart`, `lib/logic/tfidf_grader.dart`).
* **OCR Resource Publishing:** Scans documents directly to shared classroom resources (`ocr_scanner_screen.dart`).

### 5. Student Learning Console & AI Summarizer
* **Classroom Hub:** Access teacher-shared study resources and participate in Q&A discussion threads (`my_classroom_hub.dart`).
* **AI Notes Summarizer:** Uses the TextRank graph-ranking algorithm (`lib/logic/text_rank_summarizer.dart`) to generate instant extractive summaries of long study notes without internet connections (`ai_summarizer_screen.dart`).
* **Performance & Attendance Analytics:** Visual progress charts (`fl_chart`) and day-by-day attendance tracking (`student_progress_chart_screen.dart`).

### 6. Parent Monitoring Portal
* **Multi-Child Dashboard:** Link multiple children to a single parent account. Switch between children via tabbed navigation (`child_overview_screen.dart`).
* **Real-Time Monitoring:** View live attendance history, published test marks, fee challans, and direct academy contact channels.

---

## 9. File-by-File Reference

| File Path | Purpose | Key Classes / Functions | Key Dependencies | Safe Modification Notes |
|---|---|---|---|---|
| `lib/main.dart` | Application bootstrap & route map | `main()`, `TaleemPlusApp` | `firebase_core`, `provider` | Add global providers or top-level named routes here. |
| `lib/core/constants/app_constants.dart` | Global constants & route names | `AppRoutes`, `UserRole`, `DbKeys` | None | Ensure route strings match `main.dart` entries. |
| `lib/core/theme/app_theme.dart` | Mobile light/dark themes | `AppTheme.light`, `AppTheme.dark` | `AppColors` | Modify primary swatch or component styles here. |
| `lib/core/web/web_theme.dart` | Web-optimized themes | `AppWebTheme.light`, `AppWebTheme.dark` | `google_fonts` | Adjust web font typography or background colors. |
| `lib/data/local/db_helper.dart` | SQLite helper for local data | `DbHelper.instance`, `initDb()` | `sqflite`, `path` | Update `version` and write migration logic on schema change. |
| `lib/data/models/app_user.dart` | User profile data class | `AppUser`, `toMap()`, `fromMap()` | None | Reflect new Firestore user fields in constructor & mappers. |
| `lib/data/models/fee_challan_model.dart` | Fee challan data model | `FeeChallanModel`, `totalAmount` | None | Defines fee fields (monthly, admission, exam, transport). |
| `lib/data/remote/auth_service.dart` | Firebase Auth & user service | `AuthService`, `signIn()`, `signUp()` | `firebase_auth`, `cloud_firestore` | Handles user authentication & profile creation. |
| `lib/data/remote/challan_pdf_service.dart` | PDF challan generator | `ChallanPdfService.generatePdf()` | `pdf`, `printing`, `qr_flutter` | Adjust printed PDF layout or QR code payload structure. |
| `lib/logic/auth_provider.dart` | Authentication state manager | `AuthProvider`, `signIn()`, `signOut()` | `AuthService` | Controls current user lifecycle and authentication status. |
| `lib/logic/session_provider.dart` | Session security & auto-logout | `SessionProvider`, `resetTimer()` | `local_auth`, `shared_preferences` | Manages 5-minute inactivity timer & biometric unlock. |
| `lib/logic/fee_risk_model.dart` | Pure Dart fee risk ML model | `FeeRiskModel.predictRiskProbability()`| None | Modify model weights printed by `train_risk_model.py`. |
| `lib/logic/performance_index_model.dart` | Pure Dart performance ML model| `PerformanceIndexModel.predict()`| None | Modify performance regression coefficients here. |
| `lib/logic/text_rank_summarizer.dart` | Offline TextRank algorithm | `TextRankSummarizer.summarize()`| None | Adjust sentence similarity threshold or ranking weights. |
| `lib/logic/tfidf_grader.dart` | TF-IDF Cosine AI grader | `TfIdfGrader.score()` | None | Custom keyword scoring math lives here. |
| `lib/features/auth/login_screen.dart` | Login user interface | `LoginScreen`, `_handleLogin()` | `AuthProvider`, `SessionProvider` | Modify login UI fields, biometric buttons, or validation. |
| `lib/features/admin/admin_dashboard.dart` | Admin main navigation portal | `AdminDashboard` | `AdminAiProvider`, `AuthProvider` | Modify admin drawer options or quick-stat cards. |
| `lib/features/admin/admin_ai_prediction_screen.dart` | AI Analytics screen | `AdminAiPredictionScreen` | `AdminAiProvider` | Renders fee risk and academic prediction lists. |
| `lib/features/teacher/teacher_dashboard.dart` | Teacher navigation portal | `TeacherDashboard` | `QuizProvider`, `AuthProvider` | Adjust teacher action buttons or overview stats. |
| `lib/features/quiz/screens/create_quiz_screen.dart` | Test paper generator | `CreateQuizScreen` | `google_mlkit_text_recognition` | Manages AI question extraction UI and PDF export. |
| `lib/features/quiz/screens/ai_paper_grader_screen.dart` | AI Paper Grader UI | `AiPaperGraderScreen` | `TfIdfGrader` | Interface for scanning answer sheets and auto-grading. |
| `lib/features/student/screens/ai_summarizer_screen.dart` | Offline summarizer screen | `AiSummarizerScreen` | `TextRankSummarizer` | Text input & summary result view for students. |
| `lib/features/parent/screens/child_overview_screen.dart` | Multi-child parent screen | `ChildOverviewScreen` | `ParentProvider` | Controls tabbed multi-child progress switching. |
| `firestore.rules` | Firestore security rules | `sameAcademy()`, `isApproved()` | Firestore Engine | Server-side security rules for tenant isolation. |
| `android/app/build.gradle.kts` | Android app build script | `android { compileSdk = ... }` | Gradle Plugins | Update Android min/target SDKs or release signing. |

---

## 10. UI and Screen Documentation

### Auth & System Screens
* **`SplashScreen` (`lib/features/auth/splash_screen.dart`):** Animated logo loader. Automatically checks active Firebase session and routes to the appropriate role dashboard or login.
* **`LoginScreen` (`lib/features/auth/login_screen.dart`):** Card-based login supporting email/password and biometric unlock. Includes password visibility toggles and error handling snackbars.
* **`SignupScreen` (`lib/features/auth/signup_screen.dart`):** Tabbed signup view for creating a new academy (Admin) or joining an existing academy using a `TP-XXXXX` code.

### Admin Portal Screens
* **`AdminDashboard` (`lib/features/admin/admin_dashboard.dart`):** Master dashboard displaying key statistics (Total Students, Teachers, Today's Attendance %, Monthly Collection), quick action cards, and navigation drawer.
* **`UserManagementScreen` (`lib/features/admin/user_management_screen.dart`):** Tabbed listing of Teachers, Students, and Parents. Supports manual account creation, editing, roll number assignment, and parent-child linking.
* **`ChallanGenerationScreen` (`lib/features/admin/screens/challan_generation_screen.dart`):** Form for batch-generating monthly fee challans for specific class sections. Computes totals and due dates.
* **`AdminAiPredictionScreen` (`lib/features/admin/admin_ai_prediction_screen.dart`):** Displays at-risk student lists with color-coded risk bars (Low, Medium, High Default Risk) and predicted academic performance indices.

### Teacher & Quiz Screens
* **`AttendanceMarkingScreen` (`lib/features/teacher/attendance_marking_screen.dart`):** Digital roster list for marking student presence (Present, Absent, Late) with bulk toggles.
* **`CreateQuizScreen` (`lib/features/quiz/screens/create_quiz_screen.dart`):** Interface for adding manual questions or scanning textbook notes via camera OCR to generate formatted PDF test papers.
* **`AiPaperGraderScreen` (`lib/features/quiz/screens/ai_paper_grader_screen.dart`):** Camera scanner view that extracts student written answers and calculates similarity scores against answer keys.

### Student & Parent Screens
* **`StudentDashboard` (`lib/features/student/student_dashboard.dart`):** Student portal container showcasing attendance statistics, recent notices, quick AI summarizer access, and subject shortcuts.
* **`AiSummarizerScreen` (`lib/features/student/screens/ai_summarizer_screen.dart`):** Text input and document scanner view that outputs bulleted executive summaries using on-device TextRank.
* **`ChildOverviewScreen` (`lib/features/parent/screens/child_overview_screen.dart`):** Tabbed parent screen allowing seamless switching between multiple enrolled children.

---

## 11. Database and Data Management

### Cloud Firestore Collections Schema

```text
users/{uid} (AppUser)
  ├── uid: String (Primary Key)
  ├── email: String
  ├── full_name: String
  ├── role: String ("admin" | "teacher" | "student" | "parent")
  ├── account_status: String ("active" | "pending" | "rejected")
  ├── academy_id: String (Partition Key)
  ├── academy_code: String ("TP-XXXXX")
  └── linked_children: List<String> (Parent -> Student UIDs)

classes/{classId} (ClassEntity)
  ├── id: String
  ├── academy_id: String
  ├── class_name: String
  ├── section: String
  ├── primary_teacher_id: String
  └── student_ids: List<String>

attendance_records/{classId}_{studentId}_{yyyy-MM-dd} (AttendanceRecord)
  ├── academy_id: String
  ├── class_id: String
  ├── student_id: String
  ├── log_date: String
  └── status: String ("present" | "absent" | "late")

fee_challans/{challanId} (FeeChallanModel)
  ├── academy_id: String
  ├── challan_number: String
  ├── student_id: String
  ├── monthly_fee: Double
  ├── total_amount: Double
  ├── status: String ("pending" | "paid" | "overdue")
  └── due_date: Timestamp
```

### Local SQLite Database (`taleemplus_v2.db` v6)
Backed by `lib/data/local/db_helper.dart`. Houses two tables:
1. `members`: Local cache for admin staff and student records.
2. `fee_invoices`: Legacy local ledger for offline invoice tracking.

---

## 12. API and Backend Documentation

TaleemPlus uses direct native integration with **Firebase Auth** and **Cloud Firestore** via the official FlutterFire SDKs. No external custom REST APIs are exposed.

### Primary Database Interactions
* **Authentication:** Handled by `AuthService` (`FirebaseAuth.instance.signInWithEmailAndPassword`).
* **User Profile Queries:** Executed via `FirebaseFirestore.instance.collection('users')`.
* **Multi-Tenant Security Enforcement:** Configured via `firestore.rules`:
  ```javascript
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      function signedIn() { return request.auth != null; }
      function getUserData() {
        return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
      }
      function isApproved() {
        return signedIn() && getUserData().get('account_status', 'inactive') == "active";
      }
      function sameAcademy(docAcademyId) {
        return getUserData().get('academy_id', '') == docAcademyId;
      }
      match /classes/{classId} {
        allow read: if isApproved() && sameAcademy(resource.data.academy_id);
        allow write: if isApproved() && sameAcademy(request.resource.data.academy_id);
      }
    }
  }
  ```

---

## 13. Dependencies and Configuration

### Key Package Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2                   # State management
  sqflite: ^2.3.3                    # Local SQLite database
  firebase_core: ^3.1.0              # Firebase core engine
  firebase_auth: ^5.1.0              # Firebase authentication
  cloud_firestore: ^5.0.1            # Firebase Cloud Firestore
  google_mlkit_text_recognition: ^0.13.0 # On-device OCR
  fl_chart: ^0.68.0                  # Charts and analytics graphs
  pdf: ^3.13.0                       # PDF generation engine
  printing: ^5.13.0                  # Native PDF printing & sharing
  local_auth: ^2.3.0                 # Hardware biometric authentication
  shared_preferences: ^2.5.5         # Local key-value preferences
  google_fonts: ^6.2.1               # Web typography (Inter font)
```

---

## 14. Navigation Map

| Starting Screen | User Action | Destination Screen | File Path |
|---|---|---|---|
| `SplashScreen` | Session Verified (Admin) | `AdminDashboard` | `lib/features/admin/admin_dashboard.dart` |
| `SplashScreen` | Session Verified (Teacher) | `TeacherDashboard` | `lib/features/teacher/teacher_dashboard.dart` |
| `SplashScreen` | Session Verified (Student) | `StudentDashboard` | `lib/features/student/student_dashboard.dart` |
| `SplashScreen` | Session Verified (Parent) | `ParentDashboard` | `lib/features/parent/parent_dashboard.dart` |
| `SplashScreen` | No Active Session | `LoginScreen` | `lib/features/auth/login_screen.dart` |
| `LoginScreen` | Tap "Sign Up" | `SignupScreen` | `lib/features/auth/signup_screen.dart` |
| `AdminDashboard` | Tap "Approval Requests" | `ApprovalRequestsScreen` | `lib/features/admin/approval_requests_screen.dart` |
| `AdminDashboard` | Tap "User Management" | `UserManagementScreen` | `lib/features/admin/user_management_screen.dart` |
| `AdminDashboard` | Tap "AI Analytics" | `AdminAiPredictionScreen` | `lib/features/admin/admin_ai_prediction_screen.dart` |
| `TeacherDashboard` | Tap "Mark Attendance" | `AttendanceMarkingScreen` | `lib/features/teacher/attendance_marking_screen.dart` |
| `TeacherDashboard` | Tap "Create Test" | `CreateQuizScreen` | `lib/features/quiz/screens/create_quiz_screen.dart` |
| `TeacherDashboard` | Tap "AI Paper Grader" | `AiPaperGraderScreen` | `lib/features/quiz/screens/ai_paper_grader_screen.dart` |
| `StudentDashboard` | Tap "AI Note Summarizer" | `AiSummarizerScreen` | `lib/features/student/screens/ai_summarizer_screen.dart` |
| `StudentDashboard` | Tap "Classroom Hub" | `MyClassroomHub` | `lib/features/student/screens/my_classroom_hub.dart` |
| `ParentDashboard` | Switch Child Tab | `ChildOverviewScreen` | `lib/features/parent/screens/child_overview_screen.dart` |

---

## 15. How to Modify the Project

### Common Developer Modification Tasks

1. **Change App Colors & Styling:**
   * Open `lib/core/theme/app_colors.dart`. Modify static color definitions (`primary`, `secondary`, `accent`, `background`).
2. **Modify Theme Constants (Mobile vs Web):**
   * Edit `lib/core/theme/app_theme.dart` for mobile light/dark themes.
   * Edit `lib/core/web/web_theme.dart` for Web UI layout adjustments.
3. **Add a New Portal Route:**
   * Add the route string to `AppRoutes` in `lib/core/constants/app_constants.dart`.
   * Add the destination widget builder to `routes` in `lib/main.dart`.
4. **Update AI Risk Prediction Weights:**
   * Run model retraining in Python: `python ml_training/train_risk_model.py`.
   * Copy the printed logistic regression coefficients into `lib/logic/fee_risk_model.dart`.
5. **Add a New Firestore Collection:**
   * Create a data model class in `lib/data/models/`.
   * Implement a service wrapper in `lib/data/remote/`.
   * Add security rules for the collection in `firestore.rules`.

---

## 16. Debugging and Troubleshooting

### Common Build & Runtime Issues

1. **Obsolete Java Version Compiler Errors:**
   * *Problem:* Gradle fails with `Java 8 source compatibility obsolete` warnings.
   * *Solution:* Ensure `compileOptions` in `android/app/build.gradle.kts` and `android/build.gradle.kts` specify `JavaVersion.VERSION_17`.
2. **Firestore Permission Denied Errors:**
   * *Problem:* Console throws `[cloud_firestore/permission-denied]`.
   * *Solution:* Verify that the user account's `account_status` in Firestore is set to `"active"` and that queries include `.where('academy_id', isEqualTo: academyId)`.
3. **Missing Index Errors on Complex Queries:**
   * *Problem:* Query throws error with a link to create a composite index.
   * *Solution:* Check `firestore.indexes.json` or click the generated link in Logcat to deploy the index to Firebase.
4. **Biometric Authentication Fails on Emulator:**
   * *Problem:* `local_auth` throws `NotAvailableException`.
   * *Solution:* Enable Fingerprint authentication in Emulator Settings under **Settings > Security > Fingerprint**.

---

## 17. Testing

### Unit Test Suite
The project includes unit tests covering all core offline AI and ML algorithms in `test/`:
* `fee_risk_model_test.dart`: Verifies probability predictions for low-risk and high-risk student profiles.
* `performance_index_model_test.dart`: Tests performance index calculation and bounds clamping (0–100).
* `text_rank_summarizer_test.dart`: Validates graph-based sentence ranking and output sentence limits.
* `tfidf_grader_test.dart`: Tests short-answer grading scores against teacher keyword sets.

### Running Unit Tests
Execute the unit test suite via Flutter CLI:
```bash
flutter test
```

### Running Integration Tests
Execute UI integration tests on a connected emulator or physical device:
```bash
flutter test integration_test/example_test.dart
```

---

## 18. Security

1. **Server-Side Security Enforcement:** All database access is governed strictly by `firestore.rules`. Unapproved or non-active accounts (`account_status != "active"`) are rejected server-side.
2. **Multi-Tenant Scoping:** All queries must match `sameAcademy()`, preventing cross-academy data leaks.
3. **Session Inactivity Security:** `SessionProvider` forces user sign-out after 5 minutes of inactivity or 15 seconds of backgrounding.
4. **Sanitized Auth Error Messages:** `AuthService` sanitizes Firebase authentication error codes to prevent user-enumeration attacks.
5. **Secrets & Environment Safety:** API keys and credentials are not committed to source control. CI/CD injects `FIREBASE_OPTIONS` secrets during build execution.

---

## 19. Known Issues and Technical Debt

1. **Dual Fee Model Scaffolding:** `fee_invoices` (sqflite) and `fee_challans` (Firestore) coexist in the repository. The active UI uses `fee_challans`; `fee_invoices` remains for backward compatibility.
2. **Scaffolded In-App Quiz Submissions:** `QuizSubmissionModel` exists in `quiz_submission_model.dart`, but students currently take quizzes on paper while teachers input marks directly.
3. **Biometric Password Storage:** Cached biometric credentials are saved in `shared_preferences`. Future iterations should migrate to `flutter_secure_storage` for hardware-encrypted storage.

---

## 20. Development Roadmap

### High Priority
* [ ] Migrate biometric cached password storage from `shared_preferences` to `flutter_secure_storage`.
* [ ] Deprecate local `fee_invoices` sqflite table in favor of complete `fee_challans` Firestore synchronization.

### Medium Priority
* [ ] Enable online student quiz submission mode using the existing `QuizSubmissionModel` scaffolding.
* [ ] Implement push notification support using Firebase Cloud Messaging (FCM).

### Low Priority
* [ ] Add multi-language localization (Urdu and English) for parent and student screens.
* [ ] Add export capabilities to Excel/CSV for administrative fee ledgers.

---

## 21. Glossary

* **Multi-Tenancy:** Architecture where multiple academies share a single database instance while keeping data segregated by `academy_id`.
* **Provider:** Flutter state management pattern wrapping `ChangeNotifier` to pass data down the widget tree.
* **TextRank:** Graph-based unsupervised algorithm used for extractive text summarization.
* **TF-IDF:** Term Frequency-Inverse Document Frequency metric used to weigh the importance of keywords in text scoring.
* **OCR:** Optical Character Recognition technology (Google ML Kit) for extracting raw text from images.
* **Challan:** Official deposit slip or invoice document for monthly fee collection.

---

## 22. Project Documentation Limitations

* **Hardware Biometrics:** Verified via `local_auth` mock and emulator setup; full device matrix depends on hardware support.
* **Firebase Backend Live Project:** Firebase Hosting project (`taleemplus-40755`) requires appropriate Firebase administrative permissions for direct CLI deployments.
