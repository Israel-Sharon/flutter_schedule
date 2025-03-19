// firebase_service.dart

import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher.dart';
import '../models/schedule_slot.dart';
import '../models/week_settings.dart';
import '../models/class.dart';
import 'package:universal_html/html.dart' as html;


class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  final CollectionReference _teachersCollection =
  FirebaseFirestore.instance.collection('teachers');
  final CollectionReference _scheduleCollection =
  FirebaseFirestore.instance.collection('schedule_slots');
  final CollectionReference _weekSettingsCollection =
  FirebaseFirestore.instance.collection('week_settings');
  final CollectionReference _classesCollection =
  FirebaseFirestore.instance.collection('classes');

  // ------------------ TEACHER METHODS ------------------

  // Get all teachers
// Also, update your getTeachers method to sort by displayOrder
  Future<List<Teacher>> getTeachers() async {
    try {
      final snapshot = await _firestore.collection('teachers').get();
      final teachers = snapshot.docs.map((doc) {
        final data = doc.data();
        return Teacher(
          id: doc.id,
          name: data['name'],
          gender: data['gender'],
          maxHoursPerWeek: data['maxHoursPerWeek'],
          photoUrl: data['photoUrl'],
          displayOrder: data['displayOrder'] ?? 999, // Default high value for teachers without order
        );
      }).toList();

      // Sort teachers by displayOrder
      teachers.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return teachers;
    } catch (e) {
      print('Error getting teachers: $e');
      return [];
    }
  }
  // Get a single teacher
  Future<Teacher?> getTeacher(String id) async {
    try {
      final DocumentSnapshot doc = await _teachersCollection.doc(id).get();

      if (doc.exists) {
        return Teacher.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting teacher: $e');
      return null;
    }
  }

  Future<String?> addTeacher(Teacher teacher, {dynamic imageFile}) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('teachers').doc();
      String? photoUrl;

      if (imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('teacher_photos')
            .child('${docRef.id}.jpg');

        if (kIsWeb) {
          // For web, imageFile will be Uint8List
          await storageRef.putData(imageFile);
        } else {
          // For mobile, imageFile will be File
          await storageRef.putFile(imageFile);
        }

        // Get the download URL
        photoUrl = await storageRef.getDownloadURL();
      }

      final teacherWithId = teacher.copyWith(id: docRef.id, photoUrl: photoUrl);
      await docRef.set(teacherWithId.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding teacher: $e');
      return null;
    }
  }

  Future<bool> updateTeacher(Teacher teacher, {dynamic photoFile}) async {
    try {
      String? photoUrl = teacher.photoUrl;

      if (photoFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('teacher_photos')
            .child('${teacher.id}.jpg');

        if (kIsWeb) {
          // For web, photoFile will be Uint8List
          await storageRef.putData(photoFile);
        } else {
          // For mobile, photoFile will be File
          await storageRef.putFile(photoFile);
        }

        // Get the download URL
        photoUrl = await storageRef.getDownloadURL();
      }

      final updatedTeacher = teacher.copyWith(photoUrl: photoUrl);

      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacher.id)
          .update(updatedTeacher.toMap());

      return true;
    } catch (e) {
      print('Error updating teacher: $e');
      return false;
    }
  }

  // Delete a teacher
  Future<bool> deleteTeacher(String teacherId) async {
    try {
      // Get the teacher to check if there's a photo to delete
      final Teacher? teacher = await getTeacher(teacherId);

      // Delete photo if it exists
      if (teacher != null && teacher.photoUrl != null && teacher.photoUrl!.isNotEmpty) {
        await _deleteTeacherPhoto(teacherId);
      }

      // Delete the document
      await _teachersCollection.doc(teacherId).delete();
      return true;
    } catch (e) {
      print('Error deleting teacher: $e');
      return false;
    }
  }

