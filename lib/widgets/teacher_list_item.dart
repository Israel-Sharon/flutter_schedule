import 'package:flutter/material.dart';
import '../models/teacher.dart';
import 'teacher_avatar.dart';

class TeacherListItem extends StatelessWidget {
  final Teacher teacher;
  final int index;
  final dynamic assignedHours; // or use int if it's always an integer
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TeacherListItem({
    Key? key,
    required this.teacher,
    required this.index,
    required this.assignedHours,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate percentage of hours used
    double hoursPercentage = 0.0;
    if (teacher.maxHoursPerWeek! > 0) {
      hoursPercentage = (assignedHours / teacher.maxHoursPerWeek).clamp(0.0, 1.0);
    }

    // Determine color based on utilization
    Color progressColor = Colors.green;
    if (hoursPercentage > 0.9) {
      progressColor = Colors.red;
    } else if (hoursPercentage > 0.7) {
      progressColor = Colors.orange;
    }

    return Draggable<Teacher>(
      data: teacher,
      feedback: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          width: 280,
          child: ListTile(
            leading: TeacherAvatar(teacher: teacher),
            title: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Hours: $assignedHours / ${teacher.maxHoursPerWeek}',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ),
      ),
      childWhenDragging: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          leading: TeacherAvatar(teacher: teacher),
          title: Text(teacher.name, style: TextStyle(color: Colors.grey[600])),
          subtitle: Text(
            'Hours: $assignedHours / ${teacher.maxHoursPerWeek}',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            ListTile(
              title: Text(
                teacher.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Row(
                children: [
                  Icon(
                    teacher.gender == 'Male' ? Icons.male : Icons.female,
                    size: 16,
                    color: teacher.gender == 'Male' ? Colors.blue : Colors.pink,
                  ),
                  const SizedBox(width: 4),
                  Text(teacher.gender ?? 'Not specified'),
                ],
              ),
              leading: ReorderableDragStartListener(
                index: index,
                child: Stack(
                  children: [
                    TeacherAvatar(teacher: teacher),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(Icons.drag_handle, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: onEdit,
                    tooltip: 'Edit teacher',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Delete teacher',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hours: $assignedHours / ${teacher.maxHoursPerWeek}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${(hoursPercentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: hoursPercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}