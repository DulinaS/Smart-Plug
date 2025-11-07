import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/daily_summary.dart';
import '../../../data/repositories/summary_repo.dart';

class DaySummaryState {
  final String? deviceId;
  final DateTime? date; // date-only, UTC
  final bool loading;
  final String? error;
  final DailySummary? summary;

  // NEW: distinguish "no data" from hard errors
  final bool noData;

  const DaySummaryState({
    this.deviceId,
    this.date,
    this.loading = false,
    this.error,
    this.summary,
    this.noData = false,
  });

  DaySummaryState copyWith({
    String? deviceId,
    DateTime? date,
    bool? loading,
    String? error,
    DailySummary? summary,
    bool? noData,
  }) {
    return DaySummaryState(
      deviceId: deviceId ?? this.deviceId,
      date: date ?? this.date,
      loading: loading ?? this.loading,
      error: error,
      summary: summary,
      noData: noData ?? this.noData,
    );
  }
}

class DaySummaryController extends StateNotifier<DaySummaryState> {
  final SummaryRepository _repo;

  DaySummaryController(this._repo) : super(const DaySummaryState());

  void setDevice(String id) {
    state = state.copyWith(deviceId: id, error: null, noData: false);
  }

  void setDate(DateTime d) {
    // Force to UTC date-only (strip time)
    final dateOnly = DateTime.utc(d.year, d.month, d.day);
    state = state.copyWith(date: dateOnly, error: null, noData: false);
  }

  Future<void> load() async {
    final deviceId = state.deviceId;
    final date = state.date;
    if (deviceId == null || deviceId.isEmpty) {
      state = state.copyWith(error: 'Select a device', noData: false);
      return;
    }
    if (date == null) {
      state = state.copyWith(error: 'Select a date', noData: false);
      return;
    }

    // Allow ANY date strictly before today (UTC). Today/future are disallowed.
    final todayUtc = DateTime.now().toUtc();
    final todayDateOnly = DateTime.utc(
      todayUtc.year,
      todayUtc.month,
      todayUtc.day,
    );
    if (!date.isBefore(todayDateOnly)) {
      state = state.copyWith(
        error:
            'Summary for today or future is not available yet (calculated at 11:59 PM).',
        noData: false,
      );
      return;
    }

    state = state.copyWith(
      loading: true,
      error: null,
      summary: null,
      noData: false,
    );
    try {
      final dateStr = _fmt(date);

      final result = await _repo.getDailySummary(
        deviceId: deviceId,
        date: dateStr,
      );
      if (result == null) {
        // No records for that date → not an error, just show “not available”
        state = state.copyWith(
          loading: false,
          noData: true,
          summary: null,
          error: null,
        );
      } else {
        state = state.copyWith(loading: false, summary: result, noData: false);
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
        noData: false,
      );
    }
  }

  void clearError() => state = state.copyWith(error: null);

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final daySummaryControllerProvider =
    StateNotifierProvider<DaySummaryController, DaySummaryState>((ref) {
      final repo = ref.read(summaryRepositoryProvider);
      return DaySummaryController(repo);
    });
