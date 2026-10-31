# TaleemPlus Project Audit

Audit date: 2026-10-31  
Checkout: `H:\Final Version`  
Branch: `feature/api-v2-cicd` at `10c418d`

## Project structure and implementation

| Area | Verified files and implementation |
|---|---|
| Flutter client | `lib/main.dart`, `lib/core/`, `lib/data/`, `lib/features/`, `lib/logic/`, `lib/widgets/`; Provider-based state management. Roles in `lib/core/constants/app_constants.dart` are admin, teacher, student, and parent. |
| Android | `android/app/build.gradle.kts`, `android/settings.gradle.kts`, Gradle wrapper and Kotlin activity. App ID `com.example.taleem_plus`; Java/Kotlin target 17; Gradle wrapper 9.1.0; Android Gradle Plugin 9.0.1; Kotlin plugin 2.3.20. `minSdk` and `targetSdk` delegate to Flutter defaults. |
| Web | `web/index.html`, `web/manifest.json`, icons, and Flutter web bootstrap are present. `flutter build web --release` completed successfully. |
| Node backend | `taleemplus_backend/src/server.js`, Express routes/controllers/middleware and Jest tests. Versioned routes are mounted under `/api/v2` and compatibility routes under `/api/v1`; `/health` is also exposed. |
| Database | PostgreSQL via Prisma in `taleemplus_backend/prisma/schema.prisma`; Prisma uses `DATABASE_URL`. Models include academies, users, enrollments/classes, attendance, fee challans, quizzes/marks, resources, queries, notifications, timetable slots, and refresh tokens. No Prisma migration history is present; current local documentation uses schema push. |
| Firebase | `lib/main.dart` initializes Firebase; direct Firestore service/repository usages and `firestore.rules` remain. `firebase.json` configures Hosting and Firestore. `lib/firebase_options.dart` exists locally but is ignored by Git; Android `google-services.json` and iOS `GoogleService-Info.plist` are absent. Firebase values were not printed or included in this report. |
| Local storage | `sqflite` helper in `lib/data/local/db_helper.dart`; `shared_preferences` is used for preferences and API tokens. |
| Training/assets | `ml_training/generate_synthetic_data.py`, `ml_training/requirements.txt`, and a synthetic CSV exist. `assets/ml_models/placeholder.txt` is the only model-directory artifact. The referenced sklearn training and TFLite export scripts are missing from this checkout. |

### Languages and frameworks

- Dart/Flutter for the client; Kotlin and Gradle Kotlin DSL for Android; Swift/Xcode project files for iOS; JavaScript/Node.js for the backend; Prisma schema for PostgreSQL; Python for synthetic data generation; PowerShell for the local PostgreSQL helper; HTML/JSON for web configuration.
- Local tools detected: Flutter 3.47.9, Dart 3.13.7, Node.js 26.13.0, npm 11.20.0, and Java 21 in the shell. The Android Gradle daemon selected a Java 25 runtime. Android targets Java 17.

### Direct package inventory

Flutter packages from `pubspec.yaml`:

| Package | Purpose in the project |
|---|---|
| `http` | REST API requests |
| `provider` | State management |
| `sqflite`, `path` | Local SQLite database and paths |
| `firebase_core`, `firebase_auth`, `cloud_firestore` | Firebase initialization and remaining Firebase services |
| `connectivity_plus` | Connectivity status |
| `google_mlkit_text_recognition`, `image_picker` | On-device OCR and image capture |
| `fl_chart` | Dashboard charts |
| `intl`, `uuid`, `crypto` | Formatting, identifiers, and cryptographic utilities |
| `cupertino_icons`, `google_fonts` | UI assets and typography |
| `shared_preferences` | Preferences and API token persistence |
| `qr_flutter`, `pdf`, `printing` | QR and document generation/printing |
| `local_auth` | Device biometric authentication support |
| `url_launcher` | Opening external links |
| Dev: `flutter_test`, `integration_test`, `flutter_lints`, `flutter_launcher_icons` | Flutter tests, linting, and launcher icons |

The backend package inventory in `taleemplus_backend/package.json` is `@prisma/client`, `bcryptjs`, `cors`, `dotenv`, `express`, `helmet`, `jsonwebtoken`, `morgan`, `swagger-ui-express`, and `zod`; dev dependencies are `jest`, `nodemon`, `prisma`, and `supertest`. The checked-in controllers perform manual validation; `zod` was not found in use. The Python requirements list `pandas`, `scikit-learn`, `tensorflow`, and `joblib`; no active TFLite application runtime was found.

## Authentication, roles, and data flow

- The Flutter `AuthService` currently uses `ApiClient` for registration, login, and profile requests. The Node API hashes passwords with `bcryptjs`, issues JWT access/refresh tokens, and protects API routes with authentication middleware and `authorizeRoles`.
- API role names are `ADMIN`, `TEACHER`, `STUDENT`, and `PARENT`; route declarations apply role guards to privileged operations. Tenant ownership is represented by `academyId` in the Prisma schema.
- This is a partially migrated hybrid, not a Firebase-only or PostgreSQL-only client. Auth, classes, attendance, fees, and quizzes/marks have API paths; several other services still directly access Firestore. SQLite remains for legacy/local data.
- `taleemplus_backend/.env` is tracked in the current Git history and is modified in the worktree. Its contents were not inspected, modified, staged, or included in any build/test command. A new `.gitignore` rule does not untrack a file already tracked by Git.
- The target GitHub URL returned no branch refs when queried. The existing `origin` remains `https://github.com/TaleemPlus-UCP/TaleemPlus.git`; it was not changed.

