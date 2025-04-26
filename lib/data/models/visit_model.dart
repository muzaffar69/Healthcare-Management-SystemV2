// visit_model.dart

import 'package:medical_practice_app/data/models/lab_order_model.dart';
import 'package:medical_practice_app/data/models/prescription_model.dart';

class Visit {
  final int? id;
  final int patientId;
  final String date;
  final String details;
  final List<Prescription>? prescriptions;
  final List<LabOrder>? labOrders;

  Visit({
    this.id,
    required this.patientId,
    required this.date,
    required this.details,
    this.prescriptions,
    this.labOrders,
  });

  // Convert a Visit into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'date': date,
      'details': details,
    };
  }

  // Create a Visit from a Map
  factory Visit.fromMap(Map<String, dynamic> map) {
    return Visit(
      id: map['id'],
      patientId: map['patientId'],
      date: map['date'],
      details: map['details'],
    );
  }

  // Create a copy of this Visit with the given fields updated
  Visit copyWith({
    int? id,
    int? patientId,
    String? date,
    String? details,
    List<Prescription>? prescriptions,
    List<LabOrder>? labOrders,
  }) {
    return Visit(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      date: date ?? this.date,
      details: details ?? this.details,
      prescriptions: prescriptions ?? this.prescriptions,
      labOrders: labOrders ?? this.labOrders,
    );
  }
}