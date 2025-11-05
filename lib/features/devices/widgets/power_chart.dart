import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../data/models/sensor_reading.dart';
import '../../../../core/utils/formatters.dart';

class PowerChart extends StatelessWidget {
  final List<SensorReading> sensorData;

  const PowerChart({super.key, required this.sensorData});

  @override
  Widget build(BuildContext context) {
    if (sensorData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading real-time data...'),
          ],
        ),
      );
    }

    final latest = sensorData.last;
    final isOn = _isOnFromBackend(latest);

    final spots = sensorData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.power);
    }).toList();

    final maxPower = sensorData
        .map((e) => e.power)
        .reduce((a, b) => a > b ? a : b);
    final minPower = sensorData
        .map((e) => e.power)
        .reduce((a, b) => a < b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusDot(isOn: isOn),
            const SizedBox(width: 8),
            Text(
              isOn ? 'ON' : 'OFF',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isOn ? Colors.green[700] : Colors.red[700],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Last update: ${Formatters.time(DateTime.parse(latest.timestamp))}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat(
              'Current',
              '${latest.current.toStringAsFixed(2)} A',
              Colors.blue,
            ),
            _stat(
              'Voltage',
              '${latest.voltage.toStringAsFixed(1)} V',
              Colors.green,
            ),
            _stat(
              'Power',
              '${latest.power.toStringAsFixed(0)} W',
              Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxPower > 100 ? 50 : 10,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}W',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: (sensorData.length / 5).ceil().toDouble(),
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i >= 0 && i < sensorData.length) {
                        final t = DateTime.parse(sensorData[i].timestamp);
                        return Text(
                          Formatters.time(t),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              minX: 0,
              maxX: (sensorData.length - 1).toDouble(),
              minY: minPower > 0 ? 0 : (minPower - 10),
              maxY: maxPower + 10,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: Colors.blue,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: sensorData.length < 10),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touched) => touched.map((s) {
                    final i = s.x.toInt();
                    if (i >= 0 && i < sensorData.length) {
                      final r = sensorData[i];
                      return LineTooltipItem(
                        '${r.power.toStringAsFixed(1)}W\n'
                        '${r.current.toStringAsFixed(2)}A\n'
                        '${Formatters.time(DateTime.parse(r.timestamp))}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    }
                    return null;
                  }).toList(),
                ),
                handleBuiltInTouches: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isOnFromBackend(SensorReading r) {
    final s = r.state?.toUpperCase();
    if (s == 'ON') return true;
    if (s == 'OFF') return false;
    // Should be rare; fallback if state missing
    return r.power > 1.0 || r.current > 0.05;
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool isOn;
  const _StatusDot({required this.isOn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isOn ? Colors.green : Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isOn ? Colors.green : Colors.red).withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}
