// drug_model.dart
class Drug {
  final int? id;
  final String name;

  Drug({
    this.id,
    required this.name,
  });

  // Convert a Drug into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Create a Drug from a Map
  factory Drug.fromMap(Map<String, dynamic> map) {
    return Drug(
      id: map['id'],
      name: map['name'],
    );
  }
}
