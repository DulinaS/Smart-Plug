// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
  id: json['id'] as String,
  name: json['name'] as String,
  room: json['room'] as String?,
  status: DeviceStatus.fromJson(json['status'] as Map<String, dynamic>),
  lastSeen: DateTime.parse(json['lastSeen'] as String),
  firmwareVersion: json['firmwareVersion'] as String,
  isOnline: json['isOnline'] as bool,
  config: DeviceConfig.fromJson(json['config'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'room': instance.room,
  'status': instance.status,
  'lastSeen': instance.lastSeen.toIso8601String(),
  'firmwareVersion': instance.firmwareVersion,
  'isOnline': instance.isOnline,
  'config': instance.config,
};

DeviceStatus _$DeviceStatusFromJson(Map<String, dynamic> json) => DeviceStatus(
  isOn: json['isOn'] as bool,
  voltage: (json['voltage'] as num).toDouble(),
  current: (json['current'] as num).toDouble(),
  power: (json['power'] as num).toDouble(),
  energyToday: (json['energyToday'] as num).toDouble(),
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$DeviceStatusToJson(DeviceStatus instance) =>
    <String, dynamic>{
      'isOn': instance.isOn,
      'voltage': instance.voltage,
      'current': instance.current,
      'power': instance.power,
      'energyToday': instance.energyToday,
      'timestamp': instance.timestamp.toIso8601String(),
    };

DeviceConfig _$DeviceConfigFromJson(Map<String, dynamic> json) => DeviceConfig(
  maxCurrent: (json['maxCurrent'] as num).toDouble(),
  maxPower: (json['maxPower'] as num).toDouble(),
  safetyEnabled: json['safetyEnabled'] as bool,
  reportInterval: (json['reportInterval'] as num).toInt(),
);

Map<String, dynamic> _$DeviceConfigToJson(DeviceConfig instance) =>
    <String, dynamic>{
      'maxCurrent': instance.maxCurrent,
      'maxPower': instance.maxPower,
      'safetyEnabled': instance.safetyEnabled,
      'reportInterval': instance.reportInterval,
    };
