import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/teacher.dart';
import '../models/schedule_slot.dart';
import '../models/week_settings.dart';
import '../models/class.dart';
import '../widgets/schedule_grid.dart';
import '../widgets/teacher_list.dart';
import '../utils/schedule_helpers.dart';


class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Teacher> _teachers = [];
  List<ScheduleSlot> _scheduleSlots = [];
  List<WeekSettings> _weekSettings = [];
  List<Class> _classes = [];
  bool _isLoading = true;
  final bool _showingClassManagement = false;
  DateTime _currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7));
  String _previousWeekKey = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _goToPreviousWeek() {
    setState(() {
      _previousWeekKey = getWeekKey(_currentWeekStart);
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
      _loadData(checkIfEmpty: true);
    });
  }

  void _goToNextWeek() {
    setState(() {
      _previousWeekKey = getWeekKey(_currentWeekStart);
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
      _loadData(checkIfEmpty: true);
    });
  }

  String _formatWeekDisplay() {
    final endDate = _currentWeekStart.add(const Duration(days: 6));
    final startFormat = DateFormat('MMM d');
    final endFormat = DateFormat('MMM d, yyyy');
    return '${startFormat.format(_currentWeekStart)} - ${endFormat.format(endDate)}';
  }

  Future<void> _loadData({bool checkIfEmpty = false}) async {
    setState(() => _isLoading = true);
    final weekKey = getWeekKey(_currentWeekStart);

    try {
      _teachers = await _firebaseService.getTeachers();
      _scheduleSlots = await _firebaseService.getScheduleSlotsByWeek(weekKey);
      _weekSettings = await _firebaseService.getWeekSettings();
      _classes = await _firebaseService.getClasses();
      print("Fetched classes: $_classes "); // Debugging

      if (checkIfEmpty && _scheduleSlots.isEmpty && _previousWeekKey.isNotEmpty) {
        _promptCopyFromPreviousWeek();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading data: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _promptCopyFromPreviousWeek() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Empty Schedule"),
        content: const Text("This week has no assignments. Would you like to copy all assignments from the previous week?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _copyFromPreviousWeek();
            },
            child: const Text("Yes, Copy"),
          ),
        ],
      ),
    );
  }

  Future<void> _copyFromPreviousWeek() async {
    setState(() => _isLoading = true);
    try {
      final previousSlots = await _firebaseService.getScheduleSlotsByWeek(_previousWeekKey);
      final currentWeekKey = getWeekKey(_currentWeekStart);

      // Create new slots for current week based on previous week
      for (var slot in previousSlots) {
        await _firebaseService.assignTeacherToSlot(
            slot.classId,
            slot.dayIndex,
            slot.slotIndex,
            slot.teacherId,
            currentWeekKey
        );
      }

      // Reload the data
      _scheduleSlots = await _firebaseService.getScheduleSlotsByWeek(currentWeekKey);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Assignments copied from previous week"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error copying assignments: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int getAssignedHours(String teacherId) {
    return _scheduleSlots.where((slot) => slot.teacherId == teacherId).length;
  }

  void assignTeacherToSlot(String classId, int dayIndex, int slotIndex, Teacher teacher) async {
    final weekKey = getWeekKey(_currentWeekStart);

    try {
      await _firebaseService.assignTeacherToSlot(
          classId,
          dayIndex.toString(),
          slotIndex.toString(),
          teacher.id,
          weekKey
      );
      setState(() {
        _loadData();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${teacher.name} assigned successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error assigning instructor: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void removeTeacherFromSlot(ScheduleSlot slot) async {
    try {
      final weekKey = getWeekKey(_currentWeekStart);
      await _firebaseService.removeTeacherFromSlot(
          slot.dayIndex,
          slot.slotIndex,
          weekKey,
          classId: slot.classId,
          teacherId: slot.teacherId
      );

      setState(() {
        _loadData();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Instructor removed successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error removing instructor: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reorderTeachers(int oldIndex, int newIndex) async {
    // Update the order locally
    setState(() {
      final Teacher teacher = _teachers.removeAt(oldIndex);
      _teachers.insert(newIndex, teacher);
    });

    // Update the order in Firebase
    try {
      await _updateTeachersOrder();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Teacher order updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // If there's an error, reload the original data
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating teacher order: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateTeachersOrder() async {
    // We need to add this method to the FirebaseService class
    // For now, we'll just assume it exists
    try {
      // Update the display order for each teacher
      for (int i = 0; i < _teachers.length; i++) {
        // Assuming each teacher object has a 'displayOrder' field
        // or we're storing the order in a separate collection
        await _firebaseService.updateTeacherDisplayOrder(_teachers[i].id, i);
      }
    } catch (e) {
      throw Exception("Failed to update teacher order: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Schedule Management"),
        backgroundColor: Colors.grey[500],
        actions: [
          // Week navigation controls
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goToPreviousWeek,
            tooltip: "Previous Week",
          ),
          Center(
            child: Text(
              _formatWeekDisplay(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _goToNextWeek,
            tooltip: "Next Week",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: "Refresh Data",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Loading schedule data..."),
          ],
        ),
      )
          : Container(
        color: Colors.grey[100],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TeacherList(
              teachers: _teachers,
              getAssignedHours: getAssignedHours,
              onTeacherAdded: (a, b, c) => _loadData(), // Ignore parameters since they are not used
              onTeacherEdited: _loadData,
              onTeacherDeleted: _loadData,
              onReorder: _reorderTeachers, // Add the reorder callback
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ScheduleGrid(
                  classes: _classes,
                  teachers: _teachers,
                  scheduleSlots: _scheduleSlots,
                  currentWeekStart: _currentWeekStart,
                  getAssignedHours: getAssignedHours,
                  onAssignTeacher: assignTeacherToSlot,
                  onRemoveTeacher: removeTeacherFromSlot,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}