## AI, ML, OCR, and external services

| Implementation | Algorithm/model and input/output | Training status and application use |
|---|---|---|
| `lib/logic/fee_risk_model.dart` | Logistic-regression equation with fixed coefficients; attendance rate, average days late, late-payment count → probability and 0.5 threshold. | Inference is connected to `AdminAiProvider`. Comments claim coefficients came from sklearn training on the synthetic CSV. No trainer exists in this checkout, so the fit cannot be reproduced; no real academy training is verified. |
| `lib/logic/performance_index_model.dart` | Linear-regression equation with fixed coefficients; quiz average, attendance, late-payment count → clamped 0–100 index. | Connected to admin insights. Same synthetic provenance claim and missing trainer; not verified as trained on real data. |
| `lib/logic/text_rank_summarizer.dart` | Deterministic TextRank graph ranking; OCR/document sentences → ranked/extractive summary. | No model fitting or training data. Used by student notes summarization and paper generation. |
| `lib/logic/tfidf_grader.dart` | Deterministic TF-IDF weighted cosine similarity; OCR answer, teacher keywords, current quiz keyword corpus → similarity score/mark suggestion. | No learned model or external corpus; connected to the paper grader. |
| Google ML Kit via `google_mlkit_text_recognition` | Package-provided OCR model; captured image → extracted text. | Pretrained package capability; no local training. |

No OpenAI/Gemini inference call, active TFLite interpreter, or serialized model artifact (`.tflite`, `.pkl`, `.joblib`, `.h5`, `.pt`, `.pth`, `.onnx`) was found. The CSV has 800 synthetic rows; `generate_synthetic_data.py` creates features and labels from seeded random distributions and formulas. The checked-in `data_export/*.json` files are empty arrays, not academy training records. No deployed database contents were accessed.

Other AI-labeled output includes deterministic thresholds/aggregations and a revenue estimate based on current challan totals; these are not additional trained models.

## Tests and workflows

- Flutter: a new `test/core_logic_test.dart` provides six tests for probability bounds/monotonicity, performance clamping, TF-IDF scoring, and TextRank limits. `integration_test/example_test.dart` is an existing app-start integration test; it was not run because no Android emulator/device is attached.
- Backend: existing `taleemplus_backend/tests/auth.test.js` and a new `taleemplus_backend/tests/roleMiddleware.test.js` cover API health/auth validation and role authorization. See `TEST_REPORT.md` for actual commands/results.
- Workflows: `.github/workflows/flutter-ci.yml`, `main.yml`, `android-apk.yml`, and `backend-ci.yml` exist. The updated Flutter workflow runs formatting, analysis, tests, Web/APK release builds, and artifact uploads. It requires repository secrets `FIREBASE_OPTIONS` and `GOOGLE_SERVICES_JSON` and writes them only to runner files. `main.yml` also has Firebase Hosting deployment behavior on configured branch pushes; that deployment has not been run here.

## Security and incomplete areas

- The checked-in local `.env` is tracked; it must not be staged or uploaded. Because it is part of the current local commit history, pushing that history would upload the file’s historical blob even if the current modified file were excluded. The target remote appears empty, so a safe history-preserving push is blocked until a compliant delivery strategy is explicitly chosen.
- Backend JWT code previously used hard-coded fallback signing keys. Those fallbacks are removed; API startup now requires `JWT_SECRET` and `REFRESH_TOKEN_SECRET`. Local values were not read. Backend tests use disposable test-only environment values from a temp working directory.
- Refresh tokens are persisted as raw token strings in the Prisma `RefreshToken` table; hashing before persistence would reduce impact from a database disclosure.
- `firestore.rules` scopes most app collections by approval and academy, but allows unauthenticated reads of admin profile documents and password-recovery documents; own-profile updates do not restrict fields such as role/status. Review those paths before exposing Firestore to untrusted clients.
- The API uses `helmet` and configurable CORS allowlisting; localhost origins are permitted in development. Rate limiting was not found. Input validation is mostly manual despite the declared `zod` dependency.
- Multiple client service methods remain placeholders (including empty results/no-op methods in `AuthService`, `QuizService`, `AttendanceRepository`, `FeeChallanRepository`, and `ClassRepository`). In particular, academy-wide attendance, marks, and challan queries return empty lists, which limits admin analytics after the API migration. These were documented, not replaced with dummy data.
- `prisma:seed` is declared but `taleemplus_backend/prisma/seed.js` is absent. The repo has no `prisma/migrations` directory. Android build cannot complete without the excluded platform Google Services configuration.

## Git and release status

- Local branch: `feature/api-v2-cicd`; current origin is unchanged and points to the original TaleemPlus repository. The requested `RakibAkram5/Final_Year_Project` remote reported no heads; no target remote or branch was created.
- The worktree had pre-existing edits before this task. They were preserved; only the explicitly documented audit/test/security/format/workflow changes were added. No files were staged or committed.
- Web release build succeeded at `build/web/` (43 files, 45,094,285 bytes). The prior directory was backed up to the system temp folder before rebuilding.
- Android release APK build failed at `:app:processReleaseGoogleServices` because `android/app/google-services.json` is absent. No APK was produced.
- No GitHub push or Firebase deployment was performed.
