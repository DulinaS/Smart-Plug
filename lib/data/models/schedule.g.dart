// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Schedule _$ScheduleFromJson(Map<String, dynamic> json) => Schedule(
  id: json['id'] as String,
  deviceId: json['deviceId'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$ScheduleTypeEnumMap, json['type']),
  startTime: ScheduleTime.fromJson(json['startTime'] as Map<String, dynamic>),
  endTime: json['endTime'] == null
      ? null
      : ScheduleTime.fromJson(json['endTime'] as Map<String, dynamic>),
  weekdays: (json['weekdays'] as List<dynamic>)
      .map((e) => $enumDecode(_$WeekdayEnumMap, e))
      .toList(),
  action: $enumDecode(_$ScheduleActionEnumMap, json['action']),
  isEnabled: json['isEnabled'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ScheduleToJson(Schedule instance) => <String, dynamic>{
  'id': instance.id,
  'deviceId': instance.deviceId,
  'name': instance.name,
  'type': _$ScheduleTypeEnumMap[instance.type]!,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
  'weekdays': instance.weekdays.map((e) => _$WeekdayEnumMap[e]!).toList(),
  'action': _$ScheduleActionEnumMap[instance.action]!,
  'isEnabled': instance.isEnabled,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$ScheduleTypeEnumMap = {
  ScheduleType.once: 'once',
  ScheduleType.daily: 'daily',
  ScheduleType.weekly: 'weekly',
  ScheduleType.custom: 'custom',
};

const _$WeekdayEnumMap = {
  Weekday.monday: 'monday',
  Weekday.tuesday: 'tuesday',
  Weekday.wednesday: 'wednesday',
  Weekday.thursday: 'thursday',
  Weekday.friday: 'friday',
  Weekday.saturday: 'saturday',
  Weekday.sunday: 'sunday',
};

const _$ScheduleActionEnumMap = {
  ScheduleAction.turnOn: 'turnOn',
  ScheduleAction.turnOff: 'turnOff',
};

ScheduleTime _$ScheduleTimeFromJson(Map<String, dynamic> json) => ScheduleTime(
  hour: (json['hour'] as num).toInt(),
  minute: (json['minute'] as num).toInt(),
);

Map<String, dynamic> _$ScheduleTimeToJson(ScheduleTime instance) =>
    <String, dynamic>{'hour': instance.hour, 'minute': instance.minute};
