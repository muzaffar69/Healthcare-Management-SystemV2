import '../datasources/database_helper.dart';
import '../models/visit_model.dart';
import '../models/prescription_model.dart';
import '../models/lab_order_model.dart';

class VisitRepository {
  final DatabaseHelper _databaseHelper;

  // Singleton pattern
  static final VisitRepository _instance = VisitRepository._internal(DatabaseHelper.instance);
  
  factory VisitRepository() {
    return _instance;
  }
  
  VisitRepository._internal(this._databaseHelper);

  /// Create a new visit
  Future<int> createVisit(Visit visit) async {
    return await _databaseHelper.createVisit(visit);
  }

  /// Get a visit by ID
  Future<Visit?> getVisitById(int id) async {
    return await _databaseHelper.readVisit(id);
  }

  /// Get all visits for a specific patient
  Future<List<Visit>> getPatientVisits(int patientId) async {
    return await _databaseHelper.readPatientVisits(patientId);
  }

  /// Update visit information
  Future<int> updateVisit(Visit visit) async {
    return await _databaseHelper.updateVisit(visit);
  }

  /// Delete a visit
  Future<int> deleteVisit(int id) async {
    return await _databaseHelper.deleteVisit(id);
  }

  /// Create a prescription for a visit
  Future<int> createPrescription(Prescription prescription) async {
    return await _databaseHelper.createPrescription(prescription);
  }

  /// Get prescriptions for a specific visit
  Future<List<Prescription>> getVisitPrescriptions(int visitId) async {
    return await _databaseHelper.readVisitPrescriptions(visitId);
  }

  /// Update prescription information
  Future<int> updatePrescription(Prescription prescription) async {
    return await _databaseHelper.updatePrescription(prescription);
  }

  /// Delete a prescription
  Future<int> deletePrescription(int id) async {
    return await _databaseHelper.deletePrescription(id);
  }

  /// Create a lab order for a visit
  Future<int> createLabOrder(LabOrder labOrder) async {
    return await _databaseHelper.createLabOrder(labOrder);
  }

  /// Get lab orders for a specific visit
  Future<List<LabOrder>> getVisitLabOrders(int visitId) async {
    return await _databaseHelper.readVisitLabOrders(visitId);
  }

  /// Update lab order information
  Future<int> updateLabOrder(LabOrder labOrder) async {
    return await _databaseHelper.updateLabOrder(labOrder);
  }

  /// Delete a lab order
  Future<int> deleteLabOrder(int id) async {
    return await _databaseHelper.deleteLabOrder(id);
  }

  /// Get total visit count
  Future<int> getTotalVisitCount() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM visits');
    return result.first['count'] as int;
  }

  /// Get visits by month (for analytics)
  Future<List<Map<String, dynamic>>> getVisitsByMonth() async {
    final db = await _databaseHelper.database;
    
    // Using SQLite's date functions to extract month
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        substr(date, 6, 2) as month,
        COUNT(*) as count
      FROM visits
      GROUP BY month
      ORDER BY month
    ''');
    
    // Convert numeric month to month name
    final Map<String, String> monthNames = {
      '01': 'Jan', '02': 'Feb', '03': 'Mar', '04': 'Apr', '05': 'May', '06': 'Jun',
      '07': 'Jul', '08': 'Aug', '09': 'Sep', '10': 'Oct', '11': 'Nov', '12': 'Dec'
    };
    
    return result.map((item) {
      String monthNum = item['month'] as String;
      return {
        'month': monthNames[monthNum] ?? monthNum,
        'count': item['count'],
      };
    }).toList();
  }

  /// Get recent visits (most recent first)
  Future<List<Visit>> getRecentVisits(int limit) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'visits',
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    
    List<Visit> visits = maps.map((map) => Visit.fromMap(map)).toList();
    
    // Get prescriptions and lab orders for each visit
    for (var i = 0; i < visits.length; i++) {
      final prescriptions = await getVisitPrescriptions(visits[i].id!);
      final labOrders = await getVisitLabOrders(visits[i].id!);
      
      visits[i] = visits[i].copyWith(
        prescriptions: prescriptions,
        labOrders: labOrders,
      );
    }
    
    return visits;
  }

  /// Get total prescriptions count
  Future<int> getTotalPrescriptionsCount() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM prescriptions');
    return result.first['count'] as int;
  }

  /// Get total lab orders count
  Future<int> getTotalLabOrdersCount() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM lab_orders');
    return result.first['count'] as int;
  }
}