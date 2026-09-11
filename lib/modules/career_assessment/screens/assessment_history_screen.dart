import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/assessment_profile.dart';
import '../repositories/assessment_profile_repository.dart';

class AssessmentHistoryScreen extends StatefulWidget {
  const AssessmentHistoryScreen({super.key, this.loadHistory});

  final Future<List<AssessmentProfile>> Function()? loadHistory;

  @override
  State<AssessmentHistoryScreen> createState() =>
      _AssessmentHistoryScreenState();
}

class _AssessmentHistoryScreenState extends State<AssessmentHistoryScreen> {
  static const _secondary = AppColors.textSecondary;
  static const _dimensionNames = {
    'R': 'Realistic',
    'I': 'Investigative',
    'A': 'Artistic',
    'S': 'Social',
    'E': 'Enterprising',
    'C': 'Conventional',
  };

  List<AssessmentProfile> _history = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history =
          await (widget.loadHistory?.call() ??
              AssessmentProfileRepository().getHistory());
      if (mounted) setState(() => _history = history);
    } catch (error) {
      debugPrint('Unable to load assessment history: $error');
      if (mounted) {
        setState(() => _error = 'Unable to load assessment history.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment History')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadHistory,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No completed assessments yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondary),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _HistoryCard(
          profile: _history[index],
          dimensionNames: _dimensionNames,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.profile, required this.dimensionNames});

  final AssessmentProfile profile;
  final Map<String, String> dimensionNames;

  @override
  Widget build(BuildContext context) {
    final result = profile.toResult();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairlineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.riasecCode,
                  style: const TextStyle(
                    color: AppColors.violetLight,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
              ),
              Text(
                _formatDate(profile.createdAt.toLocal()),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final score in result.rankedScores) ...[
            Row(
              children: [
                SizedBox(
                  width: 105,
                  child: Text(
                    dimensionNames[score.dimension] ?? score.dimension,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: score.percentage / 100,
                    minHeight: 6,
                    color: AppColors.primaryLight,
                    backgroundColor: AppColors.hairlineStrong,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${score.percentage.toStringAsFixed(0)}%',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12, color: AppColors.cyan),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year} '
        '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }
}
