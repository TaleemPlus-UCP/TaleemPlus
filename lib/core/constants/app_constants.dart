import 'package:flutter/widgets.dart';

/// Root navigator key so code outside the widget tree (e.g. a session
/// timeout firing from a [Timer]) can still navigate/show feedback.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Named routes used across the app.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String adminDashboard = '/admin';
  static const String teacherDashboard = '/teacher';
  static const String studentDashboard = '/student';
  static const String parentDashboard = '/parent';
}

/// The four user roles supported by TaleemPlus (matches the SDS).
enum UserRole {
  admin,
  teacher,
  student,
  parent;

  /// Value stored in Firestore.
  String get value => name;
}

extension UserRoleX on UserRole {
  /// Human-readable label shown in the UI.
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin / Owner';
      case UserRole.teacher:
        return 'Teacher / Faculty';
      case UserRole.student:
        return 'Student / Learner';
      case UserRole.parent:
        return 'Parent / Guardian';
    }
  }

  /// Route this role should land on after login.
  String get dashboardRoute {
    switch (this) {
      case UserRole.admin:
        return AppRoutes.adminDashboard;
      case UserRole.teacher:
        return AppRoutes.teacherDashboard;
      case UserRole.student:
        return AppRoutes.studentDashboard;
      case UserRole.parent:
        return AppRoutes.parentDashboard;
    }
  }

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.student,
    );
  }
}

/// Firestore collection + preference key names.
class DbKeys {
  DbKeys._();

  static const String usersCollection = 'users';

  // shared_preferences keys
  static const String prefRememberMe = 'remember_me';
  static const String prefSavedEmail = 'saved_email';
}

/// Business rules.
class AppRules {
  AppRules._();

  /// Every institutional account must use this email domain.
  static const String emailDomain = '@taleem.edu.pk';
  static const int minPasswordLength = 6;
}

/// Preset security-question choices offered at signup, used to self-verify
/// identity in the "forgot password" flow without needing a backend.
class SecurityQuestions {
  SecurityQuestions._();

  static const List<String> all = [
    "What was your childhood nickname?",
    "What is your favorite teacher's name?",
    "What city were you born in?",
    "What was the name of your first school?",
    "What is your mother's maiden name?",
  ];
}

/// Fixed set of grade levels an academy offers. Kept closed (instead of
/// free-text) so every section and enrollment maps to exactly one
/// canonical class name — no "Class 10" vs "10th" duplicates.
class AppClasses {
  AppClasses._();

  static const List<String> all = ['9th', '10th', '1st Year', '2nd Year'];
}

/// Intermediate (1st/2nd Year) subject groupings. A section's Program is
/// part of its identity — "1st Year - Pre-Engineering - A" and
/// "1st Year - ICS - A" are distinct rosters, not one shared section with
/// a descriptive tag.
class AppPrograms {
  AppPrograms._();

  static const List<String> all = [
    'FSC Pre-Engineering',
    'FSC Pre-Medical',
    'ICS',
    'ICOM',
    'Arts',
    'Science',
  ];

  static bool appliesTo(String className) =>
      className == '1st Year' || className == '2nd Year';
}
