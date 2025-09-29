import 'package:json_annotation/json_annotation.dart';

import 'sensor_reading.dart';

part 'device.g.dart';

@JsonSerializable()
class Device {
  final String id;
  final String name;
  final String? room;
  final DeviceStatus status;
  final DateTime lastSeen;
  final String firmwareVersion;
  final bool isOnline;
  final DeviceConfig config;

  const Device({
    required this.id,
    required this.name,
    this.room,
    required this.status,
    required this.lastSeen,
    required this.firmwareVersion,
    required this.isOnline,
    required this.config,
  });

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceToJson(this);
}

@JsonSerializable()
class DeviceStatus {
  final bool isOn;
  final double voltage;
  final double current;
  final double power;
  final double energyToday;
  final DateTime timestamp;

  const DeviceStatus({
    required this.isOn,
    required this.voltage,
    required this.current,
    required this.power,
    required this.energyToday,
    required this.timestamp,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) =>
      _$DeviceStatusFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceStatusToJson(this);
}

@JsonSerializable()
class DeviceConfig {
  final double maxCurrent;
  final double maxPower;
  final bool safetyEnabled;
  final int reportInterval; // seconds

  const DeviceConfig({
    required this.maxCurrent,
    required this.maxPower,
    required this.safetyEnabled,
    required this.reportInterval,
  });

  factory DeviceConfig.fromJson(Map<String, dynamic> json) =>
      _$DeviceConfigFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceConfigToJson(this);
}

// Add this extension to your existing Device model
extension DeviceExtensions on Device {
  // Convert SensorReading to DeviceStatus
  static DeviceStatus statusFromSensorReading(SensorReading reading) {
    return DeviceStatus(
      isOn: reading.power > 5.0, // Device is ON if power > 5W
      voltage: reading.voltage,
      current: reading.current,
      power: reading.power,
      energyToday: 0.0, // Calculate from historical data if available
      timestamp: DateTime.parse(reading.timestamp),
    );
  }
}
