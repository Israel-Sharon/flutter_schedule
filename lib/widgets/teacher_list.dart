import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/firebase_service.dart';
import '../dialogs/add_teacher_dialog.dart';
import '../dialogs/edit_teacher_dialog.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TeacherList extends StatefulWidget {
  final List<Teacher> teachers;
  final Function(String) getAssignedHours;
  final Function(dynamic, dynamic, dynamic) onTeacherAdded;
  final VoidCallback onTeacherEdited;
  final VoidCallback onTeacherDeleted;
  final Function(int oldIndex, int newIndex)? onReorder; // New callback for reordering

  const TeacherList({
    Key? key,
    required this.teachers,
    required this.getAssignedHours,
    required this.onTeacherAdded,
    required this.onTeacherEdited,
    required this.onTeacherDeleted,
    this.onReorder,
  }) : super(key: key);

  @override
  _TeacherListState createState() => _TeacherListState();
}

class _TeacherListState extends State<TeacherList> {
  late Future<List<Teacher>> teachersFuture;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _refreshTeachers();
  }

  void _refreshTeachers() {
    setState(() {
      teachersFuture = _firebaseService.getTeachers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue[100],
            child: const Row(
              children: [
                Icon(Icons.people),
                SizedBox(width: 8),
                Text(
                  'Teachers',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search teachers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                // Implement search functionality
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddTeacherDialog(
                    onTeacherAdded: (name, gender, hours, imageFile) {
                      final newTeacher = Teacher(
                        id: '',
                        name: name,
                        gender: gender,
                        maxHoursPerWeek: hours,
                        photoUrl: null,
                      );
                      _firebaseService.addTeacher(newTeacher, imageFile: imageFile).then((teacherId) {
                        if (teacherId != null) {
                          _refreshTeachers();
                          widget.onTeacherAdded(name, gender, hours);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Teacher added successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding teacher: $error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      });
                    },
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Teacher'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.teachers.length,
              onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
              newIndex -= 1;
              }

              setState(() {
              final teacher = widget.teachers.removeAt(oldIndex);
              widget.teachers.insert(newIndex, teacher);
              });

              if (widget.onReorder != null) {
              widget.onReorder!(oldIndex, newIndex);
              }
              },

              itemBuilder: (context, index) {
                final teacher = widget.teachers[index];
                return _buildTeacherListItem(teacher, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherListItem(Teacher teacher, int index) {
    final assignedHours = widget.getAssignedHours(teacher.id);

    return Card(
      key: ValueKey(teacher.id), // Required for ReorderableListView
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(teacher.name),
        subtitle: Text('Hours assigned: $assignedHours'),
        leading: ReorderableDragStartListener( // Enable dragging
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddTeacherDialog(
                    initialName: teacher.name,
                    initialGender: teacher.gender,
                    initialHours: teacher.maxHoursPerWeek,
                    existingPhotoUrl: teacher.photoUrl,
                    onTeacherAdded: (name, gender, hours, imageFile) {
                      final updatedTeacher = teacher.copyWith(
                        name: name,
                        gender: gender,
                        maxHoursPerWeek: hours,
                      );
                      _firebaseService.updateTeacher(updatedTeacher, photoFile: imageFile).then((success) {
                        if (success) {
                          _refreshTeachers();
                          widget.onTeacherEdited();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Teacher updated successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating teacher: $error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      });
                    },
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Show delete confirmation dialog
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
                          _firebaseService.deleteTeacher(teacher.id).then((success) {
                            if (success) {
                              _refreshTeachers();
                              widget.onTeacherDeleted();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Teacher deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error deleting teacher: $error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}