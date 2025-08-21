import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_plug/data/models/sensor_reading.dart';
import '../../../data/models/device.dart';
import '../../../data/repositories/device_repo.dart';
import '../../../data/repositories/realtime_repo.dart';

class DashboardState {
  final List<Device> devices;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;

  const DashboardState({
    this.devices = const [],
    this.isLoading = false,
    this.error,
    required this.lastUpdated,
  });

  DashboardState copyWith({
    List<Device>? devices,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return DashboardState(
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final DeviceRepository _deviceRepository;
  final RealtimeRepository _realtimeRepository;
  StreamSubscription? _realtimeSubscription;

  DashboardController(this._deviceRepository, this._realtimeRepository)
    : super(DashboardState(lastUpdated: DateTime.now())) {
    loadDevices();
    _startRealtimeUpdates();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeRepository.stopRealtimeUpdates();
    super.dispose();
  }

  void _startRealtimeUpdates() {
    _realtimeRepository.startRealtimeUpdates();
    _realtimeSubscription = _realtimeRepository.readingStream.listen(
      (reading) {
        // Update device status with real-time data
        _updateDeviceWithReading(reading);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  void _updateDeviceWithReading(SensorReading reading) {
    if (state.devices.isNotEmpty) {
      final updatedDevices = state.devices.map((device) {
        return Device(
          id: device.id,
          name: device.name,
          room: device.room,
          status: DeviceExtensions.statusFromSensorReading(reading),
          lastSeen: DateTime.parse(reading.timestamp),
          firmwareVersion: device.firmwareVersion,
          isOnline: true,
          config: device.config,
        );
      }).toList();

      state = state.copyWith(
        devices: updatedDevices,
        lastUpdated: DateTime.now(),
      );
    }
  }

  Future<void> loadDevices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final devices = await _deviceRepository.getDevices();
      state = state.copyWith(
        devices: devices,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> toggleDevice(String deviceId) async {
    final deviceIndex = state.devices.indexWhere((d) => d.id == deviceId);
    if (deviceIndex == -1) return;

    final device = state.devices[deviceIndex];
    final newState = !device.status.isOn;

    try {
      await _deviceRepository.toggleDevice(deviceId, newState);

      // Device state will be updated via real-time stream
      // No need for optimistic updates
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
      final deviceRepository = ref.read(deviceRepositoryProvider);
      final realtimeRepository = ref.read(realtimeRepositoryProvider);
      return DashboardController(deviceRepository, realtimeRepository);
    });
