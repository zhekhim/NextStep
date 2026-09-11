import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../career_intelligence/models/career.dart';
import '../../career_intelligence/repositories/career_repository.dart';
import '../../career_intelligence/screens/career_detail_screen.dart';
import '../services/assessment_report_service.dart';
import '../widgets/career_recommendation_evaluation_button.dart';
import '../models/assessment_dimension.dart';
import '../repositories/assessment_dimension_repository.dart';
import '../services/riasec_scoring_service.dart';
import 'assessment_history_screen.dart';

class RiasecResultScreen extends StatefulWidget {
  const RiasecResultScreen({
    super.key,
    required this.result,
    required this.assessmentProfileId,
    this.loadCareers,
    this.loadDimensions,
  });
  final RiasecResult result;
  final String assessmentProfileId;
  final Future<List<Career>> Function()? loadCareers;
  final Future<List<AssessmentDimension>> Function()? loadDimensions;
  @override
  State<RiasecResultScreen> createState() => _RiasecResultScreenState();
}

class _RiasecResultScreenState extends State<RiasecResultScreen> {
  static const _blue = AppColors.primary;
  static const _card = AppColors.surfaceCard;
  static const _surface = AppColors.hairlineStrong;
  static const _secondary = AppColors.textSecondary;
  static const _names = {
    'R': 'Realistic',
    'I': 'Investigative',
    'A': 'Artistic',
    'S': 'Social',
    'E': 'Enterprising',
    'C': 'Conventional',
  };
  List<Career> _matches = const [];
  Map<String, AssessmentDimension> _dimensions = const {};
  bool _loading = false;
  bool _dimensionsLoading = false;
  String? _error;
  String? _dimensionsError;
  bool _exporting = false;
  Uint8List? _reportBytes;

