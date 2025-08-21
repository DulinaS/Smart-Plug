import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/telemetry.dart';

class AnalyticsRepository {
  Future<UsageSummary> getUsageSummary(String deviceId, String range) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    // Generate realistic sample data based on range
    return UsageSummary(
      deviceId: deviceId,
      startDate: _getStartDate(range),
      endDate: DateTime.now(),
      totalEnergy: _generateEnergy(range),
      totalCost: _calculateCost(_generateEnergy(range)),
      avgPower: 120.0 + (DateTime.now().millisecond % 100),
      peakPower: 450.0 + (DateTime.now().millisecond % 200),
      hourlyData: _generateHourlyData(range),
    );
  }

  DateTime _getStartDate(String range) {
    final now = DateTime.now();
    switch (range) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month, 1);
      default:
        return now.subtract(const Duration(days: 1));
    }
  }

  double _generateEnergy(String range) {
    final now = DateTime.now();
    switch (range) {
      case 'today':
        return 2.5 + (now.hour * 0.1); // Increases through the day
      case 'week':
        return 18.0 + (now.day % 5); // Weekly variation
      case 'month':
        return 75.0 + (now.day % 15); // Monthly variation
      default:
        return 5.0;
    }
  }

  double _calculateCost(double energy) {
    // Sri Lankan CEB tariff calculation
    double cost = 400.0; // Fixed charge

    if (energy <= 30) {
      cost += energy * 7.85;
    } else if (energy <= 60) {
      cost += (30 * 7.85) + ((energy - 30) * 10.00);
    } else if (energy <= 90) {
      cost += (30 * 7.85) + (30 * 10.00) + ((energy - 60) * 27.75);
    } else {
      cost +=
          (30 * 7.85) + (30 * 10.00) + (30 * 27.75) + ((energy - 90) * 32.00);
    }

    return cost;
  }

  List<HourlyUsage> _generateHourlyData(String range) {
    final periods = range == 'today'
        ? 24
        : range == 'week'
        ? 7
        : 30;
    final now = DateTime.now();

    return List.generate(periods, (index) {
      final time = range == 'today'
          ? DateTime(now.year, now.month, now.day, index)
          : range == 'week'
          ? now.subtract(Duration(days: 6 - index))
          : DateTime(now.year, now.month, index + 1);

      final baseEnergy = 0.05 + (index % 4) * 0.02;
      final energy =
          baseEnergy + (time.hour > 6 && time.hour < 22 ? 0.03 : 0.01);

      return HourlyUsage(
        hour: time,
        energy: energy,
        avgPower:
            energy * 1000 / (range == 'today' ? 1 : 24), // Convert to watts
        cost: energy * 15.0, // Average rate
      );
    });
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository();
});
