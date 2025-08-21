import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/schedule.dart';
import '../../../data/repositories/schedule_repo.dart';

class ScheduleState {
  final List<Schedule> schedules;
  final bool isLoading;
  final String? error;

  const ScheduleState({
    this.schedules = const [],
    this.isLoading = false,
    this.error,
  });

  ScheduleState copyWith({
    List<Schedule>? schedules,
    bool? isLoading,
    String? error,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ScheduleController extends StateNotifier<ScheduleState> {
  final ScheduleRepository _scheduleRepository;
  final String deviceId;

  ScheduleController(this._scheduleRepository, this.deviceId)
    : super(const ScheduleState()) {
    loadSchedules();
  }

  Future<void> loadSchedules() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final schedules = await _scheduleRepository.getSchedules(deviceId);
      state = state.copyWith(schedules: schedules, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createSchedule(Schedule schedule) async {
    try {
      await _scheduleRepository.createSchedule(schedule);

      // Add to local state
      final updatedSchedules = [...state.schedules, schedule];
      state = state.copyWith(schedules: updatedSchedules);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateSchedule(Schedule schedule) async {
    try {
      await _scheduleRepository.updateSchedule(schedule);

      // Update local state
      final updatedSchedules = state.schedules.map((s) {
        return s.id == schedule.id ? schedule : s;
      }).toList();

      state = state.copyWith(schedules: updatedSchedules);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _scheduleRepository.deleteSchedule(scheduleId);

      // Remove from local state
      final updatedSchedules = state.schedules
          .where((s) => s.id != scheduleId)
          .toList();

      state = state.copyWith(schedules: updatedSchedules);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleSchedule(String scheduleId, bool isEnabled) async {
    final scheduleIndex = state.schedules.indexWhere((s) => s.id == scheduleId);
    if (scheduleIndex == -1) return;

    final schedule = state.schedules[scheduleIndex];
    final updatedSchedule = Schedule(
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

    await updateSchedule(updatedSchedule);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final scheduleControllerProvider =
    StateNotifierProvider.family<ScheduleController, ScheduleState, String>((
      ref,
      deviceId,
    ) {
      final scheduleRepository = ref.read(scheduleRepositoryProvider);
      return ScheduleController(scheduleRepository, deviceId);
    });
