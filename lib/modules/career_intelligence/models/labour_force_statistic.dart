class LabourForceStatistic {
  const LabourForceStatistic({
    required this.date,
    required this.labourForce,
    required this.employed,
    required this.unemployed,
    required this.outsideLabourForce,
    required this.unemploymentRate,
    required this.participationRate,
    required this.employmentPopulationRatio,
  });

  final DateTime date;
  final double labourForce;
  final double employed;
  final double unemployed;
  final double outsideLabourForce;
  final double unemploymentRate;
  final double participationRate;
  final double employmentPopulationRatio;

  factory LabourForceStatistic.fromJson(Map<String, dynamic> json) {
    return LabourForceStatistic(
      date: DateTime.parse(json['date'] as String),
      labourForce: _toDouble(json['lf']),
      employed: _toDouble(json['lf_employed']),
      unemployed: _toDouble(json['lf_unemployed']),
      outsideLabourForce: _toDouble(json['lf_outside']),
      unemploymentRate: _toDouble(json['u_rate']),
      participationRate: _toDouble(json['p_rate']),
      employmentPopulationRatio: _toDouble(json['ep_ratio']),
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.parse(value.toString());
  }
}
