import 'package:flutter/foundation.dart';
import '../../core/azure/auth_service.dart';
import '../../core/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AzureAuthService _authService;
  bool _isInitializing = true;
  
  AuthProvider(this._authService) {
    _initialize();
  }
  
  // Getters
  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => currentUser != null;
  bool get isInitializing => _isInitializing;
  
  // Initialize the provider
  Future<void> _initialize() async {
    try {
      await _authService.isAuthenticated();
      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing AuthProvider: $e');
      _isInitializing = false;
      notifyListeners();
    }
  }
  
  // Login with Azure AD
  Future<bool> login() async {
    try {
      final success = await _authService.login();
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Error logging in: $e');
      return false;
    }
  }
  
  // Login with code for pharmacy and lab accounts
  Future<bool> loginWithCode(String code, String accountType) async {
    try {
      final success = await _authService.loginWithCode(code, accountType);
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Error logging in with code: $e');
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      notifyListeners();
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }
  
  // Check if user has pharmacy access
  bool get hasPharmacyAccess {
    return currentUser?.hasPharmacyAccess ?? false;
  }
  
  // Check if user has lab access
  bool get hasLabAccess {
    return currentUser?.hasLabAccess ?? false;
  }
  
  // Check if subscription is active
  bool get isSubscriptionActive {
    return currentUser?.isSubscriptionActive ?? false;
  }
  
  // Check if subscription is expiring soon
  bool isSubscriptionExpiringInDays(int days) {
    return currentUser?.isSubscriptionExpiringInDays(days) ?? false;
  }
  
  // Get subscription end date string
  String get subscriptionEndDateString {
    final endDate = currentUser?.subscriptionEndDate;
    if (endDate == null) {
      return 'No active subscription';
    }
    
    return '${endDate.day}/${endDate.month}/${endDate.year}';
  }
  
  // Get days until subscription expires
  int get daysUntilSubscriptionExpires {
    final endDate = currentUser?.subscriptionEndDate;
    if (endDate == null) {
      return 0;
    }
    
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}
