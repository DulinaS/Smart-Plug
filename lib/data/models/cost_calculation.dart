/// Cost calculation result from the API
class CostCalculationResult {
  final String id;
  final String type;
  final String deviceId;
  final String consumerType;
  final DateTime fromDate;
  final DateTime toDate;
  final int totalDays;
  final double totalEnergyKWh;
  final double totalCostLKR;
  final DateTime generatedAt;

  const CostCalculationResult({
    required this.id,
    required this.type,
    required this.deviceId,
    required this.consumerType,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.totalEnergyKWh,
    required this.totalCostLKR,
    required this.generatedAt,
  });

  factory CostCalculationResult.fromJson(Map<String, dynamic> json) {
    return CostCalculationResult(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'custom_range',
      deviceId: json['device_id'] as String? ?? '',
      consumerType: json['consumer_type'] as String? ?? 'domestic',
      fromDate: DateTime.parse(json['from_date'] as String),
      toDate: DateTime.parse(json['to_date'] as String),
      totalDays: json['total_days'] as int? ?? 0,
      totalEnergyKWh: (json['total_energy_kWh'] as num?)?.toDouble() ?? 0.0,
      totalCostLKR: (json['total_cost_LKR'] as num?)?.toDouble() ?? 0.0,
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'device_id': deviceId,
      'consumer_type': consumerType,
      'from_date': fromDate.toIso8601String().split('T')[0],
      'to_date': toDate.toIso8601String().split('T')[0],
      'total_days': totalDays,
      'total_energy_kWh': totalEnergyKWh,
      'total_cost_LKR': totalCostLKR,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  CostCalculationResult copyWith({
    String? id,
    String? type,
    String? deviceId,
    String? consumerType,
    DateTime? fromDate,
    DateTime? toDate,
    int? totalDays,
    double? totalEnergyKWh,
    double? totalCostLKR,
    DateTime? generatedAt,
  }) {
    return CostCalculationResult(
      id: id ?? this.id,
      type: type ?? this.type,
      deviceId: deviceId ?? this.deviceId,
      consumerType: consumerType ?? this.consumerType,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      totalDays: totalDays ?? this.totalDays,
      totalEnergyKWh: totalEnergyKWh ?? this.totalEnergyKWh,
      totalCostLKR: totalCostLKR ?? this.totalCostLKR,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
