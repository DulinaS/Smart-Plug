import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/provisioning_controller.dart';

class ProvisioningProgressScreen extends ConsumerWidget {
  const ProvisioningProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provisioningState = ref.watch(provisioningControllerProvider);

    ref.listen<ProvisioningState>(provisioningControllerProvider, (
      previous,
      next,
    ) {
      if (next.isCompleted && !next.hasError) {
        // Success - navigate to dashboard
        context.go('/dashboard');
      } else if (next.hasError) {
        // Show error dialog
        _showErrorDialog(context, next.error!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting up Device'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading:
            false, // Prevent back navigation during setup
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Progress Animation
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: provisioningState.progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                  Icon(
                    _getStepIcon(provisioningState.currentStep),
                    size: 48,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Progress Percentage
            Text(
              '${(provisioningState.progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),

            // Current Step
            Text(
              _getStepDescription(provisioningState.currentStep),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              _getStepDetails(provisioningState.currentStep),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Progress Steps
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildProgressStep(
                      'Connecting to Device',
                      provisioningState.currentStep ==
                          ProvisioningStep.connecting,
                      provisioningState.currentStep.index >
                          ProvisioningStep.connecting.index,
                    ),
                    _buildProgressStep(
                      'Sending Wi-Fi Credentials',
                      provisioningState.currentStep ==
                          ProvisioningStep.sendingCredentials,
                      provisioningState.currentStep.index >
                          ProvisioningStep.sendingCredentials.index,
                    ),
                    _buildProgressStep(
                      'Device Connecting to Wi-Fi',
                      provisioningState.currentStep ==
                          ProvisioningStep.deviceConnecting,
                      provisioningState.currentStep.index >
                          ProvisioningStep.deviceConnecting.index,
                    ),
                    _buildProgressStep(
                      'Registering with Cloud',
                      provisioningState.currentStep ==
                          ProvisioningStep.cloudRegistration,
                      provisioningState.currentStep.index >
                          ProvisioningStep.cloudRegistration.index,
                    ),
                    _buildProgressStep(
                      'Final Configuration',
                      provisioningState.currentStep ==
                          ProvisioningStep.finalizing,
                      provisioningState.isCompleted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Cancel Button (only show during early stages)
            if (provisioningState.currentStep.index <
                ProvisioningStep.deviceConnecting.index)
              TextButton(
                onPressed: () {
                  ref
                      .read(provisioningControllerProvider.notifier)
                      .cancelProvisioning();
                  context.go('/add-device');
                },
                child: const Text('Cancel Setup'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(String title, bool isActive, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.green
                  : isActive
                  ? Colors.blue
                  : Colors.grey[300],
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              size: 12,
              color: isCompleted || isActive ? Colors.white : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isCompleted
                    ? Colors.green
                    : isActive
                    ? Colors.blue
                    : Colors.grey[600],
              ),
            ),
          ),
          if (isActive)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  IconData _getStepIcon(ProvisioningStep step) {
    switch (step) {
      case ProvisioningStep.connecting:
        return Icons.bluetooth_searching;
      case ProvisioningStep.sendingCredentials:
        return Icons.wifi_lock;
      case ProvisioningStep.deviceConnecting:
        return Icons.wifi;
      case ProvisioningStep.cloudRegistration:
        return Icons.cloud_upload;
      case ProvisioningStep.finalizing:
        return Icons.check_circle;
    }
  }

  String _getStepDescription(ProvisioningStep step) {
    switch (step) {
      case ProvisioningStep.connecting:
        return 'Connecting to Device';
      case ProvisioningStep.sendingCredentials:
        return 'Sending Wi-Fi Details';
      case ProvisioningStep.deviceConnecting:
        return 'Device Connecting';
      case ProvisioningStep.cloudRegistration:
        return 'Cloud Registration';
      case ProvisioningStep.finalizing:
        return 'Finalizing Setup';
    }
  }

  String _getStepDetails(ProvisioningStep step) {
    switch (step) {
      case ProvisioningStep.connecting:
        return 'Establishing connection with your smart plug...';
      case ProvisioningStep.sendingCredentials:
        return 'Sending your Wi-Fi network details to the device...';
      case ProvisioningStep.deviceConnecting:
        return 'Device is connecting to your Wi-Fi network...';
      case ProvisioningStep.cloudRegistration:
        return 'Registering device with Smart Plug cloud service...';
      case ProvisioningStep.finalizing:
        return 'Completing setup and adding device to your account...';
    }
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Setup Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error),
            const SizedBox(height: 16),
            const Text('What you can try:'),
            const Text('• Check if device is in pairing mode'),
            const Text('• Verify Wi-Fi password is correct'),
            const Text('• Make sure device is close to router'),
            const Text('• Restart the setup process'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/add-device');
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/dashboard');
            },
            child: const Text('Skip for Now'),
          ),
        ],
      ),
    );
  }
}

enum ProvisioningStep {
  connecting,
  sendingCredentials,
  deviceConnecting,
  cloudRegistration,
  finalizing,
}
