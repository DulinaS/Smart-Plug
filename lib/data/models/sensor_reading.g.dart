// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_reading.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SensorReading _$SensorReadingFromJson(Map<String, dynamic> json) =>
    SensorReading(
      voltage: (json['voltage'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      power: (json['power'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$SensorReadingToJson(SensorReading instance) =>
    <String, dynamic>{
      'voltage': instance.voltage,
      'current': instance.current,
      'power': instance.power,
      'timestamp': instance.timestamp,
    };

DeviceCommand _$DeviceCommandFromJson(Map<String, dynamic> json) =>
    DeviceCommand(command: json['command'] as String);

Map<String, dynamic> _$DeviceCommandToJson(DeviceCommand instance) =>
    <String, dynamic>{'command': instance.command};
