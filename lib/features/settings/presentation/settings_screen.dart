import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
}
