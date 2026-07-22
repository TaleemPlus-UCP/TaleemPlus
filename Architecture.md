# TaleemPlus — Architecture

## 1. Overview

TaleemPlus is a cross-platform Flutter application (Android, iOS, Web) that provides four role-based portals — **Admin**, **Teacher**, **Student**, and **Parent** — for a single academy management system. It is a **multi-tenant** app: many academies ("tenants") share one Firebase project, and every domain document is partitioned by an `academy_id` field.

The stack:

| Layer | Technology |
|---|---|
| UI framework | Flutter (Dart), Material widgets, named-route navigation |
| State management | `provider` (ChangeNotifier + MultiProvider), one provider per feature/domain |
| Cloud backend | Firebase Auth + Cloud Firestore (primary data store), Firebase Hosting (web deploy) |
| Local storage | `sqflite` (two tables only — see [database.md](database.md)), `shared_preferences` (settings, remember-me, cached biometric password) |
| On-device AI | Google ML Kit (`google_mlkit_text_recognition`) for OCR; all "AI" logic beyond OCR is hand-written heuristic Dart code (see [prompt.md](prompt.md)) |
| PDF/print | `pdf` + `printing` (fee challans, blank test papers), `qr_flutter`/`pw.BarcodeWidget` for challan QR codes |
| Charts | `fl_chart` (Admin/Parent/Student analytics) |
| Auth extras | `local_auth` (biometric unlock) |

## 2. Layered structure

```
lib/
├── main.dart              # App bootstrap, Firebase init, MultiProvider wiring, route table
├── firebase_options.dart  # FlutterFire-generated config (gitignored, injected in CI)
├── core/                  # Cross-cutting, framework-agnostic building blocks
│   ├── constants/         # AppRoutes, UserRole enum, DbKeys, AppRules
│   ├── theme/              # AppColors, AppTheme, ThemeExtension
│   └── utils/              # Validators
├── data/                  # Persistence layer
│   ├── models/             # Plain Dart data classes (toMap/fromMap)
│   ├── remote/              # Firestore/Firebase service wrappers (stateless)
│   ├── repositories/        # Firestore- or sqflite-backed repositories
│   └── local/                # sqflite DbHelper (admin-only local tables)
├── logic/                 # ChangeNotifier "providers" — state + orchestration
├── widgets/                # Shared reusable UI (buttons, gradient background, theme toggle)
└── features/               # Screens grouped by role/module
    ├── auth/                  # splash, login, signup
    ├── admin/                  # admin dashboard + admin-only screens
    ├── teacher/                 # teacher dashboard + teacher-only screens
    ├── student/                  # student dashboard + student-only screens
    ├── parent/                    # parent dashboard + parent-only screens
    ├── quiz/                       # test creation, AI grading, mark entry (shared teacher/admin)
    ├── ocr/                         # general-purpose OCR scanner/history
    └── shared/                       # role-agnostic screens (notifications, announcements feed)
```

This is a conventional **layered, Provider-based MVVM-ish architecture**:

- `features/*` screens hold UI and light glue code; they read/mutate state via `context.watch<XProvider>()` / `context.read<XProvider>()`.
- `logic/*` providers hold state and orchestrate calls into `data/remote` services or `data/repositories`.
- `data/remote` and `data/repositories` wrap `cloud_firestore` or `sqflite` directly.

There is **no separate domain/use-case layer** — providers call services/repositories directly. This keeps the codebase simple, appropriate for a solo FYP build, at the cost of some duplicated business logic between providers (e.g. grade-letter calculation is duplicated in two model classes).

> Note: `lib/widgets/role_dashboard_scaffold.dart` is a **legacy/dead file** from an early "Phase II" placeholder dashboard concept. It is no longer referenced — each role now has its own hand-built dashboard screen. It is kept for historical reference (see [phases.md](phases.md)).

## 3. App bootstrap and navigation

`main.dart`:

