/* import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  // In-memory storage for demo (replace with real API calls later)
  final List<Schedule> _schedules = [];

  Future<List<Schedule>> getSchedules(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
    
    // Return device-specific schedules
    final deviceSchedules = _schedules.where((s) => s.deviceId == deviceId).toList();
    
    // If no schedules exist, create some sample ones
    if (deviceSchedules.isEmpty) {
      final sampleSchedules = [
        Schedule(
          id: 'schedule-1-$deviceId',
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
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Schedule(
          id: 'schedule-2-$deviceId',
          deviceId: deviceId,
          name: 'Night OFF',
          type: ScheduleType.daily,
          startTime: const ScheduleTime(hour: 23, minute: 0),
          endTime: null,
          weekdays: [
            Weekday.monday,
            Weekday.tuesday,
            Weekday.wednesday,
            Weekday.thursday,
            Weekday.friday,
            Weekday.saturday,
            Weekday.sunday,
          ],
          action: ScheduleAction.turnOff,
          isEnabled: false,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
      
      _schedules.addAll(sampleSchedules);
      return sampleSchedules;
    }
    
    return deviceSchedules;
  }

  Future<void> createSchedule(Schedule schedule) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Replace with actual API call to your friend's backend
    // Example: await _httpClient.post('/schedules', data: schedule.toJson());
    
    _schedules.add(schedule);
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Replace with actual API call
    // Example: await _httpClient.put('/schedules/${schedule.id}', data: schedule.toJson());
    
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _schedules[index] = schedule;
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Replace with actual API call
    // Example: await _httpClient.delete('/schedules/$scheduleId');
    
    _schedules.removeWhere((s) => s.id == scheduleId);
  }

  Future<void> toggleSchedule(String scheduleId, bool isEnabled) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      final schedule = _schedules[index];
      _schedules[index] = Schedule(
        id: schedule.id,
        deviceId: schedule.deviceId,
        name: schedule.name,
        type: schedule.type,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        weekdays: schedule.weekdays,
        action: schedule.action,
        isEnabled: isEnabled,
        createdAt: schedule.createdAt,
      );
    }
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository();
}); */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  // In-memory storage for demo (replace with real API calls later)
  final List<Schedule> _schedules = [];

  Future<List<Schedule>> getSchedules(String deviceId) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate API call

    // Return device-specific schedules
    final deviceSchedules = _schedules
        .where((s) => s.deviceId == deviceId)
        .toList();

    // If no schedules exist, create some sample ones
    if (deviceSchedules.isEmpty) {
      final sampleSchedules = [
        Schedule(
          id: 'schedule-1-$deviceId',
          deviceId: deviceId,
          name: 'Morning ON',
          type: ScheduleType.daily,
          startTime: const ScheduleTime(hour: 7, minute: 0), // Use ScheduleTime
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
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Schedule(
          id: 'schedule-2-$deviceId',
          deviceId: deviceId,
          name: 'Night OFF',
          type: ScheduleType.daily,
          startTime: const ScheduleTime(
            hour: 23,
            minute: 0,
          ), // Use ScheduleTime
          endTime: null,
          weekdays: [
            Weekday.monday,
            Weekday.tuesday,
            Weekday.wednesday,
            Weekday.thursday,
            Weekday.friday,
            Weekday.saturday,
            Weekday.sunday,
          ],
          action: ScheduleAction.turnOff,
          isEnabled: false,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];

      _schedules.addAll(sampleSchedules);
      return sampleSchedules;
    }

    return deviceSchedules;
  }

  Future<void> createSchedule(Schedule schedule) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with actual API call to your friend's backend
    // Example: await _httpClient.post('/schedules', data: schedule.toJson());

    _schedules.add(schedule);
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with actual API call
    // Example: await _httpClient.put('/schedules/${schedule.id}', data: schedule.toJson());

    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _schedules[index] = schedule;
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with actual API call
    // Example: await _httpClient.delete('/schedules/$scheduleId');

    _schedules.removeWhere((s) => s.id == scheduleId);
  }

  Future<void> toggleSchedule(String scheduleId, bool isEnabled) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      final schedule = _schedules[index];
      _schedules[index] = Schedule(
        id: schedule.id,
        deviceId: schedule.deviceId,
        name: schedule.name,
        type: schedule.type,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        weekdays: schedule.weekdays,
        action: schedule.action,
        isEnabled: isEnabled,
        createdAt: schedule.createdAt,
      );
    }
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository();
});
