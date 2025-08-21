// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telemetry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TelemetryReading _$TelemetryReadingFromJson(Map<String, dynamic> json) =>
    TelemetryReading(
      timestamp: DateTime.parse(json['timestamp'] as String),
      voltage: (json['voltage'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      power: (json['power'] as num).toDouble(),
      energy: (json['energy'] as num).toDouble(),
      relayState: json['relayState'] as bool,
    );

Map<String, dynamic> _$TelemetryReadingToJson(TelemetryReading instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'voltage': instance.voltage,
      'current': instance.current,
      'power': instance.power,
      'energy': instance.energy,
      'relayState': instance.relayState,
    };

UsageSummary _$UsageSummaryFromJson(Map<String, dynamic> json) => UsageSummary(
  deviceId: json['deviceId'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  totalEnergy: (json['totalEnergy'] as num).toDouble(),
  totalCost: (json['totalCost'] as num).toDouble(),
  avgPower: (json['avgPower'] as num).toDouble(),
  peakPower: (json['peakPower'] as num).toDouble(),
  hourlyData: (json['hourlyData'] as List<dynamic>)
      .map((e) => HourlyUsage.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UsageSummaryToJson(UsageSummary instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'totalEnergy': instance.totalEnergy,
      'totalCost': instance.totalCost,
      'avgPower': instance.avgPower,
      'peakPower': instance.peakPower,
      'hourlyData': instance.hourlyData,
    };

HourlyUsage _$HourlyUsageFromJson(Map<String, dynamic> json) => HourlyUsage(
  hour: DateTime.parse(json['hour'] as String),
  energy: (json['energy'] as num).toDouble(),
  avgPower: (json['avgPower'] as num).toDouble(),
  cost: (json['cost'] as num).toDouble(),
);

Map<String, dynamic> _$HourlyUsageToJson(HourlyUsage instance) =>
    <String, dynamic>{
      'hour': instance.hour.toIso8601String(),
      'energy': instance.energy,
      'avgPower': instance.avgPower,
      'cost': instance.cost,
    };
