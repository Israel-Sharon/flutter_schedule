// models/teacher.dart

import 'package:flutter/material.dart';

class Teacher {
  final String id;
  final String name;
  int totalHours;
  int remainingHours;
  final Color assignedColor;

  Teacher({
    required this.id,
    required this.name,
    required this.totalHours,
    required this.remainingHours,
    required this.assignedColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'totalHours': totalHours,
      'remainingHours': remainingHours,
      'assignedColor': assignedColor.value, // Store as an int
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map, String documentId) {
    return Teacher(
      id: documentId,
      name: map['name'] ?? '',
      totalHours: map['totalHours'] ?? 0,
      remainingHours: map['remainingHours'] ?? 0,
      assignedColor: Color(map['assignedColor'] ?? Colors.blue.value),
    );
  }
}
