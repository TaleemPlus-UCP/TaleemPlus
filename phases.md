# TaleemPlus — Development Phases

This timeline is reconstructed from the full commit history (`git log --reverse`) plus two primary-source planning artifacts found in the code itself:
- a doc-comment in `lib/widgets/role_dashboard_scaffold.dart` referring to "Phase II" placeholder screens, and
- a `pubspec.yaml` comment referring to a "Week 6" milestone for an on-device risk-prediction model.

No separate CHANGELOG, TODO, or ROADMAP file exists in the repository; this document is the closest thing to one.

## Phase 0 — Bootstrap (2026-05-09)

| Commit | Summary |
|---|---|
| `d4d6688` | Initial commit |
| `c213119` | Initial Flutter project |
| `5349139` | Resolve README merge conflict |

Standard Flutter project scaffold, no app-specific code yet.

## Phase 1 — Skeleton & Branding (2026-06-14 – 2026-07-18)

| Commit | Summary |
|---|---|
| `20326ff` | Add TaleemPlus project skeleton structure |
| `8204688` | Update gitignore, dependencies, remove default test |
| `540d3e7` | Add auth foundation with logo, splash, rename to Taleem Plus, remove skeleton files |

The `role_dashboard_scaffold.dart` placeholder dashboard dates from this phase ("scaffolding for Phase II — real feature screens replace the `features` placeholders in later sprints"). Auth screens (splash/login/signup) and app branding were established here; the generic placeholder dashboard was later fully replaced by four dedicated role dashboards and is now dead code.

## Phase 2 — Core Academy Features (2026-07-18 – 2026-08-18)

| Commit | Summary |
|---|---|
| `b6c823c` | Add new features: attendance, fees, class management, announcements |
| `906dd8a` | refactor(teacher): overhaul dashboard for academy workflow & fix release build |
| `72002cf` | Fix Firestore index errors, add student/parent modules, new branding |

This is where the core academy domain model took shape: classes, attendance, fees, announcements, and the Student/Parent portals. First encounters with Firestore composite-index requirements appear here — a recurring theme addressed repeatedly through client-side sorting/filtering rather than always adding indexes (see [database.md](database.md)).

## Phase 3 — Portal Hardening & Multi-Class Support (2026-09-20)

| Commit | Summary |
|---|---|
| `14fbd65` | Fixed student portal issues, added multiple class assignments for teachers, and resolved announcement visibility |

Teachers gained the ability to be assigned to multiple classes/sections; student-portal bugs and announcement-visibility issues were fixed.

## Phase 4 — CI/CD & AI Feature Rollout (2026-09-21)

| Commit | Summary |
|---|---|
| `28f5e57` | Added GitHub Actions CI/CD workflow for automated build and analysis |
| `49bc84d` | Updated GitHub Actions to v4 to fix deprecation errors |
| `48367ec` | Corrected CI/CD pipeline to handle Firebase secrets correctly |
| `3ba5fca` | Updated CI/CD to use latest stable Flutter and added directory creation |
| `f9c65d1` | Ultimate CI fix: Clean dependencies and setup Java |
| `d0b1095` | Permanent fix: Downgraded lints and specified Flutter 3.22.x in CI |
| `962584e` | Created professional README with complete project overview and features |
| `8799491` | Fixed compilation errors, added AI Paper Grader to Teacher Portal, and fixed Student enrollment visibility bug |
| `e3e1afb` | chore: setup professional ci/cd pipeline |
| `9a121f3` | fix: remove auto-generated npm workflows and update main.yml |
| `d33d222` | fix: resolve github actions syntax error and clean up |

Two threads run in parallel in this phase: (1) iterative GitHub Actions setup (Firebase secret injection, Flutter version pinning, Java setup — the classic CI teething problems for a Flutter+Firebase project), and (2) the first shipped "AI" feature, the **AI Paper Grader** (`8799491`).

### Scope decision: TFLite risk model → heuristic fallback
`pubspec.yaml` contains a commented-out dependency:
```yaml
# tflite_flutter: ^0.11.0
# On-device ML inference for the risk predictor (Week 6)
```
and `ml_training/` contains an incomplete pipeline (`synthetic_dataset.csv` with only a header row, a stub `train_risk_model.py`, and a fully-commented-out `export_tflite.py` whose own printed message says: *"If this step stalls, fall back to the documented heuristic formula instead... rather than losing days here — it's a legitimate, documentable design decision."*). This confirms an original plan (evidently scheduled around "Week 6" of development) to ship a trained TFLite classification model for at-risk student prediction, which was consciously de-scoped in favor of the heuristic threshold approach actually shipped in `AdminAiProvider` (average percentage < 50% ⇒ at-risk). See [prompt.md](prompt.md) for the heuristic that replaced it.

## Phase 5 — Final Polish & Security Hardening (2026-10-21 – 2026-07-31)

| Commit | Summary |
|---|---|
| `f8f0612` | fix: finalize ci/cd and formatting |
| `db218d5` | chore: trigger ci with formatted files |
| `58162b2` | Your commit message |
| `f059272` | Merge remote-tracking branch 'origin/main' |
| `fe5f961` | fix: close cross-tenant security holes, fix broken rules/query interaction, and repair error handling across all portals |
| `ec00b9e` | fix: stop background auto-logout from firing during camera/gallery/biometric use |
| `fe9e2f5` | fix: notify students/parents when a teacher posts an announcement |

The most significant hardening commit in the project's history, `fe5f961`, introduced `firestore.rules`/`firestore.indexes.json` from scratch and fixed matching client-side queries across the app, closing several cross-tenant data-leak paths. `ec00b9e` fixed a false-positive auto-logout bug affecting every camera/OCR-driven "AI" screen. `fe9e2f5` closed a gap where announcements weren't triggering notifications to their intended audience. Full details in [security.md](security.md) and [errorhandling.md](errorhandling.md).

## Marketing vs. shipped reality — a documented gap

The README and in-app UI describe the app as having "100% Offline AI" with "TFLite Inference: On-device execution of a custom classification model for student performance prediction." The actual shipped implementation:

- **Real on-device deep learning**: Google ML Kit text recognition (OCR) only.
- **Everything else labeled "AI"** (Smart Grader, Test Generator, Notes Summarizer, At-Risk Prediction, Revenue Forecast): deterministic, explainable, rule-based/statistical Dart code — no trained model, no `tflite_flutter` dependency active, no `.tflite` asset ever loaded (`assets/ml_models/` is an empty declared asset folder).

This is treated in this project as a legitimate, documented scope reduction (per the `ml_training/export_tflite.py` comment) rather than an oversight — appropriate for a solo Final Year Project balancing ambition against a fixed timeline. See [prompt.md](prompt.md) for exactly what each "AI" feature does instead.

## Suggested future phases (not yet started)

- Complete the `ml_training/` pipeline and wire up a real `tflite_flutter` model for at-risk prediction, replacing the average-percentage heuristic.
- Build an in-app quiz-taking flow using the already-defined but unused `QuizSubmissionModel`/`AnswerModel` (currently `TakeQuizScreen` is a static "take this test on paper" notice).
- Encrypt the locally-cached biometric-login password (`saved_pass_v1`) instead of storing it in plaintext `shared_preferences` (see [security.md](security.md)).
- Add automated integration-test coverage beyond the default Flutter template stub in `integration_test/`.
