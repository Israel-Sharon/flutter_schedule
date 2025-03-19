// teacher.dart

class Teacher {
  final String id;
  final String name;
 // final String? subject;
  final String? photoUrl;
  final String? gender;
  final bool? isActive;
  final int? classCount;
  final int? studentCount;
  final double? rating;
  final int? maxHoursPerWeek; // Change from String? to int?

  final int displayOrder;

  var additionalInfo;


  Teacher({
    required this.id,
    required this.name,
    this.photoUrl,
    this.gender,
    this.isActive = true,
    this.classCount = 0,
    this.studentCount = 0,
    this.rating = 0.0,
    this.additionalInfo = const {},
    this.maxHoursPerWeek, // Change type here as well
    this.displayOrder = 1,
  });

  factory Teacher.fromMap(String id, Map<String, dynamic> data) {
    return Teacher(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
     // subject: data['subject'] ?? '',
      photoUrl: data['photoUrl'],
      gender: data['gender'],
      isActive: data['isActive'] ?? true,
      classCount: data['classCount'] ?? 0,
      studentCount: data['studentCount'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
      maxHoursPerWeek: (data['maxHoursPerWeek'] is int)
          ? data['maxHoursPerWeek']
          : int.tryParse(data['maxHoursPerWeek']?.toString() ?? '0') ?? 0, // Ensure int conversion
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      //'subject': subject,
      'photoUrl': photoUrl,
      'gender':gender,
      'isActive': isActive,
      'classCount': classCount,
      'studentCount': studentCount,
      'rating': rating,
      'additionalInfo': additionalInfo,
      'maxHoursPerWeek': maxHoursPerWeek,
    };
  }

  Teacher copyWith({
    String? id,
    String? name,
    //String? subject,
    String? photoUrl,
    String? gender,
    bool? isActive,
    int? classCount,
    int? studentCount,
    double? rating,
    Map<String, dynamic>? additionalInfo,
    int? maxHoursPerWeek,
  }) {
    return Teacher(
      id: id ?? this.id ,
      name: name ?? this.name,
      //subject: subject ?? this.subject,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      isActive: isActive ?? this.isActive,
      classCount: classCount ?? this.classCount,
      studentCount: studentCount ?? this.studentCount,
      rating: rating ?? this.rating,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      maxHoursPerWeek: maxHoursPerWeek ?? this.maxHoursPerWeek, // Update here
    );
  }
}