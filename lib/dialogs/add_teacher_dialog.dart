import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class AddTeacherDialog extends StatefulWidget {
  final Function(String, String, int, File?) onTeacherAdded;
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

  // Store the file and bytes
  File? _imageFile;
  Uint8List? _imageBytes;
  bool _hasExistingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedGender = widget.initialGender ?? 'male';
    _maxHoursPerWeek = widget.initialHours ?? 20;
    _hasExistingImage = widget.existingPhotoUrl != null && widget.existingPhotoUrl!.isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageBytes = bytes;
        _hasExistingImage = false; // We're replacing any existing image
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onTeacherAdded(
          _nameController.text.trim(),
          _selectedGender,
          _maxHoursPerWeek,
          _imageFile // Pass the image file to the callback
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
              // Image picker widget with support for existing or new image
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: _imageBytes != null
                      ? ClipOval(
                    child: Image.memory(
                      _imageBytes!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                      : _hasExistingImage
                      ? ClipOval(
                    child: Image.network(
                      widget.existingPhotoUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey[400],
                        );
                      },
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
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Teacher Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter teacher name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Gender dropdown
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
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value ?? 'male';
                  });
                },
              ),
              const SizedBox(height: 16),
              // Hours field
              TextFormField(
                initialValue: _maxHoursPerWeek.toString(),
                decoration: const InputDecoration(
                  labelText: 'Max Hours per Week',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter max hours';
                  }
                  final hours = int.tryParse(value);
                  if (hours == null || hours < 1 || hours > 40) {
                    return 'Hours must be between 1 and 40';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _maxHoursPerWeek = int.tryParse(value) ?? 20;
                  });
                },
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

// Extension method to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}