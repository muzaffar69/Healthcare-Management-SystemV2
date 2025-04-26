// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:medical_practice_app/core/animations/loading_animation.dart';
import 'package:medical_practice_app/core/constants/app_constants.dart';
import 'package:medical_practice_app/data/datasources/database_helper.dart';
import 'package:medical_practice_app/presentation/themes/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Ensure the database is initialized (started in main)
    await DatabaseHelper.instance.database; 
    
    // Add a minimum delay for splash screen visibility
    await Future.delayed(const Duration(seconds: 2)); 

    // Navigate to Login Page
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Or AppTheme.backgroundColor
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replicate logo similar to LoginPage
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services,
                size: 70,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              AppConstants.appName,
              style: AppTheme.headingStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            const LoadingAnimation(size: 40),
            const SizedBox(height: 20),
            const Text(
              'Initializing...',
              style: TextStyle(
                color: AppTheme.textLightColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}