  Future<void> _exportReport() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final service = AssessmentReportService();
      _reportBytes ??= await service.generate(
        result: widget.result,
        careers: _matches,
        dimensions: _dimensions,
        generatedAt: DateTime.now(),
      );
      await Printing.sharePdf(
        bytes: _reportBytes!,
        filename: 'NextStep-${widget.result.code}.pdf',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose Save or an app to share your PDF.'),
        ),
      );
    } catch (error) {
      debugPrint('Assessment PDF export failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to prepare the PDF. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMatches();
    _loadDimensions();
  }

  Future<void> _loadMatches() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code = widget.result.code.trim().toUpperCase();
      final careers =
          await (widget.loadCareers?.call() ??
              CareerRepository().getCareersByRiasecCode(code));
      final matches =
          careers
              .where((career) => career.riasecCode.trim().toUpperCase() == code)
              .toList()
            ..sort(
              (left, right) => left.careerName.compareTo(right.careerName),
            );
      if (mounted) {
        setState(() {
          _matches = matches.take(5).toList(growable: false);
          _reportBytes = null;
        });
      }
    } catch (error) {
      debugPrint('Unable to generate career matches: $error');
      if (mounted) {
        setState(() => _error = 'Unable to generate career matches.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDimensions() async {
    if (_dimensionsLoading) return;
    setState(() {
      _dimensionsLoading = true;
      _dimensionsError = null;
    });
    try {
      final dimensions =
          await (widget.loadDimensions?.call() ??
              AssessmentDimensionRepository().getDimensions());
      if (mounted) {
        setState(() {
          _dimensions = {
            for (final dimension in dimensions) dimension.code: dimension,
          };
        });
      }
    } catch (error) {
      debugPrint('Unable to load assessment dimensions: $error');
      if (mounted) {
        setState(
          () => _dimensionsError = 'Unable to load strongest-area details.',
        );
      }
    } finally {
      if (mounted) setState(() => _dimensionsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strongest = widget.result.strongestDimensions;
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment Results')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _box(16),
              child: Column(
                children: [
                  const Text(
                    'YOUR RIASEC CODE',
                    style: TextStyle(
                      color: _secondary,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.result.code,
                    style: const TextStyle(
                      color: AppColors.violetLight,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These are your three strongest career-interest areas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Career Profile',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: _box(16),
              child: _Radar(result: widget.result),
            ),
            const SizedBox(height: 16),
            for (final score in widget.result.rankedScores)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScoreCard(score: score, name: _names[score.dimension]!),
              ),
            const SizedBox(height: 14),
            const Text(
              'Your Strongest Areas',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _strongestAreasState(strongest),
            const SizedBox(height: 14),
            const Text(
              'Careers Matching Your RIASEC Code',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _matchesState(),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed:
                  _exporting ||
                      _loading ||
                      _dimensionsLoading ||
                      _error != null ||
                      _dimensionsError != null
                  ? null
                  : _exportReport,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                _exporting ? 'Preparing PDF...' : 'Save or Share PDF',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Text('Retake Assessment'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AssessmentHistoryScreen(),
                  ),
                ),
                icon: const Icon(Icons.history),
                label: const Text('View History'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _box(double radius) => BoxDecoration(
    color: _card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _surface),
  );
  Widget _strongestAreasState(List<RiasecDimensionScore> strongest) {
    if (_dimensionsLoading && _dimensions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_dimensionsError != null && _dimensions.isEmpty) {
      return Column(
        children: [
          Text(
            _dimensionsError!,
            style: const TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadDimensions,
            child: const Text('Retry'),
          ),
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < strongest.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StrongCard(
              rank: i + 1,
              score: strongest[i],
              dimension: _dimensions[strongest[i].dimension],
            ),
          ),
      ],
    );
  }

  Widget _matchesState() {
    if (_loading) {
      return const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Generating career matches...'),
          ],
        ),
      );
    }
    if (_error != null) {
      return Column(
        children: [
          Text(_error!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _loadMatches, child: const Text('Retry')),
        ],
      );
    }
    if (_matches.isEmpty) {
      return const Text(
        'No career matches are currently available.',
        style: TextStyle(color: _secondary),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < _matches.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MatchCard(
              rank: i + 1,
              match: _matches[i],
              assessmentProfileId: widget.assessmentProfileId,
            ),
          ),
      ],
    );
  }
}

class _Radar extends StatelessWidget {
  const _Radar({required this.result});
  final RiasecResult result;
  @override
  Widget build(BuildContext context) {
    final scores = {
      for (final score in result.rankedScores)
        score.dimension: score.percentage,
    };
    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: [
              for (final dimension in RiasecScoringService.dimensions)
                RadarEntry(value: scores[dimension]!),
            ],
            borderColor: AppColors.primaryLight,
            fillColor: AppColors.primaryLight.withValues(alpha: .18),
            borderWidth: 2,
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        radarBorderData: const BorderSide(color: AppColors.hairlineStrong),
        radarShape: RadarShape.polygon,
        tickCount: 5,
        ticksTextStyle: const TextStyle(color: Colors.transparent),
        tickBorderData: const BorderSide(color: AppColors.hairlineStrong),
        gridBorderData: const BorderSide(color: AppColors.hairlineStrong),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
        getTitle: (index, angle) => RadarChartTitle(
          text: RiasecScoringService.dimensions[index],
          angle: 0,
        ),
        radarTouchData: RadarTouchData(enabled: false),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.name});
  final RiasecDimensionScore score;
  final String name;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.hairlineStrong),
    ),
    child: Row(
      children: [
        Text(
          score.dimension,
          style: const TextStyle(
            color: AppColors.violetLight,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '${score.percentage.toStringAsFixed(0)}%',
          style: const TextStyle(
            color: AppColors.cyan,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _StrongCard extends StatelessWidget {
  const _StrongCard({
    required this.rank,
    required this.score,
    required this.dimension,
  });
  final int rank;
  final RiasecDimensionScore score;
  final AssessmentDimension? dimension;
  @override
  Widget build(BuildContext context) {
    final name = dimension?.name ?? score.dimension;
    final description = dimension?.description ?? '';
    final characteristics = dimension?.characteristics ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.violetSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.violetLight.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$rank',
            style: const TextStyle(
              color: AppColors.violetLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      score.dimension,
                      style: const TextStyle(
                        color: AppColors.violetLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                if (characteristics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Characteristics: $characteristics',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.rank,
    required this.match,
    required this.assessmentProfileId,
  });
  final int rank;
  final Career match;
  final String assessmentProfileId;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceBlue,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.sky.withValues(alpha: 0.65)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '#$rank',
              style: const TextStyle(
                color: AppColors.sky,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                match.careerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          match.description,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CareerDetailScreen(career: match),
            ),
          ),
          child: const Text('Explore Career'),
        ),
        CareerRecommendationEvaluationButton(
          assessmentProfileId: assessmentProfileId,
          careerId: match.id,
        ),
      ],
    ),
  );
}
