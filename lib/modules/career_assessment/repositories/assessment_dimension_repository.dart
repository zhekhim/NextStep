import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assessment_dimension.dart';

class AssessmentDimensionRepository {
  factory AssessmentDimensionRepository({SupabaseClient? client}) {
    return AssessmentDimensionRepository._(client);
  }

  AssessmentDimensionRepository._(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  Future<List<AssessmentDimension>> getDimensions() async {
    final rows = await _supabase
        .from('assessment_dimensions')
        .select('code, name, description, characteristics, display_order')
        .order('display_order');
    final dimensions = rows.map(AssessmentDimension.fromJson).toList();
    const displayOrder = ['R', 'I', 'A', 'S', 'E', 'C'];
    dimensions.sort(
      (left, right) => displayOrder
          .indexOf(left.code)
          .compareTo(displayOrder.indexOf(right.code)),
    );
    return dimensions;
  }
}
