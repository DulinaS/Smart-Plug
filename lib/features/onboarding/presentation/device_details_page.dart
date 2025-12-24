/* import 'package:flutter/material.dart';
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
 */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/user_device_repo.dart';
import '../../devices/application/user_devices_controller.dart';
import '../domain/plug_types.dart';

class DeviceDetailsPage extends ConsumerStatefulWidget {
  const DeviceDetailsPage({super.key});

  @override
  ConsumerState<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends ConsumerState<DeviceDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  PlugType? _type;
  bool _submitting = false;
  String? _message;

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_message != null) ...[
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Enter the sticker ID and details to link this device to your account.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _idCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Device ID (sticker)',
                    hintText: 'e.g., Smart-Plug001',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Device ID is required'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    hintText: 'e.g., Gaming TV',
                    prefixIcon: Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _roomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Room',
                    hintText: 'e.g., Bedroom',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Plug type', style: theme.textTheme.titleSmall),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: defaultPlugTypes.map((t) {
                    final sel = _type == t;
                    return ChoiceChip(
                      label: Text(t.label),
                      selected: sel,
                      onSelected: (_) => setState(() => _type = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _linkNow,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link),
                    label: Text(_submitting ? 'Linking…' : 'Link device'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: The device may take a few seconds to appear online after joining your Wi‑Fi. '
            'Linking will complete now, and online status will update shortly.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _linkNow() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final repo = ref.read(userDeviceRepositoryProvider);

    setState(() {
      _submitting = true;
      _message = 'Linking device to your account…';
    });

    try {
      await repo.linkDeviceToCurrentUser(
        deviceId: _idCtrl.text.trim(),
        deviceName: _nameCtrl.text.trim().isEmpty
            ? _idCtrl.text.trim()
            : _nameCtrl.text.trim(),
        roomName: _roomCtrl.text.trim(),
        plugType: _type?.label ?? 'Custom',
      );

      // Refresh list
      await ref.read(userDevicesControllerProvider.notifier).refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device linked'),
          backgroundColor: Colors.green,
        ),
      );

      // Return true to Add Device flow, or go straight to devices
      if (Navigator.canPop(context)) {
        context.pop(true);
      } else {
        context.go('/devices');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Link failed: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
