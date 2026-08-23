import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../models/profile.dart';
import '../repositories/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
    this.profileRepository,
  });

  final Profile profile;
  final ProfileRepository? profileRepository;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProfileRepository _repository;
  late final TextEditingController _fullNameController;
  late final TextEditingController _universityController;
  late final TextEditingController _majorController;
  int? _studyYear;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _repository = widget.profileRepository ?? ProfileRepository();
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _universityController = TextEditingController(
      text: widget.profile.university,
    );
    _majorController = TextEditingController(text: widget.profile.major);
    _studyYear = int.tryParse(widget.profile.yearOfStudy ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _studyYear == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      await _repository.updateProfile(
        fullName: _fullNameController.text,
        university: _universityController.text,
        major: _majorController.text,
        studyYear: _studyYear!,
      );
      if (mounted) {
        Navigator.pop(
          context,
          widget.profile.copyWith(
            fullName: _fullNameController.text.trim(),
            university: _universityController.text.trim(),
            major: _majorController.text.trim(),
            yearOfStudy: _studyYear!.toString(),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Profile update failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _saveError = 'Unable to update your profile. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _fullNameController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('Full Name'),
              validator: (value) =>
                  Validators.requiredField(value, fieldName: 'Full name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.profile.email,
              readOnly: true,
              decoration: _decoration(
                'Email',
                helperText: 'Your login email cannot be changed here.',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _universityController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('University'),
              validator: (value) =>
                  Validators.requiredField(value, fieldName: 'University'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _majorController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('Major'),
              validator: (value) =>
                  Validators.requiredField(value, fieldName: 'Major'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _studyYear,
              decoration: _decoration('Year of Study'),
              dropdownColor: const Color(0xFF222222),
              items: List.generate(
                6,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('Year ${index + 1}'),
                ),
              ),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _studyYear = value),
              validator: (value) =>
                  value == null ? 'Year of study is required.' : null,
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 16),
              Text(
                _saveError!,
                style: const TextStyle(color: Color(0xFFFF4D4D)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _decoration(String label, {String? helperText}) {
  return InputDecoration(
    labelText: label,
    helperText: helperText,
    filled: true,
    fillColor: const Color(0xFF181818),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}
