import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../azure/auth_service.dart';
import '../azure/database_service.dart';
import 'api_service.dart';
import '../../config/constants.dart';

class OfflineSyncService {
  final ApiService _apiService;
  late SharedPreferences _prefs;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;
  final StreamController<bool> _syncingController = StreamController<bool>.broadcast();
  
  // Constructor
  OfflineSyncService(this._apiService);
  
  // Stream to notify UI about syncing status
  Stream<bool> get syncingStatus => _syncingController.stream;
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Set up connectivity listener
      final connectivity = Connectivity();
      _connectivitySubscription = connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
      
      // Set up periodic sync
      _setupPeriodicSync();
      
      // Check initial connectivity
      final connectivityResult = await connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // If connected, perform initial sync
        syncData();
      }
    } catch (e) {
      debugPrint('Error initializing OfflineSyncService: $e');
    }
  }
  
  // Set up periodic sync timer
  void _setupPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.syncInterval),
      (_) async {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          syncData();
        }
      },
    );
  }
  
  // Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      // When connectivity is restored, sync data
      syncData();
    }
  }
  
  // Sync data with the cloud
  Future<void> syncData() async {
    // Skip if already syncing
    if (_isSyncing) {
      return;
    }
    
    try {
      _isSyncing = true;
      _syncingController.add(true);
      
      // Get auth token
      final authService = await _apiService.getAuthService();
      final token = await authService.getAccessToken();
      
      if (token == null) {
        _isSyncing = false;
        _syncingController.add(false);
        return;
      }
      
      // Get database service
      final dbService = await _apiService.getDatabaseService();
      
      // Synchronize data
      await dbService.synchronizeData(token);
      
      // Update last sync timestamp
      await _updateLastSyncTimestamp();
      
      _isSyncing = false;
      _syncingController.add(false);
    } catch (e) {
      debugPrint('Error syncing data: $e');
      _isSyncing = false;
      _syncingController.add(false);
    }
  }
  
  // Update last sync timestamp
  Future<void> _updateLastSyncTimestamp() async {
    final now = DateTime.now().toIso8601String();
    await _prefs.setString(AppConstants.lastSyncKey, now);
  }
  
  // Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    final timestamp = _prefs.getString(AppConstants.lastSyncKey);
    if (timestamp == null) {
      return null;
    }
    return DateTime.parse(timestamp);
  }
  
  // Force sync now
  Future<bool> forceSyncNow() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false; // No internet connection
      }
      
      await syncData();
      return true;
    } catch (e) {
      debugPrint('Error forcing sync: $e');
      return false;
    }
  }
  
  // Dispose resources
  void dispose() {
    _connectivitySubscription.cancel();
    _syncTimer?.cancel();
    _syncingController.close();
  }
  
  // Add getters for auth and database services to ApiService
  extension ApiServiceExtension on ApiService {
    Future<AzureAuthService> getAuthService() async {
      // This is a workaround since we can't directly access private fields
      // In the real implementation, consider changing the visibility of _authService
      // or adding a proper getter in ApiService
      throw UnimplementedError('Implement this in ApiService');
    }
    
    Future<AzureDatabaseService> getDatabaseService() async {
      // This is a workaround since we can't directly access private fields
      // In the real implementation, consider changing the visibility of _databaseService
      // or adding a proper getter in ApiService
      throw UnimplementedError('Implement this in ApiService');
    }
  }
}
