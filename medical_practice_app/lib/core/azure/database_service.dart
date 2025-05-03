import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:azure_storage/azure_storage.dart';
import 'auth_service.dart';
import '../../config/constants.dart';

class AzureDatabaseService {
  // Local SQLite database for offline support
  late Database _localDb;
  
  // Azure services
  late AzureStorage _azureStorage;
  
  // API client for Azure SQL Database
  late http.Client _httpClient;
  
  // Service initialization status
  bool _isInitialized = false;
  
  // Getters
  bool get isInitialized => _isInitialized;
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      // Initialize local database
      await _initLocalDatabase();
      
      // Initialize Azure Storage
      final String blobConnectionString = dotenv.get(AppConstants.blobConnectionString);
      _azureStorage = AzureStorage.parse(blobConnectionString);
      
      // Initialize HTTP client
      _httpClient = http.Client();
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Azure Database Service: $e');
      rethrow;
    }
  }
  
  // Initialize local SQLite database
  Future<void> _initLocalDatabase() async {
    try {
      final Directory documentsDirectory = await getApplicationDocumentsDirectory();
      final String path = join(documentsDirectory.path, 'medical_practice.db');
      
      _localDb = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          // Create tables for offline support
          
          // Users table
          await db.execute(
            'CREATE TABLE Users ('
            'id TEXT PRIMARY KEY, '
            'displayName TEXT, '
            'email TEXT, '
            'role TEXT, '
            'subscriptionEndDate TEXT, '
            'isActive INTEGER, '
            'hasPharmacyAccount INTEGER, '
            'hasLabAccount INTEGER, '
            'pharmacyAccountActive INTEGER, '
            'labAccountActive INTEGER, '
            'settings TEXT'
            ')',
          );
          
          // Patients table
          await db.execute(
            'CREATE TABLE Patients ('
            'id TEXT PRIMARY KEY, '
            'name TEXT, '
            'age INTEGER, '
            'gender TEXT, '
            'phoneNumber TEXT, '
            'address TEXT, '
            'firstVisitDate TEXT, '
            'weight REAL, '
            'height REAL, '
            'chronicDiseases TEXT, '
            'familyHistory TEXT, '
            'notes TEXT, '
            'photoUrl TEXT, '
            'doctorId TEXT, '
            'lastModified TEXT, '
            'isDeleted INTEGER'
            ')',
          );
          
          // Visits table
          await db.execute(
            'CREATE TABLE Visits ('
            'id TEXT PRIMARY KEY, '
            'patientId TEXT, '
            'doctorId TEXT, '
            'visitDate TEXT, '
            'visitNumber INTEGER, '
            'notes TEXT, '
            'lastModified TEXT, '
            'isDeleted INTEGER, '
            'FOREIGN KEY (patientId) REFERENCES Patients (id)'
            ')',
          );
          
          // Prescriptions table
          await db.execute(
            'CREATE TABLE Prescriptions ('
            'id TEXT PRIMARY KEY, '
            'visitId TEXT, '
            'drugName TEXT, '
            'notes TEXT, '
            'sentToPharmacy INTEGER, '
            'fulfilledByPharmacy INTEGER, '
            'pharmacyNotes TEXT, '
            'lastModified TEXT, '
            'isDeleted INTEGER, '
            'FOREIGN KEY (visitId) REFERENCES Visits (id)'
            ')',
          );
          
          // Lab tests table
          await db.execute(
            'CREATE TABLE LabTests ('
            'id TEXT PRIMARY KEY, '
            'visitId TEXT, '
            'testName TEXT, '
            'notes TEXT, '
            'sentToLab INTEGER, '
            'completedByLab INTEGER, '
            'labNotes TEXT, '
            'resultFileUrl TEXT, '
            'lastModified TEXT, '
            'isDeleted INTEGER, '
            'FOREIGN KEY (visitId) REFERENCES Visits (id)'
            ')',
          );
          
          // Drugs dictionary table
          await db.execute(
            'CREATE TABLE Drugs ('
            'id TEXT PRIMARY KEY, '
            'name TEXT, '
            'doctorId TEXT, '
            'lastModified TEXT, '
            'isDeleted INTEGER'
            ')',
          );
          
          // Lab tests dictionary table
          await db.execute(
            'CREATE TABLE LabTestTypes ('
            'id TEXT PRIMARY KEY, '
            'name TEXT, '
            'doctorId TEXT, '
            'lastModified TEXT, '
            'isDeleted INTEGER'
            ')',
          );
          
          // Sync tracking table
          await db.execute(
            'CREATE TABLE SyncTracking ('
            'tableName TEXT PRIMARY KEY, '
            'lastSyncTimestamp TEXT'
            ')',
          );
        },
      );
    } catch (e) {
      debugPrint('Error initializing local database: $e');
      rethrow;
    }
  }
  
  // =========================
  // Generic database operations
  // =========================
  
  // Execute a query on the local database
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return await _localDb.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }
  
  // Insert a record into the local database
  Future<int> insert(String table, Map<String, dynamic> values) async {
    return await _localDb.insert(table, values);
  }
  
  // Update records in the local database
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    return await _localDb.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }
  
  // Delete records from the local database
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    return await _localDb.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }
  
  // Perform a raw SQL query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    return await _localDb.rawQuery(sql, arguments);
  }
  
  // =========================
  // Azure SQL Database operations
  // =========================
  
  // Fetch data from the Azure SQL Database API
  Future<List<Map<String, dynamic>>> fetchFromAzure(
    String endpoint, {
    Map<String, String>? queryParams,
    required String accessToken,
  }) async {
    try {
      final String apiUrl = dotenv.get(AppConstants.apiBaseUrl);
      final Uri uri = Uri.parse('$apiUrl/$endpoint').replace(
        queryParameters: queryParams,
      );
      
      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to fetch data from Azure: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching data from Azure: $e');
      rethrow;
    }
  }
  
  // Send data to the Azure SQL Database API
  Future<Map<String, dynamic>> sendToAzure(
    String endpoint,
    Map<String, dynamic> data, {
    required String accessToken,
    String method = 'POST',
  }) async {
    try {
      final String apiUrl = dotenv.get(AppConstants.apiBaseUrl);
      final Uri uri = Uri.parse('$apiUrl/$endpoint');
      
      late http.Response response;
      
      switch (method.toUpperCase()) {
        case 'POST':
          response = await _httpClient.post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(data),
          );
          break;
        case 'PUT':
          response = await _httpClient.put(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(data),
          );
          break;
        case 'DELETE':
          response = await _httpClient.delete(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          );
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to send data to Azure: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending data to Azure: $e');
      rethrow;
    }
  }
  
  // =========================
  // Azure Blob Storage operations
  // =========================
  
  // Upload a file to Azure Blob Storage
  Future<String> uploadFile(
    File file,
    String containerName,
    String blobName, {
    required String accessToken,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      
      await _azureStorage.putBlob(
        '/$containerName/$blobName',
        bodyBytes: bytes,
        contentType: _getContentType(file.path),
      );
      
      // Get the URL for the uploaded blob
      final url = _azureStorage.uri('/$containerName/$blobName').toString();
      return url;
    } catch (e) {
      debugPrint('Error uploading file to Azure Blob Storage: $e');
      rethrow;
    }
  }
  
  // Download a file from Azure Blob Storage
  Future<File> downloadFile(
    String blobUrl,
    String localPath, {
    required String accessToken,
  }) async {
    try {
      final Uri uri = Uri.parse(blobUrl);
      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      
      if (response.statusCode == 200) {
        final File file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        throw Exception('Failed to download file from Azure Blob Storage: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading file from Azure Blob Storage: $e');
      rethrow;
    }
  }
  
  // Delete a file from Azure Blob Storage
  Future<void> deleteFile(
    String blobUrl, {
    required String accessToken,
  }) async {
    try {
      final Uri uri = Uri.parse(blobUrl);
      final response = await _httpClient.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      
      if (response.statusCode != 202) {
        throw Exception('Failed to delete file from Azure Blob Storage: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting file from Azure Blob Storage: $e');
      rethrow;
    }
  }
  
  // Get content type based on file extension
  String _getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }
  
  // =========================
  // Data synchronization
  // =========================
  
  // Synchronize local data with Azure SQL Database
  Future<void> synchronizeData(String accessToken) async {
    try {
      // Sync all tables
      await _syncTable('Patients', 'patients', accessToken);
      await _syncTable('Visits', 'visits', accessToken);
      await _syncTable('Prescriptions', 'prescriptions', accessToken);
      await _syncTable('LabTests', 'lab-tests', accessToken);
      await _syncTable('Drugs', 'drugs', accessToken);
      await _syncTable('LabTestTypes', 'lab-test-types', accessToken);
      
      // Update sync timestamps
      final now = DateTime.now().toIso8601String();
      
      for (final table in [
        'Patients',
        'Visits',
        'Prescriptions',
        'LabTests',
        'Drugs',
        'LabTestTypes',
      ]) {
        await _localDb.insert(
          'SyncTracking',
          {'tableName': table, 'lastSyncTimestamp': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('Error synchronizing data: $e');
      rethrow;
    }
  }
  
  // Synchronize a specific table
  Future<void> _syncTable(
    String localTableName,
    String apiEndpoint,
    String accessToken,
  ) async {
    try {
      // Get last sync timestamp
      final syncTracking = await _localDb.query(
        'SyncTracking',
        where: 'tableName = ?',
        whereArgs: [localTableName],
      );
      
      String? lastSyncTimestamp;
      if (syncTracking.isNotEmpty) {
        lastSyncTimestamp = syncTracking.first['lastSyncTimestamp'] as String?;
      }
      
      // Get modified local records since last sync
      final List<Map<String, dynamic>> modifiedLocalRecords = await _localDb.query(
        localTableName,
        where: lastSyncTimestamp != null ? 'lastModified > ?' : null,
        whereArgs: lastSyncTimestamp != null ? [lastSyncTimestamp] : null,
      );
      
      // Send modified local records to Azure
      for (final record in modifiedLocalRecords) {
        // Convert SQLite boolean (int) to JSON boolean
        final processedRecord = Map<String, dynamic>.from(record);
        processedRecord.forEach((key, value) {
          if (key.startsWith('is') && value is int) {
            processedRecord[key] = value == 1;
          }
        });
        
        await sendToAzure(
          '$apiEndpoint/${record['id']}',
          processedRecord,
          accessToken: accessToken,
          method: record['isDeleted'] == 1 ? 'DELETE' : 'PUT',
        );
      }
      
      // Get modified remote records since last sync
      final List<Map<String, dynamic>> modifiedRemoteRecords = await fetchFromAzure(
        apiEndpoint,
        queryParams: lastSyncTimestamp != null
            ? {'modifiedSince': lastSyncTimestamp}
            : null,
        accessToken: accessToken,
      );
      
      // Update local database with remote records
      for (final record in modifiedRemoteRecords) {
        // Convert JSON boolean to SQLite boolean (int)
        final processedRecord = Map<String, dynamic>.from(record);
        processedRecord.forEach((key, value) {
          if (key.startsWith('is') && value is bool) {
            processedRecord[key] = value ? 1 : 0;
          }
        });
        
        await _localDb.insert(
          localTableName,
          processedRecord,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('Error syncing table $localTableName: $e');
      rethrow;
    }
  }
  
  // Dispose resources
  void dispose() {
    _httpClient.close();
    _localDb.close();
  }
}
