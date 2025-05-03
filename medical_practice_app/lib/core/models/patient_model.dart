import 'dart:convert';

class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String phoneNumber;
  final String address;
  final DateTime firstVisitDate;
  final double? weight;
  final double? height;
  final List<String> chronicDiseases;
  final String familyHistory;
  final String notes;
  final String photoUrl;
  final String doctorId;
  final DateTime lastModified;
  final bool isDeleted;
  final bool isPinned;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phoneNumber,
    this.address = '',
    required this.firstVisitDate,
    this.weight,
    this.height,
    this.chronicDiseases = const [],
    this.familyHistory = '',
    this.notes = '',
    this.photoUrl = '',
    required this.doctorId,
    required this.lastModified,
    this.isDeleted = false,
    this.isPinned = false,
  });

  // Factory constructor from JSON
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      phoneNumber: json['phoneNumber'],
      address: json['address'] ?? '',
      firstVisitDate: DateTime.parse(json['firstVisitDate']),
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      chronicDiseases: json['chronicDiseases'] != null
          ? (json['chronicDiseases'] is String
              ? List<String>.from(jsonDecode(json['chronicDiseases']))
              : List<String>.from(json['chronicDiseases']))
          : [],
      familyHistory: json['familyHistory'] ?? '',
      notes: json['notes'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      doctorId: json['doctorId'],
      lastModified: DateTime.parse(json['lastModified']),
      isDeleted: json['isDeleted'] is bool
          ? json['isDeleted']
          : (json['isDeleted'] == 1 ? true : false),
      isPinned: json['isPinned'] is bool
          ? json['isPinned']
          : (json['isPinned'] == 1 ? true : false),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'address': address,
      'firstVisitDate': firstVisitDate.toIso8601String(),
      'weight': weight,
      'height': height,
      'chronicDiseases': chronicDiseases,
      'familyHistory': familyHistory,
      'notes': notes,
      'photoUrl': photoUrl,
      'doctorId': doctorId,
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted,
      'isPinned': isPinned,
    };
  }

  // Convert to SQLite compatible map
  Map<String, dynamic> toSqlite() {
    final map = toJson();
    map['chronicDiseases'] = jsonEncode(chronicDiseases);
    map['isDeleted'] = isDeleted ? 1 : 0;
    map['isPinned'] = isPinned ? 1 : 0;
    return map;
  }

  // Create a copy with updated fields
  Patient copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? phoneNumber,
    String? address,
    DateTime? firstVisitDate,
    double? weight,
    double? height,
    List<String>? chronicDiseases,
    String? familyHistory,
    String? notes,
    String? photoUrl,
    String? doctorId,
    DateTime? lastModified,
    bool? isDeleted,
    bool? isPinned,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      firstVisitDate: firstVisitDate ?? this.firstVisitDate,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      familyHistory: familyHistory ?? this.familyHistory,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      doctorId: doctorId ?? this.doctorId,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  // Calculate BMI
  double? get bmi {
    if (weight != null && height != null && height! > 0) {
      // Convert height from cm to meters
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  // Get BMI category
  String get bmiCategory {
    final currentBmi = bmi;
    if (currentBmi == null) {
      return 'Unknown';
    }

    if (currentBmi < 18.5) {
      return 'Underweight';
    } else if (currentBmi < 25) {
      return 'Normal weight';
    } else if (currentBmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  // Format chronic diseases for display
  String get formattedChronicDiseases {
    if (chronicDiseases.isEmpty) {
      return 'None';
    }
    return chronicDiseases.join(', ');
  }

  // Patient age in months for pediatric patients
  int get ageInMonths {
    final today = DateTime.now();
    final birthYear = today.year - age;
    final birthDate = DateTime(birthYear, today.month, today.day);
    return (today.difference(birthDate).inDays / 30).round();
  }

  // Check if patient is a pediatric patient (under 18)
  bool get isPediatric => age < 18;

  // Check if patient is a senior (over 65)
  bool get isSenior => age > 65;
}
