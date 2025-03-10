class Class {
  final String id;
  final String name;
  final String description;
  final String academicLevel;

  Class({
    required this.id,
    required this.name,
    required this.description,
    required this.academicLevel,
  });

  factory Class.fromMap(String id, Map<String, dynamic> data) {
    return Class(
      id: id,
      name: data['name'] ?? 'Unnamed Class',
      description: data['description'] ?? '',
      academicLevel: data['academicLevel'] ?? 'Unspecified',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'academicLevel': academicLevel,
    };
  }
}