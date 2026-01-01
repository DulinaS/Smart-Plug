import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/modern_ui.dart';
import '../../../core/widgets/curved_header.dart';
import '../../auth/application/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // Beautiful Curved Settings Header - using standardized header
            SliverToBoxAdapter(
              child: ScreenHeader(
                title: 'Settings',
                icon: Icons.settings_rounded,
                accentColor: AppTheme.accentColor,
              ),
            ),
            // User Profile Card
            if (user != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _UserProfileCard(user: user),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Account Settings
                  const SectionHeader(title: 'Account'),
                  const SizedBox(height: 8),
                  _buildSettingsTile(
                    context,
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    subtitle: 'Update your personal information',
                    gradient: AppTheme.primaryGradient,
                    onTap: () => _showComingSoon(context, 'Profile Settings'),
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.security_rounded,
                    title: 'Security',
                    subtitle: 'Change password and security settings',
                    gradient: AppTheme.accentGradient,
                    onTap: () => _showComingSoon(context, 'Security Settings'),
                  ),

                  const SizedBox(height: 24),

                  // App Settings
                  const SectionHeader(title: 'App Settings'),
                  const SizedBox(height: 8),
                  _buildSettingsTile(
                    context,
                    icon: Icons.palette_rounded,
                    title: 'Theme',
                    subtitle: 'Light, dark, or system default',
                    gradient: AppTheme.cardGradient,
                    onTap: () => _showThemeDialog(context),
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    gradient: AppTheme.cardGradient,
                    onTap: () =>
                        _showComingSoon(context, 'Notification Settings'),
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.language_rounded,
                    title: 'Language',
                    subtitle: 'Choose your preferred language',
                    gradient: AppTheme.cardGradient,
                    onTap: () => _showLanguageDialog(context),
                  ),

                  const SizedBox(height: 24),

                  // Energy Settings
                  const SectionHeader(title: 'Energy'),
                  const SizedBox(height: 8),
                  _buildSettingsTile(
                    context,
                    icon: Icons.currency_exchange_rounded,
                    title: 'Electricity Tariffs',
                    subtitle: 'Configure CEB tariff rates',
                    gradient: AppTheme.successGradient,
                    onTap: () => _showTariffDialog(context),
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.schedule_rounded,
                    title: 'Usage Alerts',
                    subtitle: 'Set consumption and cost alerts',
                    gradient: AppTheme.successGradient,
                    onTap: () => _showComingSoon(context, 'Usage Alerts'),
                  ),

                  const SizedBox(height: 24),

                  // Support
                  const SectionHeader(title: 'Support'),
                  const SizedBox(height: 8),
                  _buildSettingsTile(
                    context,
                    icon: Icons.help_rounded,
                    title: 'Help & FAQ',
                    subtitle: 'Get help with common questions',
                    gradient: AppTheme.cardGradient,
                    onTap: () => _showComingSoon(context, 'Help & FAQ'),
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.feedback_rounded,
                    title: 'Send Feedback',
                    subtitle: 'Help us improve the app',
                    gradient: AppTheme.cardGradient,
                    onTap: () => _showComingSoon(context, 'Send Feedback'),
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.info_rounded,
                    title: 'About',
                    subtitle: 'App version and information',
                    gradient: AppTheme.cardGradient,
                    onTap: () => _showAboutDialog(context),
                  ),

                  const SizedBox(height: 32),

                  // Logout Button
                  _LogoutButton(
                    onPressed: () => _showLogoutDialog(context, ref),
                  ),

                  // Bottom padding to account for navbar
                  SizedBox(height: AppTheme.navBarTotalHeight),
                ]),
              ),
            ),
          ],
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
    required Gradient gradient,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: gradient,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.white.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(feature, style: const TextStyle(color: Colors.white)),
        content: Text(
          '$feature will be available in a future update.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Choose Theme',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              icon: Icons.light_mode_rounded,
              title: 'Light',
              isSelected: false,
            ),
            _buildThemeOption(
              context,
              icon: Icons.dark_mode_rounded,
              title: 'Dark',
              isSelected: true,
            ),
            _buildThemeOption(
              context,
              icon: Icons.settings_system_daydream_rounded,
              title: 'System Default',
              isSelected: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : Colors.white60,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor)
          : null,
      onTap: () => Navigator.of(context).pop(),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Choose Language',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'English',
                style: TextStyle(color: Colors.white),
              ),
              leading: Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primaryColor,
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              title: Text(
                'සිංහල (Sinhala)',
                style: TextStyle(color: Colors.white60),
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              title: Text(
                'தமிழ் (Tamil)',
                style: TextStyle(color: Colors.white60),
              ),
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
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: AppTheme.successColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Electricity Tariffs',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current CEB Tariff Rates (2024):',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildTariffRow('0-30 units', 'LKR 7.85/kWh'),
            _buildTariffRow('31-60 units', 'LKR 10.00/kWh'),
            _buildTariffRow('61-90 units', 'LKR 27.75/kWh'),
            _buildTariffRow('91+ units', 'LKR 32.00/kWh'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fixed Charge',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  Text(
                    'LKR 400.00',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tariff customization will be available in a future update.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildTariffRow(String range, String rate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(range, style: TextStyle(color: Colors.white.withOpacity(0.7))),
          Text(
            rate,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Smart Plug', style: TextStyle(color: Colors.white)),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Plug helps you monitor and control your electrical devices remotely.',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('Remote device control'),
            _buildFeatureItem('Real-time power monitoring'),
            _buildFeatureItem('Energy usage analytics'),
            _buildFeatureItem('Cost calculation with CEB tariffs'),
            _buildFeatureItem('Device scheduling'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppTheme.successColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authControllerProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  /*   //TEST BUTTONS
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
 */
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

class _LogoutButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _LogoutButton({required this.onPressed});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppTheme.errorColor.withOpacity(0.15),
            border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: AppTheme.errorColor),
              const SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// User Profile Card - displayed below the standardized header
class _UserProfileCard extends StatelessWidget {
  final dynamic user;

  const _UserProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                (user.displayName ?? user.username)
                    .substring(0, 1)
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? user.username,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.edit_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
