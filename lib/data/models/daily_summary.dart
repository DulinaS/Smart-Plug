class DailySummary {
  final String deviceId;
  final DateTime summaryDate; // date-only in UTC
  final double totalEnergy; // kWh (converted from total_power Wh / 1000)
  final double avgPower; // W
  final double avgCurrent; // A
  final double avgVoltage; // V
  final String? id;

  DailySummary({
    required this.deviceId,
    required this.summaryDate,
    required this.totalEnergy,
    required this.avgPower,
    required this.avgCurrent,
    required this.avgVoltage,
    this.id,
  });

  factory DailySummary.fromRecord(Map<String, dynamic> json) {
    // Convert total_power from Wh to kWh (divide by 1000)
    final totalPowerWh = (json['total_power'] ?? 0).toDouble();
    return DailySummary(
      deviceId: (json['device_id'] ?? json['deviceId'] ?? '').toString(),
      summaryDate: DateTime.parse(json['summary_date']),
      totalEnergy: totalPowerWh / 1000.0, // Wh → kWh
      avgPower: (json['avg_power'] ?? 0).toDouble(),
      avgCurrent: (json['avg_current'] ?? 0).toDouble(),
      avgVoltage: (json['avg_voltage'] ?? 0).toDouble(),
      id: json['id']?.toString(),
    );
  }
}
