# TaleemPlus CI/CD Setup Guide

TaleemPlus utilizes GitHub Actions for continuous integration, automated testing, static analysis, and APK artifact building.

---

## 1. Workflow Files (`.github/workflows/`)

* **`backend-ci.yml`**: Triggers on push/PR to `feature/api-v2-cicd` or `main`. Sets up PostgreSQL service container, runs Prisma migrations, and executes Jest API integration tests.
* **`flutter-ci.yml`**: Triggers on push/PR. Sets up Flutter stable, checks formatting (`dart format`), runs static analysis (`flutter analyze`), and executes unit test suite (`flutter test`).
* **`android-apk.yml`**: Triggers on version tags (`v*`) or manual workflow dispatch. Builds signed/unsigned split release APKs and uploads them as GitHub Actions artifacts.

---

## 2. Required GitHub Secrets
To enable production deployments and secure builds, configure the following repository secrets under **Settings > Secrets and variables > Actions**:
* `DATABASE_URL`: Production PostgreSQL connection string.
* `JWT_SECRET`: Production JWT signing secret.
* `REFRESH_TOKEN_SECRET`: Production refresh token secret.
* `FIREBASE_OPTIONS`: Base64-encoded `firebase_options.dart` config (if using Firebase services).
