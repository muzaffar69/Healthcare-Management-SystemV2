// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'presentation/themes/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/datasources/database_helper.dart';
import 'data/models/patient_model.dart';
import 'data/models/visit_model.dart';

// Pages
import 'presentation/pages/splash/splash_screen.dart';
import 'presentation/pages/login/login_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/pages/dashboard/dashboard_page.dart';
import 'presentation/pages/drugs/drugs_page.dart';
import 'presentation/pages/lab_tests/lab_tests_page.dart';
import 'presentation/pages/settings/settings_page.dart';
import 'presentation/pages/patients/add_patient_page.dart';
import 'presentation/pages/patients/patient_details_page.dart';
import 'presentation/pages/visits/add_visit_page.dart';
import 'presentation/pages/visits/visit_details_page.dart';

void main() async {
  try {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Initialize database in the background
    DatabaseHelper.instance.database.then((_) {
      print("Database initialized successfully");
    }).catchError((error) {
      print("Error initializing database: $error");
    });
    
    // Run the app - starting directly with the login screen
    runApp(const MyApp());
    
  } catch (e) {
    print('Error during app startup: $e');
    // Run minimal error app if there's a critical error
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppConstants.splashRoute, // Start with splash screen
      routes: {
        AppConstants.splashRoute: (context) => const SplashScreen(),
        AppConstants.loginRoute: (context) => const LoginPage(),
        AppConstants.homeRoute: (context) => const HomePage(),
        AppConstants.dashboardRoute: (context) => const DashboardPage(),
        AppConstants.drugsRoute: (context) => const DrugsPage(),
        AppConstants.labTestsRoute: (context) => const LabTestsPage(),
        AppConstants.settingsRoute: (context) => const SettingsPage(),
        AppConstants.addPatientRoute: (context) => const AddPatientPage(),
        // Routes requiring arguments are handled in onGenerateRoute
      },
      // For routes that require arguments, use onGenerateRoute
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppConstants.patientDetailsRoute:
            if (settings.arguments is Patient) {
              final patient = settings.arguments as Patient;
              return MaterialPageRoute(
                builder: (context) => PatientDetailsPage(patient: patient),
              );
            }
            break; // Invalid argument type
          case AppConstants.addVisitRoute:
            if (settings.arguments is Patient) {
              final patient = settings.arguments as Patient;
              return MaterialPageRoute(
                builder: (context) => AddVisitPage(patient: patient),
              );
            }
            break; // Invalid argument type
          case AppConstants.visitDetailsRoute:
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              if (args['patient'] is Patient && args['visit'] is Visit) {
                final patient = args['patient'] as Patient;
                final visit = args['visit'] as Visit;
                return MaterialPageRoute(
                  builder: (context) => VisitDetailsPage(patient: patient, visit: visit),
                );
              }
            }
            break; // Invalid argument type or structure

          // Add cases for other routes requiring arguments here if needed
        }

        // If no matching route is found or arguments are invalid, return a 404 page
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found or Invalid Arguments')),
            body: Center(child: Text('Could not find route: ${settings.name}')),
          ),
        );
      },
    );
  }
}

// Simple error app to show if critical initialization fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                'An error occurred during startup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Please restart the application',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  SystemNavigator.pop(); // Exit the app
                },
                child: const Text('Close App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}