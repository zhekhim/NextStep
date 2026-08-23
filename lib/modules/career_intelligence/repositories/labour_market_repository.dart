import '../models/labour_force_statistic.dart';
import '../services/government_data_service.dart';

class LabourMarketRepository {
  LabourMarketRepository({GovernmentDataService? governmentDataService})
    : _governmentDataService =
          governmentDataService ?? GovernmentDataService();

  static const int recentMonthCount = 36;

  final GovernmentDataService _governmentDataService;

  Future<List<LabourForceStatistic>> getRecentMonthlyStatistics() async {
    final statistics =
        await _governmentDataService.getMonthlyLabourForce();
    return statistics.take(recentMonthCount).toList(growable: false);
  }
}
