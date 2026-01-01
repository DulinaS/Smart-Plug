import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/provisioning_service.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/modern_ui.dart';

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

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Add Device',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
              tooltip: 'Back',
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Step 1: Connect to device AP
            _StepCard(
              stepNumber: 1,
              title: 'Connect to Device Hotspot',
              icon: Icons.wifi_tethering_rounded,
              gradient: AppTheme.primaryGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Open Wi‑Fi settings and connect to "$deviceApSsid". '
                    'Return to this screen and tap Verify.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _verifying
                                ? null
                                : AppTheme.primaryGradient,
                            color: _verifying ? AppTheme.darkCard : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _verifying
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.4,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _verifying
                                ? null
                                : () => _verifyAp(provisioning),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: _verifying
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white70,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              _verifying ? 'Verifying…' : 'Verify Connection',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (Platform.isAndroid) ...[
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.secondaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: IconButton(
                            onPressed: _verifying
                                ? null
                                : () => _tryAutoConnect(provisioning),
                            icon: const Icon(
                              Icons.wifi_rounded,
                              color: AppTheme.secondaryColor,
                            ),
                            tooltip: 'Auto-connect',
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_verified)
                    _ModernSuccessBanner(
                      text: 'Device AP verified. You can now enter your Wi‑Fi.',
                    )
                  else if (_verifyError != null)
                    _ModernErrorBanner(
                      text: _verifyError!,
                      onDismiss: () => setState(() => _verifyError = null),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Step 2: Home Wi‑Fi credentials (enabled after verify)
            _StepCard(
              stepNumber: 2,
              title: 'Enter Home Wi‑Fi',
              icon: Icons.router_rounded,
              gradient: AppTheme.accentGradient,
              isEnabled: _verified,
              child: Opacity(
                opacity: _verified ? 1 : 0.5,
                child: IgnorePointer(
                  ignoring: !_verified,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _ModernTextField(
                          controller: _ssidCtrl,
                          label: 'Wi‑Fi SSID (2.4 GHz)',
                          icon: Icons.wifi_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'SSID is required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _ModernTextField(
                          controller: _pwdCtrl,
                          label: 'Password',
                          icon: Icons.lock_rounded,
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _sending
                                  ? null
                                  : AppTheme.successGradient,
                              color: _sending ? AppTheme.darkCard : null,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _sending
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: AppTheme.successColor
                                            .withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _sending
                                  ? null
                                  : () => _sendCredentialsAndWait(provisioning),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: _sending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white70,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _sending ? 'Sending…' : 'Send Credentials',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_sendMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _sendMessage!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Step 3: Finalize
            _StepCard(
              stepNumber: 3,
              title: 'Finalize Setup',
              icon: Icons.check_circle_outline_rounded,
              gradient: AppTheme.successGradient,
              isEnabled: false,
              child: Text(
                'After the plug joins your home Wi‑Fi, we\'ll take you to fill in the device ID and details.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Device AP verified'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Connected and verified'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sendMessage = 'Failed to send: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Send failed: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

/// Modern step card widget
class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final IconData icon;
  final Gradient gradient;
  final Widget child;
  final bool isEnabled;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.child,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: isEnabled ? gradient : null,
                  color: isEnabled ? null : AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: gradient.colors.first.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? Colors.white : Colors.white54,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step $stepNumber',
                      style: TextStyle(
                        color: isEnabled
                            ? AppTheme.secondaryColor
                            : Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        color: isEnabled ? Colors.white : Colors.white54,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Modern text field widget
class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final String? Function(String?)? validator;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          errorStyle: const TextStyle(color: AppTheme.errorColor),
        ),
      ),
    );
  }
}

/// Modern success banner
class _ModernSuccessBanner extends StatelessWidget {
  final String text;
  const _ModernSuccessBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.successColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.successColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern error banner
class _ModernErrorBanner extends StatelessWidget {
  final String text;
  final VoidCallback onDismiss;
  const _ModernErrorBanner({required this.text, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_rounded,
              color: AppTheme.errorColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onDismiss,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text(
              'DISMISS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
