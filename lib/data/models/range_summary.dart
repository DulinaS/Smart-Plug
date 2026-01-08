class RangeDay {
  final DateTime date; // date-only (UTC)
  final bool hasData;
  final double totalEnergy; // kWh (converted from total_power Wh / 1000)
  final double avgPower; // W
  final double avgCurrent; // A
  final double avgVoltage; // V

  const RangeDay({
    required this.date,
    required this.hasData,
    required this.totalEnergy,
    required this.avgPower,
    required this.avgCurrent,
    required this.avgVoltage,
  });

  RangeDay copyWith({
    DateTime? date,
    bool? hasData,
    double? totalEnergy,
    double? avgPower,
    double? avgCurrent,
    double? avgVoltage,
  }) {
    return RangeDay(
      date: date ?? this.date,
      hasData: hasData ?? this.hasData,
      totalEnergy: totalEnergy ?? this.totalEnergy,
      avgPower: avgPower ?? this.avgPower,
      avgCurrent: avgCurrent ?? this.avgCurrent,
      avgVoltage: avgVoltage ?? this.avgVoltage,
    );
  }
}
