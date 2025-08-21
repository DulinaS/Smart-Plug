/* import 'package:flutter/material.dart';
import '../../../../data/models/schedule.dart';

class ScheduleEditorDialog extends StatefulWidget {
  final String deviceId;
  final Schedule? schedule;
  final Function(Schedule) onSave;

  const ScheduleEditorDialog({
    super.key,
    required this.deviceId,
    this.schedule,
    required this.onSave,
  });

  @override
  State<ScheduleEditorDialog> createState() => _ScheduleEditorDialogState();
}

class _ScheduleEditorDialogState extends State<ScheduleEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  
  late ScheduleType _selectedType;
  late ScheduleAction _selectedAction;
  late TimeOfDay _startTime; // Flutter's TimeOfDay for UI
  TimeOfDay? _endTime;       // Flutter's TimeOfDay for UI
  late Set<Weekday> _selectedWeekdays;
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    
    if (widget.schedule != null) {
      // Editing existing schedule
      final schedule = widget.schedule!;
      _nameController = TextEditingController(text: schedule.name);
      _selectedType = schedule.type;
      _selectedAction = schedule.action;
      _startTime = schedule.startTime.toTimeOfDay(); // Convert to Flutter's TimeOfDay
      _endTime = schedule.endTime?.toTimeOfDay();     // Convert to Flutter's TimeOfDay
      _selectedWeekdays = Set.from(schedule.weekdays);
      _isEnabled = schedule.isEnabled;
    } else {
      // Creating new schedule
      _nameController = TextEditingController();
      _selectedType = ScheduleType.daily;
      _selectedAction = ScheduleAction.turnOn;
      _startTime = const TimeOfDay(hour: 7, minute: 0);
      _endTime = null;
      _selectedWeekdays = {
        Weekday.monday,
        Weekday.tuesday,
        Weekday.wednesday,
        Weekday.thursday,
        Weekday.friday,
      };
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.schedule != null ? 'Edit Schedule' : 'Create Schedule'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Schedule Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Schedule Name',
                    hintText: 'e.g., Morning ON',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a schedule name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Action Selection
                Text(
                  'Action',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<ScheduleAction>(
                        title: const Text('Turn ON'),
                        value: ScheduleAction.turnOn,
                        groupValue: _selectedAction,
                        onChanged: (value) => setState(() => _selectedAction = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<ScheduleAction>(
                        title: const Text('Turn OFF'),
                        value: ScheduleAction.turnOff,
                        groupValue: _selectedAction,
                        onChanged: (value) => setState(() => _selectedAction = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Time Selection
                Text(
                  'Time',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('Start Time: ${_startTime.format(context)}'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _selectTime(context, true),
                ),

                // Schedule Type
                const SizedBox(height: 16),
                Text(
                  'Repeat',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ScheduleType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: ScheduleType.once, child: Text('Once')),
                    DropdownMenuItem(value: ScheduleType.daily, child: Text('Daily')),
                    DropdownMenuItem(value: ScheduleType.weekly, child: Text('Weekly')),
                  ],
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),

                // Weekday Selection (for weekly/custom)
                if (_selectedType == ScheduleType.weekly) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Days',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: Weekday.values.map((day) {
                      final isSelected = _selectedWeekdays.contains(day);
                      return FilterChip(
                        label: Text(_getWeekdayShort(day)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedWeekdays.add(day);
                            } else {
                              _selectedWeekdays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // Enable/Disable
                SwitchListTile(
                  title: const Text('Enable Schedule'),
                  subtitle: const Text('Schedule will run automatically when enabled'),
                  value: _isEnabled,
                  onChanged: (value) => setState(() => _isEnabled = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSchedule,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : (_endTime ?? _startTime),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveSchedule() {
    if (_formKey.currentState!.validate()) {
      if (_selectedType != ScheduleType.once && _selectedWeekdays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one day')),
        );
        return;
      }

      final schedule = Schedule(
        id: widget.schedule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: widget.deviceId,
        name: _nameController.text.trim(),
        type: _selectedType,
        startTime: ScheduleTime.fromTimeOfDay(_startTime), // Convert to your ScheduleTime
        endTime: _endTime != null ? ScheduleTime.fromTimeOfDay(_endTime!) : null, // Convert to your ScheduleTime
        weekdays: _selectedWeekdays.toList(),
        action: _selectedAction,
        isEnabled: _isEnabled,
        createdAt: widget.schedule?.createdAt ?? DateTime.now(),
      );

      widget.onSave(schedule);
      Navigator.of(context).pop();
    }
  }

  String _getWeekdayShort(Weekday day) {
    switch (day) {
      case Weekday.monday: return 'Mon';
      case Weekday.tuesday: return 'Tue';
      case Weekday.wednesday: return 'Wed';
      case Weekday.thursday: return 'Thu';
      case Weekday.friday: return 'Fri';
      case Weekday.saturday: return 'Sat';
      case Weekday.sunday: return 'Sun';
    }
  }
} */
import 'package:flutter/material.dart';
import '../../../../data/models/schedule.dart';

