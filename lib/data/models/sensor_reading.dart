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

  // Improved helper to parse API response with better error handling
  factory SensorReading.fromApiResponse(dynamic apiResponse) {
    try {
      // Handle case where response is already a Map
      if (apiResponse is Map<String, dynamic>) {
        // Check if it has a 'body' field (AWS Lambda response format)
        if (apiResponse.containsKey('body')) {
          final bodyString = apiResponse['body'];
          if (bodyString is String) {
            final bodyJson = jsonDecode(bodyString);
            return SensorReading.fromJson(bodyJson);
          } else if (bodyString is Map<String, dynamic>) {
            return SensorReading.fromJson(bodyString);
          }
        }
        // Direct JSON response
        return SensorReading.fromJson(apiResponse);
      }

      // Handle case where response is a String
      if (apiResponse is String) {
        final jsonData = jsonDecode(apiResponse);
        return SensorReading.fromJson(jsonData);
      }

      throw Exception('Unexpected response format: ${apiResponse.runtimeType}');
    } catch (e) {
      print('Error parsing sensor reading: $e');
      print('Response data: $apiResponse');

      // Return mock data when parsing fails
      return SensorReading(
        voltage: 0.0,
        current: 0.0,
        power: 0.0,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
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
