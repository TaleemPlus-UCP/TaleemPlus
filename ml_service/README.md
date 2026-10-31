# TaleemPlus ML Service

## Readiness

The service code is implemented, but the local PostgreSQL database inspected on 2026-10-31 had 0 attendance rows, 0 fee challans, and 0 test marks. It therefore has no usable supervised training rows at present. The model status endpoints must report `INSUFFICIENT_DATA` (or `NOT_READY` when service/database configuration is missing); there are no real trained artifacts or real validation metrics to publish. Synthetic fixtures in `tests/` validate code paths only.

## Architecture and tenant isolation

Flutter calls the existing Express API. Admin ML requests are authenticated with the normal JWT and restricted to `ADMIN` by `taleemplus_backend/src/routes/mlRoutes.js`. Express derives `academyId` from the authenticated account and calls this service with `ML_INTERNAL_TOKEN`. Flutter never receives that token or a database URL. This service uses a read-only PostgreSQL account for extraction and writes artifacts only to its configured artifact directory.

The schema extraction queries join `fee_challans`, `attendance_records`, `test_marks`, `quizzes`, and `users`, and constrain every record to the authenticated academy. Student IDs are removed before feature rows reach preprocessing/training. Names, contact details, and raw source rows are never written to artifacts or training history.

## Models and labels

The source fields used by extraction are:

| Prisma model | Required fields |
|---|---|
| `User` | `id`, `academyId`, `role`, `accountStatus` for academy/student filtering. Names, email, and phone are not selected. |
| `FeeChallan` | `id`, `academyId`, `studentId`, `issueDate`, `dueDate`, `totalAmount`, `status`, `paidAt`. |
| `AttendanceRecord` | `academyId`, `studentId`, `logDate`, `status`, `recordedAt`. Invalid date strings are excluded. |
| `Quiz` | `id`, `academyId`, `testDate`. Untimed assessments are excluded. |
| `TestMark` | `academyId`, `studentId`, `quizId`, `subject`, `percentage`, `updatedAt`. |

### Fee payment risk

One training example is a fee challan snapshot at its issue date. Inputs are the preceding 90 days of attendance (recording timestamp and attendance date both precede the issue date), matured prior paid-challan delay count/average/consistency (payment timestamp precedes the issue date), and the bill plus balances still open at issue time. Past balances are reconstructed from `paidAt`, not the present-day status. The target is late payment: a paid challan with `paidAt > dueDate`, or a still-unpaid challan more than 30 days past due. A paid challan without `paidAt` is not labelable. Open balances are not inferred from eventual payment state. The schema does not backfill `paidAt` for historical rows because `updatedAt` cannot reliably establish the payment date.

Candidates: class-weighted logistic regression, random forest, and gradient boosting. The latest 20% of distinct issue dates form a temporal holdout; both classes must be present. Reported metrics include ROC-AUC, PR-AUC, precision, recall, F1, accuracy, and confusion matrix. Promotion requires ROC-AUC >= 0.60, nonzero F1, and ROC-AUC no worse than the current production model on the same validation period. The displayed risk bands use fixed probability cutoffs (0.40 and 0.70); probabilities are model estimates and are not calibrated.

### Academic performance

Each dated quiz mark is a target percentage. The features are the same student's prior marks in that subject, entered before the target quiz date, their count, and attendance recorded in the preceding 90 days and before that date. Quizzes with no test date are excluded. The latest 20% of distinct test dates are held out. Candidates are linear regression, random forest regression, and gradient boosting regression. MAE, RMSE, and R² are reported. Promotion requires lower RMSE than a training-mean baseline and no worse RMSE than the current production model on the validation dates.

Both models use median imputation for missing numeric inputs. No target or future payment/attendance/mark information is included in its snapshot features. Models require at least 100 labelable rows by default; fee validation also requires both classes. These minimums are configurable, but lowering them does not make a weak validation statistically sound. Performance output has `uncertainty: null`; the service does not claim calibrated prediction intervals.

