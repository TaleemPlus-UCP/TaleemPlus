import 'package:flutter/material.dart';
import '../../../widgets/gradient_background.dart';
import '../../../core/theme/app_colors.dart';

class TakeQuizScreen extends StatelessWidget {
  const TakeQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Physical Test Info"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.print_rounded,
                  size: 80, color: AppColors.accent),
              const SizedBox(height: 20),
              const Text(
                "Physical Test Module",
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  "This test is conducted physically. Please obtain the printed question paper from your teacher and submit your answers in class.",
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent)),
                child: const Text("BACK TO DASHBOARD"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
