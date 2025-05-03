import 'package:flutter/material.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/doctor/home_screen.dart';
import '../presentation/screens/doctor/dashboard_screen.dart';
import '../presentation/screens/doctor/patient_list_screen.dart';
import '../presentation/screens/doctor/patient_details_screen.dart';
import '../presentation/screens/doctor/add_patient_screen.dart';
import '../presentation/screens/doctor/visit_details_screen.dart';
import '../presentation/screens/doctor/add_visit_screen.dart';
import '../presentation/screens/doctor/drug_management_screen.dart';
import '../presentation/screens/doctor/lab_test_management_screen.dart';
import '../presentation/screens/doctor/settings_screen.dart';
import '../presentation/screens/pharmacy/pharmacy_screen.dart';
import '../presentation/screens/lab/lab_screen.dart';
import '../presentation/screens/admin/admin_dashboard_screen.dart';
import '../core/models/patient_model.dart';
import '../core/models/visit_model.dart';

class AppRoutes {
  // Route names
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String patientList = '/patient-list';
  static const String patientDetails = '/patient-details';
  static const String addPatient = '/add-patient';
  static const String visitDetails = '/visit-details';
  static const String addVisit = '/add-visit';
  static const String drugManagement = '/drug-management';
  static const String labTestManagement = '/lab-test-management';
  static const String settings = '/settings';
  static const String pharmacy = '/pharmacy';
  static const String laboratory = '/laboratory';
  static const String adminDashboard = '/admin-dashboard';
  
  // Route map
  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    home: (context) => const HomeScreen(),
    dashboard: (context) => const DashboardScreen(),
    patientList: (context) => const PatientListScreen(),
    addPatient: (context) => const AddPatientScreen(),
    drugManagement: (context) => const DrugManagementScreen(),
    labTestManagement: (context) => const LabTestManagementScreen(),
    settings: (context) => const SettingsScreen(),
    pharmacy: (context) => const PharmacyScreen(),
    laboratory: (context) => const LabScreen(),
    adminDashboard: (context) => const AdminDashboardScreen(),
  };
  
  // For routes that need parameters
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case patientDetails:
        final Patient patient = settings.arguments as Patient;
        return MaterialPageRoute(
          builder: (context) => PatientDetailsScreen(patient: patient),
        );
        
      case visitDetails:
        final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => VisitDetailsScreen(
            patient: args['patient'] as Patient,
            visit: args['visit'] as Visit,
          ),
        );
        
      case addVisit:
        final Patient patient = settings.arguments as Patient;
        return MaterialPageRoute(
          builder: (context) => AddVisitScreen(patient: patient),
        );
        
      default:
        return null;
    }
  }
  
  // Page transition animations based on the design references
  static PageRouteBuilder<dynamic> buildPageRoute({
    required Widget page,
    required RouteSettings settings,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }
}
