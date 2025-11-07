class DailySummary {
  final String deviceId;
  final DateTime summaryDate; // date-only in UTC
  final double totalPower; // kWh (from total_power)
  final double avgPower; // W
  final double avgCurrent; // A
  final double avgVoltage; // V
  final String? id;

  DailySummary({
    required this.deviceId,
    required this.summaryDate,
    required this.totalPower,
    required this.avgPower,
    required this.avgCurrent,
    required this.avgVoltage,
    this.id,
  });

  factory DailySummary.fromRecord(Map<String, dynamic> json) {
    return DailySummary(
      deviceId: (json['device_id'] ?? json['deviceId'] ?? '').toString(),
      summaryDate: DateTime.parse(json['summary_date']),
      totalPower: (json['total_power'] ?? 0).toDouble(),
      avgPower: (json['avg_power'] ?? 0).toDouble(),
      avgCurrent: (json['avg_current'] ?? 0).toDouble(),
      avgVoltage: (json['avg_voltage'] ?? 0).toDouble(),
      id: json['id']?.toString(),
    );
  }
}
