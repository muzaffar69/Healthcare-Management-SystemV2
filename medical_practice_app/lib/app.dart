import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'core/azure/auth_service.dart';
import 'core/services/offline_sync_service.dart';
import 'presentation/state/auth_provider.dart';
import 'presentation/common/widgets/loading_animation.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/doctor/home_screen.dart';
import 'presentation/screens/pharmacy/pharmacy_screen.dart';
import 'presentation/screens/lab/lab_screen.dart';
import 'presentation/screens/admin/admin_dashboard_screen.dart';

class MedicalPracticeApp extends StatefulWidget {
  final AzureAuthService authService;
  final OfflineSyncService offlineSyncService;

  const MedicalPracticeApp({
    Key? key,
    required this.authService,
    required this.offlineSyncService,
  }) : super(key: key);

  @override
  _MedicalPracticeAppState createState() => _MedicalPracticeAppState();
}

class _MedicalPracticeAppState extends State<MedicalPracticeApp> {
  late Stream<ConnectivityResult> _connectivityStream;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize connectivity monitoring
    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivityStream.listen((ConnectivityResult result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      
      // Trigger sync when coming back online
      if (_isOnline) {
        widget.offlineSyncService.syncData();
      }
    });
    
    // Check initial connectivity
    Connectivity().checkConnectivity().then((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Practice Management',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isInitializing) {
            return Scaffold(
              body: Center(
                child: LoadingAnimation(),
              ),
            );
          }
          
          if (!authProvider.isAuthenticated) {
            return LoginScreen();
          }
          
          // Route to appropriate screen based on user role
          switch (authProvider.currentUser?.role) {
            case 'doctor':
              return HomeScreen();
            case 'pharmacy':
              return PharmacyScreen();
            case 'laboratory':
              return LabScreen();
            case 'admin':
              return AdminDashboardScreen();
            default:
              // Default to doctor home screen
              return HomeScreen();
          }
        },
      ),
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
