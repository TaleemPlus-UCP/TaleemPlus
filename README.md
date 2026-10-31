# TaleemPlus

TaleemPlus is a Flutter academy management app with role-based admin, teacher, student, and parent screens. The repository contains a Node.js/Express API backed by PostgreSQL and Prisma. The client migration is in progress: API/PostgreSQL, direct Firebase/Firestore, and local SQLite paths coexist.

## Project status

The repository contains runnable Flutter app code, an Express backend, database schema, and feature implementations described below. This README does not claim that production deployment, every platform, or all workflows have been end-to-end verified. See [API_CONNECTION_FIX_REPORT.md](API_CONNECTION_FIX_REPORT.md) and [API_V2.md](API_V2.md) for additional migration context.

## Technology

| Area | Verified technologies | Use in this project |
|---|---|---|
| Client | Flutter and Dart (`pubspec.yaml` requires Dart `>=3.0.0 <4.0.0`) | Android, iOS, and web UI in `lib/` |
| State management | `provider` | App state and `ChangeNotifier` providers |
| HTTP API | `http` package; Express 4 | Client REST calls to the versioned API |
| API database | PostgreSQL with Prisma 5 | API-managed academy, user, attendance, fee, quiz/marks, and related records; schema in `taleemplus_backend/prisma/schema.prisma` |
| ML service | Python, FastAPI, scikit-learn, pandas, psycopg, joblib | Academy-scoped data extraction, model evaluation, versioned inference artifacts; package constraints in `ml_service/requirements.txt` |
| Authentication | Backend JWT endpoints; Firebase packages also remain in the client | API auth is implemented in `lib/data/remote/auth_service.dart`; Firebase is initialized and Firestore is still accessed by some features |
| Other client storage | `sqflite`, `shared_preferences` | Local legacy/cache data and preferences |
| OCR | `google_mlkit_text_recognition` | On-device text extraction from images |
| Reports and charts | `pdf`, `printing`, `qr_flutter`, `fl_chart` | PDF output, QR codes, and dashboard charts |

Package names and version constraints are maintained in [pubspec.yaml](pubspec.yaml) and [taleemplus_backend/package.json](taleemplus_backend/package.json). The backend package includes `express`, `@prisma/client`, `prisma`, `jsonwebtoken`, `bcryptjs`, `cors`, `helmet`, and related packages.

## Implemented app areas

- **Admin:** user approval and management, class/section setup, timetable, fee challans and ledger, reports, and insights.
- **Teacher:** attendance, quizzes and marks, OCR resource workflows, paper generation and grading, and student queries.
- **Student:** classroom resources, attendance and marks, notes summarization, and fee information.
- **Parent:** linked-child views for attendance, marks, and fee information.
- **Shared:** authentication, role-based navigation, notifications, PDF generation, and responsive Flutter web layouts.
- **Session and password controls:** backend token refresh, five-minute inactivity timeout, lifecycle-aware session retention, minimum password checks, password strength feedback, and biometric unlock without saving a plaintext password.
- **Attendance and result reports:** printable A4 reports use loaded academy records. Attendance supports present, absent, late, and leave; report position is not computed because the current records do not expose a verified class ranking.
- **Fee payments:** academy administrators can configure payment details and upload a QR image. Students/parents can submit proof; an academy administrator must verify it before proof review marks the challan paid.
- **Student IDs:** students have permanent alphanumeric `studentCode` values while internal UUID relationships stay intact. Fee challans use a YYYY-MM billing period with an academy/student/period uniqueness constraint.

