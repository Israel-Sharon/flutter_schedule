import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../models/schedule_slot.dart';
import '../models/class.dart';
import '../widgets/time_slot_cell.dart';

final dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
final timeSlots = ['8:20 - 9:05', '9:05 - 9:50', '10:10 - 11:00', '11:00 - 11:50', '12:00 - 12:40', '13:10 - 14:00', '14:10 - 15:00', '15:10 - 16:00'];

class ScheduleGrid extends StatelessWidget {
  final List<Class> classes;
  final List<Teacher> teachers;
  final List<ScheduleSlot> scheduleSlots;
  final DateTime currentWeekStart;
  final Function(String) getAssignedHours;
  final Function(String, int, int, Teacher) onAssignTeacher;
  final Function(ScheduleSlot) onRemoveTeacher;

  const ScheduleGrid({super.key, 
    required this.classes,
    required this.teachers,
    required this.scheduleSlots,
    required this.currentWeekStart,
    required this.getAssignedHours,
    required this.onAssignTeacher,
    required this.onRemoveTeacher,
  });

  // Helper method to build the overall day cell for a class
  Widget _buildClassDayCell(String classId, int dayIndex) {
    final dayScheduleSlots = scheduleSlots.where(
            (slot) => slot.classId == classId && slot.dayIndex == dayIndex.toString()
    ).toList();

    return Container(
      width: 150,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          "${dayScheduleSlots.length} sessions",
          style: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return Center(
        child: Text(
          "No classes available.\nPlease add classes first.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: [
        // Header with class names (X-axis)
        Row(
          children: [
            // Empty corner cell
            Container(
              width: 120,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue[900],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Text(
                  "Day / Class",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Class names in header
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: classes.map((aClass) {
                    return Container(
                      width: 150,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue[800],
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          aClass.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),

        // Schedule rows (days and timeslots - Y-axis)
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: List.generate(dayNames.length, (dayIndex) {
                return Column(
                  children: [
                    // Day name row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day label
                        Container(
                          width: 120,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Center(
                            child: Text(
                              dayNames[dayIndex],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // Slots for each class for this day
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: classes.map((aClass) {
                                return _buildClassDayCell(aClass.id, dayIndex);
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Time slots for this day
                    Column(
                      children: List.generate(timeSlots.length, (slotIndex) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Time slot label (Y1 axis)
                            Container(
                              width: 120,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Center(
                                child: Text(
                                  timeSlots[slotIndex],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ),
                            ),

                            // Class cells for this time slot
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: classes.map((aClass) {
                                    return TimeSlotCell(
                                      classId: aClass.id,
                                      dayIndex: dayIndex,
                                      slotIndex: slotIndex,
                                      scheduleSlots: scheduleSlots,
                                      teachers: teachers,
                                      currentWeekStart: currentWeekStart,
                                      getAssignedHours: getAssignedHours,
                                      onAssignTeacher: onAssignTeacher,
                                      onRemoveTeacher: onRemoveTeacher,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}