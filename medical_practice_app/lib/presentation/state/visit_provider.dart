import 'package:flutter/foundation.dart';
import '../../core/services/api_service.dart';
import '../../core/models/visit_model.dart';
import '../../core/models/prescription_model.dart';
import '../../core/models/lab_test_model.dart';

class VisitProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Visit> _visits = [];
  bool _isLoading = false;
  String? _error;

  // Drug and lab test dictionaries
  List<String> _drugs = [];
  List<String> _labTestTypes = [];

  VisitProvider(this._apiService);

  // Getters
  List<Visit> get visits => _visits;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get drugs => _drugs;
  List<String> get labTestTypes => _labTestTypes;

  // Get visits for a patient
  Future<List<Visit>> getVisits(String patientId) async {
    try {
      final visits = await _apiService.getVisits(patientId);
      return visits;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Create a new visit
  Future<Visit> createVisit({required Visit visit}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final createdVisit = await _apiService.createVisit(visit);

      // Add to local list
      _visits.add(createdVisit);
      _isLoading = false;
      notifyListeners();

      return createdVisit;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update a visit
  Future<Visit> updateVisit({required Visit visit}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedVisit = await _apiService.updateVisit(visit);

      // Update in local list
      final index = _visits.indexWhere((v) => v.id == visit.id);
      if (index >= 0) {
        _visits[index] = updatedVisit;
      }

      _isLoading = false;
      notifyListeners();

      return updatedVisit;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete a visit
  Future<bool> deleteVisit(String visitId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _apiService.deleteVisit(visitId);

      if (success) {
        // Remove from local list
        _visits.removeWhere((v) => v.id == visitId);
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

  // Send prescriptions to pharmacy
  Future<bool> sendPrescriptionsToPharmacy({
    required String visitId,
    required List<Prescription> prescriptions,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _apiService.sendPrescriptionsToPharmacy(
        visitId,
        prescriptions,
      );

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

  // Send lab tests to laboratory
  Future<bool> sendLabTestsToLab({
    required String visitId,
    required List<LabTest> labTests,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _apiService.sendLabTestsToLab(visitId, labTests);

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

  // Get drugs list
  Future<List<String>> getDrugs() async {
    try {
      _drugs = await _apiService.getDrugs();
      notifyListeners();
      return _drugs;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Add a drug
  Future<bool> addDrug(String drugName) async {
    try {
      final success = await _apiService.addDrug(drugName);

      if (success) {
        _drugs.add(drugName);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete a drug
  Future<bool> deleteDrug(String drugId) async {
    try {
      final success = await _apiService.deleteDrug(drugId);

      if (success) {
        _drugs.removeWhere((d) => d == drugId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get lab test types
  Future<List<String>> getLabTestTypes() async {
    try {
      _labTestTypes = await _apiService.getLabTestTypes();
      notifyListeners();
      return _labTestTypes;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Add a lab test type
  Future<bool> addLabTestType(String testName) async {
    try {
      final success = await _apiService.addLabTestType(testName);

      if (success) {
        _labTestTypes.add(testName);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete a lab test type
  Future<bool> deleteLabTestType(String testId) async {
    try {
      final success = await _apiService.deleteLabTestType(testId);

      if (success) {
        _labTestTypes.removeWhere((t) => t == testId);
        notifyListeners();
      }

      return success;
    } catch (e) {
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
