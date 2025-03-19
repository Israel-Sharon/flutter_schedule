import 'package:flutter/material.dart';
import '../models/teacher.dart';

class TeacherAvatar extends StatelessWidget {
  final Teacher teacher;
  final double radius;

  const TeacherAvatar({
    Key? key,
    required this.teacher,
    this.radius = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (teacher.photoUrl != null && teacher.photoUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(teacher.photoUrl!),
        radius: radius,
      );
    } else {
      // Fallback icon based on gender
      IconData iconData = teacher.gender == 'Male' ? Icons.man : Icons.woman;
      return CircleAvatar(
        child: Icon(iconData),
        radius: radius,
      );
    }
  }
}