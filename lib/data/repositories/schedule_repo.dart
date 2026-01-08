import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../../core/config/env.dart';
import '../../core/utils/error_handler.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  final HttpClient _httpClient;

  ScheduleRepository(this._httpClient);

  Future<List<Schedule>> getSchedules(String deviceId) async {
    try {
      final response = await _httpClient.dio.post(
        '${AppConfig.scheduleBaseUrl}/list-device-schedules',
        data: {'deviceId': deviceId},
      );

      final List<dynamic> schedulesData = response.data['schedules'] ?? [];

      return schedulesData.map((data) {
        return Schedule(
          id: data['scheduleName'] ?? data['turnOnScheduleName'] ?? '',
          deviceId: data['deviceId'] ?? deviceId,
          name: data['name'] ?? 'Schedule',
          type: ScheduleType.daily,
          startTime: ScheduleTime(
            hour: data['startTime']?['hour'] ?? 0,
            minute: data['startTime']?['minute'] ?? 0,
          ),
          endTime: data['endTime'] != null
              ? ScheduleTime(
                  hour: data['endTime']['hour'] ?? 0,
                  minute: data['endTime']['minute'] ?? 0,
                )
              : null,
          weekdays: _parseWeekdays(data['weekdays'] ?? []),
          action: ScheduleAction.turnOn,
          isEnabled: data['isEnabled'] ?? true,
          createdAt:
              DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
        );
      }).toList();
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e, context: 'Load schedules');
    } catch (e) {
      return _getMockSchedules(deviceId);
    }
  }

  Future<void> createSchedule(Schedule schedule) async {
    try {
      await _httpClient.dio.post(
        '${AppConfig.scheduleBaseUrl}/create-schedule',
        data: {
          'deviceId': schedule.deviceId,
          'name': schedule.name,
          'startTime': {
            'hour': schedule.startTime.hour,
            'minute': schedule.startTime.minute,
          },
          'endTime': schedule.endTime != null
              ? {
                  'hour': schedule.endTime!.hour,
                  'minute': schedule.endTime!.minute,
                }
              : {'hour': 0, 'minute': 0},
          'weekdays': schedule.weekdays.map(_weekdayToString).toList(),
          'isEnabled': schedule.isEnabled,
        },
      );
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e, context: 'Create schedule');
    } catch (e) {
      throw ErrorHandler.handleException(e, context: 'Create schedule');
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _httpClient.dio.post(
        '${AppConfig.scheduleBaseUrl}/delete-schedule',
        data: {'scheduleName': scheduleId},
      );
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e, context: 'Delete schedule');
    } catch (e) {
      throw ErrorHandler.handleException(e, context: 'Delete schedule');
    }
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await deleteSchedule(schedule.id);
    await createSchedule(schedule);
  }

  Future<void> toggleSchedule(String scheduleId, bool isEnabled) async {
    throw UnimplementedError('Toggle not supported by backend');
  }

  String _weekdayToString(Weekday weekday) {
    return weekday.toString().split('.').last;
  }

  List<Weekday> _parseWeekdays(List<dynamic> weekdayStrings) {
    final Map<String, Weekday> weekdayMap = {
      'monday': Weekday.monday,
      'tuesday': Weekday.tuesday,
      'wednesday': Weekday.wednesday,
      'thursday': Weekday.thursday,
      'friday': Weekday.friday,
      'saturday': Weekday.saturday,
      'sunday': Weekday.sunday,
    };

    return weekdayStrings
        .map((day) => weekdayMap[day.toString().toLowerCase()])
        .whereType<Weekday>()
        .toList();
  }

  List<Schedule> _getMockSchedules(String deviceId) {
    return [
      Schedule(
        id: 'mock-1',
        deviceId: deviceId,
        name: 'Morning ON',
        type: ScheduleType.daily,
        startTime: const ScheduleTime(hour: 7, minute: 0),
        endTime: null,
        weekdays: [
          Weekday.monday,
          Weekday.tuesday,
          Weekday.wednesday,
          Weekday.thursday,
          Weekday.friday,
        ],
        action: ScheduleAction.turnOn,
        isEnabled: true,
        createdAt: DateTime.now(),
      ),
    ];
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final httpClient = ref.read(httpClientProvider);
  return ScheduleRepository(httpClient);
});
