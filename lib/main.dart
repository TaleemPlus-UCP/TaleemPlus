import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'logic/auth_provider.dart';
import 'logic/member_provider.dart';
import 'logic/fee_provider.dart';
import 'logic/class_provider.dart';
import 'logic/attendance_provider.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/teacher/teacher_dashboard.dart';
import 'features/student/student_dashboard.dart';
import 'features/parent/parent_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TaleemPlusApp());
}

class TaleemPlusApp extends StatelessWidget {
  const TaleemPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => FeeProvider()),
        ChangeNotifierProvider(create: (_) => ClassProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: MaterialApp(
        title: 'Taleem Plus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.signup: (_) => const SignupScreen(),
          AppRoutes.adminDashboard: (_) => const AdminDashboard(),
          AppRoutes.teacherDashboard: (_) => const TeacherDashboard(),
          AppRoutes.studentDashboard: (_) => const StudentDashboard(),
          AppRoutes.parentDashboard: (_) => const ParentDashboard(),
        },
      ),
    );
  }
}