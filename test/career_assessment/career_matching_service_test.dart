import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/modules/career_assessment/models/assessment_result.dart';
import 'package:untitled/modules/career_assessment/models/career_assessment_profile.dart';
import 'package:untitled/modules/career_assessment/services/career_matching_service.dart';
import 'package:untitled/modules/career_intelligence/models/career.dart';

void main() {
  const technicalProfile = CareerAssessmentProfile(
    id: 'profile-technical',
    careerId: 'career-technical',
    career: Career(
      id: 'career-technical',
      careerName: 'Technical Profile',
      category: 'Test',
      description: 'Test profile',
    ),
    technical: 5,
    analytical: 5,
    creative: 2,
    business: 2,
    leadership: 2,
    research: 5,
  );
  const businessProfile = CareerAssessmentProfile(
    id: 'profile-business',
    careerId: 'career-business',
    career: Career(
      id: 'career-business',
      careerName: 'Business Profile',
      category: 'Test',
      description: 'Test profile',
    ),
    technical: 2,
    analytical: 3,
    creative: 3,
    business: 5,
    leadership: 5,
    research: 2,
  );

  final service = CareerMatchingService();

  test(
    'high technical, analytical, and research ranks similar profile first',
    () {
      final result = AssessmentResult({
        'Technical': 100,
        'Analytical': 100,
        'Creative': 40,
        'Business': 40,
        'Leadership': 40,
        'Research': 100,
      });

      final matches = service.calculateMatches(
        assessmentResult: result,
        careerProfiles: [businessProfile, technicalProfile],
      );

      expect(matches.first.career.id, technicalProfile.careerId);
      expect(matches.first.matchPercentage, 100);
    },
  );

  test('high business and leadership ranks similar profile first', () {
    final result = AssessmentResult({
      'Technical': 40,
      'Analytical': 60,
      'Creative': 60,
      'Business': 100,
      'Leadership': 100,
      'Research': 40,
    });

    final matches = service.calculateMatches(
      assessmentResult: result,
      careerProfiles: [technicalProfile, businessProfile],
    );

    expect(matches.first.career.id, businessProfile.careerId);
    expect(matches.first.matchPercentage, 100);
  });

  test('uses total profile distance divided by maximum difference of 24', () {
    final result = AssessmentResult({
      'Technical': 90,
      'Analytical': 96,
      'Creative': 50,
      'Business': 70,
      'Leadership': 50,
      'Research': 80,
    });
    const dataAnalystLikeProfile = CareerAssessmentProfile(
      id: 'profile-example',
      careerId: 'career-example',
      career: Career(
        id: 'career-example',
        careerName: 'Example Profile',
        category: 'Test',
        description: 'Formula example',
      ),
      technical: 4,
      analytical: 5,
      creative: 2,
      business: 4,
      leadership: 2,
      research: 3,
    );

    final match = service
        .calculateMatches(
          assessmentResult: result,
          careerProfiles: [dataAnalystLikeProfile],
        )
        .single;

    expect(match.matchPercentage, closeTo(86.6666667, 0.0001));
  });
}
