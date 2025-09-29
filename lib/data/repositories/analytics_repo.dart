import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../../core/config/env.dart';
import '../models/telemetry.dart';

class AnalyticsRepository {
  final HttpClient _httpClient;

  AnalyticsRepository(this._httpClient);

  Future<UsageSummary> getUsageSummary(String deviceId, String range) async {
    try {
      final endDate = DateTime.now();
      final startDate = _getStartDate(range);

      final response = await _httpClient.dio.post(
        '${AppConfig.dataBaseUrl}/summary',
        data: {
          'deviceId': deviceId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );

      final summary = response.data['summary'];

      return UsageSummary(
        deviceId: summary['deviceId'] ?? deviceId,
        startDate: DateTime.parse(summary['startDate']),
        endDate: DateTime.parse(summary['endDate']),
        totalEnergy: (summary['totalEnergy'] ?? 0.0).toDouble(),
        totalCost: (summary['totalCost'] ?? 0.0).toDouble(),
        avgPower: (summary['avgPower'] ?? 0.0).toDouble(),
        peakPower: (summary['peakPower'] ?? 0.0).toDouble(),
        hourlyData: _parseHourlyData(summary['hourlyData'] ?? []),
      );
    } catch (e) {
      return _getMockSummary(deviceId, range);
    }
  }

  List<HourlyUsage> _parseHourlyData(List<dynamic> hourlyData) {
    return hourlyData.map((data) {
      return HourlyUsage(
        hour: DateTime.parse(data['hour']),
        energy: (data['energy'] ?? 0.0).toDouble(),
        avgPower: (data['avgPower'] ?? 0.0).toDouble(),
        cost: (data['cost'] ?? 0.0).toDouble(),
      );
    }).toList();
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

  UsageSummary _getMockSummary(String deviceId, String range) {
    return UsageSummary(
      deviceId: deviceId,
      startDate: _getStartDate(range),
      endDate: DateTime.now(),
      totalEnergy: _generateEnergy(range),
      totalCost: _calculateCost(_generateEnergy(range)),
      avgPower: 120.0,
      peakPower: 450.0,
      hourlyData: _generateHourlyData(range),
    );
  }

  double _generateEnergy(String range) {
    final now = DateTime.now();
    switch (range) {
      case 'today':
        return 2.5 + (now.hour * 0.1);
      case 'week':
        return 18.0 + (now.day % 5);
      case 'month':
        return 75.0 + (now.day % 15);
      default:
        return 5.0;
    }
  }

  double _calculateCost(double energy) {
    double cost = 400.0;
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

      final energy = 0.05 + (index % 4) * 0.02;

      return HourlyUsage(
        hour: time,
        energy: energy,
        avgPower: energy * 1000,
        cost: energy * 15.0,
      );
    });
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final httpClient = ref.read(httpClientProvider);
  return AnalyticsRepository(httpClient);
});