// Upload a teacher photo that works on both web and mobile
  Future<String?> _uploadTeacherPhoto(dynamic photoFile, String? teacherId) async {
    try {
      print("photoFile type: ${photoFile.runtimeType}"); // Debugging line

      final String fileName = teacherId != null
          ? 'teacher_${teacherId}.jpg'
          : 'teacher_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final Reference storageRef = _storage.ref().child('teacher_photos/$fileName');

      late UploadTask uploadTask;

      if (kIsWeb) {
        if (photoFile is html.File) {
          // Handle html.File for web
          final reader = html.FileReader();
          reader.readAsArrayBuffer(photoFile);
          await reader.onLoad.first;
          final Uint8List bytes = reader.result as Uint8List;

          uploadTask = storageRef.putData(bytes);
        } else if (photoFile is Uint8List) {
          // Handle raw bytes
          uploadTask = storageRef.putData(photoFile);
        } else {
          throw UnsupportedError("Unsupported file type for web: ${photoFile.runtimeType}");
        }
      } else {
        // Handle mobile/desktop
        if (photoFile is File) {
          uploadTask = storageRef.putFile(photoFile);
        } else if (photoFile is Uint8List) {
          uploadTask = storageRef.putData(photoFile);
        } else {
          throw UnsupportedError("Unsupported file type for mobile: ${photoFile.runtimeType}");
        }
      }

      // Wait for upload completion
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading teacher photo: $e');
      return null;
    }
  }

  Future<bool> updateTeacherDisplayOrder(String teacherId, int displayOrder) async {
    try {
      await _firestore.collection('teachers').doc(teacherId).update({
        'displayOrder': displayOrder,
      });
      return true;
    } catch (e) {
      print('Error updating teacher display order: $e');
      return false;
    }
  }

  // Delete a teacher photo
  Future<bool> _deleteTeacherPhoto(String teacherId) async {
    try {
      final Reference storageRef = _storage.ref().child('teacher_photos/teacher_$teacherId.jpg');
      await storageRef.delete();
      return true;
    } catch (e) {
      print('Error deleting teacher photo: $e');
      return false;
    }
  }

  // Search for teachers by name or subject
  Future<List<Teacher>> searchTeachers(String query) async {
    try {
      // Convert query to lowercase for case-insensitive search
      final String searchQuery = query.toLowerCase();

      // Get all teachers (for a small app, this is simpler than complex queries)
      final List<Teacher> allTeachers = await getTeachers();

      // Filter locally
      return allTeachers.where((teacher) {
        return teacher.name.toLowerCase().contains(searchQuery);
        //     teacher.subject.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Error searching teachers: $e');
      return [];
    }
  }

  // ------------------ SCHEDULE METHODS ------------------

  // Get schedule slots for a specific week
  Future<List<ScheduleSlot>> getScheduleSlotsByWeek(String weekId) async {
    try {
      final QuerySnapshot snapshot = await _scheduleCollection
          .where('weekKey', isEqualTo: weekId)
          .get();

      return snapshot.docs.map((doc) {
        return ScheduleSlot.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error getting schedule slots: $e');
      return [];
    }
  }

  // Assign a teacher to a slot
  Future<void> assignTeacherToSlot(
      String classId,
      String dayIndex,
      String slotIndex,
      String teacherId,
      String weekKey) async {
    try {
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
    } catch (e) {
      print('Error assigning teacher to slot: $e');
      throw e; // Re-throw to handle in the UI
    }
  }

  // Remove a teacher from a slot
  Future<void> removeTeacherFromSlot(
      String dayIndex,
      String slotIndex,
      String weekKey,
      {String? teacherId, String? classId}) async {
    try {
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
    } catch (e) {
      print('Error removing teacher from slot: $e');
      throw e; // Re-throw to handle in the UI
    }
  }

  // Get a single schedule slot
  Future<ScheduleSlot?> getScheduleSlot(String id) async {
    try {
      final DocumentSnapshot doc = await _scheduleCollection.doc(id).get();

      if (doc.exists) {
        return ScheduleSlot.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting schedule slot: $e');
      return null;
    }
  }

  // Get schedule slots by teacher
  Future<List<ScheduleSlot>> getScheduleSlotsByTeacher(String teacherId) async {
    try {
      final QuerySnapshot snapshot = await _scheduleCollection
          .where('teacherId', isEqualTo: teacherId)
          .get();

      return snapshot.docs.map((doc) {
        return ScheduleSlot.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error getting teacher schedule slots: $e');
      return [];
    }
  }

  // ------------------ WEEK SETTINGS METHODS ------------------

  // Get all week settings
  Future<List<WeekSettings>> getWeekSettings() async {
    try {
      final QuerySnapshot snapshot = await _weekSettingsCollection.get();

      return snapshot.docs.map((doc) {
        return WeekSettings.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error getting week settings: $e');
      return [];
    }
  }

  // Get current or active week settings
  Future<WeekSettings?> getCurrentWeekSettings() async {
    try {
      final QuerySnapshot snapshot = await _weekSettingsCollection
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return WeekSettings.fromMap(
            snapshot.docs.first.id,
            snapshot.docs.first.data() as Map<String, dynamic>
        );
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting current week settings: $e');
      return null;
    }
  }

  // Add new week settings
  Future<String?> addWeekSettings(WeekSettings settings) async {
    try {
      final DocumentReference docRef = await _weekSettingsCollection.add(settings.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding week settings: $e');
      return null;
    }
  }

  // Update week settings
  Future<bool> updateWeekSettings(WeekSettings settings) async {
    try {
      await _weekSettingsCollection.doc(settings.id).update(settings.toMap());
      return true;
    } catch (e) {
      print('Error updating week settings: $e');
      return false;
    }
  }

  // ------------------ CLASS METHODS ------------------

  // Get all classes
  Future<List<Class>> getClasses() async {
    try {
      final QuerySnapshot snapshot = await _classesCollection.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Class(
          id: doc.id,
          name: data['name'] ?? 'Unnamed Class',
          description: data['description'] ?? '',
          academicLevel: data['academicLevel'] ?? 'Unspecified',
        );
      }).toList();
    } catch (e) {
      print('Error getting classes: $e');
      return [];
    }
  }

  // Get a single class
  Future<Class?> getClass(String id) async {
    try {
      final DocumentSnapshot doc = await _classesCollection.doc(id).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Class(
          id: doc.id,
          name: data['name'] ?? 'Unnamed Class',
          description: data['description'] ?? '',
          academicLevel: data['academicLevel'] ?? 'Unspecified',
        );
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting class: $e');
      return null;
    }
  }

  // Add a new class
  Future<String?> addClass(Class classObj) async {
    try {
      final Map<String, dynamic> classData = {
        'name': classObj.name,
        'description': classObj.description,
        'academicLevel': classObj.academicLevel,
      };

      final DocumentReference docRef = await _classesCollection.add(classData);
      return docRef.id;
    } catch (e) {
      print('Error adding class: $e');
      return null;
    }
  }

  // Update an existing class
  Future<bool> updateClass(Class classObj) async {
    try {
      final Map<String, dynamic> classData = {
        'name': classObj.name,
        'description': classObj.description,
        'academicLevel': classObj.academicLevel,
      };

      await _classesCollection.doc(classObj.id).update(classData);
      return true;
    } catch (e) {
      print('Error updating class: $e');
      return false;
    }
  }

  // Delete a class
  Future<bool> deleteClass(String classId) async {
    try {
      await _classesCollection.doc(classId).delete();
      return true;
    } catch (e) {
      print('Error deleting class: $e');
      return false;
    }
  }
}