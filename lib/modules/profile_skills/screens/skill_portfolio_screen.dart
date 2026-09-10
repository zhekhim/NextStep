import 'package:flutter/material.dart';

import '../models/user_skill.dart';
import '../repositories/skill_repository.dart';
import '../widgets/skill_card.dart';
import 'add_skill_screen.dart';
import 'edit_skill_screen.dart';

class SkillPortfolioScreen extends StatefulWidget {
  const SkillPortfolioScreen({
    super.key,
    this.skillRepository,
    this.onSkillsChanged,
  });

  final SkillRepository? skillRepository;
  final ValueChanged<List<UserSkill>>? onSkillsChanged;

  @override
  State<SkillPortfolioScreen> createState() => _SkillPortfolioScreenState();
}

class _SkillPortfolioScreenState extends State<SkillPortfolioScreen> {
  late final SkillRepository _repository;
  late Future<List<UserSkill>> _skillsFuture;
  List<UserSkill> _latestSkills = const [];
  final _searchController = TextEditingController();
  String _category = 'All Categories';

  @override
  void initState() {
    super.initState();
    _repository = widget.skillRepository ?? SkillRepository();
    _skillsFuture = _repository.getUserSkills();
    _searchController.addListener(_refreshFilter);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshFilter)
      ..dispose();
    super.dispose();
  }

  void _refreshFilter() => setState(() {});

  Future<void> _reload() async {
    final refreshedSkills = _repository.getUserSkills();
    if (!mounted) return;
    setState(() => _skillsFuture = refreshedSkills);
    try {
      final skills = await refreshedSkills;
      if (!mounted) return;
      _latestSkills = skills;
      widget.onSkillsChanged?.call(skills);
    } catch (_) {
      // The FutureBuilder displays the load error and retry action.
    }
  }

  Future<void> _openAdd() async {
    final addedSkill = await Navigator.push<UserSkill>(
      context,
      MaterialPageRoute(
        builder: (_) => AddSkillScreen(skillRepository: _repository),
      ),
    );
    if (addedSkill != null && mounted) {
      final updatedSkills = [..._latestSkills, addedSkill]
        ..sort((a, b) => a.skill.name.compareTo(b.skill.name));
      setState(() {
        _latestSkills = updatedSkills;
        _skillsFuture = Future.value(updatedSkills);
      });
      widget.onSkillsChanged?.call(updatedSkills);
      _showMessage('Skill added successfully.');
    }
  }

  Future<void> _openEdit(UserSkill skill) async {
    final updatedSkill = await Navigator.push<UserSkill>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditSkillScreen(userSkill: skill, skillRepository: _repository),
      ),
    );
    if (updatedSkill != null && mounted) {
      final updatedSkills =
          _latestSkills
              .map((item) => item.id == updatedSkill.id ? updatedSkill : item)
              .toList()
            ..sort((a, b) => a.skill.name.compareTo(b.skill.name));
      setState(() {
        _latestSkills = updatedSkills;
        _skillsFuture = Future.value(updatedSkills);
      });
      widget.onSkillsChanged?.call(updatedSkills);
      _showMessage('Skill updated successfully.');
    }
  }

  Future<void> _confirmDelete(UserSkill skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Skill?'),
        content: Text(
          'Are you sure you want to remove ${skill.skill.name} from your skill portfolio?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4D4D),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.deleteSkill(skill.id);
      if (mounted) {
        final updatedSkills = _latestSkills
            .where((item) => item.id != skill.id)
            .toList();
        setState(() {
          _latestSkills = updatedSkills;
          _skillsFuture = Future.value(updatedSkills);
        });
        widget.onSkillsChanged?.call(updatedSkills);
        _showMessage('Skill removed successfully.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to delete this skill. Please try again.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Skills')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Skill'),
      ),
      body: FutureBuilder<List<UserSkill>>(
        future: _skillsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _PortfolioError(onRetry: _reload);
          }

          final allSkills = snapshot.data ?? const <UserSkill>[];
          _latestSkills = allSkills;
          final categories =
              allSkills.map((item) => item.skill.category).toSet().toList()
                ..sort();
          if (_category != 'All Categories' &&
              !categories.contains(_category)) {
            _category = 'All Categories';
          }
          final query = _searchController.text.trim().toLowerCase();
          final visibleSkills = allSkills.where((item) {
            final matchesSearch =
                query.isEmpty ||
                item.skill.name.toLowerCase().contains(query) ||
                item.skill.category.toLowerCase().contains(query);
            final matchesCategory =
                _category == 'All Categories' ||
                item.skill.category == _category;
            return matchesSearch && matchesCategory;
          }).toList();

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search skills...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: const Color(0xFF181818),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: const Color(0xFF181818),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ['All Categories', ...categories]
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 20),
                if (allSkills.isEmpty)
                  const _EmptySkills()
                else if (visibleSkills.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: Text('No skills match your search.')),
                  )
                else
                  ...visibleSkills.map(
                    (skill) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SkillCard(
                        userSkill: skill,
                        onEdit: () => _openEdit(skill),
                        onDelete: () => _confirmDelete(skill),
                      ),
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

class _EmptySkills extends StatelessWidget {
  const _EmptySkills();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 48),
    child: Column(
      children: [
        Icon(Icons.psychology_outlined, size: 44, color: Color(0xFFA8A8A8)),
        SizedBox(height: 12),
        Text('No skills added yet.', style: TextStyle(fontSize: 17)),
        SizedBox(height: 6),
        Text('Add a skill to start building your portfolio.'),
      ],
    ),
  );
}

class _PortfolioError extends StatelessWidget {
  const _PortfolioError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Unable to load your skills.'),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('Try Again')),
      ],
    ),
  );
}
