import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:provider/provider.dart';

// import 'core/theme/app_theme.dart';
// import 'features/auth/login_screen.dart';
// import 'logic/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO Week 1 Day 1: initialize Firebase
  // await Firebase.initializeApp();

  // TODO Week 1 Day 2-3: initialize local SQLite DB (see data/local/db_helper.dart)
  // await DbHelper.instance.database;

  runApp(const TaleemPlusApp());
}

class TaleemPlusApp extends StatelessWidget {
  const TaleemPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: wrap with MultiProvider once logic/*_provider.dart files are built
    return MaterialApp(
      title: 'TaleemPlus',
      debugShowCheckedModeBanner: false,
      // theme: AppTheme.themeData,
      home: const _PlaceholderHome(),
      // home: const LoginScreen(),
    );
  }
}

// Remove once LoginScreen (Week 1 Day 4-5) is wired in as the real home.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('TaleemPlus — replace with LoginScreen (see main.dart TODOs)'),
      ),
    );
  }
}
