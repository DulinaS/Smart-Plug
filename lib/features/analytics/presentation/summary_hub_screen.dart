import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/daily_summary.dart';
import '../../devices/application/user_devices_controller.dart';
import '../application/day_summary_controller.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Specific day'),
            Tab(text: 'Time period'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _DaySummaryTab(defaultDate: yesterday),
          const _PeriodSummaryPlaceholder(),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        28,
      ), // extra bottom pad to avoid tiny overflows
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
    final maxValue = values.reduce((a, b) => a > b ? a : b);
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

class _PeriodSummaryPlaceholder extends StatelessWidget {
  const _PeriodSummaryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Time period summary will be available soon.\n'
        'You will be able to compare multiple days/week/month.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
