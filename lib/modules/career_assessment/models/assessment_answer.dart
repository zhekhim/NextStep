class AssessmentAnswer {
  AssessmentAnswer({
    required this.questionId,
    required this.dimension,
    required this.selectedValue,
  }) {
    if (selectedValue < 1 || selectedValue > 5) {
      throw RangeError.range(selectedValue, 1, 5, 'selectedValue');
    }
  }

  final String questionId;
  final String dimension;
  final int selectedValue;
}
