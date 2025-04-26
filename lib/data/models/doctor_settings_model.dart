// doctor_settings_model.dart
class DoctorSettings {
  final int? id;
  final String? name;
  final String? specialty;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? notes;
  final String? profilePicPath;

  DoctorSettings({
    this.id,
    this.name,
    this.specialty,
    this.phoneNumber,
    this.email,
    this.address,
    this.notes,
    this.profilePicPath,
  });

  // Convert a DoctorSettings into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'notes': notes,
      'profilePicPath': profilePicPath,
    };
  }

  // Create a DoctorSettings from a Map
  factory DoctorSettings.fromMap(Map<String, dynamic> map) {
    return DoctorSettings(
      id: map['id'],
      name: map['name'],
      specialty: map['specialty'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      address: map['address'],
      notes: map['notes'],
      profilePicPath: map['profilePicPath'],
    );
  }

  // Create a copy of this DoctorSettings with the given fields updated
  DoctorSettings copyWith({
    int? id,
    String? name,
    String? specialty,
    String? phoneNumber,
    String? email,
    String? address,
    String? notes,
    String? profilePicPath,
  }) {
    return DoctorSettings(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      profilePicPath: profilePicPath ?? this.profilePicPath,
    );
  }
}