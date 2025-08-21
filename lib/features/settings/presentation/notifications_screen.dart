import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // Notification preferences state
  bool _deviceOnOff = true;
  bool _scheduleExecuted = true;
  bool _deviceOffline = true;
  bool _highPowerUsage = true;
  bool _dailySummary = false;
  bool _weeklySummary = true;
  bool _safetyAlerts = true;
  bool _firmwareUpdates = true;

  double _powerThreshold = 1500; // Watts
  double _costThreshold = 100; // LKR per day

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(onPressed: _saveSettings, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Device Events
          _buildSection('Device Events', [
            _buildSwitchTile(
              'Device ON/OFF',
              'Get notified when devices are turned on or off',
              _deviceOnOff,
              (value) => setState(() => _deviceOnOff = value),
            ),
            _buildSwitchTile(
              'Schedule Executed',
              'Notifications when scheduled actions run',
              _scheduleExecuted,
              (value) => setState(() => _scheduleExecuted = value),
            ),
            _buildSwitchTile(
              'Device Offline',
              'Alert when device loses connection',
              _deviceOffline,
              (value) => setState(() => _deviceOffline = value),
            ),
          ]),

          // Usage Alerts
          _buildSection('Usage Alerts', [
            _buildSwitchTile(
              'High Power Usage',
              'Alert when power exceeds threshold',
              _highPowerUsage,
              (value) => setState(() => _highPowerUsage = value),
            ),
            if (_highPowerUsage)
              _buildSliderTile(
                'Power Threshold',
                'Alert when power exceeds ${_powerThreshold.toInt()}W',
                _powerThreshold,
                500,
                3000,
                (value) => setState(() => _powerThreshold = value),
              ),

            _buildSliderTile(
              'Daily Cost Alert',
              'Notify when daily cost exceeds LKR ${_costThreshold.toInt()}',
              _costThreshold,
              50,
              500,
              (value) => setState(() => _costThreshold = value),
            ),
          ]),

          // Reports
          _buildSection('Usage Reports', [
            _buildSwitchTile(
              'Daily Summary',
              'Daily usage summary at 11 PM',
              _dailySummary,
              (value) => setState(() => _dailySummary = value),
            ),
            _buildSwitchTile(
              'Weekly Summary',
              'Weekly report every Sunday',
              _weeklySummary,
              (value) => setState(() => _weeklySummary = value),
            ),
          ]),

          // Safety & System
          _buildSection('Safety & System', [
            _buildSwitchTile(
              'Safety Alerts',
              'Critical safety warnings (overcurrent, etc.)',
              _safetyAlerts,
              (value) => setState(() => _safetyAlerts = value),
              isImportant: true,
            ),
            _buildSwitchTile(
              'Firmware Updates',
              'Notifications about device updates',
              _firmwareUpdates,
              (value) => setState(() => _firmwareUpdates = value),
            ),
          ]),

          // Notification Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: const Icon(Icons.volume_up),
                    title: const Text('Sound'),
                    subtitle: const Text('Enable notification sounds'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // TODO: Implement sound toggle
                      },
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.vibration),
                    title: const Text('Vibration'),
                    subtitle: const Text('Vibrate for notifications'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // TODO: Implement vibration toggle
                      },
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Quiet Hours'),
                    subtitle: const Text('10 PM - 7 AM'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showQuietHoursDialog(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Test Notification
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test Notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Make sure notifications are working properly'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _sendTestNotification,
                    child: const Text('Send Test Notification'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        Card(child: Column(children: children)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isImportant = false,
  }) {
    return ListTile(
      title: Text(
        title,
        style: isImportant
            ? const TextStyle(fontWeight: FontWeight.bold)
            : null,
      ),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      children: [
        ListTile(title: Text(title), subtitle: Text(subtitle)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 50).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _showQuietHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiet Hours'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set hours when non-urgent notifications will be silenced.'),
            SizedBox(height: 16),
            Text('Current: 10:00 PM - 7:00 AM'),
            SizedBox(height: 8),
            Text('Note: Safety alerts will always be delivered.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement time picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Time picker coming soon')),
              );
            },
            child: const Text('Set Times'),
          ),
        ],
      ),
    );
  }

  void _sendTestNotification() {
    // TODO: Implement test notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent! Check your notification panel.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveSettings() {
    // TODO: Save notification preferences to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
