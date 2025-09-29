import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/telemetry.dart';
import '../../../data/repositories/analytics_repo.dart';

// Additional models for analytics
class TariffBreakdown {
  final String range;
  final double units;
  final double rate;
  final double cost;

  const TariffBreakdown({
    required this.range,
    required this.units,
    required this.rate,
    required this.cost,
  });
}

class HourlyStats {
  final int hour;
  final double avgPower;
  final double peakPower;
  final double energy;

  const HourlyStats({
    required this.hour,
    required this.avgPower,
    required this.peakPower,
    required this.energy,
  });
}

class AnalyticsState {
  final bool isLoading;
  final String? error;
  final double totalEnergy;
  final double totalCost;
  final double avgPower;
  final double peakPower;
  final double runtimeHours;
  final List<HourlyUsage> hourlyData;
  final List<TariffBreakdown> tariffBreakdown;
  final List<HourlyStats> hourlyStats;
  final double powerFactor;
  final String efficiencyRating;
  final double carbonFootprint;
  final double monthlyEstimate;
  final double energyCost;
  final double fixedCost;

  const AnalyticsState({
    this.isLoading = false,
    this.error,
    this.totalEnergy = 0.0,
    this.totalCost = 0.0,
    this.avgPower = 0.0,
    this.peakPower = 0.0,
    this.runtimeHours = 0.0,
    this.hourlyData = const [],
    this.tariffBreakdown = const [],
    this.hourlyStats = const [],
    this.powerFactor = 0.9,
    this.efficiencyRating = 'Good',
    this.carbonFootprint = 0.0,
    this.monthlyEstimate = 0.0,
    this.energyCost = 0.0,
    this.fixedCost = 400.0,
  });

  AnalyticsState copyWith({
    bool? isLoading,
    String? error,
    double? totalEnergy,
    double? totalCost,
    double? avgPower,
    double? peakPower,
    double? runtimeHours,
    List<HourlyUsage>? hourlyData,
    List<TariffBreakdown>? tariffBreakdown,
    List<HourlyStats>? hourlyStats,
    double? powerFactor,
    String? efficiencyRating,
    double? carbonFootprint,
    double? monthlyEstimate,
    double? energyCost,
    double? fixedCost,
  }) {
    return AnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalEnergy: totalEnergy ?? this.totalEnergy,
      totalCost: totalCost ?? this.totalCost,
      avgPower: avgPower ?? this.avgPower,
      peakPower: peakPower ?? this.peakPower,
      runtimeHours: runtimeHours ?? this.runtimeHours,
      hourlyData: hourlyData ?? this.hourlyData,
      tariffBreakdown: tariffBreakdown ?? this.tariffBreakdown,
      hourlyStats: hourlyStats ?? this.hourlyStats,
      powerFactor: powerFactor ?? this.powerFactor,
      efficiencyRating: efficiencyRating ?? this.efficiencyRating,
      carbonFootprint: carbonFootprint ?? this.carbonFootprint,
      monthlyEstimate: monthlyEstimate ?? this.monthlyEstimate,
      energyCost: energyCost ?? this.energyCost,
      fixedCost: fixedCost ?? this.fixedCost,
    );
  }
}

class AnalyticsController extends StateNotifier<AnalyticsState> {
  final AnalyticsRepository _analyticsRepository;
  final String deviceId;

  AnalyticsController(this._analyticsRepository, this.deviceId)
    : super(const AnalyticsState()) {
    loadUsageData('today');
  }

  Future<void> loadUsageData(String period) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final summary = await _analyticsRepository.getUsageSummary(
        deviceId,
        period,
      );

      // Calculate additional metrics
      final runtimeHours = _calculateRuntimeHours(summary.hourlyData);
      final tariffBreakdown = _calculateTariffBreakdown(summary.totalEnergy);
      final hourlyStats = _generateHourlyStats(summary.hourlyData);
      final efficiency = _calculateEfficiency(
        summary.avgPower,
        summary.peakPower,
      );
      final carbonFootprint = _calculateCarbonFootprint(summary.totalEnergy);
      final monthlyEstimate = _estimateMonthlyUsage(
        summary.totalEnergy,
        period,
      );
      final energyCost = summary.totalCost - 400.0; // Subtract fixed charge

