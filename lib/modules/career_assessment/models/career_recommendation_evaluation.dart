class CareerRecommendationEvaluation {
  const CareerRecommendationEvaluation({
    required this.id,
    required this.assessmentProfileId,
    required this.careerId,
    required this.rating,
    required this.comment,
  });

  final String id;
  final String assessmentProfileId;
  final String careerId;
  final int rating;
  final String? comment;

  factory CareerRecommendationEvaluation.fromJson(Map<String, dynamic> json) {
    final rating = int.tryParse(json['rating']?.toString() ?? '');
    final id = json['id']?.toString().trim() ?? '';
    final assessmentProfileId =
        json['assessment_profile_id']?.toString().trim() ?? '';
    final careerId = json['career_id']?.toString().trim() ?? '';
    if (id.isEmpty || assessmentProfileId.isEmpty || careerId.isEmpty ||
        rating == null || rating < 1 || rating > 5) {
      throw const FormatException('Invalid career recommendation evaluation.');
    }
    final comment = json['comment']?.toString().trim();
    return CareerRecommendationEvaluation(
      id: id,
      assessmentProfileId: assessmentProfileId,
      careerId: careerId,
      rating: rating,
      comment: comment == null || comment.isEmpty ? null : comment,
    );
  }
}
