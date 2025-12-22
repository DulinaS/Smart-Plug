import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/schedule.dart';
import '../../../core/utils/formatters.dart';
import '../../timer/application/timer_controller.dart';
import '../application/schedule_controller.dart';
import 'widgets/active_timer_banner.dart';
import 'widgets/schedule_editor_dialog.dart';

class SchedulesScreen extends ConsumerWidget {
  final String deviceId;
  const SchedulesScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleControllerProvider(deviceId));
    final timerState = ref.watch(deviceTimerControllerProvider(deviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(scheduleControllerProvider(deviceId).notifier)
            .loadSchedules(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // NEW: active timer banner
            ActiveTimerBanner(deviceId: deviceId),
            if (scheduleState.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (scheduleState.schedules.isEmpty)
              _buildEmptyState(context, ref)
            else
              ...scheduleState.schedules.map(
                (s) => _buildScheduleCard(context, ref, s),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleEditor(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No Schedules',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Create your first schedule to automate your device'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showScheduleEditor(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Schedule'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(
    BuildContext context,
    WidgetRef ref,
    Schedule schedule,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getScheduleDescription(schedule),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: schedule.isEnabled,
                  onChanged: (value) {
                    ref
                        .read(scheduleControllerProvider(deviceId).notifier)
                        .toggleSchedule(schedule.id, value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  schedule.action == ScheduleAction.turnOn
                      ? Icons.power
                      : Icons.power_off,
                  color: schedule.action == ScheduleAction.turnOn
                      ? Colors.green
                      : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  schedule.action == ScheduleAction.turnOn
                      ? 'Turn ON'
                      : 'Turn OFF',
                  style: TextStyle(
                    color: schedule.action == ScheduleAction.turnOn
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'at ${schedule.startTime}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            if (schedule.weekdays.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: schedule.weekdays.map((day) {
                  return Chip(
                    label: Text(_getWeekdayShort(day)),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    labelStyle: const TextStyle(fontSize: 12),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showScheduleEditor(context, ref, schedule),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showDeleteDialog(context, ref, schedule),
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getScheduleDescription(Schedule schedule) {
    if (schedule.type == ScheduleType.once) {
      return 'One time only';
    } else if (schedule.type == ScheduleType.daily) {
      return 'Every day';
    } else if (schedule.weekdays.length == 7) {
      return 'Every day';
    } else if (schedule.weekdays.length == 5 &&
        !schedule.weekdays.contains(Weekday.saturday) &&
        !schedule.weekdays.contains(Weekday.sunday)) {
      return 'Weekdays only';
    } else if (schedule.weekdays.length == 2 &&
        schedule.weekdays.contains(Weekday.saturday) &&
        schedule.weekdays.contains(Weekday.sunday)) {
      return 'Weekends only';
    } else {
      return 'Custom days';
    }
  }

  String _getWeekdayShort(Weekday day) {
    switch (day) {
      case Weekday.monday:
        return 'Mon';
      case Weekday.tuesday:
        return 'Tue';
      case Weekday.wednesday:
        return 'Wed';
      case Weekday.thursday:
        return 'Thu';
      case Weekday.friday:
        return 'Fri';
      case Weekday.saturday:
        return 'Sat';
      case Weekday.sunday:
        return 'Sun';
    }
  }

  void _showScheduleEditor(
    BuildContext context,
    WidgetRef ref, [
    Schedule? schedule,
  ]) {
    showDialog(
      context: context,
      builder: (context) => ScheduleEditorDialog(
        deviceId: deviceId,
        schedule: schedule,
        onSave: (newSchedule) {
          if (schedule == null) {
            ref
                .read(scheduleControllerProvider(deviceId).notifier)
                .createSchedule(newSchedule);
          } else {
            ref
                .read(scheduleControllerProvider(deviceId).notifier)
                .updateSchedule(newSchedule);
          }
        },
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Schedule schedule,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Are you sure you want to delete "${schedule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(scheduleControllerProvider(deviceId).notifier)
                  .deleteSchedule(schedule.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Schedules'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedules allow you to automatically turn your device ON or OFF at specific times.',
            ),
            SizedBox(height: 12),
            Text('Features:'),
            Text('• Set daily or weekly recurring schedules'),
            Text('• Choose specific weekdays'),
            Text('• Enable/disable schedules anytime'),
            Text('• Multiple schedules per device'),
            SizedBox(height: 12),
            Text('Note: Device must be online for schedules to work.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