      state = state.copyWith(
        isLoading: false,
        totalEnergy: summary.totalEnergy,
        totalCost: summary.totalCost,
        avgPower: summary.avgPower,
        peakPower: summary.peakPower,
        runtimeHours: runtimeHours,
        hourlyData: summary.hourlyData,
        tariffBreakdown: tariffBreakdown,
        hourlyStats: hourlyStats,
        powerFactor:
            0.85 + (DateTime.now().millisecond % 150) / 1000, // Simulated
        efficiencyRating: efficiency,
        carbonFootprint: carbonFootprint,
        monthlyEstimate: monthlyEstimate,
        energyCost: energyCost,
        fixedCost: 400.0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  double _calculateRuntimeHours(List<HourlyUsage> hourlyData) {
    return hourlyData.where((h) => h.energy > 0.01).length.toDouble();
  }

  List<TariffBreakdown> _calculateTariffBreakdown(double totalEnergy) {
    final breakdown = <TariffBreakdown>[];
    double remainingEnergy = totalEnergy;

    // Sri Lankan CEB tariff slabs
    final slabs = [
      {'range': '0-30 kWh', 'limit': 30.0, 'rate': 7.85},
      {'range': '31-60 kWh', 'limit': 30.0, 'rate': 10.00},
      {'range': '61-90 kWh', 'limit': 30.0, 'rate': 27.75},
      {'range': '91+ kWh', 'limit': double.infinity, 'rate': 32.00},
    ];

    for (final slab in slabs) {
      if (remainingEnergy <= 0) break;

      final slabLimit = slab['limit']! as double;
      final slabEnergy = remainingEnergy > slabLimit
          ? slabLimit
          : remainingEnergy;

      final cost = slabEnergy * (slab['rate']! as double);

      breakdown.add(
        TariffBreakdown(
          range: slab['range']! as String,
          units: slabEnergy,
          rate: slab['rate']! as double,
          cost: cost,
        ),
      );

      remainingEnergy -= slabEnergy;
    }

    return breakdown;
  }

  List<HourlyStats> _generateHourlyStats(List<HourlyUsage> hourlyData) {
    final statsMap = <int, List<double>>{};

    for (final usage in hourlyData) {
      final hour = usage.hour.hour;
      statsMap.putIfAbsent(hour, () => []).add(usage.avgPower);
    }

    return statsMap.entries.map((entry) {
      final powers = entry.value;
      return HourlyStats(
        hour: entry.key,
        avgPower: powers.reduce((a, b) => a + b) / powers.length,
        peakPower: powers.reduce((a, b) => a > b ? a : b),
        energy: powers.reduce((a, b) => a + b) / 1000, // Convert to kWh
      );
    }).toList()..sort((a, b) => a.hour.compareTo(b.hour));
  }

  String _calculateEfficiency(double avgPower, double peakPower) {
    if (avgPower == 0 || peakPower == 0) return 'No Data';

    final efficiency = avgPower / peakPower;
    if (efficiency > 0.8) return 'Excellent';
    if (efficiency > 0.6) return 'Good';
    if (efficiency > 0.4) return 'Fair';
    return 'Poor';
  }

  double _calculateCarbonFootprint(double energyKWh) {
    // Sri Lanka grid emission factor: ~0.5 kg CO2/kWh
    return energyKWh * 0.5;
  }

  double _estimateMonthlyUsage(double currentUsage, String period) {
    switch (period) {
      case 'today':
        return currentUsage * 30; // Daily to monthly
      case 'week':
        return (currentUsage / 7) * 30; // Weekly to monthly
      case 'month':
        return currentUsage; // Already monthly
      default:
        return currentUsage * 30;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final analyticsControllerProvider =
    StateNotifierProvider.family<AnalyticsController, AnalyticsState, String>((
      ref,
      deviceId,
    ) {
      final analyticsRepository = ref.read(analyticsRepositoryProvider);
      return AnalyticsController(analyticsRepository, deviceId);
    });