1. `WidgetsFlutterBinding.ensureInitialized()` → `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
2. A single root-level `MultiProvider` registers:
   - Plain `ChangeNotifierProvider`s: `ThemeProvider`, `AuthProvider`, `MemberProvider`, `FeeProvider`, `ClassProvider`, `AttendanceProvider`, `QuizProvider`, `AdminAiProvider`, `NotificationProvider`.
   - Two `ChangeNotifierProxyProvider<AuthProvider, X>` entries that automatically re-sync when auth state changes:
     - `ParentProvider` (`syncWithUser(auth.currentUser)`)
     - `SessionProvider` (`updateAuth(auth)`)
3. The root widget (`TaleemPlusApp`) is a `Consumer2<ThemeProvider, AuthProvider>` wrapped in a `Listener` that resets an inactivity timer (`SessionProvider.resetTimer`) on every pointer-down anywhere in the app — this drives the 5-minute auto-logout (see [security.md](security.md)).
4. `MaterialApp` uses **named routes** (not `go_router`): `initialRoute: AppRoutes.splash`, with a static route table mapping to `SplashScreen`, `LoginScreen`, `SignupScreen`, and the four role dashboards. A module-level `rootNavigatorKey` (`GlobalKey<NavigatorState>`) lets code outside the widget tree (e.g. the session-timeout logic) navigate or show snackbars.

### Portal / role routing

- `UserRole { admin, teacher, student, parent }` is defined in `core/constants/app_constants.dart`, with a `dashboardRoute` extension mapping each role to its named route.
- Role is persisted as a plain string field (`role`) on the `users/{uid}` Firestore document.
- `SplashScreen._bootstrap()` calls `AuthProvider.tryRestoreSession()`: if a Firebase Auth session exists, it loads the `users/{uid}` profile and only restores the session if `account_status == "active"`. Pending/rejected accounts are signed out and sent to Login.
- On explicit sign-in, `AuthService.signIn` similarly rejects non-active accounts.
- After successful login/restore, navigation goes to `user.role.dashboardRoute`.

## 4. Multi-tenancy model

Every domain document carries an `academy_id` field:

- For an **Admin**, `academy_id == uid` — the admin's own Firebase UID *is* the tenant ID.
- All other roles (teacher/student/parent) are assigned the `academy_id` of the admin whose academy they join, either via an academy-code signup flow or admin-created accounts.

Almost every repository query and every Firestore security rule filters by `academy_id`; this is the single partitioning key across the entire schema (the one exception is `ocr_documents`, which is owner-scoped instead — see [database.md](database.md) and [security.md](security.md)).

## 5. State management pattern

One `ChangeNotifier` subclass per feature/domain, registered once in `main.dart`, consumed via `context.watch`/`context.read`. Four recurring shapes across the ~10 providers in `lib/logic/`:

1. **Simple CRUD + loading/error flags** (`FeeProvider`, `MemberProvider`, `AttendanceProvider`): `bool _loading`, `String? _error`; `load(academyId)` sets loading → awaits repository call → sets result → `notifyListeners()` in a `finally`. Derived values (totals, counts) are computed client-side over the in-memory list.
2. **Stream-based real-time providers** (`ClassProvider`, `QuizProvider`): hold or expose `Stream`s from repositories directly to `StreamBuilder`s in the UI, avoiding manual refresh logic.
3. **Proxy/dependent providers** (`ParentProvider`, `SessionProvider`): wired via `ChangeNotifierProxyProvider<AuthProvider, X>` so they automatically react to auth-state changes without screens manually coordinating it.
4. **Cross-cutting/lifecycle providers** (`SessionProvider`): additionally mixes in `WidgetsBindingObserver` for app-lifecycle-driven auto-logout, plus biometric unlock and inactivity timers (see [security.md](security.md)).

`AuthProvider` is the de facto root provider — most others read `context.read<AuthProvider>().currentUser` for `academyId`/`uid`, though only `ParentProvider`/`SessionProvider` are wired through Provider's dependency graph directly.

## 6. Data flow (typical read/write)

```
Screen (features/*)
   │  context.watch<XProvider>() / context.read<XProvider>().doThing()
   ▼
Provider (logic/*) — ChangeNotifier
   │  calls repository/service, manages _loading/_error, notifyListeners()
   ▼
Repository (data/repositories/*) or Service (data/remote/*)
   │  builds Firestore query/write, scoped by academy_id, or hits sqflite
   ▼
Firestore (cloud, enforced by firestore.rules) or sqflite (local, unenforced)
```

## 7. AI/OCR pipeline architecture

All AI-labeled features follow the same two-stage shape:

```
Image (camera/gallery via image_picker)
   → Google ML Kit TextRecognizer (on-device deep-learning OCR)
   → Hand-written heuristic/regex/keyword post-processing (Dart, no ML model)
   → Result surfaced to UI / persisted to Firestore
```

This applies to the OCR document scanner, the AI Smart Grader, the AI Test Generator, and the AI Notes Summarizer. The Admin "AI Insights" (at-risk prediction, revenue forecast) skips OCR entirely and runs simple descriptive statistics over Firestore data. See [prompt.md](prompt.md) for the exact heuristic rules of each feature, and [phases.md](phases.md) for why a planned TFLite classification model was replaced by these heuristics.

## 8. Local vs. cloud storage split

Despite the project description ("offline-first"), only two admin-side conveniences are actually local-only (sqflite): the `members` roster helper table and a legacy `fee_invoices` ledger table, both superseded in the real UI by Firestore-backed equivalents (`users` collection via `AuthService`, and `fee_challans` collection via `FeeChallanRepository`/`ChallanPdfService`). Everything else — auth/users, classes, attendance, announcements, quizzes/marks, resources, queries, notifications, OCR documents — lives directly in Firestore with no bidirectional sync engine. See [database.md](database.md) for full details.

## 9. CI/CD

`.github/workflows/main.yml` ("TaleemPlus CI/CD"), triggered on push/PR to `main`/`master` and on `v*` tags:

1. **`qa`** — checkout, Flutter setup, inject `FIREBASE_OPTIONS` secret, `flutter pub get`, `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test --coverage`.
2. **`build-android`** (needs `qa`, push-only) — Java 17 + Flutter, inject Firebase secrets, `flutter build apk --release --split-per-abi`, upload artifact.
3. **`build-web`** (needs `qa`, push-only) — inject secrets, `flutter build web --release`, deploy to Firebase Hosting (project `taleemplus-40755`).
4. **`create-release`** (needs both builds, `v*` tags only) — downloads the APK artifact and creates a GitHub Release.
