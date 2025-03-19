import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/firebase_service.dart';
import '../dialogs/add_teacher_dialog.dart';

// Helper function to show add teacher dialog
void showAddTeacherDialog(
    BuildContext context,
    FirebaseService firebaseService,
    Function(String name, String gender, dynamic hours, dynamic imageFile) onTeacherAdded,
    ) {
  showDialog(
    context: context,
    builder: (context) => AddTeacherDialog(
      onTeacherAdded: onTeacherAdded,
    ),
  );
}

// Helper function to show edit teacher dialog
void showEditTeacherDialog(
    BuildContext context,
    Teacher teacher,
    FirebaseService firebaseService,
    Function(String name, String gender, dynamic hours, dynamic imageFile) onTeacherUpdated,
    ) {
  showDialog(
    context: context,
    builder: (context) => AddTeacherDialog(
      initialName: teacher.name,
      initialGender: teacher.gender,
      initialHours: teacher.maxHoursPerWeek,
      existingPhotoUrl: teacher.photoUrl,
      onTeacherAdded: onTeacherUpdated,
    ),
  );
}

// Helper function to show delete teacher dialog
void showDeleteTeacherDialog(
    BuildContext context,
    Teacher teacher,
    VoidCallback onConfirm,
    ) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Teacher'),
      content: Text('Are you sure you want to delete ${teacher.name}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}