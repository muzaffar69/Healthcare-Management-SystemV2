import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../models/user_model.dart';

class AzureAuthService {
  late AadOAuth _oauth;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  
  User? _currentUser;
  bool _isInitialized = false;
  
  // Getters
  Stream<bool> get authStateChanges => _authStateController.stream;
  bool get isInitialized => _isInitialized;
  User? get currentUser => _currentUser;
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      // Load configuration from environment variables
      final String tenant = dotenv.get(AppConstants.azureAdTenant);
      final String clientId = dotenv.get(AppConstants.azureClientId);
      final String redirectUri = dotenv.get(AppConstants.azureRedirectUri);
      final String scope = dotenv.get(AppConstants.azureGraphScope);
      
      // Configure Azure AD OAuth
      final Config config = Config(
        tenant: tenant,
        clientId: clientId,
        scope: scope,
        redirectUri: redirectUri,
        navigatorKey: GlobalKey<NavigatorState>(),
      );
      
      _oauth = AadOAuth(config);
      
      // Check if we have a stored token
      await _loadStoredUser();
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Azure Auth Service: $e');
      rethrow;
    }
  }
  
  // Login with Azure AD
  Future<bool> login() async {
    try {
      await _oauth.login();
      final String? accessToken = await _oauth.getAccessToken();
      
      if (accessToken == null) {
        return false;
      }
      
      // Get user info from Microsoft Graph API
      final user = await _getUserInfo(accessToken);
      
      if (user != null) {
        _currentUser = user;
        
        // Store user and token
        await _storeUserAndToken(user, accessToken);
        
        // Notify listeners
        _authStateController.add(true);
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error during login: $e');
      await logout();
      return false;
    }
  }
  
  // Login with code for pharmacy and lab accounts
  Future<bool> loginWithCode(String code, String accountType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String apiUrl = dotenv.get(AppConstants.apiBaseUrl);
      
      // Call the API to verify the code
      final response = await http.post(
        Uri.parse('$apiUrl/auth/code-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'accountType': accountType,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['token'];
        final userData = data['user'];
        
        final user = User.fromJson(userData);
        _currentUser = user;
        
        // Store user and token
        await _storeUserAndToken(user, accessToken);
        
        // Notify listeners
        _authStateController.add(true);
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error during code login: $e');
      return false;
    }
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      await _oauth.logout();
      await _clearStoredUserAndToken();
      _currentUser = null;
      _authStateController.add(false);
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Force clear stored data even if logout fails
      await _clearStoredUserAndToken();
      _currentUser = null;
      _authStateController.add(false);
    }
  }
  
  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      if (_currentUser == null) {
        return false;
      }
      
      // Check if token exists and is valid
      final String? token = await _secureStorage.read(key: AppConstants.tokenKey);
      if (token == null) {
        return false;
      }
      
      // Token exists, check if it's expired
      // In a real app, you might want to use the JWT decoder to check expiration
      // For simplicity, we'll rely on Azure SDK's token refresh mechanism
      
      return true;
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }
  
  // Refresh token if needed
  Future<String?> getAccessToken() async {
    try {
      return await _oauth.getAccessToken();
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return null;
    }
  }
  
  // Get user info from Microsoft Graph API
  Future<User?> _getUserInfo(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Call your API to get the user role and other app-specific info
        final apiUrl = dotenv.get(AppConstants.apiBaseUrl);
        final userInfoResponse = await http.get(
          Uri.parse('$apiUrl/auth/user-info'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );
        
        if (userInfoResponse.statusCode == 200) {
          final appUserData = jsonDecode(userInfoResponse.body);
          
          // Combine Graph API data with app-specific user data
          return User(
            id: data['id'],
            displayName: data['displayName'],
            email: data['mail'] ?? data['userPrincipalName'],
            role: appUserData['role'],
            subscriptionEndDate: appUserData['subscriptionEndDate'] != null 
                ? DateTime.parse(appUserData['subscriptionEndDate']) 
                : null,
            isActive: appUserData['isActive'] ?? false,
            hasPharmacyAccount: appUserData['hasPharmacyAccount'] ?? false,
            hasLabAccount: appUserData['hasLabAccount'] ?? false,
            pharmacyAccountActive: appUserData['pharmacyAccountActive'] ?? false,
            labAccountActive: appUserData['labAccountActive'] ?? false,
            settings: appUserData['settings'] != null
                ? Map<String, dynamic>.from(appUserData['settings'])
                : {},
          );
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting user info: $e');
      return null;
    }
  }
  
  // Store user and token securely
  Future<void> _storeUserAndToken(User user, String token) async {
    try {
      // Store token in secure storage
      await _secureStorage.write(key: AppConstants.tokenKey, value: token);
      
      // Store user data in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error storing user and token: $e');
    }
  }
  
  // Clear stored user and token
  Future<void> _clearStoredUserAndToken() async {
    try {
      await _secureStorage.delete(key: AppConstants.tokenKey);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userKey);
    } catch (e) {
      debugPrint('Error clearing stored user and token: $e');
    }
  }
  
  // Load stored user if available
  Future<void> _loadStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
        _authStateController.add(true);
      } else {
        _authStateController.add(false);
      }
    } catch (e) {
      debugPrint('Error loading stored user: $e');
      _authStateController.add(false);
    }
  }
  
  // Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
