// prescription_model.dart
class Prescription {
  final int? id;
  final int visitId;
  final int drugId;
  final String drugName;
  final String note;
  final bool sentToPharmacy;

  Prescription({
    this.id,
    required this.visitId,
    required this.drugId,
    required this.drugName,
    required this.note,
    this.sentToPharmacy = false,
  });

  // Convert a Prescription into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visitId': visitId,
      'drugId': drugId,
      'drugName': drugName,
      'note': note,
      'sentToPharmacy': sentToPharmacy ? 1 : 0,
    };
  }

  // Create a Prescription from a Map
  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'],
      visitId: map['visitId'],
      drugId: map['drugId'],
      drugName: map['drugName'],
      note: map['note'],
      sentToPharmacy: map['sentToPharmacy'] == 1,
    );
  }

  // Create a copy of this Prescription with the given fields updated
  Prescription copyWith({
    int? id,
    int? visitId,
    int? drugId,
    String? drugName,
    String? note,
    bool? sentToPharmacy,
  }) {
    return Prescription(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      drugId: drugId ?? this.drugId,
      drugName: drugName ?? this.drugName,
      note: note ?? this.note,
      sentToPharmacy: sentToPharmacy ?? this.sentToPharmacy,
    );
  }
}