import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_plug/features/onboarding/application/provisioning_controller.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _ssidCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(text: 'Smart Plug');
  final _roomCtrl = TextEditingController(text: 'Living Room');

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _pwdCtrl.dispose();
    _nameCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provisioningControllerProvider);
    final ctrl = ref.read(provisioningControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Smart Plug')),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            if (state.message != null)
              MaterialBanner(
                content: Text(state.message!),
                actions: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(state.step),
                  child: _buildStep(context, state, ctrl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    ProvisioningState state,
    ProvisioningController ctrl,
  ) {
    switch (state.step) {
      case ProvisioningStep.pickMethod:
        return _PickMethod(onSelect: (m) => ctrl.pickMethod(m));

      case ProvisioningStep.connectToDeviceAP:
        return _ConnectAPStep(
          busy: state.busy,
          message: state.message,
          onConnectAuto: () async {
            FocusScope.of(context).unfocus();
            await _showConnectDialog(context, ctrl);
          },
          onVerify: () async {
            FocusScope.of(context).unfocus();
            await ctrl.verifyDeviceAP();
          },
        );

      case ProvisioningStep.enterWifiCredentials:
        return _CredentialsStep(
          ssidCtrl: _ssidCtrl,
          pwdCtrl: _pwdCtrl,
          nameCtrl: _nameCtrl,
          roomCtrl: _roomCtrl,
          onNext: () async {
            FocusScope.of(context).unfocus();
            ctrl.setWifiCredentials(
              ssid: _ssidCtrl.text.trim(),
              password: _pwdCtrl.text,
            );
            ctrl.setMetadata(
              deviceName: _nameCtrl.text.trim(),
              room: _roomCtrl.text.trim(),
            );
            await ctrl.submitCredentials();
          },
        );

      case ProvisioningStep.sendingCredentials:
        return const _ProgressStep(
          title: 'Sending Wi‑Fi Credentials',
          message: 'Please wait...',
        );

      case ProvisioningStep.waitingForDevice:
        return _WaitingStep(
          message: state.message ?? 'Waiting for device...',
          busy: state.busy,
          onContinue: () async {
            FocusScope.of(context).unfocus();
            await ctrl.waitAndRegister();
          },
        );

      case ProvisioningStep.registeringDevice:
        return const _ProgressStep(
          title: 'Registering Device',
          message: 'Adding to your account...',
        );

      case ProvisioningStep.success:
        return _ResultStep(
          success: true,
          message: state.message ?? 'Device added!',
          onFinish: () => _goHome(context),
          onAddAnother: () {
            FocusScope.of(context).unfocus();
            _clearFields();
            ctrl.reset();
          },
        );

      case ProvisioningStep.error:
        return _ResultStep(
          success: false,
          message: state.message ?? 'Something went wrong.',
          onFinish: () => _goHome(context),
          onRetry: () {
            FocusScope.of(context).unfocus();
            ctrl.reset();
          },
        );
    }
  }

  Future<void> _showConnectDialog(
    BuildContext context,
    ProvisioningController ctrl,
  ) async {
    final apSsidCtrl = TextEditingController();
    final apPwdCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connect to Device Hotspot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the device hotspot SSID (e.g., SmartPlug‑1234).'),
            const SizedBox(height: 12),
            TextField(
              controller: apSsidCtrl,
              decoration: const InputDecoration(labelText: 'Device SSID'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: apPwdCtrl,
              decoration: const InputDecoration(
                labelText: 'Device AP Password (if any)',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final ssid = apSsidCtrl.text.trim();
              final pass = apPwdCtrl.text;
              Navigator.of(ctx).pop();
              if (ssid.isNotEmpty) {
                FocusScope.of(context).unfocus();
                await ctrl.connectToAp(
                  deviceSsid: ssid,
                  deviceApPassword: pass.isEmpty ? null : pass,
                );
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      apSsidCtrl.dispose();
      apPwdCtrl.dispose();
    });
  }

  void _clearFields() {
    _ssidCtrl.clear();
    _pwdCtrl.clear();
    _nameCtrl.text = 'Smart Plug';
    _roomCtrl.text = 'Living Room';
  }

  void _goHome(BuildContext context) {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Prefer replacing the stack to avoid "popped last page" assertions.
      try {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } catch (_) {
        // If '/' is not registered, try maybePop; if cannot pop, do nothing.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).maybePop();
        }
      }
    });
  }
}

