import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/employment_stat.dart';

class EmploymentDatasetLoader {
  const EmploymentDatasetLoader();

  Future<List<EmploymentStat>> load() async {
    final jsonText = await rootBundle.loadString(
      'assets/data/employment_stats.json',
    );
    final decoded = jsonDecode(jsonText) as List<dynamic>;
    return decoded
        .map((item) => EmploymentStat.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
