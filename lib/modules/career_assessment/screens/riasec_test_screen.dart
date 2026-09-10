import 'package:flutter/material.dart';

import '../models/riasec_question.dart';
import '../services/riasec_scoring_service.dart';
import 'riasec_result_screen.dart';

class RiasecTestScreen extends StatefulWidget {
  const RiasecTestScreen({super.key});

  @override
  State<RiasecTestScreen> createState() => _RiasecTestScreenState();
}

class _RiasecTestScreenState extends State<RiasecTestScreen> {
  static const _blue = Color(0xFF0007CD);
  static const _card = Color(0xFF181818);
  static const _surface = Color(0xFF222222);
  static const _secondaryText = Color(0xFFA8A8A8);

  final _answers = <int, int>{};
  final _scoringService = RiasecScoringService();
  int _currentQuestion = 0;
  bool _hasStarted = false;
  String? _validationMessage;

  static const _answerLabels = [
    'Dislike',
    'Slightly Dislike',
    'Neutral',
    'Slightly Enjoy',
    'Enjoy',
  ];

  static const _questions = [
    RiasecQuestion(dimension: 'R', activity: 'Repair a piece of equipment.'),
    RiasecQuestion(dimension: 'R', activity: 'Build something using tools.'),
    RiasecQuestion(dimension: 'R', activity: 'Work outdoors.'),
    RiasecQuestion(dimension: 'R', activity: 'Operate machinery.'),
    RiasecQuestion(dimension: 'R', activity: 'Install electrical equipment.'),
    RiasecQuestion(dimension: 'R', activity: 'Assemble a physical product.'),
    RiasecQuestion(dimension: 'R', activity: 'Work with plants or animals.'),
    RiasecQuestion(dimension: 'R', activity: 'Inspect how a device works.'),
    RiasecQuestion(dimension: 'I', activity: 'Investigate how a system works.'),
    RiasecQuestion(
      dimension: 'I',
      activity: 'Analyse data to solve a problem.',
    ),
    RiasecQuestion(
      dimension: 'I',
      activity: 'Conduct a scientific experiment.',
    ),
    RiasecQuestion(dimension: 'I', activity: 'Research a difficult question.'),
    RiasecQuestion(
      dimension: 'I',
      activity: 'Use mathematics to find patterns.',
    ),
    RiasecQuestion(dimension: 'I', activity: 'Develop a hypothesis.'),
    RiasecQuestion(dimension: 'I', activity: 'Read technical reports.'),
    RiasecQuestion(dimension: 'I', activity: 'Solve a complex puzzle.'),
    RiasecQuestion(dimension: 'A', activity: 'Design a poster or visual.'),
    RiasecQuestion(dimension: 'A', activity: 'Write a story or article.'),
    RiasecQuestion(dimension: 'A', activity: 'Create music or videos.'),
    RiasecQuestion(dimension: 'A', activity: 'Express an idea through art.'),
    RiasecQuestion(dimension: 'A', activity: 'Create a new style or concept.'),
    RiasecQuestion(dimension: 'A', activity: 'Take photographs for a project.'),
    RiasecQuestion(dimension: 'A', activity: 'Plan the look of a product.'),
    RiasecQuestion(
      dimension: 'A',
      activity: 'Perform in front of an audience.',
    ),
    RiasecQuestion(dimension: 'S', activity: 'Teach someone a new skill.'),
    RiasecQuestion(dimension: 'S', activity: 'Help a person solve a problem.'),
    RiasecQuestion(dimension: 'S', activity: 'Support people in a team.'),
    RiasecQuestion(
      dimension: 'S',
      activity: 'Listen to someone who needs help.',
    ),
    RiasecQuestion(dimension: 'S', activity: 'Organise a community activity.'),
    RiasecQuestion(dimension: 'S', activity: 'Explain information clearly.'),
    RiasecQuestion(dimension: 'S', activity: 'Guide a group discussion.'),
    RiasecQuestion(dimension: 'S', activity: 'Work in a service role.'),
    RiasecQuestion(dimension: 'E', activity: 'Lead a group toward a goal.'),
    RiasecQuestion(
      dimension: 'E',
      activity: 'Present an idea to persuade others.',
    ),
    RiasecQuestion(dimension: 'E', activity: 'Start a business project.'),
    RiasecQuestion(dimension: 'E', activity: 'Negotiate an agreement.'),
    RiasecQuestion(dimension: 'E', activity: 'Make important decisions.'),
    RiasecQuestion(dimension: 'E', activity: 'Plan a marketing campaign.'),
    RiasecQuestion(dimension: 'E', activity: 'Manage a team.'),
    RiasecQuestion(dimension: 'E', activity: 'Sell a product or service.'),
    RiasecQuestion(dimension: 'C', activity: 'Organise files or records.'),
    RiasecQuestion(dimension: 'C', activity: 'Follow a detailed procedure.'),
    RiasecQuestion(dimension: 'C', activity: 'Check information for accuracy.'),
    RiasecQuestion(dimension: 'C', activity: 'Create a schedule.'),
    RiasecQuestion(dimension: 'C', activity: 'Work with spreadsheets.'),
    RiasecQuestion(dimension: 'C', activity: 'Keep financial records.'),
    RiasecQuestion(dimension: 'C', activity: 'Sort and classify information.'),
    RiasecQuestion(
      dimension: 'C',
      activity: 'Complete tasks carefully and on time.',
    ),
  ];

