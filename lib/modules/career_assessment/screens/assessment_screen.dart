import 'package:flutter/material.dart';

import '../models/assessment_answer.dart';
import '../models/assessment_question.dart';
import '../repositories/assessment_repository.dart';
import '../services/assessment_scoring_service.dart';
import '../widgets/assessment_question_card.dart';
import 'assessment_result_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final AssessmentRepository _repository = AssessmentRepository();
  final AssessmentScoringService _scoringService = AssessmentScoringService();

  List<AssessmentQuestion> _questions = const [];
  final Map<String, AssessmentAnswer> _answers = {};
  int _currentQuestionIndex = 0;
  bool _hasStarted = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _validationMessage;

  Future<void> _startAssessment() async {
    if (_isLoading) return;

    setState(() {
      _hasStarted = true;
      _isLoading = true;
      _errorMessage = null;
      _validationMessage = null;
    });

    try {
      final questions = await _repository.getActiveQuestions();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _currentQuestionIndex = 0;
        _answers.clear();
      });
    } catch (error) {
      debugPrint('Unable to load assessment questions: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load assessment questions.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectAnswer(int value) {
    if (value < 1 || value > 5 || _questions.isEmpty) return;
    final question = _questions[_currentQuestionIndex];
    setState(() {
      _answers[question.id] = AssessmentAnswer(
        questionId: question.id,
        dimension: question.dimension,
        selectedValue: value,
      );
      _validationMessage = null;
    });
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex == 0) return;
    setState(() {
      _currentQuestionIndex--;
      _validationMessage = null;
    });
  }

  void _continueOrSubmit() {
    final question = _questions[_currentQuestionIndex];
    if (!_answers.containsKey(question.id)) {
      setState(() {
        _validationMessage = 'Please select an answer before continuing.';
      });
      return;
    }

    final isFinalQuestion = _currentQuestionIndex == _questions.length - 1;
    if (!isFinalQuestion) {
      setState(() {
        _currentQuestionIndex++;
        _validationMessage = null;
      });
      return;
    }

    if (_answers.length != _questions.length) {
      setState(() {
        _validationMessage = 'Please answer all questions before submitting.';
      });
      return;
    }

    final result = _scoringService.calculateScores(_answers.values);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssessmentResultScreen(
          result: result,
          onRetake: () {
            _resetAssessment();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _resetAssessment() {
    setState(() {
      _questions = const [];
      _answers.clear();
      _currentQuestionIndex = 0;
      _hasStarted = false;
      _isLoading = false;
      _errorMessage = null;
      _validationMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment')),
      body: SafeArea(
        child: _hasStarted ? _buildAssessmentContent() : _buildIntroduction(),
      ),
    );
  }

  Widget _buildIntroduction() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 64),
            const SizedBox(height: 20),
            Text(
              'Career Assessment',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Discover career areas that may match your interests and working preferences.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.help_outline, size: 18),
                    SizedBox(width: 6),
                    Text('24 Questions'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 18),
                    SizedBox(width: 6),
                    Text('Approximately 5 minutes'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _startAssessment,
              child: const Text('Start Assessment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading assessment questions...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _startAssessment,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_questions.isEmpty) {
      return const Center(child: Text('No assessment questions available.'));
    }

    final question = _questions[_currentQuestionIndex];
    final isFinalQuestion = _currentQuestionIndex == _questions.length - 1;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _questions.length,
        ),
        const SizedBox(height: 20),
        AssessmentQuestionCard(
          question: question,
          selectedValue: _answers[question.id]?.selectedValue,
          onSelected: _selectAnswer,
        ),
        if (_validationMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _validationMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _currentQuestionIndex == 0
                    ? null
                    : _goToPreviousQuestion,
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _continueOrSubmit,
                child: Text(isFinalQuestion ? 'Submit' : 'Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
