import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/riasec_career_match.dart';
import '../services/riasec_career_matching_service.dart';
import '../services/riasec_scoring_service.dart';

class RiasecResultScreen extends StatelessWidget {
  const RiasecResultScreen({required this.result, super.key});

  final RiasecResult result;

  static const _blue = Color(0xFF0007CD);
  static const _highlightBlue = Color(0xFF1A26FF);
  static const _card = Color(0xFF181818);
  static const _surface = Color(0xFF222222);
  static const _secondaryText = Color(0xFFA8A8A8);

  static const _dimensionNames = {
    'R': 'Realistic',
    'I': 'Investigative',
    'A': 'Artistic',
    'S': 'Social',
    'E': 'Enterprising',
    'C': 'Conventional',
  };

  @override
  Widget build(BuildContext context) {
    final strongest = result.strongestDimensions;
    final careerMatches = RiasecCareerMatchingService().findTopMatches(result);
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment Results')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _surface),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR RIASEC CODE',
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    result.code,
                    style: const TextStyle(
                      color: _highlightBlue,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These are your three strongest career-interest areas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _secondaryText, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Interest Profile',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'The chart compares all six areas using every response in your assessment.',
              style: TextStyle(color: _secondaryText, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              height: 310,
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _surface),
              ),
              child: _RiasecRadarChart(result: result),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your Strongest Areas',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < strongest.length; index++) ...[
              _StrongAreaCard(
                rank: index + 1,
                code: strongest[index].dimension,
                name: _dimensionNames[strongest[index].dimension] ?? '',
              ),
              if (index != strongest.length - 1) const SizedBox(height: 10),
            ],
            const SizedBox(height: 24),
            const Text(
              'Top Career Matches',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Career paths aligned with the order of your RIASEC interests.',
              style: TextStyle(color: _secondaryText, height: 1.4),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < careerMatches.length; index++) ...[
              _CareerMatchCard(rank: index + 1, match: careerMatches[index]),
              if (index != careerMatches.length - 1) const SizedBox(height: 10),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Retake Assessment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareerMatchCard extends StatelessWidget {
  const _CareerMatchCard({required this.rank, required this.match});

  final int rank;
  final RiasecCareerMatch match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0007CD).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Color(0xFF1A26FF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        match.careerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      match.riasecCode,
                      style: const TextStyle(
                        color: Color(0xFF1A26FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  match.description,
                  style: const TextStyle(
                    color: Color(0xFFA8A8A8),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiasecRadarChart extends StatelessWidget {
  const _RiasecRadarChart({required this.result});

  final RiasecResult result;

  @override
  Widget build(BuildContext context) {
    final scoreByDimension = {
      for (final score in result.rankedScores) score.dimension: score.total,
    };
    final values = [
      for (final dimension in RiasecScoringService.dimensions)
        scoreByDimension[dimension]!.toDouble(),
    ];

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: values
                .map((value) => RadarEntry(value: value))
                .toList(),
            fillColor: const Color(0xFF0007CD).withValues(alpha: 0.22),
            borderColor: const Color(0xFF1A26FF),
            borderWidth: 2.5,
            entryRadius: 3,
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: const BorderSide(color: Color(0xFF444444)),
        radarShape: RadarShape.polygon,
        tickCount: 4,
        ticksTextStyle: const TextStyle(color: Colors.transparent),
        tickBorderData: const BorderSide(color: Color(0xFF303030)),
        gridBorderData: const BorderSide(color: Color(0xFF3A3A3A)),
        titlePositionPercentageOffset: 0.16,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        getTitle: (index, angle) => RadarChartTitle(
          text: RiasecScoringService.dimensions[index],
          angle: 0,
        ),
        radarTouchData: RadarTouchData(enabled: false),
      ),
      duration: const Duration(milliseconds: 350),
    );
  }
}

class _StrongAreaCard extends StatelessWidget {
  const _StrongAreaCard({
    required this.rank,
    required this.code,
    required this.name,
  });

  final int rank;
  final String code;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: const TextStyle(
              color: Color(0xFF1A26FF),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 32, color: const Color(0xFF2A2A2A)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            code,
            style: const TextStyle(
              color: Color(0xFF1A26FF),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
