import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../models/user_skill.dart';
import '../repositories/skill_repository.dart';

class EditSkillScreen extends StatefulWidget {
  const EditSkillScreen({
    super.key,
    required this.userSkill,
    this.skillRepository,
  });

  final UserSkill userSkill;
  final SkillRepository? skillRepository;

  @override
  State<EditSkillScreen> createState() => _EditSkillScreenState();
}

class _EditSkillScreenState extends State<EditSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  late final SkillRepository _repository;
  late Future<List<SkillCatalogItem>> _catalogFuture;
  late SkillCatalogItem _selectedSkill;
  late String _selectedLevel;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _repository = widget.skillRepository ?? SkillRepository();
    _selectedSkill = widget.userSkill.skill;
    _selectedLevel = widget.userSkill.level;
    _catalogFuture = _repository.getSkillCatalog();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final updatedSkill = await _repository.updateSkill(
        userSkill: widget.userSkill,
        skill: _selectedSkill,
        level: _selectedLevel,
      );
      if (mounted) Navigator.pop(context, updatedSkill);
    } on DuplicateSkillException catch (error) {
      if (mounted) setState(() => _saveError = error.toString());
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError = 'Unable to update this skill. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Skill')),
      body: FutureBuilder<List<SkillCatalogItem>>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(
                onPressed: () => setState(() {
                  _catalogFuture = _repository.getSkillCatalog();
                }),
                child: const Text('Try Again'),
              ),
            );
          }
          final catalog = snapshot.data ?? const <SkillCatalogItem>[];
          final selected = catalog.where(
            (item) => item.id == _selectedSkill.id,
          );
          if (selected.isNotEmpty) _selectedSkill = selected.first;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Autocomplete<SkillCatalogItem>(
                  initialValue: TextEditingValue(text: _selectedSkill.name),
                  displayStringForOption: (skill) => skill.name,
                  optionsBuilder: (value) {
                    final query = value.text.trim().toLowerCase();
                    return catalog.where((skill) {
                      return query.isEmpty ||
                          skill.name.toLowerCase().contains(query) ||
                          skill.category.toLowerCase().contains(query);
                    });
                  },
                  onSelected: (value) =>
                      setState(() => _selectedSkill = value),
                  fieldViewBuilder:
                      (context, controller, focusNode, onSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: !_saving,
                      decoration: _fieldDecoration('Search and select skill'),
                      onFieldSubmitted: (_) => onSubmitted(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey(_selectedSkill.category),
                  initialValue: _selectedSkill.category,
                  readOnly: true,
                  decoration: _fieldDecoration('Skill Category'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  decoration: _fieldDecoration('Skill Level'),
                  dropdownColor: const Color(0xFF222222),
                  items: UserSkill.levels
                      .map(
                        (level) =>
                            DropdownMenuItem(value: level, child: Text(level)),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedLevel = value);
                          }
                        },
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

InputDecoration _fieldDecoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: const Color(0xFF181818),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
);
