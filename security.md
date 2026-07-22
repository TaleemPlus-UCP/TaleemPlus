# TaleemPlus — Security

## 1. Firestore security rules (`firestore.rules`)

`rules_version = '2'`. All access control is enforced server-side by Firestore rules, evaluated against the caller's own `users/{auth.uid}` document — there are **no Firebase custom claims**; role and approval state live entirely in Firestore.

### Helper functions

```
function signedIn() { return request.auth != null; }

function getUserData() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
}

function isApproved() {
  let user = getUserData();
  return signedIn() && user.get('account_status', 'inactive') == "active";
}

function isAdmin()  { return getUserData().get('role', '') == "admin"; }
function isTeacher(){ return getUserData().get('role', '') == "teacher"; }
function isStaff()  { return isAdmin() || isTeacher(); }

function sameAcademy(docAcademyId) {
  return getUserData().get('academy_id', '') == docAcademyId;
}
```

All accessors use `.get(field, fallback)` so a document missing a field fails safe instead of crashing the rule evaluation.

- **Approval gate**: `isApproved()` requires `account_status == "active"` on the caller's *own* profile — a valid Firebase Auth session alone is not enough; pending/rejected users are locked out of nearly every collection.
- **Multi-tenant isolation**: `sameAcademy()` compares the caller's own `academy_id` against the target document's `academy_id`. This is the sole tenant-isolation mechanism in the app (no per-tenant Firebase projects).

### Per-collection access

| Collection | Read | Write |
|---|---|---|
| `users/{uid}` | any signed-in user, **or** unauthenticated if `role == 'admin'` (needed for pre-auth academy-code lookup at signup) | create: self only; update/delete: self, or an approved same-academy admin |
| `announcements`, `quizzes`, `attendance_records`, `learning_resources` | approved + same academy | staff (admin/teacher), same academy |
| `test_marks` | approved + same academy | create/update: staff; **delete: admin only** |
| `classes` | approved + same academy | **admin only** |
| `student_queries` | approved + same academy | create: any approved same-academy user; update: staff; delete: admin |
| `ocr_documents` | **owner only** (`created_by_uid == auth.uid`) | create: approved + own uid |
| `fee_challans`, `fee_invoices` | approved + same academy | admin only |
| `notifications` | **recipient only** (`recipient_id == auth.uid`) | create: approved + same academy |

Note the intentionally broad `users` read rule: any signed-in user can read any other user's profile document, regardless of academy. This is a deliberate trade-off (needed for the current implementation, e.g. cross-user lookups) rather than an oversight, but it means user profile fields should not be treated as private between tenants.

## 2. Authentication flow

- **Signup** (`AuthService.signUp`): creates the Firebase Auth user, then writes the `users/{uid}` profile.
  - **Register Academy (admin)**: `role = admin`, `account_status = active` (auto-approved), `academy_id = uid`, a generated `academy_code` (`TP-XXXXX`).
  - **Join Academy (teacher/student/parent)**: resolves the entered academy code to an `academy_id` via `AuthService.findAcademyByCode()`, sets `account_status = pending`, and **immediately signs the user back out** so a pending account isn't left with a live session.
- **Approval**: an admin lists pending users (`getPendingUsers(academyId)`) and calls `approveUser`/`rejectUser` from `ApprovalRequestsScreen`.
- **Login** (`AuthService.signIn`): signs in, then fetches the Firestore profile; throws `AuthException` (and signs the user back out) if the profile is missing, pending, or rejected.
- **Session restore** (`AuthProvider.tryRestoreSession`, called from `SplashScreen`): only restores a session if `account_status == active`; any error routes to Login.
- **Password reset**: `AuthService.sendPasswordReset(email)` → `FirebaseAuth.sendPasswordResetEmail`.
- **"Remember me"**: stores only the plaintext **email** (not password) in `shared_preferences`.

### Firebase Auth error mapping (user-enumeration mitigation)

```dart
switch (e.code) {
  case 'invalid-email': return 'The email address is not valid.';
  case 'user-disabled': return 'This account has been disabled.';
  case 'user-not-found':
  case 'wrong-password':
  case 'invalid-credential': return 'Invalid credentials. Check your email and password.';
  case 'email-already-in-use': return 'This email is already registered.';
  case 'weak-password': return 'Password is too weak.';
  case 'network-request-failed': return 'No internet connection. Please try again.';
  default: return e.message ?? 'Authentication failed. Please try again.';
}
```

`user-not-found`, `wrong-password`, and `invalid-credential` are deliberately collapsed into one generic message so a login failure doesn't reveal whether the email exists.

## 3. Biometric auth & session timeout (`lib/logic/session_provider.dart`)

`SessionProvider` (`ChangeNotifier` + `WidgetsBindingObserver`) is the single owner of all session-security behavior:

- **Biometric unlock** (`local_auth`): `authenticateWithBiometrics()` calls `LocalAuthentication.authenticate(..., options: AuthenticationOptions(stickyAuth: true, biometricOnly: true))`. When enabled, a successful biometric check silently re-runs `AuthService.signIn` using a **password cached in `shared_preferences`** (`saved_pass_v1`). Before that password is saved, `AuthService.verifyPassword()` re-authenticates it against Firebase (`reauthenticateWithCredential`) so a mistyped password can't be persisted — but the cached password itself remains **unencrypted at rest**. This is a known, accepted trade-off for local-device convenience; a device-level compromise (root/jailbreak, backup extraction) could expose it.
- **Idle timeout**: a `Timer` armed for 5 minutes (`resetTimer`, triggered on every pointer-down app-wide via the root `Listener` in `main.dart`); on expiry, force sign-out with a visible reason ("You were logged out after 5 minutes of inactivity.").
- **Background auto-logout**: `didChangeAppLifecycleState` starts a 15-second grace timer when the app is paused/hidden; if not resumed in time, force sign-out.
- **Suppression for camera/gallery/biometric sub-activities**: `suppressBackgroundLogout()` / `resumeBackgroundLogoutTracking()` (reference-counted via `_suppressCount`) let a screen opt out of the background-timer while a system camera/gallery picker or biometric prompt is in flight — both of which otherwise look identical to genuine backgrounding. Used by every OCR/AI screen that launches `image_picker` (`ocr_scanner_screen.dart`, `ai_paper_grader_screen.dart`, `create_quiz_screen.dart`, `ai_summarizer_screen.dart`) and internally by `authenticateWithBiometrics()`.
- **Force sign-out** (`_forceSignOut`) uses the global `rootNavigatorKey` to navigate to Login and show a `ScaffoldMessenger` snackbar explaining why — ensuring a dropped session is never silent.

## 4. Recent security fixes (commit history)

### `fe5f961` — "close cross-tenant security holes, fix broken rules/query interaction, and repair error handling across all portals"

The most significant security commit in the project. Before it, the app had effectively no committed Firestore rules. It:

1. **Introduced `firestore.rules`/`firestore.indexes.json` from scratch**, closing a public-read PII leak on `users`, an unscoped cross-academy admin-write path, and unscoped fee/quiz/attendance reads across academies.
2. **Fixed client queries broken by the new academy-scoped rules** — Firestore rejects list queries whose `where` filters aren't provable by the rule, so several services were adding `academy_id` filters *server-side* (in the query itself) instead of filtering the results client-side after a broader fetch:
   - `QuizService`: `watchQuizzesByClass`, `watchMarksByQuiz`, `watchStudentMarks`, `watchClassMarks`, `getAllAcademyMarks`, `deleteQuiz`.
   - `ClassroomService`: `watchResources`, `watchQueriesForClass`, `watchQueriesForTeacher` (added an `academyId` parameter).
   - `FeeChallanRepository`: `getForStudent`, `getLatestForStudent` — re-added an `academy_id` filter that had previously been deliberately removed to dodge a composite-index requirement (fixed properly by adding the index instead).
   - `ClassRepository.deleteClass` — cascade-delete of `attendance_records` now scoped by `academyId`.
   - `AuthService`: `getApprovedByRole`, `getUsersByRole`, `getPendingUsers` — removed a fallback that let users with a null/blank `academy_id` bleed into every academy's member lists.
3. **Auth/session hardening**: `signIn()` now catches generic (not just `FirebaseAuthException`) errors, fixing a stuck-loading login button; `SessionProvider` timeouts now navigate to Login with a visible message instead of silently dropping the session; added `AuthService.verifyPassword()` to re-authenticate before caching a password for biometric login.

### `ec00b9e` — "stop background auto-logout from firing during camera/gallery/biometric use"

Root cause: the original 3-second background grace period was shorter than the real time spent in a system camera/gallery picker or biometric prompt (which trigger the same `paused` lifecycle event as genuine backgrounding), so opening the camera from any AI/OCR screen could sign the user out mid-action. Fix: grace period raised to 15 seconds, plus the `suppressBackgroundLogout()`/`resumeBackgroundLogoutTracking()` mechanism described above.

### `fe9e2f5` — "notify students/parents when a teacher posts an announcement"

Fixed a gap where announcement notifications weren't fanning out to the intended audience — not a vulnerability, but an access/notification-integrity fix included here for completeness of the security-relevant commit history.

## 5. Secrets and sensitive files

- `.gitignore` excludes `lib/firebase_options.dart`, `android/app/google-services.json`, and `ios/Runner/GoogleService-Info.plist`. Confirmed these exist locally but are **not tracked** in git.
- `firebase.json` (tracked) contains only non-secret identifiers (project ID, app IDs) — safe to ship in a client per Firebase's model.
- No API-key-shaped strings were found in tracked source.
- CI injects `FIREBASE_OPTIONS` and `GOOGLE_SERVICES_JSON` as GitHub Actions secrets at build time rather than committing them.

## 6. Known accepted risks / follow-ups

- Biometric-login password cached in plaintext `shared_preferences` (`saved_pass_v1`) — see §3. Recommended follow-up: move to platform secure storage (Keychain/Keystore via `flutter_secure_storage`) instead of `shared_preferences`.
- The `users` collection read rule is broader than strictly necessary (any signed-in user can read any user's profile, not just same-academy) — acceptable for current features but worth tightening if profile data becomes more sensitive.
- No automated secret-scanning (e.g. `git-secrets`, pre-commit hooks) is configured.