class ScheduleEditorDialog extends StatefulWidget {
  final String deviceId;
  final Schedule? schedule; // null for new schedule
  final Function(Schedule) onSave;

  const ScheduleEditorDialog({
    super.key,
    required this.deviceId,
    this.schedule,
    required this.onSave,
  });

  @override
  State<ScheduleEditorDialog> createState() => _ScheduleEditorDialogState();
}

class _ScheduleEditorDialogState extends State<ScheduleEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  late ScheduleType _selectedType;
  late ScheduleAction _selectedAction;
  late TimeOfDay _startTime; // Flutter's TimeOfDay for UI
  TimeOfDay? _endTime; // Flutter's TimeOfDay for UI
  late Set<Weekday> _selectedWeekdays;
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();

    if (widget.schedule != null) {
      // Editing existing schedule
      final schedule = widget.schedule!;
      _nameController = TextEditingController(text: schedule.name);
      _selectedType = schedule.type;
      _selectedAction = schedule.action;
      _startTime = schedule.startTime
          .toTimeOfDay(); // Convert to Flutter's TimeOfDay
      _endTime = schedule.endTime
          ?.toTimeOfDay(); // Convert to Flutter's TimeOfDay
      _selectedWeekdays = Set.from(schedule.weekdays);
      _isEnabled = schedule.isEnabled;
    } else {
      // Creating new schedule
      _nameController = TextEditingController();
      _selectedType = ScheduleType.daily;
      _selectedAction = ScheduleAction.turnOn;
      _startTime = const TimeOfDay(hour: 7, minute: 0);
      _endTime = null;
      _selectedWeekdays = {
        Weekday.monday,
        Weekday.tuesday,
        Weekday.wednesday,
        Weekday.thursday,
        Weekday.friday,
      };
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.schedule != null ? 'Edit Schedule' : 'Create Schedule',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Schedule Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Schedule Name',
                    hintText: 'e.g., Morning ON',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a schedule name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Action Selection
                Text(
                  'Action',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<ScheduleAction>(
                        title: const Text('Turn ON'),
                        value: ScheduleAction.turnOn,
                        groupValue: _selectedAction,
                        onChanged: (value) =>
                            setState(() => _selectedAction = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<ScheduleAction>(
                        title: const Text('Turn OFF'),
                        value: ScheduleAction.turnOff,
                        groupValue: _selectedAction,
                        onChanged: (value) =>
                            setState(() => _selectedAction = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Time Selection
                Text(
                  'Time',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text('Start Time: ${_startTime.format(context)}'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _selectTime(context, true),
                ),

                // Schedule Type
                const SizedBox(height: 16),
                Text(
                  'Repeat',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ScheduleType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ScheduleType.once,
                      child: Text('Once'),
                    ),
                    DropdownMenuItem(
                      value: ScheduleType.daily,
                      child: Text('Daily'),
                    ),
                    DropdownMenuItem(
                      value: ScheduleType.weekly,
                      child: Text('Weekly'),
                    ),
                    DropdownMenuItem(
                      value: ScheduleType.custom,
                      child: Text('Custom'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),

                // Weekday Selection (for weekly/custom)
                if (_selectedType == ScheduleType.weekly ||
                    _selectedType == ScheduleType.custom) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Days',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: Weekday.values.map((day) {
                      final isSelected = _selectedWeekdays.contains(day);
                      return FilterChip(
                        label: Text(_getWeekdayShort(day)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedWeekdays.add(day);
                            } else {
                              _selectedWeekdays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // Enable/Disable
                SwitchListTile(
                  title: const Text('Enable Schedule'),
                  subtitle: const Text(
                    'Schedule will run automatically when enabled',
                  ),
                  value: _isEnabled,
                  onChanged: (value) => setState(() => _isEnabled = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveSchedule, child: const Text('Save')),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : (_endTime ?? _startTime),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveSchedule() {
    if (_formKey.currentState!.validate()) {
      if (_selectedType != ScheduleType.once && _selectedWeekdays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one day')),
        );
        return;
      }

      final schedule = Schedule(
        id:
            widget.schedule?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: widget.deviceId,
        name: _nameController.text.trim(),
        type: _selectedType,
        startTime: ScheduleTime.fromTimeOfDay(
          _startTime,
        ), // Convert to ScheduleTime
        endTime: _endTime != null
            ? ScheduleTime.fromTimeOfDay(_endTime!)
            : null, // Convert to ScheduleTime
        weekdays: _selectedWeekdays.toList(),
        action: _selectedAction,
        isEnabled: _isEnabled,
        createdAt: widget.schedule?.createdAt ?? DateTime.now(),
      );

      widget.onSave(schedule);
      Navigator.of(context).pop();
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
}
