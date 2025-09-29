import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/analytics_repo.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../data/repositories/device_repo.dart';
import '../../../data/repositories/schedule_repo.dart';
import '../../auth/application/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Profile Section
          if (user != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue,
                      child: Text(
                        (user.displayName ?? user.username)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.displayName ?? user.username,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Divider(),
            ListTile(
              title: Text('API Integration Tests'),
              subtitle: Text('Test backend connectivity'),
            ),
            _buildTestButtons(context, ref),
            Divider(),
          ],

          // Account Settings
          _buildSectionHeader(context, 'Account'),
          _buildSettingsTile(
            context,
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'Update your personal information',
            onTap: () => _showComingSoon(context, 'Profile Settings'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.security,
            title: 'Security',
            subtitle: 'Change password and security settings',
            onTap: () => _showComingSoon(context, 'Security Settings'),
          ),

          const SizedBox(height: 16),

          // App Settings
          _buildSectionHeader(context, 'App Settings'),
          _buildSettingsTile(
            context,
            icon: Icons.palette,
            title: 'Theme',
            subtitle: 'Light, dark, or system default',
            onTap: () => _showThemeDialog(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () => _showComingSoon(context, 'Notification Settings'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'Language',
            subtitle: 'Choose your preferred language',
            onTap: () => _showLanguageDialog(context),
          ),

          const SizedBox(height: 16),

          // Energy Settings
          _buildSectionHeader(context, 'Energy'),
          _buildSettingsTile(
            context,
            icon: Icons.currency_exchange,
            title: 'Electricity Tariffs',
            subtitle: 'Configure CEB tariff rates',
            onTap: () => _showTariffDialog(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.schedule,
            title: 'Usage Alerts',
            subtitle: 'Set consumption and cost alerts',
            onTap: () => _showComingSoon(context, 'Usage Alerts'),
          ),

          const SizedBox(height: 16),

          // Support
          _buildSectionHeader(context, 'Support'),
          _buildSettingsTile(
            context,
            icon: Icons.help,
            title: 'Help & FAQ',
            subtitle: 'Get help with common questions',
            onTap: () => _showComingSoon(context, 'Help & FAQ'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.feedback,
            title: 'Send Feedback',
            subtitle: 'Help us improve the app',
            onTap: () => _showComingSoon(context, 'Send Feedback'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () => _showAboutDialog(context),
          ),

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Sign Out'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.settings_system_daydream),
              title: const Text('System Default'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              title: const Text('සිංහල (Sinhala)'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              title: const Text('தமிழ் (Tamil)'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showTariffDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Electricity Tariffs'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current CEB Tariff Rates (2024):'),
            SizedBox(height: 8),
            Text('0-30 units: LKR 7.85/kWh'),
            Text('31-60 units: LKR 10.00/kWh'),
            Text('61-90 units: LKR 27.75/kWh'),
            Text('91+ units: LKR 32.00/kWh'),
            Text('Fixed Charge: LKR 400.00'),
            SizedBox(height: 8),
            Text('Tariff customization will be available in a future update.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Smart Plug',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.power, size: 48, color: Colors.blue),
      children: [
        const Text(
          'Smart Plug helps you monitor and control your electrical devices remotely.',
        ),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Remote device control'),
        const Text('• Real-time power monitoring'),
        const Text('• Energy usage analytics'),
        const Text('• Cost calculation with CEB tariffs'),
        const Text('• Device scheduling'),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authControllerProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  //TEST BUTTONS
  Widget _buildTestButtons(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () async {
              print('=== STARTING AUTH TEST ===');
              final authRepo = ref.read(authRepositoryProvider);

              try {
                print('Testing signup...');
                final result = await authRepo.signUp(
                  'test${DateTime.now().millisecondsSinceEpoch}@dulina.com',
                  'TestPass123!',
                  'Test User',
                );
                print('SUCCESS: $result');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Success: ${result['message']}')),
                );
              } catch (e) {
                print('FAILED: $e');
                print('Stack trace: ${StackTrace.current}');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed: $e'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            },
            child: Text('Test Auth Now'),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _testDeviceData(context, ref),
            child: Text('Test Device Data'),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _testSchedules(context, ref),
            child: Text('Test Schedules'),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _testAnalytics(context, ref),
            child: Text('Test Analytics'),
          ),
        ],
      ),
    );
  }

  Future<void> _testAuth(BuildContext context, WidgetRef ref) async {
    final authRepo = ref.read(authRepositoryProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing...'),
          ],
        ),
      ),
    );

    try {
      final result = await authRepo.signUp(
        'test${DateTime.now().millisecondsSinceEpoch}@test.com',
        'TestPass123!',
        'Test User',
      );

      Navigator.pop(context);
      _showResult(
        context,
        'Auth Test',
        'Success: User registered\n${result['message']}',
      );
    } catch (e) {
      Navigator.pop(context);
      _showResult(context, 'Auth Test', 'Error: $e');
    }
  }

  Future<void> _testDeviceData(BuildContext context, WidgetRef ref) async {
    final deviceRepo = ref.read(deviceRepositoryProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing...'),
          ],
        ),
      ),
    );

    try {
      final reading = await deviceRepo.getLatestReading();

      Navigator.pop(context);
      _showResult(
        context,
        'Device Data Test',
        'Success!\n\n'
            'Voltage: ${reading.voltage}V\n'
            'Current: ${reading.current}A\n'
            'Power: ${reading.power}W\n'
            'Time: ${reading.timestamp}',
      );
    } catch (e) {
      Navigator.pop(context);
      _showResult(context, 'Device Data Test', 'Error: $e');
    }
  }

  Future<void> _testSchedules(BuildContext context, WidgetRef ref) async {
    final scheduleRepo = ref.read(scheduleRepositoryProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing...'),
          ],
        ),
      ),
    );

    try {
      final schedules = await scheduleRepo.getSchedules('LivingRoomESP32');

      Navigator.pop(context);
      _showResult(
        context,
        'Schedule Test',
        'Success!\n\nFound ${schedules.length} schedules',
      );
    } catch (e) {
      Navigator.pop(context);
      _showResult(context, 'Schedule Test', 'Error: $e');
    }
  }

  Future<void> _testAnalytics(BuildContext context, WidgetRef ref) async {
    final analyticsRepo = ref.read(analyticsRepositoryProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing...'),
          ],
        ),
      ),
    );

    try {
      final summary = await analyticsRepo.getUsageSummary(
        'LivingRoomESP32',
        'today',
      );

      Navigator.pop(context);
      _showResult(
        context,
        'Analytics Test',
        'Success!\n\n'
            'Energy: ${summary.totalEnergy.toStringAsFixed(2)} kWh\n'
            'Cost: Rs. ${summary.totalCost.toStringAsFixed(2)}\n'
            'Avg Power: ${summary.avgPower.toStringAsFixed(1)}W',
      );
    } catch (e) {
      Navigator.pop(context);
      _showResult(context, 'Analytics Test', 'Error: $e');
    }
  }

  void _showResult(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
