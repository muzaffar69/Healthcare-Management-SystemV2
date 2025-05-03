import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../azure/auth_service.dart';
import '../azure/database_service.dart';
import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../models/prescription_model.dart';
import '../models/lab_test_model.dart';
import '../../config/constants.dart';

class ApiService {
  final AzureAuthService _authService;
  final AzureDatabaseService _databaseService;
  final Uuid _uuid = const Uuid();
  final http.Client _httpClient = http.Client();
  
  ApiService(this._authService, this._databaseService);
  
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
  
  // =====================
  // Patient API methods
  // =====================
  
  // Get all patients for the current doctor
  Future<List<Patient>> getPatients() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Check if online or offline
      try {
        final headers = await _getHeaders();
        final response = await _httpClient.get(
          Uri.parse('$_baseUrl/patients?doctorId=${currentUser.id}'),
          headers: headers,
        );
        
        _handleError(response);
        
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Patient.fromJson(json)).toList();
      } catch (e) {
        // If online request fails, try to get from local database
        final patientsData = await _databaseService.query(
          'Patients',
          where: 'doctorId = ? AND isDeleted = ?',
          whereArgs: [currentUser.id, 0],
        );
        
        return patientsData.map((data) => Patient.fromJson(data)).toList();
      }
    } catch (e) {
      debugPrint('Error getting patients: $e');
      rethrow;
    }
  }
  
  // Get a specific patient by ID
  Future<Patient> getPatient(String id) async {
    try {
      // Check if online or offline
      try {
        final headers = await _getHeaders();
        final response = await _httpClient.get(
          Uri.parse('$_baseUrl/patients/$id'),
          headers: headers,
        );
        
        _handleError(response);
        
        final data = jsonDecode(response.body);
        return Patient.fromJson(data);
      } catch (e) {
        // If online request fails, try to get from local database
        final patientData = await _databaseService.query(
          'Patients',
          where: 'id = ?',
          whereArgs: [id],
        );
        
        if (patientData.isEmpty) {
          throw Exception('Patient not found');
        }
        
        return Patient.fromJson(patientData.first);
      }
    } catch (e) {
      debugPrint('Error getting patient: $e');
      rethrow;
    }
  }
  
  // Create a new patient
  Future<Patient> createPatient(Patient patient) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Generate a new ID if not provided
      final patientWithId = patient.id.isEmpty
          ? patient.copyWith(
              id: _uuid.v4(),
              doctorId: currentUser.id,
              lastModified: DateTime.now(),
            )
          : patient;
      
      try {
        // Try to create patient online
        final headers = await _getHeaders();
        final response = await _httpClient.post(
          Uri.parse('$_baseUrl/patients'),
          headers: headers,
          body: jsonEncode(patientWithId.toJson()),
        );
        
        _handleError(response);
        
        final data = jsonDecode(response.body);
        final createdPatient = Patient.fromJson(data);
        
        // Save to local database as well
        await _databaseService.insert(
          'Patients',
          patientWithId.toSqlite(),
        );
        
        return createdPatient;
      } catch (e) {
        // If online creation fails, save to local database only
        await _databaseService.insert(
          'Patients',
          patientWithId.toSqlite(),
        );
        
        return patientWithId;
      }
    } catch (e) {
      debugPrint('Error creating patient: $e');
      rethrow;
    }
  }
  
  // Update an existing patient
  Future<Patient> updatePatient(Patient patient) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Ensure the patient belongs to the current doctor
      if (patient.doctorId != currentUser.id) {
        throw Exception('Unauthorized to update this patient');
      }
      
      final patientWithTimestamp = patient.copyWith(
        lastModified: DateTime.now(),
      );
      
      try {
        // Try to update patient online
        final headers = await _getHeaders();
        final response = await _httpClient.put(
          Uri.parse('$_baseUrl/patients/${patient.id}'),
          headers: headers,
          body: jsonEncode(patientWithTimestamp.toJson()),
        );
        
        _handleError(response);
        
        final data = jsonDecode(response.body);
        final updatedPatient = Patient.fromJson(data);
        
        // Update in local database as well
        await _databaseService.update(
          'Patients',
          patientWithTimestamp.toSqlite(),
          where: 'id = ?',
          whereArgs: [patient.id],
        );
        
        return updatedPatient;
      } catch (e) {
        // If online update fails, update in local database only
        await _databaseService.update(
          'Patients',
          patientWithTimestamp.toSqlite(),
          where: 'id = ?',
          whereArgs: [patient.id],
        );
        
        return patientWithTimestamp;
      }
    } catch (e) {
      debugPrint('Error updating patient: $e');
      rethrow;
    }
  }
  
  // Delete a patient (soft delete)
  Future<bool> deletePatient(String id) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      try {
        // Try to delete patient online
        final headers = await _getHeaders();
        final response = await _httpClient.delete(
          Uri.parse('$_baseUrl/patients/$id'),
          headers: headers,
        );
        
        _handleError(response);
        
        // Soft delete in local database as well
        await _databaseService.update(
          'Patients',
          {
            'isDeleted': 1,
            'lastModified': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        
        return true;
      } catch (e) {
        // If online deletion fails, soft delete in local database only
        await _databaseService.update(
          'Patients',
          {
            'isDeleted': 1,
            'lastModified': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting patient: $e');
      return false;
    }
  }
  
  // Toggle patient pin status
  Future<bool> togglePatientPin(String id, bool isPinned) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      try {
        // Try to update pin status online
        final headers = await _getHeaders();
        final response = await _httpClient.patch(
          Uri.parse('$_baseUrl/patients/$id/pin'),
          headers: headers,
          body: jsonEncode({'isPinned': isPinned}),
        );
        
        _handleError(response);
        
        // Update in local database as well
        await _databaseService.update(
          'Patients',
          {
            'isPinned': isPinned ? 1 : 0,
            'lastModified': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        
        return true;
      } catch (e) {
        // If online update fails, update in local database only
        await _databaseService.update(
          'Patients',
          {
            'isPinned': isPinned ? 1 : 0,
            'lastModified': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling patient pin: $e');
      return false;
    }
  }
  
  // Upload patient photo
  Future<String> uploadPatientPhoto(File photoFile, String patientId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Failed to get access token');
      }
      
      // Generate a unique filename
      final fileName = '$patientId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to Azure Blob Storage
      final photoUrl = await _databaseService.uploadFile(
        photoFile,
        'patient-photos',
        fileName,
        accessToken: token,
      );
      
      // Update patient with new photo URL
      await _databaseService.update(
        'Patients',
        {
          'photoUrl': photoUrl,
          'lastModified': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [patientId],
      );
      
      return photoUrl;
    } catch (e) {
      debugPrint('Error uploading patient photo: $e');
      rethrow;
    }
  }
  
  // =====================
  // Visit API methods
  // =====================
  
  // Get all visits for a patient
  Future<List<Visit>> getVisits(String patientId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      try {
        // Try to get visits online
        final headers = await _getHeaders();
        final response = await _httpClient.get(
          Uri.parse('$_baseUrl/patients/$patientId/visits'),
          headers: headers,
        );
        
        _handleError(response);
        
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Visit.fromJson(json)).toList();
      } catch (e) {
        // If online request fails, get from local database
        final visitsData = await _databaseService.query(
          'Visits',
          where: 'patientId = ? AND isDeleted = ?',
          whereArgs: [patientId, 0],
        );
        
        final visits = visitsData.map((data) => Visit.fromJson(data)).toList();
        
        // For each visit, get prescriptions and lab tests
        for (int i = 0; i < visits.length; i++) {
          final visitId = visits[i].id;
          
          final prescriptionsData = await _databaseService.query(
            'Prescriptions',
            where: 'visitId = ? AND isDeleted = ?',
            whereArgs: [visitId, 0],
          );
          
          final labTestsData = await _databaseService.query(
            'LabTests',
            where: 'visitId = ? AND isDeleted = ?',
            whereArgs: [visitId, 0],
          );
          
          final prescriptions = prescriptionsData
              .map((data) => Prescription.fromJson(data))
              .toList();
          
          final labTests = labTestsData
              .map((data) => LabTest.fromJson(data))
              .toList();
          
          visits[i] = visits[i].copyWith(
            prescriptions: prescriptions,
            labTests: labTests,
          );
        }
        
        return visits;
      }
    } catch (e) {
      debugPrint('Error getting visits: $e');
      rethrow;
    }
  }
  
  // Get a specific visit by ID
  Future<Visit> getVisit(String visitId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      try {
        // Try to get visit online
        final headers = await _getHeaders();
        final response = await _httpClient.get(
          Uri.parse('$_baseUrl/visits/$visitId'),
          headers: headers,
        );
        
        _handleError(response);
        
        final data = jsonDecode(response.body);
        return Visit.fromJson(data);
      } catch (e) {
        // If online request fails, get from local database
        final visitData = await _databaseService.query(
          'Visits',
          where: 'id = ?',
          whereArgs: [visitId],
        );
        
        if (visitData.isEmpty) {
          throw Exception('Visit not found');
        }
        
        final visit = Visit.fromJson(visitData.first);
        
        // Get prescriptions and lab tests
        final prescriptionsData = await _databaseService.query(
          'Prescriptions',
          where: 'visitId = ? AND isDeleted = ?',
          whereArgs: [visitId, 0],
        );
        
        final labTestsData = await _databaseService.query(
          'LabTests',
          where: 'visitId = ? AND isDeleted = ?',
          whereArgs: [visitId, 0],
        );
        
        final prescriptions = prescriptionsData
            .map((data) => Prescription.fromJson(data))
            .toList();
        
        final labTests = labTestsData
            .map((data) => LabTest.fromJson(data))
            .toList();
        
        return visit.copyWith(
          prescriptions: prescriptions,
          labTests: labTests,
        );
      }
    } catch (e) {
      debugPrint('Error getting visit: $e');
      rethrow;
    }
  }
  
  // Create a new visit
  Future<Visit> createVisit(Visit visit) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Generate a new ID if not provided
      final visitWithId = visit.id.isEmpty
          ? visit.copyWith(
              id: _uuid.v4(),
              doctorId: currentUser.id,
              lastModified: DateTime.now(),
            )
          : visit;
      
      try {
        // Try to create visit online
        final headers = await _getHeaders();
        final response = await _httpClient.post(
          Uri.parse('$_baseUrl/visits'),
          headers: headers,
          body: jsonEncode(visitWithId.toJson()),
        );
        
        _handleError(response);
        
        final data = jsonDecode(response.body);
        final createdVisit = Visit.fromJson(data);
        
        // Save to local database as well
        await _databaseService.insert(
          'Visits',
          visitWithId.toSqlite(),
        );
        
        // Save prescriptions and lab tests
        for (final prescription in visitWithId.prescriptions) {
          await _databaseService.insert(
            'Prescriptions',
            prescription.toSqlite(),
          );
        }
        
        for (final labTest in visitWithId.labTests) {
          await _databaseService.insert(
            'LabTests',
            labTest.toSqlite(),
          );
        }
        
        return createdVisit;
      } catch (e) {
        // If online creation fails, save to local database only
        await _databaseService.insert(
          'Visits',
          visitWithId.toSqlite(),
        );
        
        // Save prescriptions and lab tests
        for (final prescription in visitWithId.prescriptions) {
          await _databaseService.insert(
            'Prescriptions',
            prescription.toSqlite(),
          );
        }
        
        for (final labTest in visitWithId.labTests) {
          await _databaseService.insert(
            'LabTests',
            labTest.toSqlite(),
          );
        }
        
        return visitWithId;
      }
    } catch (e) {
      debugPrint('Error creating visit: $e');
      rethrow;
    }
  }
  
  // Update an existing visit
  Future<Visit> updateVisit(Visit visit) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Ensure the visit belongs to the current doctor
      if (visit.doctorId != currentUser.id) {
        throw Exception('Unauthorized to update this visit');
      }
      
      final visitWithTimestamp = visit.copyWith(
        lastModified: DateTime.now(),
      );
      
      try {
        // Try to update visit online
        final headers = await _getHeaders();
        final response = await _httpClient.put(
          Uri.parse('$_baseUrl/visits/${visit.id}'),
          headers: headers,
          body: jsonEncode(visitWithTimestamp.toJson()),
        );
        
        _handleError(response);
        
        final data = jsonDecode(response.body);
        final updatedVisit = Visit.fromJson(data);
        
        // Update in local database as well
        await _databaseService.update(
          'Visits',
          visitWithTimestamp.toSqlite(),
          where: 'id = ?',
          whereArgs: [visit.id],
        );
        
        // Update prescriptions and lab tests
        for (final prescription in visitWithTimestamp.prescriptions) {
          await _databaseService.insert(
            'Prescriptions',
            prescription.toSqlite(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        for (final labTest in visitWithTimestamp.labTests) {
          await _databaseService.insert(
            'LabTests',
            labTest.toSqlite(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        return updatedVisit;
      } catch (e) {
        // If online update fails, update in local database only
        await _databaseService.update(
          'Visits',
          visitWithTimestamp.toSqlite(),
          where: 'id = ?',
          whereArgs: [visit.id],
        );
        
        // Update prescriptions and lab tests
        for (final prescription in visitWithTimestamp.prescriptions) {
          await _databaseService.insert(
            'Prescriptions',
            prescription.toSqlite(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        for (final labTest in visitWithTimestamp.labTests) {
          await _databaseService.insert(
            'LabTests',
            labTest.toSqlite(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        return visitWithTimestamp;
      }
    } catch (e) {
      debugPrint('Error updating visit: $e');
      rethrow;
    }
  }
  
  // Delete a visit (soft delete)
  Future<bool> deleteVisit(String id) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      try {
        // Try to delete visit online
        final headers = await _getHeaders();
        final response = await _httpClient.delete(
          Uri.parse('$_baseUrl/visits/$id'),
          headers: headers,
        );
        
        _handleError(response);
        
        // Soft delete in local database as well
        await _databaseService.update(
          'Visits',
          {
            'isDeleted': 1,
            'lastModified': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        
        return true;
      } catch (e) {
        // If online deletion fails, soft delete in local database only
        await _databaseService.update(
          'Visits',
          {
            'isDeleted': 1,
            'lastModified': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting visit: $e');
      return false;
    }
  }
  
  // =====================
  // Prescription API methods
  // =====================
  
  // Send prescriptions to pharmacy
  Future<bool> sendPrescriptionsToPharmacy(
    String visitId,
    List<Prescription> prescriptions,
  ) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Check if pharmacy account is active
      if (!currentUser.hasPharmacyAccess) {
        throw Exception('Pharmacy account is not active');
      }
      
      try {
        // Try to send prescriptions online
        final headers = await _getHeaders();
        final response = await _httpClient.post(
          Uri.parse('$_baseUrl/visits/$visitId/prescriptions/send'),
          headers: headers,
          body: jsonEncode({
            'prescriptionIds': prescriptions.map((p) => p.id).toList(),
          }),
        );
        
        _handleError(response);
        
        // Update local database as well
        for (final prescription in prescriptions) {
          await _databaseService.update(
            'Prescriptions',
            {
              'sentToPharmacy': 1,
              'lastModified': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [prescription.id],
          );
        }
        
        return true;
      } catch (e) {
        // If online update fails, update in local database only
        for (final prescription in prescriptions) {
          await _databaseService.update(
            'Prescriptions',
            {
              'sentToPharmacy': 1,
              'lastModified': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [prescription.id],
          );
        }
        
        return true;
      }
    } catch (e) {
      debugPrint('Error sending prescriptions to pharmacy: $e');
      return false;
    }
  }
  
  // =====================
  // Lab Test API methods
  // =====================
  
  // Send lab tests to laboratory
  Future<bool> sendLabTestsToLab(
    String visitId,
    List<LabTest> labTests,
  ) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Check if lab account is active
      if (!currentUser.hasLabAccess) {
        throw Exception('Laboratory account is not active');
      }
      
      try {
        // Try to send lab tests online
        final headers = await _getHeaders();
        final response = await _httpClient.post(
          Uri.parse('$_baseUrl/visits/$visitId/lab-tests/send'),
          headers: headers,
          body: jsonEncode({
            'labTestIds': labTests.map((lt) => lt.id).toList(),
          }),
        );
        
        _handleError(response);
        
        // Update local database as well
        for (final labTest in labTests) {
          await _databaseService.update(
            'LabTests',
            {
              'sentToLab': 1,
              'lastModified': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [labTest.id],
          );
        }
        
        return true;
      } catch (e) {
        // If online update fails, update in local database only
        for (final labTest in labTests) {
          await _databaseService.update(
            'LabTests',
            {
              'sentToLab': 1,
              'lastModified': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [labTest.id],
          );
        }
        
        return true;
      }
    } catch (e) {
      debugPrint('Error sending lab tests to laboratory: $e');
      return false;
    }
  }
  
  // =====================
  // Drug API methods
  // =====================
  
  // Get all drugs for the current doctor
  Future<List<String>> getDrugs() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      try {
        // Try to get drugs online
        final headers = await _getHeaders();
        final response = await _httpClient.get(
          Uri.parse('$_baseUrl/drugs?doctorId=${currentUser.id}'),
          headers: headers,
        );
        
        _handleError(response);
        
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => json['name'] as String).toList();
      } catch (e) {
        // If online request fails, get from local database
        final drugsData = await _databaseService.query(
          'Drugs',
          where: 'doctorId = ? AND isDeleted = ?',
          whereArgs: [currentUser.id, 0],
        );
        
        return drugsData.map((data) => data['name'] as String).toList();
      }
    } catch (e) {
      debugPrint('Error getting drugs: $e');
      rethrow;
    }
  }
  
  // Add a new drug
  Future<bool> addDrug(String name) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final drugId = _uuid.v4();
      
      try {
        // Try to add drug online
        final headers = await _getHeaders();
        final response = await _httpClient.post(
          Uri.parse('$_baseUrl/drugs'),
          headers: headers,
          body: jsonEncode({
            'id': drugId,
            'name': name,
            'doctorId': currentUser.id,
            'lastModified': DateTime.now().toIso8601String(),
            'isDeleted': false,
          }),
        );
        
        _handleError(response);
        
        // Add to local database as well
        await _databaseService.insert(
          'Drugs',
          {
            'id': drugId,
            'name': name,
            'doctorId': currentUser.id,
            'lastModified': DateTime.now().toIso8601String(),
            'isDeleted': 0,
          },
        );
        
        return true;
      } catch (e) {
        // If online addition fails, add to local database only
        await _databaseService.insert(
          'Drugs',
          {
            'id': drugId,
            'name': name,
            'doctorId': currentUser.id,
            'lastModified': DateTime.now().toIso8601String(),
            'isDeleted': 0,
          },
        );
        
        return true;
      }
    } catch (e) {
      debugPrint('Error adding drug: $e');
      return false;
    }
  }
  
  // Delete a drug
  Future<bool> deleteDrug(String id) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      try {
        // Try to delete drug online
        final headers = await _getHeaders();
        final response = await _httpClient.delete(
          Uri.parse('$_baseUrl/drugs/$id'),
          headers: headers,
        );
        
        _handleError(response);
        
        // Soft delete in local database as well
        await _databaseService.update(
          'Drugs',
          {
            'isDeleted': 1,
            'lastModified': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        
        return true;
      } catch (e) {
        // If online deletion fails, soft delete in local database only
        await _databaseService.update(
          'Drugs',
          {
            'isDeleted': 1,
            'lastModified': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting drug: $e');
      return false;
    }
  }
  
  // =====================
  // Lab Test Type API methods
  // =====================
  
  // Get all lab test types for the current doctor
  Future<List<String>> getLabTestTypes() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      try {
        // Try to get lab test types online
        final headers = await _getHeaders();
        final response = await _httpClient.get(
          Uri.parse('$_baseUrl/lab-test-types?doctorId=${currentUser.id}'),
          headers: headers,
        );
        
        _handleError(response);
        
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => json['name'] as String).toList();
      } catch (e) {
        // If online request fails, get from local database
        final labTestTypesData = await _databaseService.query(
          'LabTestTypes',
          where: 'doctorId = ? AND isDeleted = ?',
          whereArgs: [currentUser.id, 0],
        );
        
        return labTestTypesData.map((data) => data['name'] as String).toList();
      }
    } catch (e) {
      debugPrint('Error getting lab test types: $e');
      rethrow;
    }
  }
  
  // Add a new lab test type
  Future<bool> addLabTestType(String name) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final labTestTypeId = _uuid.v4();
      
      try {
        // Try to add lab test type online
        final headers = await _getHeaders();
        final response = await _httpClient.post(
          Uri.parse('$_baseUrl/lab-test-types'),
          headers: headers,
          body: jsonEncode({
            'id': labTestTypeId,
            'name': name,
            'doctorId': currentUser.id,
            'lastModified': DateTime.now().toIso8601String(),
            'isDeleted': false,
          }),
        );
        
        _handleError(response);
        
        // Add to local database as well
        await _databaseService.insert(
          'LabTestTypes',
          {
            'id': labTestTypeId,
            'name': name,
            'doctorId': currentUser.id,
            'lastModified': DateTime.now().toIso8601String(),
            'isDeleted': 0,
          },
        );
        
        return true;
      } catch (e) {
        // If online addition fails, add to local database only
        await _databaseService.insert(
          'LabTestTypes',
          {
            'id': labTestTypeId,
            'name': name,
            'doctorId': currentUser.id,
            'lastModified': DateTime.now().toIso8601String(),
            'isDeleted': 0,
          },
        );
        
        return true;
      }
    } catch (e) {
      debugPrint('Error adding lab test type: $e');
      return false;
    }
  }
  
  // Delete a lab test type
  Future<bool> deleteLabTestType(String id) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      try {
        // Try to delete lab test type online
        final headers = await _getHeaders();
        final response = await _httpClient.delete(
          Uri.parse('$_baseUrl/lab-test-types/$id'),
          headers: headers,
        );
        
        _handleError(response);
        
        // Soft delete in local database as well
        await _databaseService.update(
          'LabTestTypes',
          {
            'isDeleted': 1,
            'lastModified': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        
        return true;
      } catch (e) {
        // If online deletion fails, soft delete in local database only
        await _databaseService.update(
          'LabTestTypes',
          {
            'isDeleted': 1,
            'lastModified': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting lab test type: $e');
      return false;
    }
  }
  
  // =====================
  // Settings API methods
  // =====================
  
  // Get doctor settings
  Future<Map<String, dynamic>> getDoctorSettings() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      return currentUser.settings;
    } catch (e) {
      debugPrint('Error getting doctor settings: $e');
      rethrow;
    }
  }
  
  // Update doctor settings
  Future<bool> updateDoctorSettings(Map<String, dynamic> settings) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      try {
        // Try to update settings online
        final headers = await _getHeaders();
        final response = await _httpClient.put(
          Uri.parse('$_baseUrl/settings'),
          headers: headers,
          body: jsonEncode(settings),
        );
        
        _handleError(response);
        
        return true;
      } catch (e) {
        // If online update fails, we can't update settings
        // as they are tied to the user account
        debugPrint('Error updating doctor settings online: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating doctor settings: $e');
      return false;
    }
  }
  
  // =====================
  // Cleanup
  // =====================
  
  void dispose() {
    _httpClient.close();
  }
}
