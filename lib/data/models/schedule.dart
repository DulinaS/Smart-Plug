import 'package:json_annotation/json_annotation.dart';

part 'schedule.g.dart';

@JsonSerializable()
class Schedule {
  final String id;
  final String deviceId;
  final String name;
  final ScheduleType type;
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
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
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromJson(Map<String, dynamic> json) =>
      _$TimeOfDayFromJson(json);
  Map<String, dynamic> toJson() => _$TimeOfDayToJson(this);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
