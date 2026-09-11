import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/career_recommendation_evaluation.dart';
import '../repositories/career_recommendation_evaluation_repository.dart';

class CareerRecommendationEvaluationButton extends StatefulWidget {
  const CareerRecommendationEvaluationButton({
    super.key,
    required this.assessmentProfileId,
    required this.careerId,
  });

  final String assessmentProfileId;
  final String careerId;

  @override
  State<CareerRecommendationEvaluationButton> createState() =>
      _CareerRecommendationEvaluationButtonState();
}

class _CareerRecommendationEvaluationButtonState
    extends State<CareerRecommendationEvaluationButton> {
  final _repository = CareerRecommendationEvaluationRepository();
  CareerRecommendationEvaluation? _evaluation;
  bool _loading = true;
  bool _saving = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loadFailed = false);
    try {
      final evaluation = await _repository.getEvaluation(
        assessmentProfileId: widget.assessmentProfileId,
        careerId: widget.careerId,
      );
      if (mounted) setState(() => _evaluation = evaluation);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final submitted = await showDialog<({int rating, String? comment})>(
      context: context,
      builder: (_) => _EvaluationDialog(existing: _evaluation),
    );
    if (submitted == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final saved = await _repository.save(
        existing: _evaluation,
        assessmentProfileId: widget.assessmentProfileId,
        careerId: widget.careerId,
        rating: submitted.rating,
        comment: submitted.comment,
      );
      if (mounted) {
        setState(() => _evaluation = saved);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Career evaluation saved.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save your evaluation. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final evaluation = _evaluation;
    if (evaluation == null) return;
    setState(() => _saving = true);
    try {
      await _repository.delete(evaluation.id);
      if (mounted) {
        setState(() => _evaluation = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Career evaluation removed.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to remove your evaluation. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_loadFailed) {
      return TextButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry loading evaluation'),
      );
    }
    final evaluation = _evaluation;
    if (evaluation == null) {
      return TextButton.icon(
        onPressed: _saving ? null : _edit,
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Evaluate Recommendation'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: AppColors.warning, size: 18),
            const SizedBox(width: 4),
            Text('${evaluation.rating}/5 - Your evaluation'),
            const Spacer(),
            IconButton(
              tooltip: 'Edit evaluation',
              onPressed: _saving ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Remove evaluation',
              color: AppColors.error,
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        if (evaluation.comment != null) Text(evaluation.comment!),
      ],
    );
  }
}

class _EvaluationDialog extends StatefulWidget {
  const _EvaluationDialog({this.existing});
  final CareerRecommendationEvaluation? existing;

  @override
  State<_EvaluationDialog> createState() => _EvaluationDialogState();
}

class _EvaluationDialogState extends State<_EvaluationDialog> {
  late int _rating = widget.existing?.rating ?? 0;
  late final _comment = TextEditingController(text: widget.existing?.comment);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Evaluate Recommendation'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How relevant is this assessment recommendation?'),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: AppColors.warning,
                ),
              ),
            ),
          ),
          TextField(
            controller: _comment,
            maxLength: 1000,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Comment (optional)'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _rating == 0
            ? null
            : () => Navigator.pop(context, (
                rating: _rating,
                comment: _comment.text.trim().isEmpty
                    ? null
                    : _comment.text.trim(),
              )),
        child: const Text('Save'),
      ),
    ],
  );
}