// ---------------- UI widgets ----------------

class _PickMethod extends StatelessWidget {
  const _PickMethod({required this.onSelect});
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Choose Setup Method',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Put your plug into pairing mode (hold the button until the LED blinks).',
        ),
        const SizedBox(height: 24),
        _MethodCard(
          title: 'Wi‑Fi (SoftAP)',
          subtitle: 'Connect to device hotspot, send your Wi‑Fi credentials.',
          icon: Icons.wifi_tethering,
          onTap: () => onSelect('softap'),
        ),
        const SizedBox(height: 12),
        _MethodCard(
          title: 'Bluetooth (BLE)',
          subtitle: 'Pair over BLE. Coming soon.',
          icon: Icons.bluetooth,
          onTap: () {},
          disabled: true,
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: disabled ? null : onTap,
      ),
    );
    return Opacity(opacity: disabled ? 0.5 : 1, child: card);
  }
}

class _ConnectAPStep extends StatelessWidget {
  const _ConnectAPStep({
    required this.busy,
    required this.message,
    required this.onConnectAuto,
    required this.onVerify,
  });

  final bool busy;
  final String? message;
  final Future<void> Function() onConnectAuto;
  final Future<void> Function() onVerify;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Connect to Device Hotspot',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Use “Connect automatically” to stay in the app. If it fails, open Wi‑Fi settings and connect manually.',
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.wifi),
          label: const Text('Connect automatically'),
          onPressed: busy ? null : onConnectAuto,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('I am connected to the device'),
          onPressed: busy ? null : onVerify,
        ),
        const SizedBox(height: 12),
        if (busy) const LinearProgressIndicator(),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message!),
          ),
      ],
    );
  }
}

class _CredentialsStep extends StatelessWidget {
  const _CredentialsStep({
    required this.ssidCtrl,
    required this.pwdCtrl,
    required this.nameCtrl,
    required this.roomCtrl,
    required this.onNext,
  });

  final TextEditingController ssidCtrl;
  final TextEditingController pwdCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController roomCtrl;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Enter Your Wi‑Fi Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ssidCtrl,
          decoration: const InputDecoration(labelText: 'Wi‑Fi SSID'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: pwdCtrl,
          decoration: const InputDecoration(labelText: 'Wi‑Fi Password'),
          obscureText: true,
        ),
        const SizedBox(height: 20),
        const Text(
          'Device Info (for your labeling)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Device Name'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: roomCtrl,
          decoration: const InputDecoration(labelText: 'Room'),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.send),
          label: const Text('Send to Device'),
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _WaitingStep extends StatelessWidget {
  const _WaitingStep({
    required this.message,
    required this.onContinue,
    required this.busy,
  });
  final String message;
  final Future<void> Function() onContinue;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Waiting for Device',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_done),
              label: const Text('Continue'),
              onPressed: busy ? null : onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStep extends StatelessWidget {
  const _ResultStep({
    required this.success,
    required this.message,
    required this.onFinish,
    this.onRetry,
    this.onAddAnother,
  });

  final bool success;
  final String message;
  final VoidCallback onFinish;
  final VoidCallback? onRetry;
  final VoidCallback? onAddAnother;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              size: 64,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              success ? 'Success' : 'Something went wrong',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: onFinish,
                  child: const Text('Finish'),
                ),
                if (!success && onRetry != null)
                  OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                if (success && onAddAnother != null)
                  OutlinedButton(
                    onPressed: onAddAnother,
                    child: const Text('Add another'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
