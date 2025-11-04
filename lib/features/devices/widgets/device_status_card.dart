import 'package:flutter/material.dart';
import '../../../../data/models/device.dart';
import '../../../../core/utils/formatters.dart';

class DeviceStatusCard extends StatelessWidget {
  final Device device;

  const DeviceStatusCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final status = device.status;
    final isOnline = device.isOnline;
    final isOn = status.isOn;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (device.room != null)
                      Text(
                        device.room!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? (isOn ? Colors.green : Colors.grey)
                            : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOnline ? (isOn ? 'ON' : 'OFF') : 'OFFLINE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last seen: ${Formatters.timeAgo(device.lastSeen)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Electrical Parameters
            if (isOnline) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildParameterCard(
                      context,
                      icon: Icons.flash_on,
                      iconColor: Colors.orange,
                      label: 'Power',
                      value: '${Formatters.power(status.power)}W',
                      isActive: isOn,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildParameterCard(
                      context,
                      icon: Icons.electrical_services,
                      iconColor: Colors.blue,
                      label: 'Voltage',
                      value: Formatters.voltage(status.voltage),
                      isActive: isOn,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildParameterCard(
                      context,
                      icon: Icons.timeline,
                      iconColor: Colors.purple,
                      label: 'Current',
                      value: Formatters.current(status.current),
                      isActive: isOn,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildParameterCard(
                      context,
                      icon: Icons.battery_charging_full,
                      iconColor: Colors.green,
                      label: 'Energy Today',
                      value: '${Formatters.energy(status.energyToday)} kWh',
                      isActive: true,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Device Offline',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check your Wi-Fi connection and device power',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParameterCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? iconColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? iconColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: isActive ? iconColor : Colors.grey, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isActive ? iconColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
