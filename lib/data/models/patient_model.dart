// patient_model.dart
class Patient {
  final int? id;
  final String name;
  final int age;
  final String gender;
  final String phoneNumber;
  final String? profilePicPath;
  final String? address;
  final double? weight;
  final double? height;
  final String? chronicDiseases;
  final String? familyHistory;
  final String? notes;
  final String? firstVisitDate;

  Patient({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phoneNumber,
    this.profilePicPath,
    this.address,
    this.weight,
    this.height,
    this.chronicDiseases,
    this.familyHistory,
    this.notes,
    this.firstVisitDate,
  });

  // Convert a Patient into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'profilePicPath': profilePicPath,
      'address': address,
      'weight': weight,
      'height': height,
      'chronicDiseases': chronicDiseases,
      'familyHistory': familyHistory,
      'notes': notes,
      'firstVisitDate': firstVisitDate,
    };
  }

  // Create a Patient from a Map
  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      phoneNumber: map['phoneNumber'],
      profilePicPath: map['profilePicPath'],
      address: map['address'],
      weight: map['weight'],
      height: map['height'],
      chronicDiseases: map['chronicDiseases'],
      familyHistory: map['familyHistory'],
      notes: map['notes'],
      firstVisitDate: map['firstVisitDate'],
    );
  }

  // Create a copy of this Patient with the given fields updated
  Patient copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    String? phoneNumber,
    String? profilePicPath,
    String? address,
    double? weight,
    double? height,
    String? chronicDiseases,
    String? familyHistory,
    String? notes,
    String? firstVisitDate,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicPath: profilePicPath ?? this.profilePicPath,
      address: address ?? this.address,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      familyHistory: familyHistory ?? this.familyHistory,
      notes: notes ?? this.notes,
      firstVisitDate: firstVisitDate ?? this.firstVisitDate,
    );
  }
}