## Schema change

`FeeChallan.paidAt` is a nullable timestamp. The backend sets it when an admin marks a challan paid. The additive SQL migration is `taleemplus_backend/prisma/migrations/20261031120000_fee_paid_at/migration.sql`. Existing paid rows remain NULL and are excluded from fee labels. Apply migrations using the deployment's existing Prisma migration procedure; do not run a schema push that removes columns.

For a non-empty deployment database that predates Prisma migrations, first verify its schema against the generated baseline. Only when it matches should migration history be initialized with `npx prisma migrate resolve --applied 20261031000000_baseline`, followed by `npx prisma migrate deploy`. The local database was checked with `prisma migrate diff`: its only schema difference was the new nullable payment timestamp; the baseline was marked applied and the additive migration deployed.

## Local setup

Use a Python version supported by the pinned packages (Python 3.11 or newer) and Node.js 18 or newer. Supply `DATABASE_URL` for a database user with SELECT access to the required tables; use a different credential from the API's write account. Supply the same randomly generated `ML_INTERNAL_TOKEN` to Node and the service via a secret manager or process environment. Do not place credentials in source control.

From the repository root in PowerShell:

```powershell
py -m venv ml_service/.venv
ml_service/.venv/Scripts/python.exe -m pip install -r ml_service/requirements-dev.txt
$env:DATABASE_URL = '<read-only PostgreSQL connection supplied locally>'
$env:ML_INTERNAL_TOKEN = '<same random secret configured in the backend environment>'
$env:ML_ARTIFACT_DIR = 'ml_service/artifacts'
ml_service/.venv/Scripts/python.exe -m uvicorn app.main:app --app-dir ml_service --host 127.0.0.1 --port 8100
```

In a separate terminal, configure `ML_SERVICE_URL=http://127.0.0.1:8100` and the same `ML_INTERNAL_TOKEN` in the backend process environment, then start Express using the project's existing `npm run dev` command from `taleemplus_backend/`. Keep the service private to the backend network in deployment; the Bearer token is a second boundary, not a reason to expose this service publicly.

## API

All routes except `/health` require `Authorization: Bearer <ML_INTERNAL_TOKEN>`. Express exposes only these admin routes beneath `/api/v2/admin/ml`:

| Method | Python route | Purpose |
|---|---|---|
| GET | `/health` | Process and PostgreSQL reachability; does not reveal the URL. |
| GET | `/models/status?academy_id=...` | Per-academy model status, usable row count, or production metadata. |
| GET | `/models/metrics?academy_id=...` | Current production evaluation metadata. |
| GET | `/models/history?academy_id=...` | Metadata-only training history. |
| POST | `/models/train/fee-risk` | Extract, validate, compare, and conditionally promote fee model. |
| POST | `/models/train/performance` | Extract, validate, compare, and conditionally promote performance model. |
| POST | `/models/retrain` | Attempt each model independently and report each outcome. |
| POST | `/models/rollback` | Restore a previously promoted version after validating its metadata and artifact. |
| POST | `/predict/fee-risk` | Validate a production model and return probability/risk category for supplied features. |
| POST | `/predict/performance` | Return predicted percentage for supplied historical features. |

Express also provides `POST /api/v2/admin/ml/predict/fee-risk` and `POST /api/v2/admin/ml/predict/performance`. These routes build inference features from the authenticated academy's PostgreSQL rows, invoke the internal service, and return aggregate counts/averages without student identifiers or names.

Express also provides `POST /api/v2/admin/ml/predict/fee-risk` and `POST /api/v2/admin/ml/predict/performance`. These routes build inference features from the authenticated academy's PostgreSQL rows, invoke the internal service, and return only aggregate counts/averages without student identifiers or names.

Training/status requests use the academy ID taken from the authenticated Node account. Prediction request features are validated against the model schema and ranges. No route returns training rows. A model that is not promoted returns an explicit unavailable/not-ready error instead of a heuristic prediction.

