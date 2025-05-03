import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';

class SettingsProvider with ChangeNotifier {
  final ApiService _apiService;

  Map<String, dynamic> _settings = {};
  bool _isLoading = false;
  String? _error;

  SettingsProvider(this._apiService) {
    loadSettings();
  }

  // Getters
  Map<String, dynamic> get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Doctor settings getters
  String get doctorName => _settings['doctorName'] ?? '';
  String get specialty => _settings['specialty'] ?? '';
  String get phoneNumber => _settings['phoneNumber'] ?? '';
  String get address => _settings['address'] ?? '';
  String get email => _settings['email'] ?? '';
  String get notes => _settings['notes'] ?? '';
  String get profilePhotoUrl => _settings['profilePhotoUrl'] ?? '';

  // Load settings
  Future<void> loadSettings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _settings = await _apiService.getDoctorSettings();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update settings
  Future<bool> updateSettings(Map<String, dynamic> newSettings) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _apiService.updateDoctorSettings(newSettings);

      if (success) {
        _settings = newSettings;
      }

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update specific setting
  Future<bool> updateSetting(String key, dynamic value) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedSettings = Map<String, dynamic>.from(_settings);
      updatedSettings[key] = value;

      final success = await _apiService.updateDoctorSettings(updatedSettings);

      if (success) {
        _settings = updatedSettings;
      }

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
