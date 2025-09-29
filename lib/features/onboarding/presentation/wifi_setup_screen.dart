import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/provisioning_controller.dart';

class WiFiSetupScreen extends ConsumerStatefulWidget {
  const WiFiSetupScreen({super.key});

  @override
  ConsumerState<WiFiSetupScreen> createState() => _WiFiSetupScreenState();
}

class _WiFiSetupScreenState extends ConsumerState<WiFiSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _deviceNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isScanning = false;
  List<String> _availableNetworks = [];

  @override
  void initState() {
    super.initState();
    _scanForNetworks();
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provisioningState = ref.watch(provisioningControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Setup'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              LinearProgressIndicator(
                value: 0.6,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 24),

              // Instructions
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Setup Instructions',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Make sure your smart plug is in pairing mode (LED blinking)',
                      ),
                      const Text('2. Select your Wi-Fi network from the list'),
                      const Text('3. Enter your Wi-Fi password'),
                      const Text('4. Give your device a name'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Network Selection
              Text(
                'Select Wi-Fi Network',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text('Scan for Networks'),
                      trailing: _isScanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_ios),
                      onTap: _isScanning ? null : _scanForNetworks,
                    ),
                    const Divider(height: 1),

                    if (_availableNetworks.isNotEmpty) ...[
                      ...List.generate(_availableNetworks.length, (index) {
                        final network = _availableNetworks[index];
                        return ListTile(
                          leading: const Icon(Icons.wifi),
                          title: Text(network),
                          trailing: _ssidController.text == network
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            setState(() {
                              _ssidController.text = network;
                            });
                          },
                        );
                      }),
                    ] else if (!_isScanning) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No networks found. Tap "Scan for Networks" to refresh.',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Manual SSID Entry
              TextFormField(
                controller: _ssidController,
                decoration: const InputDecoration(
                  labelText: 'Network Name (SSID)',
                  hintText: 'Enter Wi-Fi network name',
                  prefixIcon: Icon(Icons.wifi),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter network name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Wi-Fi Password',
                  hintText: 'Enter Wi-Fi password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Wi-Fi password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Device Name Field
              TextFormField(
                controller: _deviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Device Name',
                  hintText: 'e.g., Living Room Lamp',
                  prefixIcon: Icon(Icons.device_hub),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter device name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Setup Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: provisioningState.isLoading
                      ? null
                      : _startProvisioning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: provisioningState.isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Setting up device...'),
                          ],
                        )
                      : const Text(
                          'Setup Device',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanForNetworks() async {
    setState(() => _isScanning = true);

    // Simulate network scanning (replace with actual Wi-Fi scanning)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isScanning = false;
      _availableNetworks = [
        'Home_WiFi',
        'Office_Network',
        'Guest_Network',
        'Neighbor_WiFi',
        'Mobile_Hotspot',
      ];
    });
  }

  void _startProvisioning() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(provisioningControllerProvider.notifier)
          .startWiFiSetup(
            ssid: _ssidController.text.trim(),
            password: _passwordController.text,
            deviceName: _deviceNameController.text.trim(),
          );
    }
  }
}
