// lab_test_model.dart
class LabTest {
  final int? id;
  final String name;

  LabTest({
    this.id,
    required this.name,
  });

  // Convert a LabTest into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Create a LabTest from a Map
  factory LabTest.fromMap(Map<String, dynamic> map) {
    return LabTest(
      id: map['id'],
      name: map['name'],
    );
  }
}