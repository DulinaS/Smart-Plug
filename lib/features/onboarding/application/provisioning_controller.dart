import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ProvisioningStep {
  connecting,
  sendingCredentials,
  deviceConnecting,
  cloudRegistration,
  finalizing,
}

class ProvisioningState {
  final ProvisioningStep currentStep;
  final double progress;
  final bool isCompleted;
  final bool hasError;
  final String? error;
  final bool isLoading;

  const ProvisioningState({
    this.currentStep = ProvisioningStep.connecting,
    this.progress = 0.0,
    this.isCompleted = false,
    this.hasError = false,
    this.error,
    this.isLoading = false,
  });

  ProvisioningState copyWith({
    ProvisioningStep? currentStep,
    double? progress,
    bool? isCompleted,
    bool? hasError,
    String? error,
    bool? isLoading,
  }) {
    return ProvisioningState(
      currentStep: currentStep ?? this.currentStep,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      hasError: hasError ?? this.hasError,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProvisioningController extends StateNotifier<ProvisioningState> {
  ProvisioningController() : super(const ProvisioningState());

  Future<void> startWiFiSetup({
    required String ssid,
    required String password,
    required String deviceName,
  }) async {
    state = state.copyWith(isLoading: true, hasError: false);

    try {
      // Step 1: Connect to device
      await _updateStep(ProvisioningStep.connecting, 0.2);
      await _simulateConnection();

      // Step 2: Send WiFi credentials
      await _updateStep(ProvisioningStep.sendingCredentials, 0.4);
      await _sendCredentials(ssid, password);

      // Step 3: Device connects to WiFi
      await _updateStep(ProvisioningStep.deviceConnecting, 0.6);
      await _waitForDeviceConnection();

      // Step 4: Register with cloud
      await _updateStep(ProvisioningStep.cloudRegistration, 0.8);
      await _registerWithCloud(deviceName);

      // Step 5: Finalize
      await _updateStep(ProvisioningStep.finalizing, 1.0);
      await _finalizeSetup();

      state = state.copyWith(isCompleted: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        hasError: true,
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> _updateStep(ProvisioningStep step, double progress) async {
    state = state.copyWith(currentStep: step, progress: progress);
    // Simulate time for each step
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> _simulateConnection() async {
    // TODO: Replace with actual device connection logic
    // This would connect to ESP32's WiFi hotspot or BLE
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> _sendCredentials(String ssid, String password) async {
    // TODO: Replace with actual credential sending
    // This would send WiFi SSID and password to ESP32
    await Future.delayed(const Duration(seconds: 3));
  }

  Future<void> _waitForDeviceConnection() async {
    // TODO: Replace with actual device monitoring
    // This would wait for ESP32 to connect to user's WiFi
    await Future.delayed(const Duration(seconds: 5));
  }

  Future<void> _registerWithCloud(String deviceName) async {
    // TODO: Replace with actual cloud registration
    // This would register the device with your friend's backend
    await Future.delayed(const Duration(seconds: 3));
  }

  Future<void> _finalizeSetup() async {
    // TODO: Final setup steps
    await Future.delayed(const Duration(seconds: 1));
  }

  void cancelProvisioning() {
    state = const ProvisioningState();
  }
}

final provisioningControllerProvider =
    StateNotifierProvider<ProvisioningController, ProvisioningState>((ref) {
      return ProvisioningController();
    });
