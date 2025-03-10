import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../dialogs/add_teacher_dialog.dart' as dialogs;
import '../dialogs/edit_teacher_dialog.dart' as dialogs;
import '../services/firebase_service.dart';

class TeacherList extends StatelessWidget {
  final List<Teacher> teachers;
  final Function(String) getAssignedHours;
  final Function(String, String, int) onTeacherAdded;
  final VoidCallback onTeacherEdited;
  final VoidCallback onTeacherDeleted;
  final FirebaseService _firebaseService = FirebaseService();

  TeacherList({
    super.key,
    required this.teachers,
    required this.getAssignedHours,
    required this.onTeacherAdded,
    required this.onTeacherEdited,
    required this.onTeacherDeleted,
  });

  void _showAddTeacherDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => dialogs.AddTeacherDialog(
        onTeacherAdded: onTeacherAdded,
      ),
    );
  }

  void _editTeacher(BuildContext context, Teacher teacher) {
    showDialog(
      context: context,
      builder: (context) => dialogs.EditTeacherDialog(
        teacher: teacher,
        onTeacherEdited: onTeacherEdited,
      ),
    );
  }

  void _deleteTeacher(BuildContext context, String id) async {
    // Confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to remove this teacher? This will also remove them from all assigned slots."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _firebaseService.deleteTeacher(id);
      onTeacherDeleted();
    }
  }

  Widget _buildProgressIndicator(int assigned, int max) {
    final double percentage = max > 0 ? assigned / max : 0;
    final Color progressColor = percentage >= 1
        ? Colors.red
        : percentage >= 0.8
        ? Colors.orange
        : Colors.green;

    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: progressColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            color: Colors.blue[700],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Teachers",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add"),
                  onPressed: () => _showAddTeacherDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: teachers.isEmpty
                ? Center(
              child: Text(
                "No teachers yet.\nClick 'Add' to create one.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
                : ListView.separated(
              itemCount: teachers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final teacher = teachers[index];
                final assignedHours = getAssignedHours(teacher.id);
                final remainingHours = teacher.maxHoursPerWeek - assignedHours;

                return Draggable<Teacher>(
                  data: teacher,
                  feedback: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[700]!),
                      ),
                      child: Text(
                        teacher.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    height: 80,
                    color: Colors.grey[100],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: remainingHours <= 0 ? Colors.red : Colors.blue,
                      child: Icon(
                        teacher.gender == 'female' ? Icons.female : Icons.male,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      teacher.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        _buildProgressIndicator(assignedHours, teacher.maxHoursPerWeek),
                        const SizedBox(height: 4),
                        Text(
                          "Hours: $assignedHours/${teacher.maxHoursPerWeek} ($remainingHours remaining)",
                          style: TextStyle(
                            color: remainingHours <= 0 ? Colors.red : Colors.black87,
                            fontWeight: remainingHours <= 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editTeacher(context, teacher),
                          tooltip: "Edit",
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTeacher(context, teacher.id),
                          tooltip: "Delete",
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}