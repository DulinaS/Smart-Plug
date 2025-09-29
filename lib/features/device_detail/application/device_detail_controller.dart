import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/device.dart';
import '../../../data/models/sensor_reading.dart';
import '../../../data/repositories/device_repo.dart';
import '../../../data/repositories/realtime_repo.dart';

class DeviceDetailState {
  final Device? device;
  final List<SensorReading> realtimeData;
  final bool isLoading;
  final String? error;
  final bool isToggling;

  const DeviceDetailState({
    this.device,
    this.realtimeData = const [],
    this.isLoading = false,
    this.error,
    this.isToggling = false,
  });

  DeviceDetailState copyWith({
    Device? device,
    List<SensorReading>? realtimeData,
    bool? isLoading,
    String? error,
    bool? isToggling,
  }) {
    return DeviceDetailState(
      device: device ?? this.device,
      realtimeData: realtimeData ?? this.realtimeData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isToggling: isToggling ?? this.isToggling,
    );
  }
}

class DeviceDetailController extends StateNotifier<DeviceDetailState> {
  final DeviceRepository _deviceRepository;
  final RealtimeRepository _realtimeRepository;
  final String deviceId;
  StreamSubscription? _realtimeSubscription;

  DeviceDetailController(
    this._deviceRepository,
    this._realtimeRepository,
    this.deviceId,
  ) : super(const DeviceDetailState()) {
    loadDevice();
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
        // Add to real-time data for charts
        final updatedData = [...state.realtimeData, reading];
        // Keep only last 50 readings for chart performance
        if (updatedData.length > 50) {
          updatedData.removeAt(0);
        }

        // Update device status
        if (state.device != null) {
          final updatedDevice = Device(
            id: state.device!.id,
            name: state.device!.name,
            room: state.device!.room,
            status: DeviceExtensions.statusFromSensorReading(reading),
            lastSeen: DateTime.parse(reading.timestamp),
            firmwareVersion: state.device!.firmwareVersion,
            isOnline: true,
            config: state.device!.config,
          );

          state = state.copyWith(
            device: updatedDevice,
            realtimeData: updatedData,
          );
        }
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  Future<void> loadDevice() async {
    if (state.device == null) {
      state = state.copyWith(isLoading: true);
    }

    try {
      final device = await _deviceRepository.getDevice(deviceId);
      state = state.copyWith(device: device, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> toggleDevice() async {
    if (state.device == null || state.isToggling) return;

    state = state.copyWith(isToggling: true);

    try {
      final newState = !state.device!.status.isOn;
      await _deviceRepository.toggleDevice(deviceId, newState);

      // Device state will be updated via real-time stream
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isToggling: false);
    }
  }

  Future<void> updateDevice({String? name, String? room}) async {
    if (state.device == null) return;

    // Clear any previous errors
    state = state.copyWith(error: null);

    try {
      await _deviceRepository.updateDevice(deviceId, name: name, room: room);
      await loadDevice();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final deviceDetailControllerProvider =
    StateNotifierProvider.family<
      DeviceDetailController,
      DeviceDetailState,
      String
    >((ref, deviceId) {
      final deviceRepository = ref.read(deviceRepositoryProvider);
      final realtimeRepository = ref.read(realtimeRepositoryProvider);
      return DeviceDetailController(
        deviceRepository,
        realtimeRepository,
        deviceId,
      );
    });
