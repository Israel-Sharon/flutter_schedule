import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/firebase_service.dart';
import 'teacher_list_item.dart';
import '../dialogs/add_teacher_dialog.dart';

class TeacherList extends StatefulWidget {
  final List<Teacher> teachers;
  final Function(String) getAssignedHours;
  final Function(String, String?, int) onTeacherAdded;
  final VoidCallback onTeacherEdited;
  final VoidCallback onTeacherDeleted;
  final Function(int oldIndex, int newIndex)? onReorder;

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
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshTeachers();
  }

  void _refreshTeachers() {
    setState(() {
      _isLoading = true;
      teachersFuture = _firebaseService.getTeachers();
      teachersFuture.then((_) {
        setState(() {
          _isLoading = false;
        });
      }).catchError((error) {
        setState(() {
          _isLoading = false;
        });
      });
    });
  }

  // Calculate total hours and usage
  Map<String, dynamic> _calculateStats() {
    int totalMaxHours = 0;
    int totalAssignedHours = 0;

    for (var teacher in widget.teachers) {
      totalMaxHours += teacher.maxHoursPerWeek!;
      totalAssignedHours += widget.getAssignedHours(teacher.id) as int;
    }

    double usagePercentage = totalMaxHours > 0 ? (totalAssignedHours / totalMaxHours) : 0;

    return {
      'totalMaxHours': totalMaxHours,
      'totalAssignedHours': totalAssignedHours,
      'usagePercentage': usagePercentage,
    };
  }

  List<Teacher> _getFilteredTeachers() {
    if (_searchQuery.isEmpty) {
      return widget.teachers;
    }

    return widget.teachers.where((teacher) =>
        teacher.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTeachers = _getFilteredTeachers();
    final stats = _calculateStats();

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Teachers',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.teachers.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Stats panel
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Hours: ${stats['totalAssignedHours']} / ${stats['totalMaxHours']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(stats['usagePercentage'] * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: stats['usagePercentage'] > 0.9 ? Colors.red :
                        stats['usagePercentage'] > 0.7 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats['usagePercentage'].clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      stats['usagePercentage'] > 0.9 ? Colors.red :
                      stats['usagePercentage'] > 0.7 ? Colors.orange : Colors.green,
                    ),
                    minHeight: 10,
                  ),
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
                suffixIcon: _searchQuery.isNotEmpty ?
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ) : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
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
                      // Convert hours to int
                      final hoursValue = int.tryParse(hours.toString()) ?? 0;
                      final newTeacher = Teacher(
                        id: '',
                        name: name,
                        gender: gender,
                        maxHoursPerWeek: hoursValue,
                        photoUrl: null,
                      );

                      setState(() {
                        _isLoading = true;
                      });

                      _firebaseService.addTeacher(newTeacher, imageFile: imageFile).then((teacherId) {
                        if (teacherId != null) {
                          _refreshTeachers();
                          widget.onTeacherAdded(name, gender, hoursValue);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Teacher added successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }).catchError((error) {
                        setState(() {
                          _isLoading = false;
                        });
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
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredTeachers.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty ?
                      'No teachers added yet' :
                      'No teachers match "$_searchQuery"',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredTeachers.length,
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }

                  final originalIndex = widget.teachers.indexOf(filteredTeachers[oldIndex]);
                  final newOriginalIndex = widget.teachers.indexOf(filteredTeachers[newIndex]);

                  setState(() {
                    final teacher = widget.teachers.removeAt(originalIndex);
                    widget.teachers.insert(newOriginalIndex, teacher);
                  });

                  if (widget.onReorder != null) {
                    widget.onReorder!(originalIndex, newOriginalIndex);
                  }
                },
                itemBuilder: (context, index) {
                  final teacher = filteredTeachers[index];
                  return TeacherListItem(
                    key: ValueKey(teacher.id),
                    teacher: teacher,
                    index: index,
                    assignedHours: widget.getAssignedHours(teacher.id),
                    onEdit: () {
                      showDialog(
                        context: context,
                        builder: (context) => AddTeacherDialog(
                          initialName: teacher.name,
                          initialGender: teacher.gender,
                          initialHours: teacher.maxHoursPerWeek,
                          existingPhotoUrl: teacher.photoUrl,
                          onTeacherAdded: (name, gender, hours, imageFile) {
                            // Convert hours to int
                            final hoursValue = int.tryParse(hours.toString()) ?? 0;

                            final updatedTeacher = teacher.copyWith(
                              name: name,
                              gender: gender,
                              maxHoursPerWeek: hoursValue,
                            );

                            setState(() {
                              _isLoading = true;
                            });

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
                              setState(() {
                                _isLoading = false;
                              });
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
                    onDelete: () {
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
                                setState(() {
                                  _isLoading = true;
                                });
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
                                  setState(() {
                                    _isLoading = false;
                                  });
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
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}