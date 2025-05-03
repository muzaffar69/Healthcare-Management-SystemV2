import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'core/services/api_service.dart';
import 'core/services/offline_sync_service.dart';
import 'presentation/state/auth_provider.dart';
import 'presentation/state/patient_provider.dart';
import 'presentation/state/visit_provider.dart';
import 'presentation/state/settings_provider.dart';
import 'core/azure/auth_service.dart';
import 'core/azure/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Azure services
  final authService = AzureAuthService();
  await authService.initialize();
  
  final databaseService = AzureDatabaseService();
  await databaseService.initialize();
  
  // Initialize API service
  final apiService = ApiService(authService, databaseService);
  
  // Initialize offline sync service
  final offlineSyncService = OfflineSyncService(apiService);
  await offlineSyncService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => PatientProvider(apiService)),
        ChangeNotifierProvider(create: (_) => VisitProvider(apiService)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(apiService)),
      ],
      child: MedicalPracticeApp(
        authService: authService,
        offlineSyncService: offlineSyncService,
      ),
    ),
  );
}
