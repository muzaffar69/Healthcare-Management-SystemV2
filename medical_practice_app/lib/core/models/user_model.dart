class User {
  final String id;
  final String displayName;
  final String email;
  final String role;
  final DateTime? subscriptionEndDate;
  final bool isActive;
  final bool hasPharmacyAccount;
  final bool hasLabAccount;
  final bool pharmacyAccountActive;
  final bool labAccountActive;
  final Map<String, dynamic> settings;

  User({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    this.subscriptionEndDate,
    this.isActive = false,
    this.hasPharmacyAccount = false,
    this.hasLabAccount = false,
    this.pharmacyAccountActive = false,
    this.labAccountActive = false,
    this.settings = const {},
  });

  // Factory constructor from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      displayName: json['displayName'],
      email: json['email'],
      role: json['role'],
      subscriptionEndDate: json['subscriptionEndDate'] != null
          ? DateTime.parse(json['subscriptionEndDate'])
          : null,
      isActive: json['isActive'] ?? false,
      hasPharmacyAccount: json['hasPharmacyAccount'] ?? false,
      hasLabAccount: json['hasLabAccount'] ?? false,
      pharmacyAccountActive: json['pharmacyAccountActive'] ?? false,
      labAccountActive: json['labAccountActive'] ?? false,
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'])
          : {},
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'role': role,
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
      'isActive': isActive,
      'hasPharmacyAccount': hasPharmacyAccount,
      'hasLabAccount': hasLabAccount,
      'pharmacyAccountActive': pharmacyAccountActive,
      'labAccountActive': labAccountActive,
      'settings': settings,
    };
  }

  // Create a copy with updated fields
  User copyWith({
    String? id,
    String? displayName,
    String? email,
    String? role,
    DateTime? subscriptionEndDate,
    bool? isActive,
    bool? hasPharmacyAccount,
    bool? hasLabAccount,
    bool? pharmacyAccountActive,
    bool? labAccountActive,
    Map<String, dynamic>? settings,
  }) {
    return User(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      isActive: isActive ?? this.isActive,
      hasPharmacyAccount: hasPharmacyAccount ?? this.hasPharmacyAccount,
      hasLabAccount: hasLabAccount ?? this.hasLabAccount,
      pharmacyAccountActive: pharmacyAccountActive ?? this.pharmacyAccountActive,
      labAccountActive: labAccountActive ?? this.labAccountActive,
      settings: settings ?? this.settings,
    );
  }

  // Doctor-specific settings getters
  String get doctorName => settings['doctorName'] ?? '';
  String get specialty => settings['specialty'] ?? '';
  String get phoneNumber => settings['phoneNumber'] ?? '';
  String get address => settings['address'] ?? '';
  String get email => settings['email'] ?? '';
  String get notes => settings['notes'] ?? '';
  String get profilePhotoUrl => settings['profilePhotoUrl'] ?? '';

  // Check subscription status
  bool get isSubscriptionActive {
    if (subscriptionEndDate == null) {
      return false;
    }
    return subscriptionEndDate!.isAfter(DateTime.now());
  }

  // Check subscription expiration soon
  bool isSubscriptionExpiringInDays(int days) {
    if (subscriptionEndDate == null) {
      return false;
    }
    final expirationThreshold = DateTime.now().add(Duration(days: days));
    return subscriptionEndDate!.isBefore(expirationThreshold) && 
           subscriptionEndDate!.isAfter(DateTime.now());
  }

  // Check if user has lab access
  bool get hasLabAccess => hasLabAccount && labAccountActive;

  // Check if user has pharmacy access
  bool get hasPharmacyAccess => hasPharmacyAccount && pharmacyAccountActive;
}
