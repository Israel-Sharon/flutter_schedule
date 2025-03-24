// lib/utils/schedule_helpers.dart
import 'package:intl/intl.dart';

/// Returns a standardized string key for a week based on its start date
/// Format: YYYY-MM-DD (ISO format of the week's Monday)
String getWeekKey(DateTime weekStart) {
  // Ensure we're using the start of the week (Monday)
  final monday = weekStart.subtract(Duration(days: weekStart.weekday - 1));
  return DateFormat('yyyy-MM-dd').format(monday);
}

/// Utility function to check if a teacher is overbooked
bool isTeacherOverbooked(int assignedHours, int maxHours) {
  return assignedHours > maxHours;
}

/// Gets the display name for a day index
String getDayName(int dayIndex) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  return days[dayIndex];
}