## Training, versioning, and rollback safety

Admin training is available through the Admin AI screen and the Express admin routes. The service also checks all academies on a configurable scheduled interval (`ML_RETRAIN_INTERVAL_HOURS`, default 24). A stable data fingerprint avoids retraining when the usable dataset has not changed. Candidate artifacts are stored under a SHA-256 academy directory with a unique version, `pipeline.joblib`, and metadata. Only the atomic `production.json` pointer marks the active artifact. Failed, insufficient, or worse candidates leave the prior pointer untouched; old promoted versions are retained and an admin-only rollback endpoint can restore one. `ML_ARTIFACT_DIR` must be a persistent, access-controlled volume in deployment and is git-ignored.

To request an admin training attempt after signing in through the app/backend, keep the access token in a local environment variable and run:

```powershell
$headers = @{ Authorization = "Bearer $env:TALEEMPLUS_ADMIN_ACCESS_TOKEN" }
Invoke-RestMethod -Method Post -Uri 'http://localhost:5000/api/v2/admin/ml/retrain' -Headers $headers -ContentType 'application/json' -Body '{}'
```

An insufficient-data response is expected until the minimum history and class/date requirements are met. A training request never makes synthetic data available to the service.

Important environment variables:

| Name | Purpose |
|---|---|
| `DATABASE_URL` | Read-only PostgreSQL connection for extraction. |
| `ML_INTERNAL_TOKEN` | Shared Node-to-ML Bearer token; use a strong random value. |
| `ML_ARTIFACT_DIR` | Private persistent model and history storage. |
| `ML_MIN_FEE_SAMPLES` | Fee-row minimum (default 100). |
| `ML_MIN_PERFORMANCE_SAMPLES` | Dated mark minimum (default 100). |
| `ML_RETRAIN_INTERVAL_HOURS` | Scheduled recheck interval (default 24). |

## Docker

Build with `docker build -t taleemplus-ml ./ml_service`. Run on a private network with `DATABASE_URL`, `ML_INTERNAL_TOKEN`, and a persistent writable volume mounted at `/srv/ml/artifacts`; the image runs as UID 10001. Configure Node's `ML_SERVICE_URL` to the internal container address. Never bake secrets, database dumps, artifacts, or student exports into the image.

## Troubleshooting

- `NOT_READY` means the service lacks a usable database configuration or cannot reach PostgreSQL. Check the process environment and network path without printing the connection string.
- `INSUFFICIENT_DATA` reports the count of labelable academy rows. Fee labels require a reliable `paidAt` timestamp or a challan observed more than 30 days after its due date; old paid rows with NULL `paidAt` are intentionally skipped. Academic labels require a quiz `testDate`.
- A prediction request returns `NOT_READY` when no production pointer exists. A validated candidate that failed promotion is visible in status/history but is not used for predictions.
- If artifacts cannot be written or restored, check that the persistent artifact volume is writable by UID 10001 and is not mounted read-only.
- The Node client returns service unavailability when `ML_SERVICE_URL` or `ML_INTERNAL_TOKEN` is missing. Confirm the same strong token is configured in both private processes; never print it while debugging.
- Prisma Client must be regenerated after changing the schema. If Windows reports a locked query engine DLL, stop the process that loaded it and rerun `npm exec prisma generate`; preserve the active backend process until a restart is approved.

## Tests

From the repository root, install dev dependencies as above and run:

```powershell
ml_service/.venv/Scripts/python.exe -m pytest ml_service/tests -q
```

The tests use synthetic fixtures for deterministic code checks only. They do not train or validate a real academy model. The current local database yielded no eligible samples, so manual training should return an insufficient-data state and create no production artifact. No teacher-reviewed TF-IDF grading set is currently available; the Dart tests are illustrative mechanics checks and do not establish grading accuracy.
