class Prescription {
  final String id;
  final String visitId;
  final String drugName;
  final String notes;
  final bool sentToPharmacy;
  final bool fulfilledByPharmacy;
  final String pharmacyNotes;
  final DateTime lastModified;
  final bool isDeleted;

  Prescription({
    required this.id,
    required this.visitId,
    required this.drugName,
    this.notes = '',
    this.sentToPharmacy = false,
    this.fulfilledByPharmacy = false,
    this.pharmacyNotes = '',
    required this.lastModified,
    this.isDeleted = false,
  });

  // Factory constructor from JSON
  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      visitId: json['visitId'],
      drugName: json['drugName'],
      notes: json['notes'] ?? '',
      sentToPharmacy: json['sentToPharmacy'] is bool
          ? json['sentToPharmacy']
          : (json['sentToPharmacy'] == 1 ? true : false),
      fulfilledByPharmacy: json['fulfilledByPharmacy'] is bool
          ? json['fulfilledByPharmacy']
          : (json['fulfilledByPharmacy'] == 1 ? true : false),
      pharmacyNotes: json['pharmacyNotes'] ?? '',
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
      'drugName': drugName,
      'notes': notes,
      'sentToPharmacy': sentToPharmacy,
      'fulfilledByPharmacy': fulfilledByPharmacy,
      'pharmacyNotes': pharmacyNotes,
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  // Convert to SQLite compatible map
  Map<String, dynamic> toSqlite() {
    final map = {
      'id': id,
      'visitId': visitId,
      'drugName': drugName,
      'notes': notes,
      'sentToPharmacy': sentToPharmacy ? 1 : 0,
      'fulfilledByPharmacy': fulfilledByPharmacy ? 1 : 0,
      'pharmacyNotes': pharmacyNotes,
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
    };
    return map;
  }

  // Create a copy with updated fields
  Prescription copyWith({
    String? id,
    String? visitId,
    String? drugName,
    String? notes,
    bool? sentToPharmacy,
    bool? fulfilledByPharmacy,
    String? pharmacyNotes,
    DateTime? lastModified,
    bool? isDeleted,
  }) {
    return Prescription(
      id: id ?? this.id,
      visitId: visitId ?? this.visitId,
      drugName: drugName ?? this.drugName,
      notes: notes ?? this.notes,
      sentToPharmacy: sentToPharmacy ?? this.sentToPharmacy,
      fulfilledByPharmacy: fulfilledByPharmacy ?? this.fulfilledByPharmacy,
      pharmacyNotes: pharmacyNotes ?? this.pharmacyNotes,
      lastModified: lastModified ?? this.lastModified,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Status of the prescription
  String get status {
    if (isDeleted) {
      return 'Deleted';
    } else if (fulfilledByPharmacy) {
      return 'Fulfilled';
    } else if (sentToPharmacy) {
      return 'Sent to Pharmacy';
    } else {
      return 'Draft';
    }
  }

  // Color for the status
  int get statusColor {
    if (isDeleted) {
      return 0xFFE57373; // Red
    } else if (fulfilledByPharmacy) {
      return 0xFF81C784; // Green
    } else if (sentToPharmacy) {
      return 0xFFFFB74D; // Orange
    } else {
      return 0xFF90CAF9; // Blue
    }
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
