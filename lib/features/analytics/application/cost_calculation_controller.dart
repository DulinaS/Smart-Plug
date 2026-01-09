import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/cost_calculation_repo.dart';
import '../../../data/models/cost_calculation.dart';

class CostCalculationState {
  final String? deviceId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool loading;
  final String? error;
  final CostCalculationResult? result;

  // User's total bill for comparison
  final double? userTotalBill;
  final double? deviceContribution; // calculated percentage

  const CostCalculationState({
    this.deviceId,
    this.startDate,
    this.endDate,
    this.loading = false,
    this.error,
    this.result,
    this.userTotalBill,
    this.deviceContribution,
  });

  CostCalculationState copyWith({
    String? deviceId,
    DateTime? startDate,
    DateTime? endDate,
    bool? loading,
    String? error,
    CostCalculationResult? result,
    double? userTotalBill,
    double? deviceContribution,
  }) {
    return CostCalculationState(
      deviceId: deviceId ?? this.deviceId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      loading: loading ?? this.loading,
      error: error,
      result: result ?? this.result,
      userTotalBill: userTotalBill ?? this.userTotalBill,
      deviceContribution: deviceContribution ?? this.deviceContribution,
    );
  }

  /// Calculate the contribution percentage of device cost to total bill
  double? get contributionPercentage {
    if (result == null || userTotalBill == null || userTotalBill! <= 0) {
      return null;
    }
    return (result!.totalCostLKR / userTotalBill!) * 100;
  }

  /// Get the remaining bill amount after device cost
  double? get remainingBill {
    if (result == null || userTotalBill == null) return null;
    return userTotalBill! - result!.totalCostLKR;
  }
}

class CostCalculationController extends StateNotifier<CostCalculationState> {
  final CostCalculationRepository _repo;

  CostCalculationController(this._repo) : super(const CostCalculationState());

  void setDevice(String id) =>
      state = state.copyWith(deviceId: id, error: null);

  void setStartDate(DateTime d) => state = state.copyWith(
    startDate: DateTime.utc(d.year, d.month, d.day),
    error: null,
  );

  void setEndDate(DateTime d) => state = state.copyWith(
    endDate: DateTime.utc(d.year, d.month, d.day),
    error: null,
  );

  void setUserTotalBill(double? bill) {
    state = state.copyWith(userTotalBill: bill);
    _updateContribution();
  }

  void clearError() => state = state.copyWith(error: null);

  void _updateContribution() {
    if (state.result != null &&
        state.userTotalBill != null &&
        state.userTotalBill! > 0) {
      final contribution =
          (state.result!.totalCostLKR / state.userTotalBill!) * 100;
      state = state.copyWith(deviceContribution: contribution);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> calculateCost() async {
    final dev = state.deviceId;
    final s = state.startDate;
    final e = state.endDate;

    if ((dev ?? '').isEmpty) {
      state = state.copyWith(error: 'Please select a device');
      return;
    }
    if (s == null || e == null) {
      state = state.copyWith(error: 'Please select both start and end dates');
      return;
    }
    if (e.isBefore(s)) {
      state = state.copyWith(error: 'End date must be after start date');
      return;
    }

    state = state.copyWith(loading: true, error: null);

    try {
      final result = await _repo.calculateCost(
        deviceId: dev!,
        startDate: _formatDate(s),
        endDate: _formatDate(e),
      );

      state = state.copyWith(loading: false, result: result, error: null);

      _updateContribution();
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void reset() {
    state = const CostCalculationState();
  }
}

// Provider
final costCalculationControllerProvider =
    StateNotifierProvider<CostCalculationController, CostCalculationState>((
      ref,
    ) {
      return CostCalculationController(
        ref.watch(costCalculationRepositoryProvider),
      );
    });
