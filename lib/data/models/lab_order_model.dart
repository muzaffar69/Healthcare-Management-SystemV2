// lab_order_model.dart
class LabOrder {
  final int? id;
  final int visitId;
  final int labTestId;
  final String testName;
  final String note;
  final bool sentToLab;

  LabOrder({
    this.id,
    required this.visitId,
    required this.labTestId,
    required this.testName,
    required this.note,
    this.sentToLab = false,
  });

  // Convert a LabOrder into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visitId': visitId,
      'labTestId': labTestId,
      'testName': testName,
      'note': note,
      'sentToLab': sentToLab ? 1 : 0,
    };
  }

  // Create a LabOrder from a Map
  factory LabOrder.fromMap(Map<String, dynamic> map) {
    return LabOrder(
      id: map['id'],
      visitId: map['visitId'],
      labTestId: map['labTestId'],
      testName: map['testName'],
      note: map['note'],
      sentToLab: map['sentToLab'] == 1,
    );
  }

  // Create a copy of this LabOrder with the given fields updated
  LabOrder copyWith({
    int? id,
    int? visitId,
    int? labTestId,
    String? testName,
    String? note,
    bool? sentToLab,
  }) {
    return LabOrder(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      labTestId: labTestId ?? this.labTestId,
      testName: testName ?? this.testName,
      note: note ?? this.note,
      sentToLab: sentToLab ?? this.sentToLab,
    );
  }
}