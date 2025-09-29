import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'sensor_reading.g.dart';

@JsonSerializable()
class SensorReading {
  final double voltage;
  final double current;
  final double power;
  final String timestamp;

  const SensorReading({
    required this.voltage,
    required this.current,
    required this.power,
    required this.timestamp,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) =>
      _$SensorReadingFromJson(json);

  Map<String, dynamic> toJson() => _$SensorReadingToJson(this);

  // Helper to parse your friend's nested response
  factory SensorReading.fromApiResponse(Map<String, dynamic> apiResponse) {
    final bodyString = apiResponse['body'] as String;
    final bodyJson = jsonDecode(bodyString);
    return SensorReading.fromJson(bodyJson);
  }
}

@JsonSerializable()
class DeviceCommand {
  final String command; // "ON" or "OFF"

  const DeviceCommand({required this.command});

  factory DeviceCommand.fromJson(Map<String, dynamic> json) =>
      _$DeviceCommandFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceCommandToJson(this);
}
