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
enum UserRole { admin, teacher, student, parent }

extension UserRoleX on UserRole {
  /// Value stored in Firestore.
  String get value => name;

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
