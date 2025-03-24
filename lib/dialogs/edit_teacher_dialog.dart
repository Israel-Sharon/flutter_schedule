import 'package:flutter/material.dart';
import '../models/teacher.dart';

class EditTeacherDialog extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onTeacherEdited;

  const EditTeacherDialog({super.key, required this.teacher, required this.onTeacherEdited});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Teacher"),
      content: const Text("Teacher editing form goes here"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            onTeacherEdited();
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
