import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'package:image_picker/image_picker.dart'; // Assuming you have this already
import '../models/teacher.dart';
import '../services/firebase_service.dart';
import '../dialogs/add_teacher_dialog.dart';
import '../dialogs/edit_teacher_dialog.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddTeacherDialog extends StatefulWidget {
  final Function(String, String, int, dynamic) onTeacherAdded;
  final String? initialName;
  final String? initialGender;
  final int? initialHours;
  final String? existingPhotoUrl;

  const AddTeacherDialog({
    super.key,
    required this.onTeacherAdded,
    this.initialName,
    this.initialGender,
    this.initialHours,
    this.existingPhotoUrl,
  });

  @override
  _AddTeacherDialogState createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<AddTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedGender;
  late int _maxHoursPerWeek;
  dynamic _selectedImage; // Can be File or Uint8List depending on platform

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedGender = widget.initialGender ?? 'male';
    _maxHoursPerWeek = widget.initialHours ?? 20;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      await input.onChange.first;
      if (input.files!.isNotEmpty) {
        final file = input.files![0];
        final reader = html.FileReader();

        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;

        setState(() {
          _selectedImage = reader.result as Uint8List; // Store as Uint8List
        });
      }
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _selectedImage = File(pickedImage.path);
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      dynamic imageToSend;

      if (kIsWeb && _selectedImage is Uint8List) {
        imageToSend = _selectedImage; // Keep as Uint8List for web (Firebase handles this)
      } else if (!kIsWeb && _selectedImage is File) {
        imageToSend = _selectedImage; // Keep as File for mobile
      } else {
        imageToSend = null; // No image selected
      }

      widget.onTeacherAdded(
        _nameController.text.trim(),
        _selectedGender,
        _maxHoursPerWeek,
        _selectedImage, // Correct type
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName != null ? "Edit Teacher" : "Add New Teacher"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: _selectedImage != null
                      ? ClipOval(
                    child: kIsWeb
                        ? Image.memory(
                      _selectedImage as Uint8List, // Use stored Uint8List
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                        : Image.file(
                      _selectedImage as File,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Teacher Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter teacher name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                value: _selectedGender,
                items: ['male', 'female']
                    .map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender.capitalize()),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value ?? 'male'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _maxHoursPerWeek.toString(),
                decoration: const InputDecoration(
                  labelText: 'Max Hours per Week',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final hours = int.tryParse(value ?? '');
                  if (hours == null || hours < 1 || hours > 40) {
                    return 'Hours must be between 1 and 40';
                  }
                  return null;
                },
                onChanged: (value) => setState(() => _maxHoursPerWeek = int.tryParse(value) ?? 20),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: Text(widget.initialName != null ? "Save Changes" : "Add Teacher"),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
  }
}
