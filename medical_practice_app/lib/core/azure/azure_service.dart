import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';
import 'auth_service.dart';
import 'database_service.dart';

class AzureService {
  final AzureAuthService _authService;
  final AzureDatabaseService _databaseService;
  final http.Client _httpClient = http.Client();

  AzureService(this._authService, this._databaseService);

  // Get base URL
  String get _baseUrl => dotenv.get(AppConstants.apiBaseUrl);

  // Get headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Handle API errors
  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'API error: ${response.statusCode}');
    }
  }

  // Health check
  Future<bool> checkApiHealth() async {
    try {
      final response = await _httpClient.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API health check failed: $e');
      return false;
    }
  }

  // Get database health
  Future<bool> checkDatabaseHealth() async {
    try {
      return _databaseService.isInitialized;
    } catch (e) {
      debugPrint('Database health check failed: $e');
      return false;
    }
  }

  // Initialize all services
  Future<void> initialize() async {
    try {
      await _authService.initialize();
      await _databaseService.initialize();
    } catch (e) {
      debugPrint('Error initializing Azure services: $e');
      rethrow;
    }
  }

  // Cleanup
  void dispose() {
    _httpClient.close();
    _authService.dispose();
    _databaseService.dispose();
  }

  // Get service instances
  AzureAuthService get authService => _authService;
  AzureDatabaseService get databaseService => _databaseService;
}
