import 'package:flutter/material.dart';
import '../../../../data/models/device.dart';
import '../../../../core/utils/formatters.dart';

class UsageSummaryCard extends StatelessWidget {
  final List<Device> devices;

  const UsageSummaryCard({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    final totalPower = devices
        .where((d) => d.isOnline && d.status.isOn)
        .fold<double>(0, (sum, device) => sum + device.status.power);

    final totalEnergyToday = devices
        .where((d) => d.isOnline)
        .fold<double>(0, (sum, device) => sum + device.status.energyToday);

    final activeDevices = devices
        .where((d) => d.isOnline && d.status.isOn)
        .length;
    final totalDevices = devices.length;

    // Rough cost calculation (will be more accurate with proper tariff in later phases)
    final estimatedCostToday =
        totalEnergyToday * 25.0; // ~LKR 25 per kWh average

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Usage',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.flash_on,
                    iconColor: Colors.orange,
                    label: 'Current Power',
                    value: '${Formatters.power(totalPower)}W',
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.electrical_services,
                    iconColor: Colors.blue,
                    label: 'Energy Used',
                    value: '${Formatters.energy(totalEnergyToday)} kWh',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.currency_exchange,
                    iconColor: Colors.green,
                    label: 'Est. Cost',
                    value: 'LKR ${Formatters.currency(estimatedCostToday)}',
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    icon: Icons.devices,
                    iconColor: Colors.purple,
                    label: 'Active Devices',
                    value: '$activeDevices / $totalDevices',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
