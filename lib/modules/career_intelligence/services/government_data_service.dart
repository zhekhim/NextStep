import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/labour_force_statistic.dart';

class GovernmentDataService {
  static const String _baseUrl = 'https://api.data.gov.my/data-catalogue';

  Future<List<LabourForceStatistic>> getMonthlyLabourForce() async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: const {
        'id': 'lfs_month',
        'limit': '36',
        'sort': '-date',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      final statistics =
          data
              .map(
                (record) => LabourForceStatistic.fromJson(
                  record as Map<String, dynamic>,
                ),
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

      return statistics;
    }

    throw Exception('Failed to load labour force data: ${response.statusCode}');
  }
}
