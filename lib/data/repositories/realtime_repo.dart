import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_reading.dart';
import 'device_repo.dart';

class RealtimeRepository {
  final DeviceRepository _deviceRepository;
  Timer? _pollingTimer;
  final StreamController<SensorReading> _readingController =
      StreamController.broadcast();

  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 5;
  static const int _baseDelaySeconds = 5;
  static const int _maxDelaySeconds = 60;

  RealtimeRepository(this._deviceRepository);

  // Stream of real-time sensor readings
  Stream<SensorReading> get readingStream => _readingController.stream;

  // Start polling for real-time data with exponential backoff on errors
  void startRealtimeUpdates() {
    _pollingTimer?.cancel();
    _consecutiveErrors = 0;
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    final delay = _calculateDelay();
    _pollingTimer = Timer(Duration(seconds: delay), _performPoll);
  }

  int _calculateDelay() {
    if (_consecutiveErrors == 0) {
      return _baseDelaySeconds;
    }

    // Exponential backoff: base * 2^errors, capped at max
    final exponentialDelay =
        _baseDelaySeconds * pow(2, min(_consecutiveErrors, 4)).toInt();
    return min(exponentialDelay, _maxDelaySeconds);
  }

  void _performPoll() async {
    try {
      final reading = await _deviceRepository.getLatestReading();
      _readingController.add(reading);

      // Reset error count on success
      _consecutiveErrors = 0;

      // Schedule next poll with normal interval
      _scheduleNextPoll();
    } catch (e) {
      _consecutiveErrors++;

      print('Error fetching real-time data (attempt $_consecutiveErrors): $e');

      // Stop polling after too many consecutive errors
      if (_consecutiveErrors >= _maxConsecutiveErrors) {
        print('Too many consecutive errors. Stopping real-time updates.');
        _readingController.addError(
          'Real-time data unavailable. Device may be offline.',
        );
        return;
      }

      // Schedule next poll with exponential backoff
      _scheduleNextPoll();
    }
  }

  // Stop real-time updates
  void stopRealtimeUpdates() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _consecutiveErrors = 0;
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
