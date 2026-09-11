import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assessment_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../models/riasec_question.dart';
import '../repositories/assessment_profile_repository.dart';
import '../repositories/assessment_question_repository.dart';
import '../services/riasec_scoring_service.dart';
import 'assessment_history_screen.dart';
import 'riasec_about_screen.dart';
import 'riasec_result_screen.dart';

class RiasecTestScreen extends StatefulWidget {
  const RiasecTestScreen({
    super.key,
    this.loadQuestions,
    this.loadLatestResult,
    this.saveResult,
  });
  final Future<List<RiasecQuestion>> Function()? loadQuestions;
  final Future<AssessmentProfile?> Function()? loadLatestResult;
  final Future<String> Function(RiasecResult result)? saveResult;
  @override
  State<RiasecTestScreen> createState() => _RiasecTestScreenState();
}

class _RiasecTestScreenState extends State<RiasecTestScreen> {
  static const _card = AppColors.surfaceCard;
  static const _surface = AppColors.hairlineStrong;
  static const _secondary = AppColors.textSecondary;
  static const _labels = [
    'Dislike',
    'Slightly Dislike',
    'Neutral',
    'Slightly Enjoy',
    'Enjoy',
  ];
  final _answers = <int, int>{};
  final _scoring = RiasecScoringService();
  List<RiasecQuestion> _questions = const [];
  int _current = 0;
  bool _started = false;
  bool _loading = false;
  bool _latestResultLoading = false;
  bool _submitting = false;
  String? _error;
  String? _latestResultError;
  String? _validation;
  AssessmentProfile? _latestResult;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _loadLatestResult();
  }

  Future<void> _loadLatestResult() async {
    if (_latestResultLoading) return;
    setState(() {
      _latestResultLoading = true;
      _latestResultError = null;
    });
    try {
      final result =
          await (widget.loadLatestResult?.call() ??
              AssessmentProfileRepository().getLatestResult());
      if (mounted) setState(() => _latestResult = result);
    } catch (error) {
      debugPrint('Unable to load latest assessment result: $error');
      if (mounted) {
        setState(() {
          _latestResult = null;
          _latestResultError = 'Unable to load your latest result.';
        });
      }
    } finally {
      if (mounted) setState(() => _latestResultLoading = false);
    }
  }

  Future<void> _loadQuestions() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final AssessmentQuestionRepository? repository =
          widget.loadQuestions == null ? AssessmentQuestionRepository() : null;
      if (repository != null) {
        try {
          final cached = await repository.getCachedQuestions();
          if (cached.isNotEmpty) {
            _scoring.validateQuestions(cached);
            if (mounted) setState(() => _questions = cached);
          }
        } catch (_) {
          // Continue with Supabase when cached questions are unavailable.
        }
      }
      final questions =
          await (widget.loadQuestions?.call() ??
              repository!.getActiveQuestions());
      _scoring.validateQuestions(questions);
      if (mounted) setState(() => _questions = questions);
    } catch (error) {
      debugPrint('Unable to load assessment questions: $error');
      if (mounted) {
        setState(() => _error = 'Unable to load assessment questions.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _next() async {
    if (_submitting) return;
    if (!_answers.containsKey(_current)) {
      setState(
        () => _validation = 'Please select an answer before continuing.',
      );
      return;
    }
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _validation = null;
      });
      return;
    }
    if (_answers.length != _questions.length) {
      setState(
        () => _validation = 'Please answer all questions before submitting.',
      );
      return;
    }
    final result = _scoring.calculate(questions: _questions, answers: _answers);
    setState(() {
      _submitting = true;
      _validation = null;
    });
    try {
      final assessmentProfileId =
          await (widget.saveResult?.call(result) ??
              AssessmentProfileRepository().saveResult(result));
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => RiasecResultScreen(
            result: result,
            assessmentProfileId: assessmentProfileId,
          ),
        ),
      );
      if (mounted) {
        _resetAssessment();
        _loadLatestResult();
      }
    } catch (error, stackTrace) {
      debugPrint('Unable to save assessment result: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _validation = _assessmentSaveError(error);
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _assessmentSaveError(Object error) {
    if (error is PostgrestException) {
      return 'Unable to save assessment (${error.code}): ${error.message}';
    }
    if (error is AuthException) {
      return 'Unable to save assessment: ${error.message}';
    }
    if (error is StateError) {
      return error.message;
    }
    return 'Unable to save your assessment. Please try again.';
  }

  void _resetAssessment() {
    setState(() {
      _started = false;
      _current = 0;
      _answers.clear();
      _validation = null;
    });
  }

  Future<void> _confirmGiveUp() async {
    final giveUp = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Give up assessment?'),
        content: const Text(
          'Your current answers will be lost if you leave the assessment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Assessment'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Give Up'),
          ),
        ],
      ),
    );
    if (giveUp == true && mounted) _resetAssessment();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_started,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _started) _confirmGiveUp();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Assessment'),
        leading: _started
            ? IconButton(
                onPressed: _confirmGiveUp,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Leave assessment',
              )
            : null,
      ),
      body: SafeArea(child: _started ? _questionPage() : _introPage()),
    ),
  );

  Widget _introPage() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Image.asset('lib/image/riasec.png', height: 210)),
        const SizedBox(height: 24),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Discover Your Interests.\n',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              TextSpan(
                text: 'Shape Your Career.',
                style: TextStyle(color: AppColors.violetLight),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: 25,
            height: 1.18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Understand your career interests through the RIASEC assessment and discover career paths that suit you.',
          style: TextStyle(color: _secondary, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),
        _questionStatus(),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _loading || _questions.isEmpty
                ? null
                : () => setState(() => _started = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.violetLight,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Start Assessment'),
          ),
        ),
        const SizedBox(height: 10),
        if (_latestResult != null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RiasecResultScreen(
                    result: _latestResult!.toResult(),
                    assessmentProfileId: _latestResult!.id,
                  ),
                ),
              ),
              icon: const Icon(Icons.recommend_outlined),
              label: const Text('View Latest Result & Recommendations'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AssessmentHistoryScreen(),
              ),
            ),
            icon: const Icon(Icons.history),
            label: const Text('View Assessment History'),
          ),
        ),
        if (_latestResultError != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _latestResultError!,
                  style: const TextStyle(color: Color(0xFFFF4D4D)),
                ),
              ),
              TextButton(
                onPressed: _latestResultLoading ? null : _loadLatestResult,
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RiasecAboutScreen(),
              ),
            ),
            icon: const Icon(Icons.info_outline),
            label: const Text('About the RIASEC Test'),
          ),
        ),
      ],
    ),
  );

  Widget _questionStatus() {
    if (_loading) {
      return const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading assessment questions...'),
          ],
        ),
      );
    }
    if (_error != null) {
      return Column(
        children: [
          Text(_error!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _loadQuestions, child: const Text('Retry')),
        ],
      );
    }
    if (_questions.isEmpty) {
      return const Text(
        'No assessment questions available.',
        style: TextStyle(color: _secondary),
      );
    }
    return Row(
      children: [
        Expanded(
          child: _Fact(value: '${_questions.length}', label: 'QUESTIONS'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Fact(
            value: '${RiasecScoringService.dimensions.length}',
            label: 'INTEREST AREAS',
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: _Fact(value: '~5', label: 'MINUTES'),
        ),
      ],
    );
  }

  Widget _questionPage() {
    final question = _questions[_current];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Question ${_current + 1} of ${_questions.length}',
          style: const TextStyle(color: _secondary),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: (_current + 1) / _questions.length,
          minHeight: 6,
          color: AppColors.primaryLight,
          backgroundColor: _surface,
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
        for (var index = 0; index < _labels.length; index++)
          _answerOption(index + 1, _labels[index]),
        if (_validation != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _validation!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _submitting || _current == 0
                      ? null
                      : () => setState(() {
                          _current--;
                          _validation = null;
                        }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.hairlineStrong),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.chevron_left, size: 24),
                  label: const Text(
                    'Previous',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violetLight,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _current == _questions.length - 1
                                  ? 'Submit'
                                  : 'Next',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right, size: 24),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _answerOption(int value, String label) {
    final selected = _answers[_current] == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() {
          _answers[_current] = value;
          _validation = null;
        }),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.violetSoft : _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.violetLight : _surface,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? AppColors.violetLight : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.violetLight : _secondary,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                '$value. $label',
                style: TextStyle(
                  color: selected
                      ? AppColors.violetLight
                      : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.surfaceBlue,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.hairlineStrong),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.violetLight,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
        ),
      ],
    ),
  );
}
