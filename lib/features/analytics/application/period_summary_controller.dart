import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/summary_repo.dart';
import '../../../data/models/range_summary.dart';

class PeriodSummaryState {
  final String? deviceId;
  final DateTime? startDate; // date-only UTC
  final DateTime? endDate; // date-only UTC
  final bool loading;
  final String? error;
  final List<RangeDay> days; // full span; missing days as hasData=false
  final int missingDays;

  const PeriodSummaryState({
    this.deviceId,
    this.startDate,
    this.endDate,
    this.loading = false,
    this.error,
    this.days = const [],
    this.missingDays = 0,
  });

  PeriodSummaryState copyWith({
    String? deviceId,
    DateTime? startDate,
    DateTime? endDate,
    bool? loading,
    String? error,
    List<RangeDay>? days,
    int? missingDays,
  }) {
    return PeriodSummaryState(
      deviceId: deviceId ?? this.deviceId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      loading: loading ?? this.loading,
      error: error,
      days: days ?? this.days,
      missingDays: missingDays ?? this.missingDays,
    );
  }
}

class PeriodSummaryController extends StateNotifier<PeriodSummaryState> {
  final SummaryRepository _repo;

  PeriodSummaryController(this._repo) : super(const PeriodSummaryState());

  void setDevice(String id) =>
      state = state.copyWith(deviceId: id, error: null);
  void setStart(DateTime d) => state = state.copyWith(
    startDate: DateTime.utc(d.year, d.month, d.day),
    error: null,
  );
  void setEnd(DateTime d) => state = state.copyWith(
    endDate: DateTime.utc(d.year, d.month, d.day),
    error: null,
  );
  void clearError() => state = state.copyWith(error: null);

  Future<void> load() async {
    final dev = state.deviceId;
    final s = state.startDate;
    final e = state.endDate;

    if ((dev ?? '').isEmpty) {
      state = state.copyWith(error: 'Select a device');
      return;
    }
    if (s == null || e == null) {
      state = state.copyWith(error: 'Select both start and end dates');
      return;
    }
    if (e.isBefore(s)) {
      state = state.copyWith(error: 'End date must be after start date');
      return;
    }

    // Must end before today (UTC); summaries at 23:59
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    if (!e.isBefore(today)) {
      state = state.copyWith(
        error:
            'End date cannot be today or in the future (generated at 11:59 PM).',
      );
      return;
    }

    // Length (inclusive) 2–14 days
    final len = e.difference(s).inDays + 1;
    if (len < 2) {
      state = state.copyWith(error: 'Minimum range is 2 days.');
      return;
    }
    if (len > 14) {
      state = state.copyWith(error: 'Maximum range is 14 days (2 weeks).');
      return;
    }

    state = state.copyWith(
      loading: true,
      error: null,
      days: const [],
      missingDays: 0,
    );

    try {
      final sStr = _fmt(s);
      final eStr = _fmt(e);
      final raw = await _repo.getRangeRaw(
        deviceId: dev!,
        startDate: sStr,
        endDate: eStr,
      );

      // Map records by date string
      final byDate = <String, Map<String, dynamic>>{};
      for (final r in raw) {
        final d = (r['summary_date'] ?? r['date'] ?? '').toString();
        if (d.isNotEmpty) byDate[d] = r;
      }

      // Build complete span
      final days = <RangeDay>[];
      var cursor = s;
      int missing = 0;
      while (!cursor.isAfter(e)) {
        final key = _fmt(cursor);
        final rec = byDate[key];
        if (rec == null) {
          days.add(
            RangeDay(
              date: cursor,
              hasData: false,
              totalPower: 0,
              avgPower: 0,
              avgCurrent: 0,
              avgVoltage: 0,
            ),
          );
          missing++;
        } else {
          days.add(
            RangeDay(
              date: cursor,
              hasData: true,
              totalPower: (rec['total_power'] ?? 0).toDouble(),
              avgPower: (rec['avg_power'] ?? 0).toDouble(),
              avgCurrent: (rec['avg_current'] ?? 0).toDouble(),
              avgVoltage: (rec['avg_voltage'] ?? 0).toDouble(),
            ),
          );
        }
        cursor = cursor.add(const Duration(days: 1));
      }

      state = state.copyWith(loading: false, days: days, missingDays: missing);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final periodSummaryControllerProvider =
    StateNotifierProvider<PeriodSummaryController, PeriodSummaryState>((ref) {
      final repo = ref.read(summaryRepositoryProvider);
      return PeriodSummaryController(repo);
    });
