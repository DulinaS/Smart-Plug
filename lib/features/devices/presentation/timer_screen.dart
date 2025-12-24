import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

enum TimerAction { turnOff, turnOn }

class TimerScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final String deviceName;

  const TimerScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  Timer? _countdownTimer;
  Duration _selectedDuration = const Duration(minutes: 30);
  Duration? _remainingTime;
  bool _isActive = false;
  TimerAction _selectedAction = TimerAction.turnOff;

  final List<Duration> _quickTimes = [
    const Duration(minutes: 15),
    const Duration(minutes: 30),
    const Duration(hours: 1),
    const Duration(hours: 2),
    const Duration(hours: 4),
    const Duration(hours: 8),
  ];

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Timer - ${widget.deviceName}'),
        actions: [
          if (_isActive)
            IconButton(icon: const Icon(Icons.stop), onPressed: _cancelTimer),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timer Display
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Text(
                      _isActive ? 'Timer Active' : 'Set Timer',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timer Display
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isActive ? Colors.red : Colors.blue,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatDuration(
                                _isActive ? _remainingTime! : _selectedDuration,
                              ),
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _isActive ? Colors.red : Colors.blue,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isActive ? 'Remaining' : 'Duration',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedAction == TimerAction.turnOff
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedAction == TimerAction.turnOff
                                ? Icons.power_off
                                : Icons.power,
                            color: _selectedAction == TimerAction.turnOff
                                ? Colors.red
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Will ${_selectedAction == TimerAction.turnOff ? 'turn OFF' : 'turn ON'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedAction == TimerAction.turnOff
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (!_isActive) ...[
              // Action Selection
              Text(
                'Action',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'Turn OFF',
                      Icons.power_off,
                      Colors.red,
                      TimerAction.turnOff,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      'Turn ON',
                      Icons.power,
                      Colors.green,
                      TimerAction.turnOn,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Times
              Text(
                'Quick Times',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickTimes.map((duration) {
                  final isSelected = _selectedDuration == duration;
                  return FilterChip(
                    label: Text(_formatDuration(duration)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedDuration = duration);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Custom Time
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Time',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeInput(
                              'Hours',
                              _selectedDuration.inHours,
                              23,
                              (value) {
                                setState(() {
                                  _selectedDuration = Duration(
                                    hours: value,
                                    minutes: _selectedDuration.inMinutes % 60,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimeInput(
                              'Minutes',
                              _selectedDuration.inMinutes % 60,
                              59,
                              (value) {
                                setState(() {
                                  _selectedDuration = Duration(
                                    hours: _selectedDuration.inHours,
                                    minutes: value,
                                  );
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Start Timer Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedDuration.inMinutes > 0
                      ? _startTimer
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Start Timer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Active Timer Controls
              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelTimer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Cancel Timer'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addTime,
                      child: const Text('Add 15 min'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    TimerAction action,
  ) {
    final isSelected = _selectedAction == action;

    return Card(
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => setState(() => _selectedAction = action),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInput(
    String label,
    int value,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: value,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: List.generate(max + 1, (index) {
            return DropdownMenuItem(
              value: index,
              child: Text(index.toString().padLeft(2, '0')),
            );
          }),
          onChanged: (newValue) => onChanged(newValue ?? 0),
        ),
      ],
    );
  }

  void _startTimer() {
    setState(() {
      _isActive = true;
      _remainingTime = _selectedDuration;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime = _remainingTime! - const Duration(seconds: 1);

        if (_remainingTime!.inSeconds <= 0) {
          _executeTimerAction();
          _cancelTimer();
        }
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Timer started! Will ${_selectedAction == TimerAction.turnOff ? 'turn OFF' : 'turn ON'} in ${_formatDuration(_selectedDuration)}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isActive = false;
      _remainingTime = null;
    });
  }

  void _addTime() {
    setState(() {
      _remainingTime = _remainingTime! + const Duration(minutes: 15);
    });
  }

  void _executeTimerAction() {
    // TODO: Execute the timer action (turn device ON/OFF)
    final actionText = _selectedAction == TimerAction.turnOff
        ? 'turned OFF'
        : 'turned ON';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Device $actionText!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData image;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}
