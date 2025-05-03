import 'dart:convert';

class LabTest {
  final String id;
  final String visitId;
  final String testName;
  final String notes;
  final bool sentToLab;
  final bool completedByLab;
  final String labNotes;
  final String resultFileUrl;
  final DateTime lastModified;
  final bool isDeleted;

  LabTest({
    required this.id,
    required this.visitId,
    required this.testName,
    this.notes = '',
    this.sentToLab = false,
    this.completedByLab = false,
    this.labNotes = '',
    this.resultFileUrl = '',
    required this.lastModified,
    this.isDeleted = false,
  });

  // Factory constructor from JSON
  factory LabTest.fromJson(Map<String, dynamic> json) {
    return LabTest(
      id: json['id'],
      visitId: json['visitId'],
      testName: json['testName'],
      notes: json['notes'] ?? '',
      sentToLab: json['sentToLab'] is bool
          ? json['sentToLab']
          : (json['sentToLab'] == 1 ? true : false),
      completedByLab: json['completedByLab'] is bool
          ? json['completedByLab']
          : (json['completedByLab'] == 1 ? true : false),
      labNotes: json['labNotes'] ?? '',
      resultFileUrl: json['resultFileUrl'] ?? '',
      lastModified: DateTime.parse(json['lastModified']),
      isDeleted: json['isDeleted'] is bool
          ? json['isDeleted']
          : (json['isDeleted'] == 1 ? true : false),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visitId': visitId,
      'testName': testName,
      'notes': notes,
      'sentToLab': sentToLab,
      'completedByLab': completedByLab,
      'labNotes': labNotes,
      'resultFileUrl': resultFileUrl,
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  // Convert to SQLite compatible map
  Map<String, dynamic> toSqlite() {
    final map = {
      'id': id,
      'visitId': visitId,
      'testName': testName,
      'notes': notes,
      'sentToLab': sentToLab ? 1 : 0,
      'completedByLab': completedByLab ? 1 : 0,
      'labNotes': labNotes,
      'resultFileUrl': resultFileUrl,
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
    };
    return map;
  }

  // Create a copy with updated fields
  LabTest copyWith({
    String? id,
    String? visitId,
    String? testName,
    String? notes,
    bool? sentToLab,
    bool? completedByLab,
    String? labNotes,
    String? resultFileUrl,
    DateTime? lastModified,
    bool? isDeleted,
  }) {
    return LabTest(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      testName: testName ?? this.testName,
      notes: notes ?? this.notes,
      sentToLab: sentToLab ?? this.sentToLab,
      completedByLab: completedByLab ?? this.completedByLab,
      labNotes: labNotes ?? this.labNotes,
      resultFileUrl: resultFileUrl ?? this.resultFileUrl,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Status of the lab test
  String get status {
    if (isDeleted) {
      return 'Deleted';
    } else if (completedByLab) {
      return 'Completed';
    } else if (sentToLab) {
      return 'Sent to Lab';
    } else {
      return 'Pending';
    }
  }

  // Color for the status
  int get statusColor {
    if (isDeleted) {
      return 0xFFE57373; // Red
    } else if (completedByLab) {
      return 0xFF81C784; // Green
    } else if (sentToLab) {
      return 0xFFFFB74D; // Orange
    } else {
      return 0xFF90CAF9; // Blue
    }
  }

  // Check if the test has results
  bool get hasResults => resultFileUrl.isNotEmpty;

  // Get file extension
  String get resultFileExtension {
    if (!hasResults) return '';
    
    final uri = Uri.parse(resultFileUrl);
    final path = uri.path;
    final extension = path.split('.').last.toLowerCase();
    
    return extension;
  }

  // Check if result is an image
  bool get isResultImage {
    final ext = resultFileExtension;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(ext);
  }

  // Check if result is a PDF
  bool get isResultPdf {
    return resultFileExtension == 'pdf';
  }

  // Time elapsed since modification
  String get timeElapsed {
    final now = DateTime.now();
    final difference = now.difference(lastModified);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      final months = difference.inDays ~/ 30;
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}