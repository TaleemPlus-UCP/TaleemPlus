# TaleemPlus — Error Handling

## 1. Summary

TaleemPlus does **not** use a centralized `Result<T>`/`Either<L, R>`/`Failure` type. Error handling is ad hoc and layered, with a different convention at each layer of the stack. The only custom exception type in the codebase is `AuthException`.

```
Repository/Service layer   → mostly unguarded (lets exceptions propagate), a few catch-and-return-empty
Provider layer             → try/catch → _error (String?) + _loading (bool) → notifyListeners()
Screen/widget layer        → try/catch around user actions → SnackBar / dialog, guarded against double-submit
```

## 2. `AuthException` (`lib/data/remote/auth_service.dart`)

The one custom exception class in the app:

```dart
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
```

`AuthService` catches `FirebaseAuthException` from every auth-related call (`signUp`, `signIn`, `adminCreateUser`, `sendPasswordReset`, `directUpdatePassword`) and rethrows it as `AuthException(_mapAuthError(e))` with a user-facing message (see [security.md](security.md) for the exact code→message mapping). As of `fe5f961`, `signIn()` also catches **non-`FirebaseAuthException`** errors (e.g. a Firestore read failure while fetching the profile) and wraps them the same way — previously such an error would propagate uncaught past `AuthProvider.signIn`'s `on AuthException` catch clause and leave the login button stuck in a permanent loading state.

## 3. Provider layer pattern

The dominant pattern across `lib/logic/*.dart` (`FeeProvider`, `AttendanceProvider`, `AdminAiProvider`, etc.):

```dart
bool _loading = false;
String? _error;

Future<void> load(String academyId) async {
  _loading = true;
  _error = null;
  notifyListeners();
  try {
    _data = await _repository.getAll(academyId);
  } catch (e) {
    _error = 'Failed to load ...: $e';
  } finally {
    _loading = false;
    notifyListeners();
  }
}
```

The UI reads `provider.error` and renders a distinct error state. Example: `admin_ai_prediction_screen.dart` renders an `_aiErrorBanner(ai.error!)` when `AdminAiProvider.error != null` — this banner was **added in `fe5f961`**, replacing what that commit's message describes as the previous behavior of "rendering a load failure as 'all is well'" (i.e. a failed load previously showed an empty-but-successful-looking dashboard with no indication anything went wrong).

## 4. Screen/widget layer pattern

Direct `try/catch` around user-triggered actions, surfaced via `ScaffoldMessenger` SnackBars:

```dart
try {
  await someAction();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to X: $e'), backgroundColor: AppColors.danger),
  );
} finally {
  setState(() => _processingIds.remove(id));
}
```

Seen for example in `approval_requests_screen.dart` around approve/reject actions, guarded by a `_processingIds` set to prevent double-submission while an async action is in flight. Across the codebase, roughly 40 files use `try {`, 28 use `ScaffoldMessenger`, and 20 use `showDialog` (mostly confirmation dialogs and success/pending modals, not error display).

## 5. Repository/service layer

Two different behaviors coexist:

- **Repositories (`lib/data/repositories/*.dart`)** — `AttendanceRepository`, `ClassRepository`, `FeeChallanRepository`, `MemberRepository`, `FeeRepository` — are thin, **unguarded** wrappers around Firestore/sqflite calls with no `try/catch`. Exceptions propagate straight to the calling provider, which is where they're actually handled (§3).
- **Some remote services (`lib/data/remote/*.dart`)** — several `AuthService` lookup methods (`getApprovedByRole`, `getUsersByRole`, `getPendingUsers`, `findAcademyByCode`, `searchStudentsByName`) catch generic exceptions, `debugPrint(...)` them, and return `[]`/`null` rather than propagating. **This means a network failure in these specific calls looks identical to "no results" one layer up** — a caller can't distinguish "this academy code doesn't exist" from "Firestore was unreachable." This is a known limitation, not a bug fix target by itself, but worth being aware of when debugging seemingly-empty results.

## 6. Query/rules-interaction errors (fixed in `fe5f961`)

A specific class of error surfaced when `firestore.rules` was introduced: Firestore **rejects** (rather than silently returning partial data for) any list query whose `where` filters can't be proven consistent with the security rule. Several services previously fetched broadly and filtered client-side (e.g. `watchQuizzesByClass` fetching all quizzes for a class then filtering by `academyId` in Dart); under the new rules these queries started failing outright with a permission-denied error. The fix was to move the `academy_id` filter into the Firestore query itself (`.where('academy_id', isEqualTo: academyId)`) everywhere this pattern occurred — see [security.md](security.md) §4 for the full list of affected methods. This is a good example of how tightening security rules can surface latent client-side query bugs that previously "worked" only because rules weren't enforcing anything.

## 7. Session/lifecycle errors

`SessionProvider._forceSignOut(message)` is the app's mechanism for surfacing session-level errors (timeout, forced logout) — before `fe5f961` it silently flipped an `_isLocked` flag and called `signOut()` with no user-visible explanation, so a session could drop mid-screen with no indication why. It now navigates to Login via the global `rootNavigatorKey` and shows a `ScaffoldMessenger` SnackBar with the specific reason ("logged out after 5 minutes of inactivity", etc.) on the next frame.

## 8. Recommendations for future work

- Introduce a lightweight `Result<T>` (or a shared `AppError` sealed type) so the provider layer stops re-deriving the same try/catch/`_error` boilerplate in ~10 separate classes, and so screen code can pattern-match on error type instead of string-matching a message.
- Make the "catch and return empty" services (§5) distinguish "not found" from "request failed" — e.g. return `null`/throw on network error, `[]` only for a genuinely empty result set.
- Add a lint or code-review checklist item for "every Firestore repository call site should decide, deliberately, whether to catch or propagate" — currently that decision is inconsistent between files.
