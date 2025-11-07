class RangeDay {
  final DateTime date; // date-only (UTC)
  final bool hasData;
  final double totalPower; // from total_power (kWh)
  final double avgPower; // W
  final double avgCurrent; // A
  final double avgVoltage; // V

  const RangeDay({
    required this.date,
    required this.hasData,
    required this.totalPower,
    required this.avgPower,
    required this.avgCurrent,
    required this.avgVoltage,
  });

  RangeDay copyWith({
    DateTime? date,
    bool? hasData,
    double? totalPower,
    double? avgPower,
    double? avgCurrent,
    double? avgVoltage,
  }) {
    return RangeDay(
      date: date ?? this.date,
      hasData: hasData ?? this.hasData,
      totalPower: totalPower ?? this.totalPower,
      avgPower: avgPower ?? this.avgPower,
      avgCurrent: avgCurrent ?? this.avgCurrent,
      avgVoltage: avgVoltage ?? this.avgVoltage,
    );
  }
}
