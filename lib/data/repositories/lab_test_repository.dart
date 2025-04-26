import '../datasources/database_helper.dart';
import '../models/lab_test_model.dart';

class LabTestRepository {
  final DatabaseHelper _databaseHelper;

  // Singleton pattern
  static final LabTestRepository _instance = LabTestRepository._internal(DatabaseHelper.instance);
  
  factory LabTestRepository() {
    return _instance;
  }
  
  LabTestRepository._internal(this._databaseHelper);

  /// Create a new lab test
  Future<int> createLabTest(LabTest labTest) async {
    return await _databaseHelper.createLabTest(labTest);
  }

  /// Get all lab tests
  Future<List<LabTest>> getAllLabTests() async {
    return await _databaseHelper.readAllLabTests();
  }

  /// Search lab tests by name
  Future<List<LabTest>> searchLabTests(String query) async {
    return await _databaseHelper.searchLabTests(query);
  }

  /// Update lab test
  Future<int> updateLabTest(LabTest labTest) async {
    return await _databaseHelper.updateLabTest(labTest);
  }

  /// Delete lab test
  Future<int> deleteLabTest(int id) async {
    return await _databaseHelper.deleteLabTest(id);
  }

  /// Get a lab test by ID
  Future<LabTest?> getLabTestById(int id) async {
    // This method wasn't implemented in the database helper, so we'll implement it here
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lab_tests',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return LabTest.fromMap(maps.first);
  }

  /// Check if a lab test exists by name
  Future<bool> labTestExistsByName(String name) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'lab_tests',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Get lab test count
  Future<int> getLabTestCount() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM lab_tests');
    return result.first['count'] as int;
  }

  /// Get most commonly ordered lab tests (for analytics)
  Future<List<Map<String, dynamic>>> getMostCommonLabTests(int limit) async {
    final db = await _databaseHelper.database;
    
    // Join lab_orders with lab_tests to get test names
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT lt.id, lt.name, COUNT(lo.id) as count
      FROM lab_tests lt
      JOIN lab_orders lo ON lt.id = lo.labTestId
      GROUP BY lt.id
      ORDER BY count DESC
      LIMIT ?
    ''', [limit]);
    
    return result;
  }
}