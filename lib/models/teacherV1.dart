import 'package:flutter/material.dart';

class Teacher {
  final String id;
  final String name;
  final String gender;
  final int maxHoursPerWeek;
  final Color color; // Add this property

  Teacher({
    required this.id,
    required this.name,
    required this.gender,
    required this.maxHoursPerWeek,
    Color? color, // Initialize in the constructor

  }) : color = color ?? Colors.grey; // Default color is Grey;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'maxHoursPerWeek': maxHoursPerWeek,
      'color': color ,
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'],
      name: map['name'],
      gender: map['gender'],
      maxHoursPerWeek: map['maxHoursPerWeek'],
      color: map['color']
    );
  }
}


class AddTeacherDialog extends StatefulWidget {
  final Function(String name, String subject, Color color) onTeacherAdded;

  const AddTeacherDialog({super.key, required this.onTeacherAdded});

  @override
  _AddTeacherDialogState createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<AddTeacherDialog> {
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  Color _selectedColor = Colors.blue; // Default color


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Teachers"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Teacher Name"),
          ),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(labelText: "Subject"),
          ),
          const SizedBox(height: 10),
          const Text("Select Color"),
          Wrap(
            spacing: 8.0,
            children: [
              for (var color in [Colors.red, Colors.green, Colors.blue, Colors.purple])
                GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onTeacherAdded(
                _nameController.text,
                _subjectController.text,
                _selectedColor,
              );
              Navigator.pop(context);
            }
          },
          child: const Text("Add"),
        ),
      ],
    );
  }
}
