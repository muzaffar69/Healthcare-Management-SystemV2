import '../datasources/database_helper.dart';
import '../models/drug_model.dart';

class DrugRepository {
  final DatabaseHelper _databaseHelper;

  // Singleton pattern
  static final DrugRepository _instance = DrugRepository._internal(DatabaseHelper.instance);
  
  factory DrugRepository() {
    return _instance;
  }
  
  DrugRepository._internal(this._databaseHelper);

  /// Create a new drug
  Future<int> createDrug(Drug drug) async {
    return await _databaseHelper.createDrug(drug);
  }

  /// Get all drugs
  Future<List<Drug>> getAllDrugs() async {
    return await _databaseHelper.readAllDrugs();
  }

  /// Search drugs by name
  Future<List<Drug>> searchDrugs(String query) async {
    return await _databaseHelper.searchDrugs(query);
  }

  /// Update drug
  Future<int> updateDrug(Drug drug) async {
    return await _databaseHelper.updateDrug(drug);
  }

  /// Delete drug
  Future<int> deleteDrug(int id) async {
    return await _databaseHelper.deleteDrug(id);
  }

  /// Get a drug by ID
  Future<Drug?> getDrugById(int id) async {
    // This method wasn't implemented in the database helper, so we'll implement it here
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drugs',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Drug.fromMap(maps.first);
  }

  /// Check if a drug exists by name
  Future<bool> drugExistsByName(String name) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'drugs',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Get drug count
  Future<int> getDrugCount() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) as count FROM drugs');
    return result.first['count'] as int;
  }
}