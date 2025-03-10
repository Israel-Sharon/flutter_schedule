import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher.dart';
import '../models/schedule_slot.dart';
import '../models/week_settings.dart';
import '../models/class.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Teacher methods
  Future<List<Teacher>> getTeachers() async {
    final snapshot = await _firestore.collection('teachers').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Teacher(
        id: doc.id,
        name: data['name'] ?? 'Unnamed',
        gender: data['gender'] ?? 'male',
        maxHoursPerWeek: data['maxHoursPerWeek'] ?? 20,
      );
    }).toList();
  }

  Future<void> addTeacher(String name, String gender, int maxHoursPerWeek) async {
    await _firestore.collection('teachers').add({
      'name': name,
      'gender': gender,
      'maxHoursPerWeek': maxHoursPerWeek,
    });
  }

  Future<void> updateTeacher(String id, String name, String gender, int maxHoursPerWeek) async {
    await _firestore.collection('teachers').doc(id).update({
      'name': name,
      'gender': gender,
      'maxHoursPerWeek': maxHoursPerWeek,
    });
  }

  Future<void> deleteTeacher(String id) async {
    // Delete the teacher
    await _firestore.collection('teachers').doc(id).delete();

    // Also delete all schedule slots assigned to this teacher
    final slotsToDelete = await _firestore
        .collection('schedule_slots')
        .where('teacherId', isEqualTo: id)
        .get();

    for (var doc in slotsToDelete.docs) {
      await _firestore.collection('schedule_slots').doc(doc.id).delete();
    }
  }

  Future<Teacher?> getTeacherById(String id) async {
    if (id.isEmpty) return null;

    final doc = await _firestore.collection('teachers').doc(id).get();
    if (doc.exists) {
      final data = doc.data();
      return Teacher(
        id: doc.id,
        name: data!['name'] ?? 'Unnamed',
        gender: data['gender'] ?? 'male',
        maxHoursPerWeek: data['maxHoursPerWeek'] ?? 20,
      );
    }
    return null;
  }

  // Class methods
  Future<List<Class>> getClasses() async {
    final snapshot = await _firestore.collection('classes').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Class(
        id: doc.id,
        name: data['name'] ?? 'Unnamed Class',
        description: data['description'] ?? '',
        academicLevel: data['academicLevel'] ?? 'Unspecified',
      );
    }).toList();
  }

  Future<void> addClass(String name, String description, String academicLevel) async {
    await _firestore.collection('classes').add({
      'name': name,
      'description': description,
      'academicLevel': academicLevel,
    });
  }

  Future<void> updateClass(String id, String name, String description, String academicLevel) async {
    await _firestore.collection('classes').doc(id).update({
      'name': name,
      'description': description,
      'academicLevel': academicLevel,
    });
  }

  Future<void> deleteClass(String id) async {
    // Delete the class
    await _firestore.collection('classes').doc(id).delete();

    // Also delete all schedule slots associated with this class
    final slotsToDelete = await _firestore
        .collection('schedule_slots')
        .where('classId', isEqualTo: id)
        .get();

    for (var doc in slotsToDelete.docs) {
      await _firestore.collection('schedule_slots').doc(doc.id).delete();
    }
  }

  // Schedule methods
  Future<void> assignTeacherToSlot(
      String classId,
      String dayIndex,
      String slotIndex,
      String teacherId,
      String weekKey) async {
    // Check if there's already a slot for this class/day/hour/week
    final existingSlots = await _firestore
        .collection('schedule_slots')
        .where('classId', isEqualTo: classId)
        .where('dayIndex', isEqualTo: dayIndex)
        .where('slotIndex', isEqualTo: slotIndex)
        .where('weekKey', isEqualTo: weekKey)
        .get();

    // If a slot exists, update it
    if (existingSlots.docs.isNotEmpty) {
      await _firestore.collection('schedule_slots').doc(existingSlots.docs.first.id).update({
        'teacherId': teacherId,
      });
    } else {
      // Otherwise, create a new slot
      await _firestore.collection('schedule_slots').add({
        'classId': classId,
        'dayIndex': dayIndex,
        'slotIndex': slotIndex,
        'teacherId': teacherId,
        'weekKey': weekKey,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> removeTeacherFromSlot(
      String dayIndex,
      String slotIndex,
      String weekKey,
      {String? teacherId,
        String? classId}) async {

    var query = _firestore
        .collection('schedule_slots')
        .where('dayIndex', isEqualTo: dayIndex)
        .where('slotIndex', isEqualTo: slotIndex)
        .where('weekKey', isEqualTo: weekKey);

    if (teacherId != null) {
      query = query.where('teacherId', isEqualTo: teacherId);
    }

    if (classId != null) {
      query = query.where('classId', isEqualTo: classId);
    }

    final slotsToDelete = await query.get();

    for (var doc in slotsToDelete.docs) {
      await _firestore.collection('schedule_slots').doc(doc.id).delete();
    }
  }

  Future<List<ScheduleSlot>> getScheduleSlotsByWeek(String weekKey) async {
    final snapshot = await _firestore
        .collection('schedule_slots')
        .where('weekKey', isEqualTo: weekKey)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ScheduleSlot(
        id: doc.id,
        dayIndex: data['dayIndex'] ?? '',
        slotIndex: data['slotIndex'] ?? '',
        classId: data['classId'] ?? '',
        teacherId: data['teacherId'] ?? '',
        weekKey: data['weekKey'] ?? '',
      );
    }).toList();
  }

  // Week settings methods
  Future<List<WeekSettings>> getWeekSettings() async {
    final snapshot = await _firestore.collection('week_settings').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return WeekSettings(
        id: doc.id,
        weekKey: data['weekKey'] ?? '',
        isDefinitive: data['isDefinitive'] ?? false,
      );
    }).toList();
  }

  Future<void> setWeekDefinitiveStatus(String weekKey, bool isDefinitive) async {
    final query = await _firestore
        .collection('week_settings')
        .where('weekKey', isEqualTo: weekKey)
        .get();

    if (query.docs.isEmpty) {
      await _firestore.collection('week_settings').add({
        'weekKey': weekKey,
        'isDefinitive': isDefinitive,
      });
    } else {
      await _firestore.collection('week_settings').doc(query.docs.first.id).update({
        'isDefinitive': isDefinitive,
      });
    }
  }
}