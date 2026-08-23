import 'package:flutter/material.dart';

import '../../career_intelligence/screens/career_detail_screen.dart';
import '../models/assessment_result.dart';
import '../models/career_match_result.dart';
import '../repositories/assessment_repository.dart';
import '../services/career_matching_service.dart';

class AssessmentResultScreen extends StatefulWidget {
  const AssessmentResultScreen({
    required this.result,
    required this.onRetake,
    super.key,
  });

  final AssessmentResult result;
  final VoidCallback onRetake;

  @override
  State<AssessmentResultScreen> createState() => _AssessmentResultScreenState();
}

class _AssessmentResultScreenState extends State<AssessmentResultScreen> {
  final AssessmentRepository _repository = AssessmentRepository();
  final CareerMatchingService _matchingService = CareerMatchingService();

  List<CareerMatchResult> _careerMatches = const [];
  bool _isLoadingMatches = false;
  String? _matchErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadCareerMatches();
  }

  Future<void> _loadCareerMatches() async {
    if (_isLoadingMatches) return;

    setState(() {
      _isLoadingMatches = true;
      _matchErrorMessage = null;
    });

    try {
      final profiles = await _repository.getCareerAssessmentProfiles();
      final matches = _matchingService.calculateMatches(
        assessmentResult: widget.result,
        careerProfiles: profiles,
      );
      if (!mounted) return;
      setState(() => _careerMatches = matches);
    } catch (error) {
      debugPrint('Unable to generate career matches: $error');
      if (mounted) {
        setState(() {
          _matchErrorMessage = 'Unable to generate career matches.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingMatches = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankedScores = widget.result.rankedScores;
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment Results')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Your Career Profile',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            for (final score in rankedScores)
              Card(
                child: ListTile(
                  title: Text(score.key),
                  trailing: Text(
                    '${score.value.round()}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Your Strongest Areas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            for (final area in widget.result.strongestAreas.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${area.$1 + 1}. ${area.$2}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            const SizedBox(height: 28),
            Text(
              'Top Career Matches',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildCareerMatches(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onRetake,
              child: const Text('Retake Assessment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerMatches() {
    if (_isLoadingMatches && _careerMatches.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Generating career matches...'),
            ],
          ),
        ),
      );
    }

    if (_matchErrorMessage != null && _careerMatches.isEmpty) {
      return Center(
        child: Column(
          children: [
            Text(_matchErrorMessage!),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoadingMatches ? null : _loadCareerMatches,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_careerMatches.isEmpty) {
      return const Text('No career matches are currently available.');
    }

    return Column(
      children: _careerMatches.indexed.map((indexedMatch) {
        final rank = indexedMatch.$1 + 1;
        final match = indexedMatch.$2;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$rank. ${match.career.careerName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${match.matchPercentage.round()}% Match'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CareerDetailScreen(career: match.career),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Explore Career'),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
