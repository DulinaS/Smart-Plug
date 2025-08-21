import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Help',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildQuickAction(
                    context,
                    icon: Icons.video_library,
                    title: 'Setup Video Tutorial',
                    subtitle: 'Watch step-by-step device setup',
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.chat,
                    title: 'Live Chat Support',
                    subtitle: 'Chat with our support team',
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.email,
                    title: 'Email Support',
                    subtitle: 'support@smartplug.lk',
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // FAQ Sections
          _buildFAQSection(context, 'Getting Started', [
            FAQItem(
              'How do I add a new device?',
              'Go to Dashboard → Tap "+" button → Follow the setup wizard. Make sure your device is in pairing mode (LED blinking blue).',
            ),
            FAQItem(
              'What if my device won\'t connect?',
              'Check: 1) Device is powered on, 2) Wi-Fi password is correct, 3) Device is within router range, 4) 2.4GHz network is used (not 5GHz).',
            ),
            FAQItem(
              'Can I use 5GHz Wi-Fi?',
              'No, most smart plugs only support 2.4GHz networks. Make sure you connect to a 2.4GHz network during setup.',
            ),
          ]),

          _buildFAQSection(context, 'Device Control', [
            FAQItem(
              'Why is my device showing offline?',
              'Check your internet connection and device power. The device may have lost Wi-Fi connection or been unplugged.',
            ),
            FAQItem(
              'How do schedules work?',
              'Schedules run automatically when your device is online. If offline during a scheduled time, it will execute when reconnected.',
            ),
            FAQItem(
              'Can I control devices from anywhere?',
              'Yes, as long as your device is connected to Wi-Fi and you have internet access.',
            ),
          ]),

          _buildFAQSection(context, 'Energy Monitoring', [
            FAQItem(
              'How accurate is energy monitoring?',
              'Our devices measure voltage and current with ±2% accuracy. Energy calculations are highly precise for billing estimates.',
            ),
            FAQItem(
              'Why don\'t I see real-time data?',
              'Real-time data requires a stable internet connection. Data updates every 5-30 seconds depending on your plan.',
            ),
            FAQItem(
              'How is cost calculated?',
              'Cost uses Sri Lankan CEB tariff slabs. You can customize rates in Settings → Electricity Tariffs.',
            ),
          ]),

          _buildFAQSection(context, 'Troubleshooting', [
            FAQItem(
              'Device not responding to commands?',
              '1) Check Wi-Fi connection, 2) Restart the device by unplugging for 10 seconds, 3) Check if device firmware needs updating.',
            ),
            FAQItem(
              'App showing wrong power readings?',
              'Restart the app and device. If problem persists, the device may need calibration - contact support.',
            ),
            FAQItem(
              'How to factory reset my device?',
              'Hold the device button for 10 seconds until LED flashes rapidly. This will erase all settings.',
            ),
          ]),

          _buildFAQSection(context, 'Account & Billing', [
            FAQItem(
              'Is the app free to use?',
              'Basic features are free. Premium features like advanced analytics and multiple locations require a subscription.',
            ),
            FAQItem(
              'How to change my tariff rates?',
              'Go to Settings → Electricity Tariffs → Edit the slab rates according to your CEB bill.',
            ),
            FAQItem(
              'Can I export my usage data?',
              'Yes, go to Analytics → Export Data. You can export CSV files for further analysis.',
            ),
          ]),

          // Contact Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Still Need Help?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Contact our support team:'),
                  const SizedBox(height: 8),
                  const Text('📧 Email: support@smartplug.lk'),
                  const Text('📱 WhatsApp: +94 77 123 4567'),
                  const Text('🕒 Hours: 9 AM - 6 PM (Mon-Sat)'),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: () => _showComingSoon(context),
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Report a Bug'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildFAQSection(
    BuildContext context,
    String title,
    List<FAQItem> items,
  ) {
    return Card(
      child: ExpansionTile(
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        children: items.map((item) => _buildFAQItem(context, item)).toList(),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, FAQItem item) {
    return ExpansionTile(
      title: Text(item.question, style: Theme.of(context).textTheme.bodyLarge),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            item.answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feature coming soon!')));
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem(this.question, this.answer);
}
