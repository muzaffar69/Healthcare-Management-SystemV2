// ignore_for_file: depend_on_referenced_packages

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';
import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../models/drug_model.dart';
import '../models/lab_test_model.dart';
import '../models/prescription_model.dart';
import '../models/lab_order_model.dart';
import '../models/doctor_settings_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static final _log = Logger('DatabaseHelper');

  DatabaseHelper._init();

  Future<Database> get database async {
    try {
      if (_database != null) return _database!;
      _database = await _initDB('medical_practice.db');
      return _database!;
    } catch (e) {
      _log.severe('Database initialization error', e);
      return await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: _createDB,
      );
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create patients table
    await db.execute('''
      CREATE TABLE patients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        profilePicPath TEXT,
        address TEXT,
        weight REAL,
        height REAL,
        chronicDiseases TEXT,
        familyHistory TEXT,
        notes TEXT,
        firstVisitDate TEXT
      )
    ''');

    // Create visits table
    await db.execute('''
      CREATE TABLE visits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER NOT NULL,
        date TEXT NOT NULL,
        details TEXT NOT NULL,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    // Create drugs table
    await db.execute('''
      CREATE TABLE drugs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Create lab tests table
    await db.execute('''
      CREATE TABLE lab_tests(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Create prescriptions table
    await db.execute('''
      CREATE TABLE prescriptions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visitId INTEGER NOT NULL,
        drugId INTEGER NOT NULL,
        drugName TEXT NOT NULL,
        note TEXT NOT NULL,
        sentToPharmacy INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (visitId) REFERENCES visits (id) ON DELETE CASCADE,
        FOREIGN KEY (drugId) REFERENCES drugs (id) ON DELETE CASCADE
      )
    ''');

    // Create lab orders table
    await db.execute('''
      CREATE TABLE lab_orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visitId INTEGER NOT NULL,
        labTestId INTEGER NOT NULL,
        testName TEXT NOT NULL,
        note TEXT NOT NULL,
        sentToLab INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (visitId) REFERENCES visits (id) ON DELETE CASCADE,
        FOREIGN KEY (labTestId) REFERENCES lab_tests (id) ON DELETE CASCADE
      )
    ''');

    // Create doctor settings table
    await db.execute('''
      CREATE TABLE doctor_settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        specialty TEXT,
        phoneNumber TEXT,
        email TEXT,
        address TEXT,
        notes TEXT,
        profilePicPath TEXT
      )
    ''');

    // Insert default doctor settings
    await db.insert('doctor_settings', {
      'id': 1,
      'name': 'Dr. John Doe',
      'specialty': 'General Practitioner',
      'phoneNumber': '555-0123',
      'email': 'dr.doe@example.com',
      'address': '123 Medical Center St.',
    });

    // Insert some default drugs
    await db.insert('drugs', {'name': 'Paracetamol'});
    await db.insert('drugs', {'name': 'Ibuprofen'});
    await db.insert('drugs', {'name': 'Aspirin'});

    // Insert some default lab tests
    await db.insert('lab_tests', {'name': 'Complete Blood Count'});
    await db.insert('lab_tests', {'name': 'Blood Glucose'});
    await db.insert('lab_tests', {'name': 'Lipid Panel'});
  }

  // Patient CRUD operations
  Future<int> createPatient(Patient patient) async {
    final db = await instance.database;
    return await db.insert('patients', patient.toMap());
  }

  Future<Patient?> readPatient(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Patient.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Patient>> readAllPatients() async {
    final db = await instance.database;
    final result = await db.query('patients', orderBy: 'name ASC');
    return result.map((json) => Patient.fromMap(json)).toList();
  }

  Future<List<Patient>> searchPatients(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'patients',
      where: 'name LIKE ? OR phoneNumber LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((json) => Patient.fromMap(json)).toList();
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await instance.database;
    return await db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<int> deletePatient(int id) async {
    final db = await instance.database;
    return await db.delete(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Visit CRUD operations
  Future<int> createVisit(Visit visit) async {
    final db = await instance.database;
    return await db.insert('visits', visit.toMap());
  }

  Future<Visit?> readVisit(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'visits',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Visit.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Visit>> readPatientVisits(int patientId) async {
    final db = await instance.database;
    final result = await db.query(
      'visits',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'date DESC',
    );
    
    List<Visit> visits = result.map((json) => Visit.fromMap(json)).toList();
    
    // Get prescriptions and lab orders for each visit
    for (var i = 0; i < visits.length; i++) {
      final prescriptions = await readVisitPrescriptions(visits[i].id!);
      final labOrders = await readVisitLabOrders(visits[i].id!);
      
      visits[i] = visits[i].copyWith(
        prescriptions: prescriptions,
        labOrders: labOrders,
      );
    }
    
    return visits;
  }

  Future<int> updateVisit(Visit visit) async {
    final db = await instance.database;
    return await db.update(
      'visits',
      visit.toMap(),
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<int> deleteVisit(int id) async {
    final db = await instance.database;
    return await db.delete(
      'visits',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Drug CRUD operations
  Future<int> createDrug(Drug drug) async {
    final db = await instance.database;
    return await db.insert('drugs', drug.toMap());
  }

  Future<List<Drug>> readAllDrugs() async {
    final db = await instance.database;
    final result = await db.query('drugs', orderBy: 'name ASC');
    return result.map((json) => Drug.fromMap(json)).toList();
  }

  Future<List<Drug>> searchDrugs(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'drugs',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((json) => Drug.fromMap(json)).toList();
  }

  Future<int> updateDrug(Drug drug) async {
    final db = await instance.database;
    return await db.update(
      'drugs',
      drug.toMap(),
      where: 'id = ?',
      whereArgs: [drug.id],
    );
  }

  Future<int> deleteDrug(int id) async {
    final db = await instance.database;
    return await db.delete(
      'drugs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Lab Test CRUD operations
  Future<int> createLabTest(LabTest labTest) async {
    final db = await instance.database;
    return await db.insert('lab_tests', labTest.toMap());
  }

  Future<List<LabTest>> readAllLabTests() async {
    final db = await instance.database;
    final result = await db.query('lab_tests', orderBy: 'name ASC');
    return result.map((json) => LabTest.fromMap(json)).toList();
  }

  Future<List<LabTest>> searchLabTests(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'lab_tests',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((json) => LabTest.fromMap(json)).toList();
  }

  Future<int> updateLabTest(LabTest labTest) async {
    final db = await instance.database;
    return await db.update(
      'lab_tests',
      labTest.toMap(),
      where: 'id = ?',
      whereArgs: [labTest.id],
    );
  }

  Future<int> deleteLabTest(int id) async {
    final db = await instance.database;
    return await db.delete(
      'lab_tests',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Prescription CRUD operations
  Future<int> createPrescription(Prescription prescription) async {
    final db = await instance.database;
    return await db.insert('prescriptions', prescription.toMap());
  }

  Future<List<Prescription>> readVisitPrescriptions(int visitId) async {
    final db = await instance.database;
    final result = await db.query(
      'prescriptions',
      where: 'visitId = ?',
      whereArgs: [visitId],
    );
    return result.map((json) => Prescription.fromMap(json)).toList();
  }

  Future<int> updatePrescription(Prescription prescription) async {
    final db = await instance.database;
    return await db.update(
      'prescriptions',
      prescription.toMap(),
      where: 'id = ?',
      whereArgs: [prescription.id],
    );
  }

  Future<int> deletePrescription(int id) async {
    final db = await instance.database;
    return await db.delete(
      'prescriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Lab Order CRUD operations
  Future<int> createLabOrder(LabOrder labOrder) async {
    final db = await instance.database;
    return await db.insert('lab_orders', labOrder.toMap());
  }

  Future<List<LabOrder>> readVisitLabOrders(int visitId) async {
    final db = await instance.database;
    final result = await db.query(
      'lab_orders',
      where: 'visitId = ?',
      whereArgs: [visitId],
    );
    return result.map((json) => LabOrder.fromMap(json)).toList();
  }

  Future<int> updateLabOrder(LabOrder labOrder) async {
    final db = await instance.database;
    return await db.update(
      'lab_orders',
      labOrder.toMap(),
      where: 'id = ?',
      whereArgs: [labOrder.id],
    );
  }

  Future<int> deleteLabOrder(int id) async {
    final db = await instance.database;
    return await db.delete(
      'lab_orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Doctor Settings operations
  Future<DoctorSettings?> readDoctorSettings() async {
    final db = await instance.database;
    final maps = await db.query('doctor_settings', where: 'id = 1');

    if (maps.isNotEmpty) {
      return DoctorSettings.fromMap(maps.first);
    } else {
      return DoctorSettings(id: 1);
    }
  }

  Future<int> updateDoctorSettings(DoctorSettings settings) async {
    final db = await instance.database;
    return await db.update(
      'doctor_settings',
      settings.toMap(),
      where: 'id = 1',
    );
  }

  // Close the database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}