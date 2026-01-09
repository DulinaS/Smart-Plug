import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/modern_ui.dart';
import '../../../core/widgets/curved_header.dart';
import '../../devices/application/user_devices_controller.dart';
import '../application/cost_calculation_controller.dart';

class CostCalculationScreen extends ConsumerStatefulWidget {
  const CostCalculationScreen({super.key});

  @override
  ConsumerState<CostCalculationScreen> createState() =>
      _CostCalculationScreenState();
}

class _CostCalculationScreenState extends ConsumerState<CostCalculationScreen>
    with SingleTickerProviderStateMixin {
  String? _deviceId;
  DateTime? _startDate;
  DateTime? _endDate;
  late TabController _tabController;
  final TextEditingController _billController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _billController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(userDevicesControllerProvider);
    final costState = ref.watch(costCalculationControllerProvider);

    return AnimatedGradientBackground(
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ScreenHeader(
                  title: 'Cost Calculator',
                  subtitle: 'Estimate your electricity costs',
                  icon: Icons.calculate_rounded,
                  accentColor: AppTheme.successColor,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: devices.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _buildErrorState(context, e.toString()),
                    data: (list) {
                      if (list.isEmpty) {
                        return _buildEmptyState(context);
                      }
                      _deviceId ??= list.first.deviceId;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDeviceSelector(list),
                          const SizedBox(height: 16),
                          _buildDateRangeSelector(),
                          const SizedBox(height: 16),
                          _buildCalculateButton(costState),
                          if (costState.result != null) ...[
                            const SizedBox(height: 24),
                            _buildTabBar(),
                            const SizedBox(height: 16),
                            _buildTabContent(costState),
                          ],
                          if (costState.error != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(
                              message: costState.error!,
                              onClose: () => ref
                                  .read(
                                    costCalculationControllerProvider.notifier,
                                  )
                                  .clearError(),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.navBarTotalHeight + 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceSelector(List<UserDeviceView> list) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.devices_rounded,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Select Device',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _deviceId,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppTheme.darkCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownColor: AppTheme.darkCard,
            items: list
                .map(
                  (d) => DropdownMenuItem(
                    value: d.deviceId,
                    child: Text(
                      d.deviceName.isNotEmpty ? d.deviceName : d.deviceId,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              setState(() => _deviceId = v);
              ref
                  .read(costCalculationControllerProvider.notifier)
                  .setDevice(v!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: AppTheme.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Date Range',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DatePickerTile(
                  label: 'From',
                  date: _startDate,
                  formattedDate: _startDate != null
                      ? dateFormat.format(_startDate!)
                      : 'Select date',
                  onTap: () => _selectDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerTile(
                  label: 'To',
                  date: _endDate,
                  formattedDate: _endDate != null
                      ? dateFormat.format(_endDate!)
                      : 'Select date',
                  onTap: () => _selectDate(isStart: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_startDate ?? now.subtract(const Duration(days: 30)))
        : (_endDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.darkCard,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          ref
              .read(costCalculationControllerProvider.notifier)
              .setStartDate(picked);
        } else {
          _endDate = picked;
          ref
              .read(costCalculationControllerProvider.notifier)
              .setEndDate(picked);
        }
      });
    }
  }

  Widget _buildCalculateButton(CostCalculationState costState) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: costState.loading
            ? null
            : () {
                if (_deviceId != null) {
                  ref
                      .read(costCalculationControllerProvider.notifier)
                      .setDevice(_deviceId!);
                }
                ref
                    .read(costCalculationControllerProvider.notifier)
                    .calculateCost();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: costState.loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calculate_rounded, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Calculate Cost',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.successGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Cost Summary'),
          Tab(text: 'Bill Comparison'),
        ],
      ),
    );
  }

  Widget _buildTabContent(CostCalculationState costState) {
    return SizedBox(
      height: 520,
      child: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _CostSummaryTab(result: costState.result!),
          _BillComparisonTab(
            costState: costState,
            billController: _billController,
            onBillChanged: (value) {
              final bill = double.tryParse(value);
              ref
                  .read(costCalculationControllerProvider.notifier)
                  .setUserTotalBill(bill);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calculate_outlined,
              size: 48,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No devices available',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a device first to calculate costs',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Date Picker Tile Widget
class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String formattedDate;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null
                ? AppTheme.accentColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: date != null ? AppTheme.accentColor : Colors.white38,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      color: date != null ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Cost Summary Tab with Circular Display
class _CostSummaryTab extends StatelessWidget {
  final dynamic result;

  const _CostSummaryTab({required this.result});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Column(
      children: [
        const SizedBox(height: 8),
        // Circular Cost Display
        _CircularCostDisplay(
          totalCost: result.totalCostLKR,
          totalEnergy: result.totalEnergyKWh,
        ),
        const SizedBox(height: 24),
        // Details Card
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Period',
                value:
                    '${dateFormat.format(result.fromDate)} - ${dateFormat.format(result.toDate)}',
                color: AppTheme.accentColor,
              ),
              const Divider(color: Colors.white12, height: 24),
              _DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Total Days',
                value: '${result.totalDays} days',
                color: AppTheme.primaryColor,
              ),
              const Divider(color: Colors.white12, height: 24),
              _DetailRow(
                icon: Icons.bolt_rounded,
                label: 'Energy Used',
                value: '${result.totalEnergyKWh.toStringAsFixed(2)} kWh',
                color: AppTheme.warningColor,
              ),
              const Divider(color: Colors.white12, height: 24),
              _DetailRow(
                icon: Icons.account_balance_rounded,
                label: 'Consumer Type',
                value: result.consumerType.toString().toUpperCase(),
                color: AppTheme.secondaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Circular Cost Display Widget
class _CircularCostDisplay extends StatefulWidget {
  final double totalCost;
  final double totalEnergy;

  const _CircularCostDisplay({
    required this.totalCost,
    required this.totalEnergy,
  });

  @override
  State<_CircularCostDisplay> createState() => _CircularCostDisplayState();
}

class _CircularCostDisplayState extends State<_CircularCostDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _CircularProgressPainter(
                    progress: 1.0,
                    strokeWidth: 12,
                    backgroundColor: AppTheme.darkCard,
                  ),
                ),
                // Progress circle
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _CircularProgressPainter(
                    progress: _progressAnimation.value,
                    strokeWidth: 12,
                    progressGradient: const LinearGradient(
                      colors: [
                        AppTheme.successColor,
                        AppTheme.secondaryColor,
                        AppTheme.primaryColor,
                      ],
                    ),
                  ),
                ),
                // Glow effect
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                // Inner content
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.darkSurface.withOpacity(0.8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.attach_money_rounded,
                        color: AppTheme.successColor,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LKR',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white54),
                      ),
                      Text(
                        (widget.totalCost * _progressAnimation.value)
                            .toStringAsFixed(2),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFeatures: [
                                const FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Cost',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Bill Comparison Tab
class _BillComparisonTab extends StatelessWidget {
  final CostCalculationState costState;
  final TextEditingController billController;
  final ValueChanged<String> onBillChanged;

  const _BillComparisonTab({
    required this.costState,
    required this.billController,
    required this.onBillChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasComparison =
        costState.userTotalBill != null &&
        costState.userTotalBill! > 0 &&
        costState.result != null;

    return Column(
      children: [
        const SizedBox(height: 8),
        // Bill Input Card
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppTheme.warningColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Your Total Bill',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'See how much this device contributes',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: billController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: onBillChanged,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  prefixText: 'LKR ',
                  prefixStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                  ),
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 24),
                  filled: true,
                  fillColor: AppTheme.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.warningColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasComparison) ...[
          const SizedBox(height: 16),
          // Comparison Result
          _ComparisonResultCard(costState: costState),
        ] else ...[
          const SizedBox(height: 24),
          // Placeholder
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.darkCard.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 64,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter your total electricity bill',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white38),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'to see the contribution of this device',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white24),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// Comparison Result Card with Circular Progress
class _ComparisonResultCard extends StatefulWidget {
  final CostCalculationState costState;

  const _ComparisonResultCard({required this.costState});

  @override
  State<_ComparisonResultCard> createState() => _ComparisonResultCardState();
}

class _ComparisonResultCardState extends State<_ComparisonResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _updateAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _ComparisonResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.costState.contributionPercentage !=
        widget.costState.contributionPercentage) {
      _updateAnimation();
      _controller.forward(from: 0);
    }
  }

  void _updateAnimation() {
    final percentage = widget.costState.contributionPercentage ?? 0;
    _progressAnimation = Tween<double>(
      begin: 0,
      end: (percentage / 100).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.costState.contributionPercentage ?? 0;
    final deviceCost = widget.costState.result?.totalCostLKR ?? 0;
    final remaining = widget.costState.remainingBill ?? 0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Circular Progress
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(160, 160),
                      painter: _CircularProgressPainter(
                        progress: 1.0,
                        strokeWidth: 16,
                        backgroundColor: AppTheme.darkCard,
                      ),
                    ),
                    CustomPaint(
                      size: const Size(160, 160),
                      painter: _CircularProgressPainter(
                        progress: _progressAnimation.value,
                        strokeWidth: 16,
                        progressGradient: LinearGradient(
                          colors: [
                            _getProgressColor(percentage),
                            _getProgressColor(percentage).withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(percentage * _progressAnimation.value / (percentage > 0 ? percentage / 100 : 1)).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getProgressColor(percentage),
                              ),
                        ),
                        Text(
                          'of total bill',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Summary Rows
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Device Cost',
                  value: 'LKR ${deviceCost.toStringAsFixed(2)}',
                  color: AppTheme.successColor,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white12),
              Expanded(
                child: _SummaryItem(
                  label: 'Other Usage',
                  value: 'LKR ${remaining.toStringAsFixed(2)}',
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 10) return AppTheme.successColor;
    if (percentage < 25) return AppTheme.primaryColor;
    if (percentage < 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}

// Summary Item Widget
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Detail Row Widget
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Error Banner Widget
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.errorColor),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.errorColor),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// Circular Progress Painter
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color? backgroundColor;
  final Gradient? progressGradient;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    this.backgroundColor,
    this.progressGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    if (backgroundColor != null) {
      final bgPaint = Paint()
        ..color = backgroundColor!
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, bgPaint);
    }

    // Progress arc
    if (progressGradient != null && progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final progressPaint = Paint()
        ..shader = progressGradient!.createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        rect,
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
