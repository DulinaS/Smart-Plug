import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/modern_ui.dart';
import '../../../core/widgets/curved_header.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/daily_summary.dart';
import '../../devices/application/user_devices_controller.dart';
import '../application/day_summary_controller.dart';

// PERIOD TAB SUPPORT
import '../application/period_summary_controller.dart';
import '../../../data/models/range_summary.dart';

class SummaryHubScreen extends ConsumerStatefulWidget {
  const SummaryHubScreen({super.key});

  @override
  ConsumerState<SummaryHubScreen> createState() => _SummaryHubScreenState();
}

class _SummaryHubScreenState extends ConsumerState<SummaryHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayUtc = DateTime.now().toUtc();
    final yesterday = DateTime.utc(
      todayUtc.year,
      todayUtc.month,
      todayUtc.day,
    ).subtract(const Duration(days: 1));

    return MeshGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Beautiful curved header
            ScreenHeader(
              title: 'Analytics',
              subtitle: 'Energy usage summary',
              icon: Icons.analytics_rounded,
              accentColor: AppTheme.secondaryColor,
            ),
            const SizedBox(height: 12), // Spacing between header and tabs
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.5),
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Specific day'),
                  Tab(text: 'Time period'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _DaySummaryTab(defaultDate: yesterday),
                  const _RangeSummaryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- Specific Day TAB (DO NOT CHANGE) --------------------------- */

class _DaySummaryTab extends ConsumerStatefulWidget {
  final DateTime defaultDate;
  const _DaySummaryTab({required this.defaultDate});

  @override
  ConsumerState<_DaySummaryTab> createState() => _DaySummaryTabState();
}

class _DaySummaryTabState extends ConsumerState<_DaySummaryTab> {
  @override
  void initState() {
    super.initState();
    // Ensure devices list is loaded and set default date
    Future.microtask(() {
      final devices = ref.read(userDevicesControllerProvider);
      if (!devices.hasValue) {
        ref.read(userDevicesControllerProvider.notifier).refresh();
      }
      ref
          .read(daySummaryControllerProvider.notifier)
          .setDate(widget.defaultDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(userDevicesControllerProvider);
    final state = ref.watch(daySummaryControllerProvider);
    final ctrl = ref.read(daySummaryControllerProvider.notifier);

    final todayUtc = DateTime.now().toUtc();
    final lastSelectable = DateTime.utc(
      todayUtc.year,
      todayUtc.month,
      todayUtc.day,
    ).subtract(const Duration(days: 1));
    final firstSelectable = DateTime(2024, 1, 1); // adjust if needed

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        AppTheme.navBarTotalHeight,
      ), // extra bottom pad to avoid navbar overlap
      children: [
        // Errors (hard failures)
        if (state.error != null) ...[
          _Banner(
            color: Colors.red,
            icon: Icons.error_outline,
            message: state.error!,
            onClose: ctrl.clearError,
          ),
          const SizedBox(height: 12),
        ],

        Text('Select device', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        devicesAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (e, _) => Text('Failed to load devices: $e'),
          data: (list) {
            final currentValue =
                state.deviceId ??
                (list.isNotEmpty ? list.first.deviceId : null);
            return DropdownButtonFormField<String>(
              value: currentValue,
              items: list
                  .map(
                    (d) => DropdownMenuItem(
                      value: d.deviceId,
                      child: Text(
                        d.deviceName.isNotEmpty ? d.deviceName : d.deviceId,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => v != null ? ctrl.setDevice(v) : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        Text(
          'Select date (any day before today)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  state.date == null ? 'Pick a date' : _fmtDate(state.date!),
                ),
                onPressed: () async {
                  final initial = (state.date ?? lastSelectable);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial.isAfter(lastSelectable)
                        ? lastSelectable
                        : initial,
                    firstDate: firstSelectable,
                    lastDate:
                        lastSelectable, // allow ANY past day (not just yesterday)
                  );
                  if (picked != null) {
                    ctrl.setDate(
                      DateTime.utc(picked.year, picked.month, picked.day),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: state.loading ? null : () => ctrl.load(),
              child: state.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load'),
            ),
          ],
        ),

        const SizedBox(height: 16),
        const _NoteCard(),

        const SizedBox(height: 16),

        // "No data" info (friendly, not an error)
        if (state.noData && state.date != null)
          _Banner(
            color: Colors.blue,
            icon: Icons.info_outline,
            message:
                'No summary available for ${_fmtDate(state.date!)}. Try another past date.',
          ),

        if (state.summary != null) _SummaryCharts(summary: state.summary!),
      ],
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _NoteCard extends StatelessWidget {
  const _NoteCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 8),
            // Use Flexible to avoid pushing Row height unexpectedly
            const Flexible(
              child: Text(
                'Daily summaries are calculated at 11:59 PM. '
                'You can select any past date (before today). If a date has no data, we\'ll show "Not available".',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;
  final VoidCallback? onClose;

  const _Banner({
    required this.color,
    required this.icon,
    required this.message,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color.withOpacity(0.9)),
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: color),
            ),
        ],
      ),
    );
  }
}

class _SummaryCharts extends StatelessWidget {
  final DailySummary summary;
  const _SummaryCharts({required this.summary});

  // Calculate appropriate max Y value with padding
  double _calculateMaxY(List<double> values) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    // Add 10% padding to the top
    return maxValue * 1.1;
  }

  // Calculate appropriate interval for Y axis
  double? _calculateInterval(List<double> values) {
    final maxY = _calculateMaxY(values);

    // Calculate a nice interval (aim for 4-6 labels)
    final rawInterval = maxY / 5;

    // Round to a nice number
    if (rawInterval >= 100) {
      return (rawInterval / 50).ceil() * 50.0;
    } else if (rawInterval >= 10) {
      return (rawInterval / 10).ceil() * 10.0;
    } else if (rawInterval >= 1) {
      return (rawInterval / 1).ceil() * 1.0;
    } else {
      return (rawInterval / 0.5).ceil() * 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        label: 'Total Energy',
        value: '${Formatters.energy(summary.totalPower)} kWh',
        icon: Icons.bolt,
        color: Colors.orange,
      ),
      _StatCard(
        label: 'Avg Power',
        value: '${summary.avgPower.toStringAsFixed(1)} W',
        icon: Icons.flash_on,
        color: Colors.blue,
      ),
      _StatCard(
        label: 'Avg Voltage',
        value: '${summary.avgVoltage.toStringAsFixed(1)} V',
        icon: Icons.electric_bolt,
        color: Colors.green,
      ),
      _StatCard(
        label: 'Avg Current',
        value: '${summary.avgCurrent.toStringAsFixed(2)} A',
        icon: Icons.speed,
        color: Colors.purple,
      ),
    ];

    // Pie: relative distribution of avg metrics (normalized)
    final comp = [
      ('Power', summary.avgPower, Colors.blue),
      ('Voltage', summary.avgVoltage, Colors.green),
      ('Current', summary.avgCurrent, Colors.purple),
    ];
    final total = comp.fold<double>(0.0, (a, b) => a + b.$2);
    final pieSections = comp.map((e) {
      final pct = total > 0 ? (e.$2 / total) * 100 : 0.0;
      return PieChartSectionData(
        color: e.$3,
        value: e.$2,
        title: '${e.$1}\n${pct.toStringAsFixed(0)}%',
        radius: 54, // slightly smaller to avoid tight fits
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
    }).toList();

    // Bar: show raw averages
    final bars = [
      BarChartGroupData(
        x: 0,
        barRods: [BarChartRodData(toY: summary.avgPower, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(toY: summary.avgVoltage, color: Colors.green),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(toY: summary.avgCurrent, color: Colors.purple),
        ],
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min, // important: size to content
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Grid (responsive, scroll-safe)
        LayoutBuilder(
          builder: (context, constraints) {
            // 2 columns on phones, 3+ on wide
            final crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.3, // Changed from 2.6 to 2.3 for more height
              children: cards,
            );
          },
        ),
        const SizedBox(height: 16),

        // Donut/Pie
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average metrics mix',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height:
                      236, // a touch taller to avoid off-by-few-pixels overflow
                  child: PieChart(
                    PieChartData(
                      sections: pieSections,
                      centerSpaceRadius: 48,
                      sectionsSpace: 2,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Bars
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Averages',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 236,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      barGroups: bars,
                      minY: 0,
                      maxY: _calculateMaxY([
                        summary.avgPower,
                        summary.avgVoltage,
                        summary.avgCurrent,
                      ]),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            interval: _calculateInterval([
                              summary.avgPower,
                              summary.avgVoltage,
                              summary.avgCurrent,
                            ]),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              switch (value.toInt()) {
                                case 0:
                                  return const Text(
                                    'Power (W)',
                                    style: TextStyle(fontSize: 11),
                                  );
                                case 1:
                                  return const Text(
                                    'Voltage (V)',
                                    style: TextStyle(fontSize: 11),
                                  );
                                case 2:
                                  return const Text(
                                    'Current (A)',
                                    style: TextStyle(fontSize: 11),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10), // Reduced from 12
        child: Row(
          children: [
            CircleAvatar(
              radius: 18, // Reduced from 20
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 20), // Explicit size
            ),
            const SizedBox(width: 10), // Reduced from 12
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      fontSize: 11, // Slightly smaller
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2), // Reduced from 4
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Slightly smaller
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- TIME PERIOD TAB (MODIFIED) --------------------------- */

class _RangeSummaryTab extends ConsumerStatefulWidget {
  const _RangeSummaryTab();

  @override
  ConsumerState<_RangeSummaryTab> createState() => _RangeSummaryTabState();
}

class _RangeSummaryTabState extends ConsumerState<_RangeSummaryTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final devices = ref.read(userDevicesControllerProvider);
      if (!devices.hasValue) {
        ref.read(userDevicesControllerProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(userDevicesControllerProvider);
    final state = ref.watch(periodSummaryControllerProvider);
    final ctrl = ref.read(periodSummaryControllerProvider.notifier);

    final todayUtc = DateTime.now().toUtc();
    final maxSelectable = DateTime.utc(
      todayUtc.year,
      todayUtc.month,
      todayUtc.day,
    ).subtract(const Duration(days: 1));
    final firstSelectable = DateTime(2024, 1, 1);

    // Derived stats
    final availableDays = state.days.where((d) => d.hasData).toList();
    final totalKwh = availableDays.fold<double>(
      0.0,
      (a, b) => a + b.totalPower,
    );
    final avgPower = availableDays.isNotEmpty
        ? availableDays.fold<double>(0.0, (a, b) => a + b.avgPower) /
              availableDays.length
        : 0.0;
    final avgVoltage = availableDays.isNotEmpty
        ? availableDays.fold<double>(0.0, (a, b) => a + b.avgVoltage) /
              availableDays.length
        : 0.0;
    final avgCurrent = availableDays.isNotEmpty
        ? availableDays.fold<double>(0.0, (a, b) => a + b.avgCurrent) /
              availableDays.length
        : 0.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, AppTheme.navBarTotalHeight),
      children: [
        if (state.error != null) ...[
          _Banner(
            color: Colors.red,
            icon: Icons.error_outline,
            message: state.error!,
            onClose: ctrl.clearError,
          ),
          const SizedBox(height: 12),
        ],

        Text('Select device', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        devicesAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (e, _) => Text('Failed to load devices: $e'),
          data: (list) {
            return DropdownButtonFormField<String>(
              value:
                  state.deviceId ??
                  (list.isNotEmpty ? list.first.deviceId : null),
              items: list
                  .map(
                    (d) => DropdownMenuItem(
                      value: d.deviceId,
                      child: Text(
                        d.deviceName.isNotEmpty ? d.deviceName : d.deviceId,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => v != null ? ctrl.setDevice(v) : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        Text(
          'Select range (2–14 days, ending before today)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  state.startDate == null
                      ? 'Start date'
                      : _fmt(state.startDate!),
                ),
                onPressed: () async {
                  final initial =
                      state.startDate ??
                      maxSelectable.subtract(const Duration(days: 6));
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial.isAfter(maxSelectable)
                        ? maxSelectable
                        : initial,
                    firstDate: firstSelectable,
                    lastDate: maxSelectable,
                  );
                  if (picked != null) {
                    ctrl.setStart(
                      DateTime.utc(picked.year, picked.month, picked.day),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.event_available_outlined),
                label: Text(
                  state.endDate == null ? 'End date' : _fmt(state.endDate!),
                ),
                onPressed: () async {
                  final initial = state.endDate ?? maxSelectable;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial.isAfter(maxSelectable)
                        ? maxSelectable
                        : initial,
                    firstDate: firstSelectable,
                    lastDate: maxSelectable,
                  );
                  if (picked != null) {
                    ctrl.setEnd(
                      DateTime.utc(picked.year, picked.month, picked.day),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: state.loading ? null : () => ctrl.load(),
              child: state.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (state.days.isEmpty && state.loading == false && state.error == null)
          Text(
            'Pick a device and a valid date range (2–14 days, before today) to see analytics.',
            style: Theme.of(context).textTheme.bodySmall,
          ),

        if (state.days.isNotEmpty) ...[
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Energy',
                  value: '${Formatters.energy(totalKwh)} kWh',
                  icon: Icons.bolt,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Avg Power',
                  value: '${avgPower.toStringAsFixed(1)} W',
                  icon: Icons.flash_on,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Avg Voltage',
                  value: '${avgVoltage.toStringAsFixed(1)} V',
                  icon: Icons.electric_bolt,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Avg Current',
                  value: '${avgCurrent.toStringAsFixed(2)} A',
                  icon: Icons.speed,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Days with data',
                  value: '${availableDays.length}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Missing days',
                  value: '${state.missingDays}',
                  icon: Icons.info_outline,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // PIE: energy share per day (exclude zero, show missing slice if any)
          _EnergyDistributionPie(days: state.days),

          const SizedBox(height: 20),

          // Bar: total power per day (kWh), grey for missing
          _TotalEnergyBar(days: state.days),

          const SizedBox(height: 20),

          // Trend line: avgPower (W) with improved styling & tooltips
          _AvgPowerTrend(days: state.days),
        ],
      ],
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/* ------------------------ PERIOD TAB SUBCOMPONENTS ------------------------ */

class _EnergyDistributionPie extends StatelessWidget {
  final List<RangeDay> days;
  const _EnergyDistributionPie({required this.days});

  @override
  Widget build(BuildContext context) {
    final total = days.fold<double>(0, (a, b) => a + b.totalPower);
    final missingCount = days.where((d) => !d.hasData).length;

    // Build sections: Each day with >0 energy gets slice; if all zero or missing, show placeholder
    final slices = <PieChartSectionData>[];
    for (final d in days) {
      if (d.totalPower > 0) {
        final pct = total > 0 ? (d.totalPower / total) * 100 : 0;
        slices.add(
          PieChartSectionData(
            color: _colorForIndex(days.indexOf(d)),
            value: d.totalPower,
            title: '${d.date.month}/${d.date.day}\n${pct.toStringAsFixed(0)}%',
            radius: 56,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
    }

    if (slices.isEmpty) {
      // Single neutral slice to show "No energy data"
      slices.add(
        PieChartSectionData(
          color: Colors.grey,
          value: 1,
          title: 'No data',
          radius: 56,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (missingCount > 0) {
      // Add one slice for missing days (visual context)
      final missingValue = total == 0 ? 1.0 : total * 0.05; // small slice
      slices.add(
        PieChartSectionData(
          color: Colors.grey.shade400,
          value: missingValue,
          title: 'Missing-$missingCount',
          radius: 56,
          titleStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Energy distribution (kWh)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: slices,
                  centerSpaceRadius: 48,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                for (final s in slices)
                  if (s.title != 'No data')
                    _LegendChip(
                      color: s.color,
                      label: s.title.split('\n').first,
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForIndex(int i) {
    const palette = [
      Colors.deepPurple,
      Colors.blue,
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.green,
      Colors.cyan,
      Colors.red,
      Colors.lime,
      Colors.amber,
      Colors.brown,
      Colors.purple,
      Colors.lightBlue,
    ];
    return palette[i % palette.length];
  }
}

class _TotalEnergyBar extends StatelessWidget {
  final List<RangeDay> days;
  const _TotalEnergyBar({required this.days});

  double _computeMaxY() {
    final maxVal = days.fold<double>(
      0,
      (a, b) => a > b.totalPower ? a : b.totalPower,
    );
    return (maxVal == 0 ? 1 : maxVal) * 1.15; // pad
  }

  double _tickInterval() {
    final maxVal = days.fold<double>(
      0,
      (a, b) => a > b.totalPower ? a : b.totalPower,
    );
    if (maxVal <= 1) return 0.2;
    if (maxVal <= 5) return 1;
    if (maxVal <= 10) return 2;
    if (maxVal <= 25) return 5;
    return (maxVal / 6).ceilToDouble(); // fallback
  }

  @override
  Widget build(BuildContext context) {
    final maxY = _computeMaxY();
    final interval = _tickInterval();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total energy per day (kWh)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.25),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        interval: interval,
                        getTitlesWidget: (value, _) {
                          // Avoid label overlap by only showing nice ticks
                          if ((value / interval).round() == value / interval) {
                            final txt = value >= 10
                                ? value.toStringAsFixed(0)
                                : value.toStringAsFixed(1);
                            return Text(
                              txt,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i >= 0 && i < days.length) {
                            final d = days[i].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${d.month}/${d.day}',
                                style: const TextStyle(fontSize: 10),
                              ),
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
                  barGroups: List.generate(days.length, (i) {
                    final day = days[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: day.totalPower,
                          color: day.hasData
                              ? Colors.deepPurple
                              : Colors.grey.shade400,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                          rodStackItems: [],
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    );
                  }),
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(5),
                      getTooltipItem: (group, _, rod, __) {
                        final day = days[group.x.toInt()];
                        return BarTooltipItem(
                          '${day.date.month}/${day.date.day}\n'
                          '${day.totalPower.toStringAsFixed(2)} kWh',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Grey bars indicate days with no data. Axis interval dynamically chosen to prevent label overlap.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvgPowerTrend extends StatelessWidget {
  final List<RangeDay> days;
  const _AvgPowerTrend({required this.days});

  double _computeMaxY() {
    final maxVal = days.fold<double>(
      0,
      (a, b) => a > b.avgPower ? a : b.avgPower,
    );
    return (maxVal == 0 ? 1 : maxVal) * 1.15;
  }

  double _interval() {
    final maxVal = days.fold<double>(
      0,
      (a, b) => a > b.avgPower ? a : b.avgPower,
    );
    if (maxVal <= 50) return 10;
    if (maxVal <= 120) return 20;
    if (maxVal <= 300) return 50;
    return (maxVal / 6).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final maxY = _computeMaxY();
    final interval = _interval();

    // Build segments to create visible gaps (each list of contiguous data)
    final segments = <List<FlSpot>>[];
    List<FlSpot> current = [];
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      if (d.hasData) {
        current.add(FlSpot(i.toDouble(), d.avgPower));
      } else {
        if (current.isNotEmpty) {
          segments.add(current);
          current = [];
        }
      }
    }
    if (current.isNotEmpty) segments.add(current);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average power trend (W)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.25),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.08),
                      strokeWidth: 1,
                      dashArray: [4, 3],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: maxY,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: interval,
                        getTitlesWidget: (value, _) {
                          if ((value / interval).round() != value / interval) {
                            return const SizedBox.shrink();
                          }
                          final txt = value >= 100
                              ? value.toStringAsFixed(0)
                              : value.toStringAsFixed(0);
                          return Text(
                            txt,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i >= 0 && i < days.length) {
                            final d = days[i].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${d.month}/${d.day}',
                                style: const TextStyle(fontSize: 10),
                              ),
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
                  lineBarsData: segments
                      .map(
                        (segment) => LineChartBarData(
                          spots: segment,
                          isCurved: true,
                          curveSmoothness: 0.25,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: FlDotData(show: segment.length <= 16),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.10),
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.20),
                                Colors.blue.withOpacity(0.02),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) {
                        return touched
                            .map((barSpot) {
                              final i = barSpot.x.toInt();
                              if (i >= 0 && i < days.length) {
                                final day = days[i];
                                return LineTooltipItem(
                                  '${day.date.month}/${day.date.day}\n'
                                  '${day.avgPower.toStringAsFixed(1)} W',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }
                              return null;
                            })
                            .whereType<LineTooltipItem>()
                            .toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gaps indicate missing days. Smoothed curve with gradient area improves trend readability.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------------------- SMALL UTIL WIDGETS ---------------------------- */

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.darken(),
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- COLOR EXTENSION --------------------------- */
extension _ColorExt on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
