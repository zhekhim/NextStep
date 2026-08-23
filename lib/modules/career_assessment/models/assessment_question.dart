class AssessmentQuestion {
  const AssessmentQuestion({
    required this.id,
    required this.questionText,
    required this.dimension,
    required this.questionOrder,
  });

  final String id;
  final String questionText;
  final String dimension;
  final int questionOrder;

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestion(
      id: json['id'].toString(),
      questionText: json['question_text'].toString(),
      dimension: json['dimension'].toString(),
      questionOrder: (json['question_order'] as num).toInt(),
    );
  }
}
