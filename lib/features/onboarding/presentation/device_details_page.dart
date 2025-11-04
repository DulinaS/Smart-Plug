import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_plug/features/onboarding/domain/plug_types.dart';
import 'package:smart_plug/features/onboarding/application/provisioning_controller.dart';

class DeviceDetailsPage extends ConsumerStatefulWidget {
  const DeviceDetailsPage({super.key});

  @override
  ConsumerState<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends ConsumerState<DeviceDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdCtrl = TextEditingController();
  final _deviceNameCtrl = TextEditingController();
  final _roomNameCtrl = TextEditingController(text: 'Living Room');

  PlugType? _selectedType;
  bool _submitting = false;

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _deviceNameCtrl.dispose();
    _roomNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final plugTypeLabel = (_selectedType ?? PlugType.custom).label;

    ref
        .read(provisioningControllerProvider.notifier)
        .setDeviceDetails(
          deviceId: _deviceIdCtrl.text.trim(),
          deviceName: _deviceNameCtrl.text.trim().isEmpty
              ? _deviceIdCtrl.text.trim()
              : _deviceNameCtrl.text.trim(),
          roomName: _roomNameCtrl.text.trim(),
          plugType: plugTypeLabel,
        );

    setState(() => _submitting = true);
    try {
      await ref.read(provisioningControllerProvider.notifier).waitAndLink();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provisioningControllerProvider);

    ref.listen(provisioningControllerProvider, (prev, next) {
      if (next.step == ProvisioningStep.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device linked successfully')),
        );
        Navigator.of(context).pop(true); // or navigate to dashboard
      } else if (next.step == ProvisioningStep.error && mounted) {
        final msg = next.message ?? 'Failed';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Device details')),
      body: AbsorbPointer(
        absorbing: _submitting || state.busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.message != null && state.message!.isNotEmpty) ...[
              Text(
                state.message!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _deviceIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Device ID (from sticker)',
                      hintText: 'e.g., Smart_Plug_0001',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Device ID is required'
                        : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deviceNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Device name (display)',
                      hintText: 'e.g., Smart Plug A',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _roomNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Room',
                      hintText: 'e.g., Bedroom',
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Plug type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: defaultPlugTypes.map((t) {
                      final selected = _selectedType == t;
                      return ChoiceChip(
                        label: Text(t.label),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedType = t),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _onContinue,
              icon: (_submitting || state.busy)
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
