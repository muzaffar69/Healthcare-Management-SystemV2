import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../../core/models/patient_model.dart';

class PatientProvider with ChangeNotifier {
  final ApiService _apiService;
  
  List<Patient> _patients = [];
  bool _isLoading = false;
  String? _error;
  
  PatientProvider(this._apiService);
  
  // Getters
  List<Patient> get patients => _patients;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load all patients
  Future<void> loadPatients() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final patients = await _apiService.getPatients();
      
      _patients = patients;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Get a specific patient
  Future<Patient> getPatient(String id) async {
    try {
      // First, try to find in local list
      final localPatient = _patients.firstWhere(
        (p) => p.id == id,
        orElse: () => Patient(
          id: '',
          name: '',
          age: 0,
          gender: '',
          phoneNumber: '',
          firstVisitDate: DateTime.now(),
          doctorId: '',
          lastModified: DateTime.now(),
        ),
      );
      
      if (localPatient.id.isNotEmpty) {
        return localPatient;
      }
      
      // If not found, fetch from API
      final patient = await _apiService.getPatient(id);
      return patient;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Add a new patient
  Future<Patient> addPatient({
    required String name,
    required int age,
    required String gender,
    required String phoneNumber,
    String address = '',
    required DateTime firstVisitDate,
    double? weight,
    double? height,
    List<String> chronicDiseases = const [],
    String familyHistory = '',
    String notes = '',
    File? photoFile,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Create a patient object
      final newPatient = Patient(
        id: '',  // API will generate an ID
        name: name,
        age: age,
        gender: gender,
        phoneNumber: phoneNumber,
        address: address,
        firstVisitDate: firstVisitDate,
        weight: weight,
        height: height,
        chronicDiseases: chronicDiseases,
        familyHistory: familyHistory,
        notes: notes,
        photoUrl: '',
        doctorId: '',  // API will set this
        lastModified: DateTime.now(),
      );
      
      // Create the patient
      final createdPatient = await _apiService.createPatient(newPatient);
      
      // If a photo was provided, upload it
      if (photoFile != null) {
        final photoUrl = await _apiService.uploadPatientPhoto(photoFile, createdPatient.id);
        
        // Update the patient with the photo URL
        final updatedPatient = createdPatient.copyWith(photoUrl: photoUrl);
        await _apiService.updatePatient(updatedPatient);
        
        // Add to local list
        _patients.add(updatedPatient);
        _isLoading = false;
        notifyListeners();
        
        return updatedPatient;
      } else {
        // Add to local list
        _patients.add(createdPatient);
        _isLoading = false;
        notifyListeners();
        
        return createdPatient;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Update an existing patient
  Future<Patient> updatePatient({
    required String id,
    String? name,
    int? age,
    String? gender,
    String? phoneNumber,
    String? address,
    DateTime? firstVisitDate,
    double? weight,
    double? height,
    List<String>? chronicDiseases,
    String? familyHistory,
    String? notes,
    File? photoFile,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Get the current patient
      final currentPatient = await getPatient(id);
      
      // Create updated patient object
      final updatedPatient = currentPatient.copyWith(
        name: name ?? currentPatient.name,
        age: age ?? currentPatient.age,
        gender: gender ?? currentPatient.gender,
        phoneNumber: phoneNumber ?? currentPatient.phoneNumber,
        address: address ?? currentPatient.address,
        firstVisitDate: firstVisitDate ?? currentPatient.firstVisitDate,
        weight: weight ?? currentPatient.weight,
        height: height ?? currentPatient.height,
        chronicDiseases: chronicDiseases ?? currentPatient.chronicDiseases,
        familyHistory: familyHistory ?? currentPatient.familyHistory,
        notes: notes ?? currentPatient.notes,
        lastModified: DateTime.now(),
      );
      
      // Update the patient
      final result = await _apiService.updatePatient(updatedPatient);
      
      // If a photo was provided, upload it
      if (photoFile != null) {
        final photoUrl = await _apiService.uploadPatientPhoto(photoFile, id);
        
        // Update the patient with the photo URL
        final patientWithPhoto = result.copyWith(photoUrl: photoUrl);
        await _apiService.updatePatient(patientWithPhoto);
        
        // Update in local list
        final index = _patients.indexWhere((p) => p.id == id);
        if (index >= 0) {
          _patients[index] = patientWithPhoto;
        }
        
        _isLoading = false;
        notifyListeners();
        
        return patientWithPhoto;
      } else {
        // Update in local list
        final index = _patients.indexWhere((p) => p.id == id);
        if (index >= 0) {
          _patients[index] = result;
        }
        
        _isLoading = false;
        notifyListeners();
        
        return result;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Delete a patient
  Future<bool> deletePatient(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final success = await _apiService.deletePatient(id);
      
      if (success) {
        // Remove from local list
        _patients.removeWhere((p) => p.id == id);
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
  
  // Toggle patient pin status
  Future<bool> togglePatientPin(String id, bool isPinned) async {
    try {
      final success = await _apiService.togglePatientPin(id, isPinned);
      
      if (success) {
        // Update in local list
        final index = _patients.indexWhere((p) => p.id == id);
        if (index >= 0) {
          _patients[index] = _patients[index].copyWith(isPinned: isPinned);
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Get pinned patients
  List<Patient> get pinnedPatients {
    return _patients.where((p) => p.isPinned).toList();
  }
  
  // Search patients
  List<Patient> searchPatients(String query) {
    if (query.isEmpty) {
      return _patients;
    }
    
    final lowerQuery = query.toLowerCase();
    return _patients.where((p) => 
      p.name.toLowerCase().contains(lowerQuery) ||
      p.phoneNumber.contains(lowerQuery)
    ).toList();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}
