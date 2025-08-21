import 'package:json_annotation/json_annotation.dart';

part 'telemetry.g.dart';

@JsonSerializable()
class TelemetryReading {
  final DateTime timestamp;
  final double voltage;
  final double current;
  final double power;
  final double energy; // cumulative kWh
  final bool relayState;

  const TelemetryReading({
    required this.timestamp,
    required this.voltage,
    required this.current,
    required this.power,
    required this.energy,
    required this.relayState,
  });

  factory TelemetryReading.fromJson(Map<String, dynamic> json) =>
      _$TelemetryReadingFromJson(json);
  Map<String, dynamic> toJson() => _$TelemetryReadingToJson(this);
}

@JsonSerializable()
class UsageSummary {
  final String deviceId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalEnergy; // kWh
  final double totalCost; // LKR
  final double avgPower; // W
  final double peakPower; // W
  final List<HourlyUsage> hourlyData;

  const UsageSummary({
    required this.deviceId,
    required this.startDate,
    required this.endDate,
    required this.totalEnergy,
    required this.totalCost,
    required this.avgPower,
    required this.peakPower,
    required this.hourlyData,
  });

  factory UsageSummary.fromJson(Map<String, dynamic> json) =>
      _$UsageSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$UsageSummaryToJson(this);
}

@JsonSerializable()
class HourlyUsage {
  final DateTime hour;
  final double energy; // kWh for this hour
  final double avgPower; // W
  final double cost; // LKR

  const HourlyUsage({
    required this.hour,
    required this.energy,
    required this.avgPower,
    required this.cost,
  });

  factory HourlyUsage.fromJson(Map<String, dynamic> json) =>
      _$HourlyUsageFromJson(json);
  Map<String, dynamic> toJson() => _$HourlyUsageToJson(this);
}
