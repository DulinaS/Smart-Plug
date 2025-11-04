import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_plug/features/onboarding/application/provisioning_controller.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _wifiFormKey = GlobalKey<FormState>();
  final _homeSsidCtrl = TextEditingController();
  final _homePwdCtrl = TextEditingController();

  final _deviceApSsidCtrl = TextEditingController(text: 'SMART_PLUG_AP');
  final _deviceApPwdCtrl = TextEditingController();

  bool _autoConnecting = false;
  bool _sendingCreds = false;
  bool _verifyingAp = false;

  @override
  void initState() {
    super.initState();
    // Do NOT call ref.listen or mutate providers here.
    // ProvisioningController already starts at connectToDeviceAP by default.
  }

  @override
  void dispose() {
    _homeSsidCtrl.dispose();
    _homePwdCtrl.dispose();
    _deviceApSsidCtrl.dispose();
    _deviceApPwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provisioningControllerProvider);

    // Safe: ref.listen in build. Use post-frame for navigation to avoid doing it during build.
    ref.listen<ProvisioningState>(provisioningControllerProvider, (prev, next) {
      if (!mounted) return;

      if (next.step == ProvisioningStep.waitingForDevice &&
          ModalRoute.of(context)?.isCurrent == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.push('/provision/details');
        });
      }

      if (next.step == ProvisioningStep.success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            context.go('/dashboard');
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Add Device (Wi‑Fi Provisioning)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if ((state.message ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MaterialBanner(
                content: Text(state.message!),
                leading: Icon(
                  state.step == ProvisioningStep.error
                      ? Icons.error
                      : Icons.info_outline,
                  color: state.step == ProvisioningStep.error
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      ref.read(provisioningControllerProvider.notifier).reset();
                      // Controller initial() already sets SoftAP flow.
                    },
                    child: const Text('RESET'),
                  ),
                ],
              ),
            ),

          // 1) Connect to device AP
          _Section(
            title: '1) Connect to device hotspot',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Open Wi‑Fi settings and connect to the device AP.\n'
                  'Return here and tap "I am connected" to verify.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _verifyingAp
                          ? null
                          : () async {
                              setState(() => _verifyingAp = true);
                              try {
                                await ref
                                    .read(
                                      provisioningControllerProvider.notifier,
                                    )
                                    .verifyDeviceAP();
                              } finally {
                                if (mounted)
                                  setState(() => _verifyingAp = false);
                              }
                            },
                      icon: _verifyingAp
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering),
                      label: const Text('I am connected • Verify'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _autoConnecting
                          ? null
                          : () async {
                              setState(() => _autoConnecting = true);
                              try {
                                await ref
                                    .read(
                                      provisioningControllerProvider.notifier,
                                    )
                                    .connectToAp(
                                      deviceSsid: _deviceApSsidCtrl.text.trim(),
                                      deviceApPassword:
                                          _deviceApPwdCtrl.text.trim().isEmpty
                                          ? null
                                          : _deviceApPwdCtrl.text.trim(),
                                    );
                              } finally {
                                if (mounted)
                                  setState(() => _autoConnecting = false);
                              }
                            },
                      icon: _autoConnecting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_find),
                      label: const Text('Try auto‑connect'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ExpansionTile(
                  title: const Text('Device AP (optional)'),
                  subtitle: const Text('Used only if you try auto‑connect'),
                  children: [
                    TextField(
                      controller: _deviceApSsidCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Device AP SSID',
                        hintText: 'e.g., SMART_PLUG_AP',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _deviceApPwdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Device AP password (if any)',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ],
            ),
          ),

          // 2) Home Wi‑Fi credentials
          _Section(
            title: '2) Enter your home Wi‑Fi',
            child: Form(
              key: _wifiFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _homeSsidCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Home Wi‑Fi SSID',
                      hintText: 'e.g., MyHomeWiFi',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'SSID is required'
                        : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _homePwdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Wi‑Fi password',
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _sendingCreds
                        ? null
                        : () async {
                            if (!(_wifiFormKey.currentState?.validate() ??
                                false))
                              return;
                            setState(() => _sendingCreds = true);
                            try {
                              ref
                                  .read(provisioningControllerProvider.notifier)
                                  .setWifiCredentials(
                                    ssid: _homeSsidCtrl.text.trim(),
                                    password: _homePwdCtrl.text,
                                  );

                              await ref
                                  .read(provisioningControllerProvider.notifier)
                                  .submitCredentials();
                              // Navigation to details page happens via the listener above
                            } finally {
                              if (mounted)
                                setState(() => _sendingCreds = false);
                            }
                          },
                    icon: _sendingCreds
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Send credentials'),
                  ),
                ],
              ),
            ),
          ),

          _Section(
            title: 'Advanced',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(provisioningControllerProvider.notifier)
                      .reprovision(),
                  icon: const Icon(Icons.settings_backup_restore),
                  label: const Text('Re‑enable AP'),
                ),
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(provisioningControllerProvider.notifier)
                      .factoryReset(),
                  icon: const Icon(Icons.factory),
                  label: const Text('Factory reset'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _StatusPanel(),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(provisioningControllerProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _row('Step', s.step.name),
            _row('Busy', s.busy ? 'Yes' : 'No'),
            if ((s.deviceId ?? '').isNotEmpty) _row('Device ID', s.deviceId!),
            if ((s.ssid ?? '').isNotEmpty) _row('Target SSID', s.ssid!),
            if ((s.message ?? '').isNotEmpty) _row('Message', s.message!),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
