import 'package:flutter/material.dart';

import '../../career_goals/models/career_goal.dart';
import '../../career_goals/repositories/career_goal_repository.dart';
import '../../career_goals/screens/career_goal_screen.dart';
import '../models/career.dart';
import '../models/career_skill.dart';
import '../models/career_shortlist.dart';
import '../repositories/career_repository.dart';
import '../repositories/career_shortlist_repository.dart';
import 'edit_interested_career_screen.dart';

class CareerDetailScreen extends StatefulWidget {
  const CareerDetailScreen({
    required this.career,
    super.key,
    this.loadSkills,
    this.shortlistRepository,
  });

  final Career career;
  final Future<List<CareerSkill>> Function(String careerId)? loadSkills;
  final CareerShortlistRepository? shortlistRepository;

  @override
  State<CareerDetailScreen> createState() => _CareerDetailScreenState();
}

class _CareerDetailScreenState extends State<CareerDetailScreen> {
  final CareerRepository _repository = CareerRepository();
  final CareerGoalRepository _goalRepository = CareerGoalRepository();
  late final CareerShortlistRepository _shortlistRepository;

  List<CareerSkill> _skills = const [];
  bool _isLoading = false;
  bool _isSavingGoal = false;
  bool _isCheckingShortlist = false;
  bool _isSavingShortlist = false;
  CareerShortlist? _shortlist;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _shortlistRepository =
        widget.shortlistRepository ?? SupabaseCareerShortlistRepository();
    _loadSkills();
    _checkShortlist();
  }

  Future<void> _checkShortlist() async {
    setState(() => _isCheckingShortlist = true);
    try {
      final shortlist = await _shortlistRepository.getShortlistForCareer(
        widget.career.id,
      );
      if (mounted) setState(() => _shortlist = shortlist);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to check interested career status.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingShortlist = false);
    }
  }

  Future<void> _handleShortlist() async {
    if (_isCheckingShortlist || _isSavingShortlist) return;
    final existing = _shortlist;
    if (existing != null) {
      final result = await Navigator.of(context).push<Object>(
        MaterialPageRoute<Object>(
          builder: (_) => EditInterestedCareerScreen(
            shortlist: existing,
            repository: _shortlistRepository,
          ),
        ),
      );
      if (!mounted || result == null) return;
      setState(() => _shortlist = result is CareerShortlist ? result : null);
      return;
    }

    setState(() => _isSavingShortlist = true);
    try {
      final saved = await _shortlistRepository.addCareer(
        careerId: widget.career.id,
      );
      if (!mounted) return;
      setState(() => _shortlist = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Career saved to interested careers.')),
      );
    } on DuplicateCareerShortlistException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
        await _checkShortlist();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save this career. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingShortlist = false);
    }
  }

  Future<void> _loadSkills() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final skills =
          await (widget.loadSkills ?? _repository.getSkillsForCareer)(
            widget.career.id,
          );
      if (!mounted) return;
      final seenSkillIds = <String>{};
      final uniqueSkills = skills
          .where((skill) => seenSkillIds.add(skill.skillId))
          .toList(growable: false);
      setState(() => _skills = uniqueSkills);
    } catch (error) {
      debugPrint('Unable to load required skills: $error');
      if (mounted) {
        setState(() => _errorMessage = 'Unable to load required skills.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setAsGoal() async {
    if (_isSavingGoal) return;

    setState(() => _isSavingGoal = true);
    try {
      final existingGoal = await _goalRepository.getGoal();
      if (!mounted) return;

      if (existingGoal?.career.id == widget.career.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This career is already your goal.')),
        );
        return;
      }

      if (existingGoal != null) {
        final replace =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Replace career goal?'),
                content: Text(
                  'Your current goal, ${existingGoal.career.name}, will be replaced with ${widget.career.careerName}.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Replace Goal'),
                  ),
                ],
              ),
            ) ??
            false;
        if (!replace || !mounted) return;
      }

      await _goalRepository.saveGoal(
        career: CareerOption(
          id: widget.career.id,
          name: widget.career.careerName,
          category: widget.career.category,
        ),
        preferredState: existingGoal?.preferredState,
        targetGraduationYear: existingGoal?.targetGraduationYear,
        expectedSalary: existingGoal?.expectedSalary,
      );
      if (!mounted) return;

      if (existingGoal != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.career.careerName} is now your career goal.',
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const CareerGoalScreen()),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.career.careerName} is now your career goal.'),
        ),
      );
    } catch (error) {
      debugPrint('Unable to set career goal: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to set this career as your goal. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingGoal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final career = widget.career;
    return Scaffold(
      appBar: AppBar(title: Text(career.careerName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              career.careerName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Category'),
            const SizedBox(height: 6),
            Text(career.category),
            const SizedBox(height: 24),
            const _SectionLabel('About This Career'),
            const SizedBox(height: 6),
            Text(career.description),
            const SizedBox(height: 24),
            const _SectionLabel('Required Skills'),
            const SizedBox(height: 12),
            _buildSkills(),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isCheckingShortlist || _isSavingShortlist
                  ? null
                  : _handleShortlist,
              icon: _isCheckingShortlist || _isSavingShortlist
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _shortlist == null
                          ? Icons.bookmark_add_outlined
                          : Icons.bookmark,
                    ),
              label: Text(
                _isCheckingShortlist
                    ? 'Checking Interested Careers...'
                    : _isSavingShortlist
                    ? 'Saving...'
                    : _shortlist == null
                    ? 'Save to Interested Careers'
                    : 'Saved to Interested Careers',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isSavingGoal ? null : _setAsGoal,
              icon: _isSavingGoal
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flag_outlined),
              label: Text(
                _isSavingGoal
                    ? 'Setting Career Goal...'
                    : 'Set This Career as Goal',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkills() {
    if (_isLoading && _skills.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading required skills...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && _skills.isEmpty) {
      return Column(
        children: [
          Text(_errorMessage!),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _loadSkills,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_skills.isEmpty) {
      return const Text('No required skills available for this career.');
    }

    return Column(
      children: _skills
          .map(
            (skill) => Card(
              child: ListTile(
                title: Text(skill.skillName),
                subtitle: Text(skill.category),
                trailing: Text(skill.requiredLevel),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
