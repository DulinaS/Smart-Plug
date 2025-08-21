import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/device.dart';
import '../../../../core/utils/formatters.dart';

class DeviceInfoCard extends StatelessWidget {
  final Device device;

  const DeviceInfoCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildInfoRow(context, 'Device ID', device.id, canCopy: true),
            _buildInfoRow(context, 'Name', device.name),
            if (device.room != null)
              _buildInfoRow(context, 'Room', device.room!),
            _buildInfoRow(
              context,
              'Status',
              device.isOnline ? 'Online' : 'Offline',
              statusColor: device.isOnline ? Colors.green : Colors.red,
            ),
            _buildInfoRow(
              context,
              'Last Seen',
              Formatters.timeAgo(device.lastSeen),
            ),
            _buildInfoRow(context, 'Firmware Version', device.firmwareVersion),

            const SizedBox(height: 16),

            // Device Configuration
            Text(
              'Configuration',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),

            _buildInfoRow(
              context,
              'Max Current',
              '${device.config.maxCurrent} A',
            ),
            _buildInfoRow(context, 'Max Power', '${device.config.maxPower} W'),
            _buildInfoRow(
              context,
              'Safety Protection',
              device.config.safetyEnabled ? 'Enabled' : 'Disabled',
              statusColor: device.config.safetyEnabled
                  ? Colors.green
                  : Colors.orange,
            ),
            _buildInfoRow(
              context,
              'Report Interval',
              '${device.config.reportInterval} seconds',
            ),

            const SizedBox(height: 16),

            // Current Status
            if (device.isOnline) ...[
              Text(
                'Current Readings',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      context,
                      'Voltage',
                      '${device.status.voltage.toStringAsFixed(1)} V',
                      Icons.flash_on,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusCard(
                      context,
                      'Current',
                      '${device.status.current.toStringAsFixed(2)} A',
                      Icons.timeline,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      context,
                      'Power',
                      '${device.status.power.toStringAsFixed(1)} W',
                      Icons.electrical_services,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusCard(
                      context,
                      'Energy Today',
                      '${device.status.energyToday.toStringAsFixed(2)} kWh',
                      Icons.battery_charging_full,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? statusColor,
    bool canCopy = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          Row(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _copyToClipboard(context, value),
                  child: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
