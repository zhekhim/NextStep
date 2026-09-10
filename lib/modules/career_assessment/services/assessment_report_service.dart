import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../career_intelligence/models/career.dart';
import '../models/assessment_dimension.dart';
import 'riasec_scoring_service.dart';

class AssessmentReportService {
  Future<Uint8List> generate({
    required RiasecResult result,
    required List<Career> careers,
    required Map<String, AssessmentDimension> dimensions,
    required DateTime generatedAt,
  }) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        footer: (context) => pw.Text(
          'NextStep | Page ${context.pageNumber} of ${context.pagesCount}',
        ),
        build: (context) => [
          pw.Header(level: 0, text: 'NextStep Assessment Report'),
          pw.Text('Generated: ${generatedAt.toUtc().toIso8601String()}'),
          pw.Header(level: 1, text: 'RIASEC code: ${result.code}'),
          pw.Text('Percentage = (total / question count - 1) / 4 x 100.'),
          pw.Text(
            'Ranked by total, then more 5s, more 4s, fewer 1s, fewer 2s, then R, I, A, S, E, C.',
          ),
          pw.SizedBox(height: 12),
          for (final score in result.rankedScores)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(
                '${dimensions[score.dimension]?.name ?? score.dimension}: ${score.percentage.toStringAsFixed(2)}% | Total ${score.totalScore} / ${score.questionCount * 5} | ${score.questionCount} questions',
              ),
            ),
          pw.Header(level: 1, text: 'Strongest areas'),
          for (final score in result.strongestDimensions) ...[
            pw.Header(
              level: 2,
              text: dimensions[score.dimension]?.name ?? score.dimension,
            ),
            pw.Text(
              dimensions[score.dimension]?.description ??
                  'Details unavailable.',
            ),
            pw.Text(
              'Characteristics: ${dimensions[score.dimension]?.characteristics ?? 'Unavailable'}',
            ),
          ],
          pw.Header(level: 1, text: 'Career recommendations'),
          if (careers.isEmpty) pw.Text('No careers match this RIASEC code.'),
          for (var i = 0; i < careers.length; i++) ...[
            pw.Header(level: 2, text: '${i + 1}. ${careers[i].careerName}'),
            pw.Text(careers[i].description),
          ],
        ],
      ),
    );
    return document.save();
  }

  Future<String> upload(Uint8List bytes) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to save a report.');
    final path = '$userId/${const Uuid().v4()}.pdf';
    await client.storage
        .from('assessment-reports')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
    return path;
  }
}