  Future<void> _goForward() async {
    if (!_answers.containsKey(_currentQuestion)) {
      setState(
        () => _validationMessage = 'Please select an answer before continuing.',
      );
      return;
    }
    if (_currentQuestion == _questions.length - 1) {
      final result = _scoringService.calculate(
        questions: _questions,
        answers: _answers,
      );
      final shouldRetake = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => RiasecResultScreen(result: result)),
      );
      if (shouldRetake == true && mounted) {
        setState(() {
          _hasStarted = false;
          _currentQuestion = 0;
          _answers.clear();
          _validationMessage = null;
        });
      }
      return;
    }
    setState(() {
      _currentQuestion++;
      _validationMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment')),
      body: SafeArea(
        child: _hasStarted ? _buildQuestion() : _buildIntroduction(),
      ),
    );
  }

  Widget _buildIntroduction() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'lib/image/riasec.png',
              height: 210,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Discover Your Interests.\nShape Your Career.',
            style: TextStyle(
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Understand your career interests through the RIASEC assessment and discover career paths that suit you. Explore your strongest areas, find matching careers, and identify the skills you need to prepare for your future.',
            style: TextStyle(color: _secondaryText, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _surface),
            ),
            child: const Row(
              children: [
                Icon(Icons.quiz_outlined, color: _blue),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '48 questions',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'About 8 minutes',
                      style: TextStyle(color: _secondaryText, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => setState(() => _hasStarted = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Start Your RIASEC Test'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final question = _questions[_currentQuestion];
    final isLast = _currentQuestion == _questions.length - 1;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Question ${_currentQuestion + 1} of ${_questions.length}',
          style: const TextStyle(fontSize: 14, color: _secondaryText),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: (_currentQuestion + 1) / _questions.length,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
          backgroundColor: _surface,
          color: _blue,
        ),
        const SizedBox(height: 24),
        const Text(
          'Please rate how much you would enjoy doing each activity. Your responses will help us understand your career interests.',
          style: TextStyle(color: _secondaryText, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _surface),
          ),
          child: Text(
            question.activity,
            style: const TextStyle(
              fontSize: 21,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < _answerLabels.length; index++)
          _buildAnswerOption(value: index + 1, label: _answerLabels[index]),
        if (_validationMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _validationMessage!,
            style: const TextStyle(color: Color(0xFFFF4D4D)),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _currentQuestion == 0
                    ? null
                    : () => setState(() {
                        _currentQuestion--;
                        _validationMessage = null;
                      }),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: _secondaryText),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _goForward,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isLast ? 'Submit' : 'Next'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnswerOption({required int value, required String label}) {
    final isSelected = _answers[_currentQuestion] == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() {
          _answers[_currentQuestion] = value;
          _validationMessage = null;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _blue.withValues(alpha: 0.22) : _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _blue : _surface,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? const Color(0xFF1A26FF) : _secondaryText,
              ),
              const SizedBox(width: 12),
              Text(
                '$value. $label',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
