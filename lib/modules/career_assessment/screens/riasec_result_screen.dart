import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../career_intelligence/models/career.dart';
import '../../career_intelligence/repositories/career_repository.dart';
import '../../career_intelligence/screens/career_detail_screen.dart';
import '../models/assessment_dimension.dart';
import '../models/riasec_career_match.dart';
import '../repositories/assessment_dimension_repository.dart';
import '../services/riasec_scoring_service.dart';

class RiasecResultScreen extends StatefulWidget {
  const RiasecResultScreen({
    super.key,
    required this.result,
    this.loadCareers,
    this.loadDimensions,
  });
  final RiasecResult result;
  final Future<List<Career>> Function()? loadCareers;
  final Future<List<AssessmentDimension>> Function()? loadDimensions;
  @override
  State<RiasecResultScreen> createState() => _RiasecResultScreenState();
}

class _RiasecResultScreenState extends State<RiasecResultScreen> {
  static const _blue = Color(0xFF0007CD);
  static const _card = Color(0xFF181818);
  static const _surface = Color(0xFF222222);
  static const _secondary = Color(0xFFA8A8A8);
  static const _names = {
    'R': 'Realistic',
    'I': 'Investigative',
    'A': 'Artistic',
    'S': 'Social',
    'E': 'Enterprising',
    'C': 'Conventional',
  };
  List<RiasecCareerMatch> _matches = const [];
  Map<String, AssessmentDimension> _dimensions = const {};
  bool _loading = false;
  bool _dimensionsLoading = false;
  String? _error;
  String? _dimensionsError;

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
      final careers =
          await (widget.loadCareers?.call() ??
              CareerRepository().getCareersByRiasecCode(widget.result.code));
      final matchingCareers = widget.loadCareers == null
          ? careers
          : careers
                .where(
                  (career) =>
                      career.riasecCode.isEmpty ||
                      career.riasecCode == widget.result.code,
                )
                .toList(growable: false);
      final matches = matchingCareers
          .take(5)
          .map(
            (career) => RiasecCareerMatch(career: career, matchPercentage: 100),
          )
          .toList(growable: false);
      if (mounted) setState(() => _matches = matches);
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
                      color: Color(0xFF1A26FF),
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
              'Top Career Matches',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _matchesState(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retake Assessment'),
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
            style: const TextStyle(color: Color(0xFFFF4D4D)),
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
          Text(_error!, style: const TextStyle(color: Color(0xFFFF4D4D))),
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
            child: _MatchCard(rank: i + 1, match: _matches[i]),
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
            fillColor: const Color(0xFF0007CD).withValues(alpha: .22),
            borderColor: const Color(0xFF1A26FF),
            borderWidth: 2,
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        radarShape: RadarShape.polygon,
        tickCount: 5,
        ticksTextStyle: const TextStyle(color: Colors.transparent),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
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
      color: const Color(0xFF181818),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF222222)),
    ),
    child: Row(
      children: [
        Text(
          score.dimension,
          style: const TextStyle(
            color: Color(0xFF1A26FF),
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
            color: Color(0xFF1A26FF),
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
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$rank',
            style: const TextStyle(
              color: Color(0xFF1A26FF),
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
                        color: Color(0xFF1A26FF),
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
                      color: Color(0xFFA8A8A8),
                      height: 1.4,
                    ),
                  ),
                ],
                if (characteristics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Characteristics: $characteristics',
                    style: const TextStyle(
                      color: Color(0xFFA8A8A8),
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
  const _MatchCard({required this.rank, required this.match});
  final int rank;
  final RiasecCareerMatch match;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF181818),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF222222)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '#$rank',
              style: const TextStyle(
                color: Color(0xFF1A26FF),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                match.career.careerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${match.matchPercentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Color(0xFF1A26FF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          match.career.description,
          style: const TextStyle(color: Color(0xFFA8A8A8)),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CareerDetailScreen(career: match.career),
            ),
          ),
          child: const Text('Explore Career'),
        ),
      ],
    ),
  );
}
