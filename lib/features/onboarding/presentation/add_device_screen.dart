import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../onboarding/domain/plug_types.dart';
import '../../../core/services/provisioning_service.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  static const deviceApSsid = 'ESP32_Config'; // matches your ESP32 define

  bool _verifying = false;
  bool _verified = false;
  String? _verifyError;

  final _ssidCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _sending = false;
  String? _sendMessage;

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provisioning = ref.watch(provisioningServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Step 1: Connect to device AP
          Text(
            'Step 1 — Connect to the device hotspot',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Open Wi‑Fi settings and connect to "$deviceApSsid". '
            'Return to this screen and tap Verify.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _verifying ? null : () => _verifyAp(provisioning),
                  icon: _verifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _verifying ? 'Verifying…' : 'I am connected • Verify',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (Platform.isAndroid)
                OutlinedButton.icon(
                  onPressed: _verifying
                      ? null
                      : () => _tryAutoConnect(provisioning),
                  icon: const Icon(Icons.wifi),
                  label: const Text('Auto-connect'),
                ),
            ],
          ),

          const SizedBox(height: 12),

          if (_verified)
            _SuccessBanner(
              text: 'Device AP verified. You can now enter your Wi‑Fi.',
            )
          else if (_verifyError != null)
            _ErrorBanner(
              text: _verifyError!,
              onDismiss: () => setState(() => _verifyError = null),
            ),

          const SizedBox(height: 16),
          const Divider(height: 24),

          // Step 2: Home Wi‑Fi credentials (enabled after verify)
          Text(
            'Step 2 — Enter your home Wi‑Fi',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Opacity(
            opacity: _verified ? 1 : 0.5,
            child: IgnorePointer(
              ignoring: !_verified,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _ssidCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Wi‑Fi SSID (2.4 GHz)',
                        prefixIcon: Icon(Icons.wifi),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'SSID is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pwdCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      // Some networks are open; allow empty password
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _sending
                            ? null
                            : () => _sendCredentialsAndWait(provisioning),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_sending ? 'Sending…' : 'Send credentials'),
                      ),
                    ),
                    if (_sendMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _sendMessage!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 24),

          // Step 3: Finish / enter device details (navigates automatically)
          Text(
            'Step 3 — Finalize',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'After the plug joins your home Wi‑Fi, we’ll take you to fill in the device ID and details.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _verifyAp(ProvisioningService provisioning) async {
    setState(() {
      _verifying = true;
      _verifyError = null;
    });

    try {
      // Best-effort ping
      final ok = await provisioning.pingDevice();
      if (!mounted) return;
      if (ok) {
        setState(() {
          _verified = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device AP verified'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(
          () => _verifyError =
              'Could not reach the device. Make sure you are connected to "$deviceApSsid".',
        );
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _tryAutoConnect(ProvisioningService provisioning) async {
    setState(() {
      _verifying = true;
      _verifyError = null;
    });
    try {
      final joined = await provisioning.connectToAp(
        deviceSsid: deviceApSsid,
        deviceApPassword: '', // open AP per your firmware
      );
      if (!mounted) return;
      if (joined) {
        final ok = await provisioning.pingDevice();
        if (!mounted) return;
        if (ok) {
          setState(() {
            _verified = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connected and verified'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(
            () => _verifyError =
                'Connected to AP, but device did not respond. Keep Wi‑Fi on this AP and try again.',
          );
        }
      } else {
        setState(
          () => _verifyError =
              'Could not auto-connect. Connect manually to "$deviceApSsid" in Wi‑Fi settings and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _sendCredentialsAndWait(ProvisioningService provisioning) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _sending = true;
      _sendMessage = 'Sending credentials to device…';
    });

    try {
      await provisioning.sendWifiCredentials(
        ssid: _ssidCtrl.text.trim(),
        password: _pwdCtrl.text,
      );

      if (!mounted) return;
      setState(() {
        _sendMessage =
            'Credentials sent. Waiting for device to join your Wi‑Fi…';
      });

      final result = await provisioning.waitForStatus();
      if (!mounted) return;

      if (result.connected) {
        setState(() {
          _sendMessage = 'Connected to ${result.ssid ?? 'your Wi‑Fi'}.';
        });

        // Ask device to exit AP (best-effort)
        await provisioning.finalizeDevice();

        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;
        // Navigate to details form to capture deviceId/name/type
        context.push('/provision/details');
      } else {
        setState(() {
          _sendMessage =
              result.message ??
              'Device did not connect in time. You can retry.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_sendMessage!),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sendMessage = 'Failed to send: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _SuccessBanner extends StatelessWidget {
  final String text;
  const _SuccessBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: cs.onPrimaryContainer, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: cs.onPrimaryContainer, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.text, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(Icons.error, color: cs.onErrorContainer, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: cs.onErrorContainer, fontSize: 12),
            ),
          ),
          TextButton(onPressed: onDismiss, child: const Text('DISMISS')),
        ],
      ),
    );
  }
}
