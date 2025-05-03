import 'prescription_model.dart';
import 'lab_test_model.dart';

class Visit {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime visitDate;
  final int visitNumber;
  final String notes;
  final List<Prescription> prescriptions;
  final List<LabTest> labTests;
  final DateTime lastModified;
  final bool isDeleted;

  Visit({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.visitDate,
    required this.visitNumber,
    this.notes = '',
    this.prescriptions = const [],
    this.labTests = const [],
    required this.lastModified,
    this.isDeleted = false,
  });

  // Factory constructor from JSON
  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'],
      patientId: json['patientId'],
      doctorId: json['doctorId'],
      visitDate: DateTime.parse(json['visitDate']),
      visitNumber: json['visitNumber'],
      notes: json['notes'] ?? '',
      prescriptions: json['prescriptions'] != null
          ? (json['prescriptions'] as List)
              .map((prescription) => Prescription.fromJson(prescription))
              .toList()
          : [],
      labTests: json['labTests'] != null
          ? (json['labTests'] as List)
              .map((labTest) => LabTest.fromJson(labTest))
              .toList()
          : [],
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
      'patientId': patientId,
      'doctorId': doctorId,
      'visitDate': visitDate.toIso8601String(),
      'visitNumber': visitNumber,
      'notes': notes,
      'prescriptions': prescriptions.map((prescription) => prescription.toJson()).toList(),
      'labTests': labTests.map((labTest) => labTest.toJson()).toList(),
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  // Convert to SQLite compatible map (without nested objects)
  Map<String, dynamic> toSqlite() {
    final map = {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'visitDate': visitDate.toIso8601String(),
      'visitNumber': visitNumber,
      'notes': notes,
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
    };
    return map;
  }

  // Create a copy with updated fields
  Visit copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    DateTime? visitDate,
    int? visitNumber,
    String? notes,
    List<Prescription>? prescriptions,
    List<LabTest>? labTests,
    DateTime? lastModified,
    bool? isDeleted,
  }) {
    return Visit(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      visitDate: visitDate ?? this.visitDate,
      visitNumber: visitNumber ?? this.visitNumber,
      notes: notes ?? this.notes,
      prescriptions: prescriptions ?? this.prescriptions,
      labTests: labTests ?? this.labTests,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Check if the visit has any prescriptions
  bool get hasPrescriptions => prescriptions.isNotEmpty;

  // Check if the visit has any lab tests
  bool get hasLabTests => labTests.isNotEmpty;

  // Check if all prescriptions are fulfilled
  bool get areAllPrescriptionsFulfilled {
    if (prescriptions.isEmpty) {
      return false;
    }
    return prescriptions.every((prescription) => prescription.fulfilledByPharmacy);
  }

  // Check if all lab tests are completed
  bool get areAllLabTestsCompleted {
    if (labTests.isEmpty) {
      return false;
    }
    return labTests.every((labTest) => labTest.completedByLab);
  }

  // Get a summary of the visit
  String get summary {
    final List<String> summaryParts = [];
    
    // Add notes if available
    if (notes.isNotEmpty) {
      summaryParts.add(notes);
    }
    
    // Add prescription count
    if (prescriptions.isNotEmpty) {
      summaryParts.add('${prescriptions.length} prescriptions');
    }
    
    // Add lab test count
    if (labTests.isNotEmpty) {
      summaryParts.add('${labTests.length} lab tests');
    }
    
    // Return summary or default message
    return summaryParts.isNotEmpty
        ? summaryParts.join(', ')
        : 'No details available';
  }

  // Get the visit date in a formatted string
  String get formattedVisitDate {
    return '${visitDate.day}/${visitDate.month}/${visitDate.year}';
  }
}
