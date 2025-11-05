import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../data/models/sensor_reading.dart';
import '../../../../core/utils/formatters.dart';

class PowerChart extends StatelessWidget {
  final List<SensorReading> sensorData; // Changed from telemetryData

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

    // Prepare chart data from sensor readings
    final spots = sensorData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.power);
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
        // Real-time stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCard(
              'Current',
              '${sensorData.last.current.toStringAsFixed(2)} A',
              Colors.blue,
            ),
            _buildStatCard(
              'Voltage',
              '${sensorData.last.voltage.toStringAsFixed(1)} V',
              Colors.green,
            ),
            _buildStatCard(
              'Power',
              '${sensorData.last.power.toStringAsFixed(0)} W',
              Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Power chart
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxPower > 100 ? 50 : 10,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}W',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: (sensorData.length / 5).ceil().toDouble(),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < sensorData.length) {
                        final time = DateTime.parse(
                          sensorData[index].timestamp,
                        );
                        return Text(
                          Formatters.time(time),
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
              minY: minPower > 0 ? 0 : minPower - 10,
              maxY: maxPower + 10,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: Colors.blue,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show:
                        sensorData.length <
                        10, // Show dots only for small datasets
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index >= 0 && index < sensorData.length) {
                        final reading = sensorData[index];
                        return LineTooltipItem(
                          '${reading.power.toStringAsFixed(1)}W\n'
                          '${reading.current.toStringAsFixed(2)}A\n'
                          '${Formatters.time(DateTime.parse(reading.timestamp))}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
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
