import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_reading.dart';
import 'device_repo.dart';

class RealtimeRepository {
  final DeviceRepository _deviceRepository;
  Timer? _pollingTimer;
  final StreamController<SensorReading> _readingController =
      StreamController.broadcast();

  RealtimeRepository(this._deviceRepository);

  // Stream of real-time sensor readings
  Stream<SensorReading> get readingStream => _readingController.stream;

  // Start polling for real-time data every 5 seconds
  void startRealtimeUpdates() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final reading = await _deviceRepository.getLatestReading();
        _readingController.add(reading);
      } catch (e) {
        // Log error but don't break the stream
        print('Error fetching real-time data: $e');
      }
    });
  }

  // Stop real-time updates
  void stopRealtimeUpdates() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Get single reading
  Future<SensorReading> getCurrentReading() async {
    return await _deviceRepository.getLatestReading();
  }

  void dispose() {
    _pollingTimer?.cancel();
    _readingController.close();
  }
}

final realtimeRepositoryProvider = Provider<RealtimeRepository>((ref) {
  final deviceRepository = ref.read(deviceRepositoryProvider);
  return RealtimeRepository(deviceRepository);
});
