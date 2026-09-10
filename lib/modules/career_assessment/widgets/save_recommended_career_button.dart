import 'package:flutter/material.dart';

import '../../career_intelligence/models/career.dart';
import '../../career_intelligence/models/career_shortlist.dart';
import '../../career_intelligence/repositories/career_shortlist_repository.dart';

class SaveRecommendedCareerButton extends StatefulWidget {
  const SaveRecommendedCareerButton({
    super.key,
    required this.career,
    this.repository,
  });
  final Career career;
  final CareerShortlistRepository? repository;

  @override
  State<SaveRecommendedCareerButton> createState() =>
      _SaveRecommendedCareerButtonState();
}

class _SaveRecommendedCareerButtonState
    extends State<SaveRecommendedCareerButton> {
  bool _busy = false;

  Future<void> _save() async {
    if (_busy) return;
    final details = await showDialog<({String status, String? notes})>(
      context: context,
      builder: (_) => const _SaveDetailsDialog(),
    );
    if (details == null || !mounted) return;
    setState(() => _busy = true);
    var message = 'Career saved.';
    try {
      await (widget.repository ?? SupabaseCareerShortlistRepository())
          .addCareer(
            careerId: widget.career.id,
            status: details.status,
            notes: details.notes,
          );
    } on DuplicateCareerShortlistException {
      message =
          'This career is already saved. Open Manage Saved Careers to edit it.';
    } catch (error) {
      debugPrint('Unable to save recommended career: $error');
      message = 'Unable to save career. Please try again.';
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: _busy ? null : _save,
    icon: const Icon(Icons.bookmark_add_outlined),
    label: Text(_busy ? 'Saving...' : 'Save Career'),
  );
}

class _SaveDetailsDialog extends StatefulWidget {
  const _SaveDetailsDialog();
  @override
  State<_SaveDetailsDialog> createState() => _SaveDetailsDialogState();
}

class _SaveDetailsDialogState extends State<_SaveDetailsDialog> {
  final _form = GlobalKey<FormState>();
  final _notes = TextEditingController();
  String _status = 'Interested';

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Save Career'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Interest status *'),
              items: CareerShortlist.statuses
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _status = value!),
              validator: (value) =>
                  value == null ? 'Select an interest status.' : null,
            ),
            TextFormField(
              controller: _notes,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              validator: (value) => (value?.trim().length ?? 0) > 500
                  ? 'Use at most 500 characters.'
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate())
            Navigator.pop(context, (
              status: _status,
              notes: CareerShortlist.normalizeNotes(_notes.text),
            ));
        },
        child: const Text('Save'),
      ),
    ],
  );
}
