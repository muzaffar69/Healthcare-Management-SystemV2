import '../datasources/database_helper.dart';
import '../models/patient_model.dart';

class PatientRepository {
  final DatabaseHelper _databaseHelper;

  // Singleton pattern
  static final PatientRepository _instance = PatientRepository._internal(DatabaseHelper.instance);
  
  factory PatientRepository() {
    return _instance;
  }
  
  PatientRepository._internal(this._databaseHelper);

  /// Create a new patient
  Future<int> createPatient(Patient patient) async {
    return await _databaseHelper.createPatient(patient);
  }

  /// Get a patient by ID
  Future<Patient?> getPatientById(int id) async {
    return await _databaseHelper.readPatient(id);
  }

  /// Get all patients
  Future<List<Patient>> getAllPatients() async {
    return await _databaseHelper.readAllPatients();
  }

  /// Search patients by name or phone number
  Future<List<Patient>> searchPatients(String query) async {
    return await _databaseHelper.searchPatients(query);
  }

  /// Update patient information
  Future<int> updatePatient(Patient patient) async {
    return await _databaseHelper.updatePatient(patient);
  }

  /// Delete a patient
  Future<int> deletePatient(int id) async {
    return await _databaseHelper.deletePatient(id);
  }

  /// Get patient count
  Future<int> getPatientCount() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM patients');
    return result.first['count'] as int;
  }

  /// Get patients by gender
  Future<Map<String, int>> getPatientsByGender() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT gender, COUNT(*) as count
      FROM patients
      GROUP BY gender
    ''');
    
    // Convert list of maps to a single map
    Map<String, int> patientsByGender = {};
    for (var item in result) {
      patientsByGender[item['gender'] as String] = item['count'] as int;
    }
    
    return patientsByGender;
  }

  /// Get patients by age groups (for analytics)
  Future<List<Map<String, dynamic>>> getPatientsByAgeGroup() async {
    final db = await _databaseHelper.database;
    
    // Define age groups: 0-18, 19-35, 36-50, 51-65, 66+
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        CASE
          WHEN age <= 18 THEN '0-18'
          WHEN age <= 35 THEN '19-35'
          WHEN age <= 50 THEN '36-50'
          WHEN age <= 65 THEN '51-65'
          ELSE '66+'
        END as age_group,
        COUNT(*) as count
      FROM patients
      GROUP BY age_group
      ORDER BY age_group
    ''');
    
    return result;
  }

  /// Get recent patients (most recently added)
  Future<List<Patient>> getRecentPatients(int limit) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'patients',
      orderBy: 'id DESC',
      limit: limit,
    );
    
    return maps.map((map) => Patient.fromMap(map)).toList();
  }
}