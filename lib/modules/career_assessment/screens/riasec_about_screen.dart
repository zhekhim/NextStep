import 'package:flutter/material.dart';

import '../models/assessment_dimension.dart';
import '../repositories/assessment_dimension_repository.dart';

class RiasecAboutScreen extends StatefulWidget {
  const RiasecAboutScreen({super.key, this.loadDimensions});

  final Future<List<AssessmentDimension>> Function()? loadDimensions;

  @override
  State<RiasecAboutScreen> createState() => _RiasecAboutScreenState();
}

class _RiasecAboutScreenState extends State<RiasecAboutScreen> {
  static const _secondaryText = Color(0xFFA8A8A8);

  List<AssessmentDimension> _dimensions = const [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDimensions();
  }

  Future<void> _loadDimensions() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final dimensions =
          await (widget.loadDimensions?.call() ??
              AssessmentDimensionRepository().getDimensions());
      if (mounted) setState(() => _dimensions = dimensions);
    } catch (error) {
      debugPrint('Unable to load assessment dimensions: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load the RIASEC dimensions.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About the RIASEC Test')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'About the RIASEC Test',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            const _InformationSection(
              heading: 'Background',
              paragraphs: [
                "The RIASEC model is a career-interest framework developed from vocational psychologist John L. Holland's theory of vocational personalities and work environments. Holland proposed that people tend to have different patterns of interests and that career environments can also be described using similar categories. Understanding the relationship between a person's interests and different types of work environments can support career exploration and career decision-making.",
                'The model organizes career interests into six dimensions: Realistic (R), Investigative (I), Artistic (A), Social (S), Enterprising (E), and Conventional (C). Together, these six dimensions are commonly referred to as RIASEC or the Holland Codes.',
              ],
            ),
            const SizedBox(height: 24),
            const _InformationSection(
              heading: 'How This Assessment Works',
              paragraphs: [
                'In NextStep, the assessment presents active activity-based questions from the application database. For each activity, you indicate how much you would enjoy doing it using a five-point scale:',
                'Dislike (1) → Slightly Dislike (2) → Neutral (3) → Slightly Enjoy (4) → Enjoy (5)',
                'All responses contribute to the assessment. After completing the active questions, NextStep calculates and ranks the percentage scores for all six dimensions. Your three highest-scoring dimensions are combined to form your three-letter RIASEC code. For example, if Investigative, Conventional, and Realistic receive your three highest scores, your code would be ICR.',
              ],
            ),
            const SizedBox(height: 24),
            const _InformationSection(
              heading: 'What Your Result Means',
              paragraphs: [
                'Your RIASEC code represents the areas of work and activities that most closely align with the interests expressed in your responses. NextStep uses this result to help you explore careers associated with your strongest interest areas and provide career recommendations for further exploration.',
                'The result should be treated as career exploration guidance rather than a fixed judgment of your abilities or future career. Your interests may develop over time, and factors such as skills, education, experience, personal values, and career opportunities should also be considered when making career decisions.',
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'The Six RIASEC Dimensions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildDimensions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensions() {
    if (_isLoading && _dimensions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null && _dimensions.isEmpty) {
      return Center(
        child: Column(
          children: [
            Text(_errorMessage!, style: const TextStyle(color: _secondaryText)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadDimensions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_dimensions.isEmpty) {
      return const Text(
        'No RIASEC dimensions are currently available.',
        style: TextStyle(color: _secondaryText),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < _dimensions.length; index++) ...[
          _DimensionCard(dimension: _dimensions[index]),
          if (index != _dimensions.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _InformationSection extends StatelessWidget {
  const _InformationSection({required this.heading, required this.paragraphs});

  final String heading;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < paragraphs.length; index++) ...[
          Text(
            paragraphs[index],
            style: const TextStyle(
              color: Color(0xFFA8A8A8),
              fontSize: 15,
              height: 1.55,
            ),
          ),
          if (index != paragraphs.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _DimensionCard extends StatefulWidget {
  const _DimensionCard({required this.dimension});

  final AssessmentDimension dimension;

  @override
  State<_DimensionCard> createState() => _DimensionCardState();
}

class _DimensionCardState extends State<_DimensionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final dimension = widget.dimension;
    return Semantics(
      button: true,
      expanded: _isExpanded,
      label: '${dimension.name} dimension details',
      child: Material(
        color: const Color(0xFF181818),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF222222)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0007CD).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dimension.code,
                      style: const TextStyle(
                        color: Color(0xFF1A26FF),
                        fontSize: 18,
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
                                dimension.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Color(0xFFA8A8A8),
                              ),
                            ),
                          ],
                        ),
                        if (_isExpanded) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Description',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dimension.description,
                            style: const TextStyle(
                              color: Color(0xFFA8A8A8),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          if (dimension.characteristics.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Characteristics',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dimension.characteristics,
                              style: const TextStyle(
                                color: Color(0xFFA8A8A8),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
