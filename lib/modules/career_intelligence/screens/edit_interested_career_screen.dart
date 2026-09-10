import 'package:flutter/material.dart';

import '../models/career_shortlist.dart';
import '../repositories/career_shortlist_repository.dart';

class EditInterestedCareerScreen extends StatefulWidget {
  const EditInterestedCareerScreen({
    required this.shortlist,
    required this.repository,
    super.key,
  });

  final CareerShortlist shortlist;
  final CareerShortlistRepository repository;

  @override
  State<EditInterestedCareerScreen> createState() =>
      _EditInterestedCareerScreenState();
}

class _EditInterestedCareerScreenState
    extends State<EditInterestedCareerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _notesController;
  String? _priority;
  late String _status;
  bool _isSaving = false;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _priority = widget.shortlist.priority;
    _status = widget.shortlist.status;
    _notesController = TextEditingController(text: widget.shortlist.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || _isRemoving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updated = await widget.repository.updateCareer(
        shortlistId: widget.shortlist.id,
        priority: _priority,
        notes: _notesController.text,
        status: _status,
      );
      if (mounted) Navigator.pop(context, updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save changes. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _remove() async {
    if (_isSaving || _isRemoving) return;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove interested career?'),
            content: Text(
              '${widget.shortlist.career.careerName} will be removed from your interested careers.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _isRemoving = true);
    try {
      await widget.repository.removeCareer(widget.shortlist.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to remove this career.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Interested Career')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.shortlist.career.careerName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Interest status *',
                  border: OutlineInputBorder(),
                ),
                items: CareerShortlist.statuses
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                validator: (value) =>
                    value == null ? 'Select an interest status.' : null,
                onChanged: _isSaving || _isRemoving
                    ? null
                    : (value) => setState(() => _status = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('None')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                ],
                onChanged: (value) => setState(() => _priority = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add an optional note',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 4,
                maxLines: 6,
                maxLength: 500,
                validator: (value) => value != null && value.trim().length > 500
                    ? 'Notes cannot exceed 500 characters.'
                    : null,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _isSaving || _isRemoving ? null : _save,
                child: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isSaving || _isRemoving ? null : _remove,
                child: Text(
                  _isRemoving
                      ? 'Removing...'
                      : 'Remove from Interested Careers',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
