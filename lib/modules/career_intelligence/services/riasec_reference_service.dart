import '../models/riasec_type.dart';

class RiasecReferenceService {
  const RiasecReferenceService();

  static const String sourceName =
      'Ministry of Higher Education Malaysia (MOHE) e-Profiling';
  static const String sourceUrl = 'https://eprofiling.mohe.gov.my/';
  static const String translationNote =
      'English translation based on the Malaysian Ministry of Higher Education e-Profiling content.';

  List<RiasecType> getTypes() => const [
    RiasecType(
      code: 'R',
      name: 'Realistic',
      description:
          'Assertive individuals who prefer concrete tasks over abstract ones and generally have less interest in social and interpersonal interaction.',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
    ),
    RiasecType(
      code: 'I',
      name: 'Investigative',
      description:
          'Intellectual, abstract-thinking, analytical, independent and task-oriented individuals who may sometimes be radical.',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
    ),
    RiasecType(
      code: 'A',
      name: 'Artistic',
      description:
          'Imaginative, expressive and independent individuals who place a high value on aesthetics and tend to be fairly outgoing.',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
    ),
    RiasecType(
      code: 'S',
      name: 'Social',
      description:
          'Individuals who prefer social interaction and are oriented towards community, religious and educational work.',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
    ),
    RiasecType(
      code: 'E',
      name: 'Enterprising',
      description:
          'Outgoing and assertive individuals who enjoy travelling and leadership roles and are skilled at persuasion and using words.',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
    ),
    RiasecType(
      code: 'C',
      name: 'Conventional',
      description:
          'Practical, self-controlled and sociable individuals who tend to be conservative, prefer structured tasks and follow established rules.',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
    ),
  ];
}
