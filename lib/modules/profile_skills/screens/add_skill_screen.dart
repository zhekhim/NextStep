import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../models/user_skill.dart';
import '../repositories/skill_repository.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key, this.skillRepository});

  final SkillRepository? skillRepository;

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  late final SkillRepository _repository;
  late Future<List<SkillCatalogItem>> _catalogFuture;
  SkillCatalogItem? _selectedSkill;
  String? _selectedLevel;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _repository = widget.skillRepository ?? SkillRepository();
    _catalogFuture = _repository.getSkillCatalog();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedSkill == null) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final addedSkill = await _repository.addSkill(
        skill: _selectedSkill!,
        level: _selectedLevel!,
      );
      if (mounted) Navigator.pop(context, addedSkill);
    } on DuplicateSkillException catch (error) {
      if (mounted) setState(() => _saveError = error.toString());
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError = 'Unable to save this skill. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Skill')),
      body: FutureBuilder<List<SkillCatalogItem>>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LoadError(
              onRetry: () {
                setState(() => _catalogFuture = _repository.getSkillCatalog());
              },
            );
          }
          final catalog = snapshot.data ?? const <SkillCatalogItem>[];
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<SkillCatalogItem>(
                  initialValue: _selectedSkill,
                  decoration: _decoration('Skill Name'),
                  dropdownColor: const Color(0xFF222222),
                  items: catalog
                      .map(
                        (skill) => DropdownMenuItem(
                          value: skill,
                          child: Text(skill.name),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _selectedSkill = value),
                  validator: (value) =>
                      value == null ? 'Skill cannot be empty.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey(_selectedSkill?.category),
                  readOnly: true,
                  initialValue:
                      _selectedSkill?.category ?? 'Select a skill first',
                  decoration: _decoration('Skill Category'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  decoration: _decoration('Skill Level'),
                  dropdownColor: const Color(0xFF222222),
                  items: UserSkill.levels
                      .map(
                        (level) =>
                            DropdownMenuItem(value: level, child: Text(level)),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _selectedLevel = value),
                  validator: Validators.skillLevel,
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
                        : const Text('Save Skill'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

InputDecoration _decoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: const Color(0xFF181818),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
);

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Unable to load the skill catalogue.'),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('Try Again')),
      ],
    ),
  );
}
