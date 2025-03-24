import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../models/schedule_slot.dart';
import '../utils/schedule_helpers.dart';

class TimeSlotCell extends StatelessWidget {
  final String classId;
  final int dayIndex;
  final int slotIndex;
  final List<ScheduleSlot> scheduleSlots;
  final List<Teacher> teachers;
  final DateTime currentWeekStart;
  final Function(String) getAssignedHours;
  final Function(String, int, int, Teacher) onAssignTeacher;
  final Function(ScheduleSlot) onRemoveTeacher;

  const TimeSlotCell({
    super.key,
    required this.classId,
    required this.dayIndex,
    required this.slotIndex,
    required this.scheduleSlots,
    required this.teachers,
    required this.currentWeekStart,
    required this.getAssignedHours,
    required this.onAssignTeacher,
    required this.onRemoveTeacher,
  });

  // Improved color generation with more consistent and visually appealing colors
  Color _getTeacherColor(String id) {
    final colors = [
      Colors.red.shade100,
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
      Colors.pink.shade100,
      Colors.amber.shade100,
      Colors.brown.shade100,
      Colors.cyan.shade100,
    ];
    return colors[id.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final slot = scheduleSlots.firstWhere(
          (slot) =>
      slot.classId == classId &&
          slot.dayIndex == dayIndex.toString() &&
          slot.slotIndex == slotIndex.toString(),
      orElse: () => ScheduleSlot(
        id: '',
        dayIndex: dayIndex.toString(),
        slotIndex: slotIndex.toString(),
        classId: classId,
        teacherId: '',
        weekKey: getWeekKey(currentWeekStart),
      ),
    );

    // Improved null handling for assigned teacher
    Teacher? assignedTeacher = slot.teacherId.isNotEmpty
        ? teachers.firstWhereOrNull((t) => t.id == slot.teacherId)
        : null;

    return DragTarget<Teacher>(
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 150,
          height: 80,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? Colors.green.shade50
                : assignedTeacher != null
                ? _getTeacherColor(assignedTeacher.id)
                : Colors.white,
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? Colors.green
                  : Colors.grey.shade300,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: assignedTeacher != null
              ? _buildAssignedTeacherContent(assignedTeacher, slot)
              : _buildDropTargetContent(),
        );
      },
      onAcceptWithDetails: (DragTargetDetails<Teacher> details) {
        final teacher = details.data;
        onAssignTeacher(classId, dayIndex, slotIndex, teacher);
      },
      onWillAcceptWithDetails: (DragTargetDetails<Teacher>? details) {
        if (details == null) return false;
        final teacher = details.data;
        final assignedHours = getAssignedHours(teacher.id);
        return assignedHours < teacher.maxHoursPerWeek;
      },
    );
  }

  Widget _buildAssignedTeacherContent(Teacher teacher, ScheduleSlot slot) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                teacher.gender == 'female' ? Icons.female : Icons.male,
                color: Colors.blue.shade700,
                size: 24,
              ),
              Text(
                teacher.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            onPressed: () => onRemoveTeacher(slot),
            constraints: BoxConstraints.tight(const Size(24, 24)),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildDropTargetContent() {
    return Center(
      child: Text(
        "Drop instructor here",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 12,
        ),
      ),
    );
  }
}

// Extension method to add firstWhereOrNull to List
extension FirstWhereOrNullExtension<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}