These are code-level features. Some data flows are split between the API and Firestore during migration; see [Backend and data](#backend-and-data).

## AI/ML status

The repository includes a Python ML service under `ml_service/`, Node.js admin-only proxy routes, and an Admin AI screen that reports model readiness and offers training. The service extracts data from PostgreSQL by academy, uses dated labels and historical-only features, compares candidate models on chronological validation data, and stores versioned artifacts outside Git. The local database contained 0 attendance rows, 0 fee challans, and 0 test marks when checked on 2026-10-31, so neither supervised model is currently trainable or validated on real academy data. No real model artifact or real-data metric is claimed.

| Implementation | What it does | Current status |
|---|---|---|
| `ml_service/app/training/pipeline.py` | Fee delay classification (logistic regression, random forest, gradient boosting) and academic mark regression (linear, random forest, gradient boosting), with evaluation and versioned `joblib` pipelines. | Training code implemented; status is insufficient data until dated real records meet thresholds. |
| `lib/logic/fee_risk_model.dart` | Legacy fixed logistic-regression coefficients. | Not used for Admin AI predictions; source comments trace coefficients to synthetic data. |
| `lib/logic/performance_index_model.dart` | Legacy fixed linear-regression coefficients. | Not used for Admin AI predictions; source comments trace coefficients to synthetic data. |
| `lib/logic/text_rank_summarizer.dart` | Deterministic extractive TextRank, including OCR line repair, duplicate suppression, and English/Urdu token support. | No training step. |
| `lib/logic/tfidf_grader.dart` | Deterministic keyword similarity scoring for English/Urdu OCR answers. | No training step; lexical similarity is not semantic understanding and needs teacher review. |
| OCR via `google_mlkit_text_recognition` | Extracts text from images for paper and notes workflows. | Pretrained package functionality; this repository does not train the OCR model. |

`ml_training/data/synthetic_dataset.csv` is simulated and is not used to train the Python production service. The legacy Dart coefficient models do not provide the Admin AI screen with fallback predictions. The revenue forecast and student screening still include heuristic/rule-based calculations and should not be presented as learned ML.

For setup, data requirements, endpoint names, limitations, and training commands, see [ml_service/README.md](ml_service/README.md).

## Backend and data

The backend entry point is `taleemplus_backend/src/server.js`; Express routes are mounted under `/api/v2` (with `/api/v1` compatibility routes) in `taleemplus_backend/src/app.js`. The API includes authentication and password verification/change, academy profile, users, classes, attendance, fee challans/payment settings/payment proof review, quizzes/marks, resources, notifications, and timetable endpoints. The health endpoint is `/health`.

PostgreSQL is the datasource declared in `taleemplus_backend/prisma/schema.prisma`, using `DATABASE_URL`; Prisma Client is initialized in `taleemplus_backend/src/config/db.js`. Local database helper commands are declared in `taleemplus_backend/package.json` and implemented in `taleemplus_backend/scripts/dev-db.ps1`. The helper expects a PostgreSQL data directory at `taleemplus_backend/.pgdata` or a configured `PG_CTL` executable. A local database and API are not automatically provisioned by Flutter.

The client uses `ApiClient` (`lib/data/remote/api_client.dart`) for the backend URL and bearer-token requests. Its default API URL is `http://localhost:5000/api/v2` on web/iOS/desktop and `http://10.0.2.2:5000/api/v2` on Android emulator. Override it using `--dart-define=API_BASE_URL=...`.

**Migration is incomplete.** API/PostgreSQL repositories currently include auth, academy profile, class, attendance, quiz/marks, fee challans, payment settings, and payment proofs. Other client features still use direct Cloud Firestore, and `sqflite` remains for local/legacy data. Firebase is initialized in `lib/main.dart`; do not treat PostgreSQL as the only data store or Firestore as the primary store for all current API-managed entities. Password-reset email delivery and security-question recovery are not connected to PostgreSQL accounts. The repository does not establish whether a deployed database contains real academy records.

## Setup

### Flutter client

Requirements: Flutter with a Dart SDK satisfying the constraint in `pubspec.yaml`. Android builds use Java 17 settings in the Android Gradle configuration. Chrome is needed to run the web target.

```powershell
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000/api/v2
```

For an Android emulator, use the API default (`10.0.2.2`) or pass that URL explicitly. The app initializes Firebase and requires valid platform Firebase configuration files; these are ignored by Git. If they have not been generated for your Firebase project, install and run FlutterFire CLI:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

Do not commit credentials or generated private configuration.

### Node.js API and PostgreSQL

Requirements: Node.js/npm, PostgreSQL tools, a configured private `taleemplus_backend/.env`, and a PostgreSQL database matching `DATABASE_URL`. The repository's local database helper also requires the `.pgdata` directory; that local data directory is ignored by Git and is not delivered as project data.

```powershell
Set-Location taleemplus_backend
npm ci
# Create .env from .env.example, then set private local values (including JWT secrets).
npm run prisma:generate
npx prisma migrate deploy
npm run dev
```

These commands expect PostgreSQL to be running and reachable using the private `DATABASE_URL` in `.env`. Prisma migrations include a baseline and additive changes for payment timestamps, permanent student codes, leave attendance, academy payment settings/proof records, and fee billing periods. For an existing non-empty database without migration history, verify its schema matches the baseline before marking that baseline applied; see [ml_service/README.md](ml_service/README.md). `npm run db:start` is an optional Windows helper for a pre-initialized `.pgdata` cluster; it does not create that cluster.

Do not use example development credentials or secrets in production. The checked-in npm scripts are `start`, `dev`, `prisma:generate`, `prisma:migrate`, `db:start`, `db:stop`, `db:status`, `prisma:seed`, and `test`. The package declares `prisma:seed`, but `taleemplus_backend/prisma/seed.js` is not present in this checkout, so that command is currently incomplete.

To build Android APKs, use the configured Flutter SDK:

```powershell
flutter build apk --debug
flutter build apk --release --split-per-abi
```

## Repository map

```text
lib/                         Flutter application
  data/                      API clients, Firestore services, local database, models
  features/                  Admin, teacher, student, parent, and quiz screens
  logic/                     Providers and Dart inference/algorithms
ml_training/                 Synthetic data generator and requirements
ml_service/                  Python data extraction, model training, API, and tests
assets/ml_models/             Placeholder directory; no trained model artifact
taleemplus_backend/          Express API, Prisma schema, and PostgreSQL helper
integration_test/            Flutter integration test
```

## Verification and limitations

- Automated tests include Flutter `test/core_logic_test.dart`, backend Jest tests in `taleemplus_backend/tests/`, Python service tests in `ml_service/tests/`, and `integration_test/example_test.dart`.
- Backend setup depends on private environment values and a PostgreSQL instance. No credentials are documented here.
- Verification on 2026-10-31: `flutter analyze` clean; Flutter tests 12 passed; backend Jest 6 suites / 17 tests passed; Prisma validation and migration status succeeded; local `/health` reported PostgreSQL connected.
- `flutter build web --release` succeeded; final output is `build/web/` (43 files, approximately 43 MiB).
- `flutter build apk --release` failed at `:app:processReleaseGoogleServices` because `android/app/google-services.json` is absent. No Firebase configuration was fabricated. No Android release artifact was produced; app bundle was not attempted because the same configuration is required.
- The local PostgreSQL database checked on 2026-10-31 had two academy records, one student account, and zero attendance, fee challan, or test mark records. The ML extractor found zero usable fee and academic training rows. Deployed database contents were not checked.
- No real-data production model artifacts are present. No `.tflite`, `.pkl`, `.joblib`, `.h5`, `.pt`, `.pth`, or `.onnx` artifact is checked in; ML test artifacts are created only in temporary test directories.
