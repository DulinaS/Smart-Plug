/* import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'schedule.g.dart';

// In lib/data/models/schedule.dart

enum ScheduleType {
  once,
  daily,
  weekly,
}

@JsonSerializable()
class ScheduleTime {
  final int hour;
  final int minute;

  const ScheduleTime({required this.hour, required this.minute});

  factory ScheduleTime.fromJson(Map<String, dynamic> json) => 
      _$ScheduleTimeFromJson(json);
  Map<String, dynamic> toJson() => _$ScheduleTimeToJson(this);

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  
  // Convert from Flutter's TimeOfDay
  factory ScheduleTime.fromTimeOfDay(TimeOfDay timeOfDay) {
    return ScheduleTime(hour: timeOfDay.hour, minute: timeOfDay.minute);
  }
  
  // Convert to Flutter's TimeOfDay  
  TimeOfDay toTimeOfDay() {
    return TimeOfDay(hour: hour, minute: minute);
  }
}

// Define Weekday enum
enum Weekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

// Define ScheduleAction enum or class
enum ScheduleAction {
  turnOn,
  turnOff,
}

@JsonSerializable()
class Schedule {
  final String id;
  final String deviceId;
  final String name;
  final ScheduleType type;
  final ScheduleTime startTime; // Changed from TimeOfDay
  final ScheduleTime? endTime;  // Changed from TimeOfDay
  final List<Weekday> weekdays;
  final ScheduleAction action;
  final bool isEnabled;
  final DateTime createdAt;

  const Schedule({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.type,
    required this.startTime,
    this.endTime,
    required this.weekdays,
    required this.action,
    required this.isEnabled,
    required this.createdAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) => 
      _$ScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$ScheduleToJson(this);
} */
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart' as material;

part 'schedule.g.dart';

@JsonSerializable()
class Schedule {
  final String id;
  final String deviceId;
  final String name;
  final ScheduleType type;
  final ScheduleTime startTime; // Changed from TimeOfDay to ScheduleTime
  final ScheduleTime? endTime; // Changed from TimeOfDay to ScheduleTime
  final List<Weekday> weekdays;
  final ScheduleAction action;
  final bool isEnabled;
  final DateTime createdAt;

  const Schedule({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.type,
    required this.startTime,
    this.endTime,
    required this.weekdays,
    required this.action,
    required this.isEnabled,
    required this.createdAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) =>
      _$ScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$ScheduleToJson(this);
}

enum ScheduleType { once, daily, weekly, custom }

enum ScheduleAction { turnOn, turnOff }

enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

@JsonSerializable()
class ScheduleTime {
  // Renamed from TimeOfDay to ScheduleTime
  final int hour;
  final int minute;

  const ScheduleTime({required this.hour, required this.minute});

  factory ScheduleTime.fromJson(Map<String, dynamic> json) =>
      _$ScheduleTimeFromJson(json);
  Map<String, dynamic> toJson() => _$ScheduleTimeToJson(this);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  // Convert from Flutter's TimeOfDay
  factory ScheduleTime.fromTimeOfDay(material.TimeOfDay timeOfDay) {
    return ScheduleTime(hour: timeOfDay.hour, minute: timeOfDay.minute);
  }

  // Convert to Flutter's TimeOfDay
  material.TimeOfDay toTimeOfDay() {
    return material.TimeOfDay(hour: hour, minute: minute);
  }
}
