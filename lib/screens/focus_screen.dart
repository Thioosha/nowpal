import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import 'active_session_screen.dart';
import '../models/planned_session.dart';
import '../providers/planned_session_provider.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/alarm_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  int _focusMinutes = 25;
  int _breakMinutes = 5;
  bool _strictMode = false;
  final List<int> _presets = [15, 25, 45, 60];

  void _startPlannedSession(PlannedSession session) async {
    context.read<PlannedSessionProvider>().deleteSession(session.id);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveSessionScreen(
          focusMinutes: session.durationMinutes,
          breakMinutes: 5,
          strictMode: session.strictMode,
        ),
      ),
    );
  }

  void _deletePlannedSession(PlannedSession session) async {
    final alarmId = session.id.hashCode;
    await NotificationService.cancelReminder(alarmId);
    await NotificationService.cancelReminder(alarmId + 1);
    if (mounted) {
      context.read<PlannedSessionProvider>().deleteSession(session.id);
    }
  }

  void _pickCustomDuration() async {
    final controller = TextEditingController(text: '$_focusMinutes');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Custom duration'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'minutes'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _focusMinutes = result);
    }
  }

  void _openPlanDialog({PlannedSession? existing}) async {
    DateTime selectedDate = existing?.dateTime ?? DateTime.now();
    TimeOfDay selectedTime = existing != null
        ? TimeOfDay(
            hour: existing.dateTime.hour,
            minute: existing.dateTime.minute,
          )
        : TimeOfDay.now();
    int duration = existing?.durationMinutes ?? 25;
    bool strict = existing?.strictMode ?? false;
    final presets = [15, 25, 45, 60];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(existing != null ? 'Edit session' : 'Plan a session'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // date picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF7C5CBF),
                      ),
                      title: Text(
                        DateFormat('EEE, MMM d').format(selectedDate),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                    // time picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF7C5CBF),
                      ),
                      title: Text(selectedTime.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ...presets.map(
                          (min) => _DurationChip(
                            label: '${min}m',
                            selected: duration == min,
                            onTap: () => setDialogState(() => duration = min),
                          ),
                        ),
                        _DurationChip(
                          label: presets.contains(duration)
                              ? 'Custom'
                              : '${duration}m',
                          selected: !presets.contains(duration),
                          onTap: () async {
                            final controller = TextEditingController(
                              text: '$duration',
                            );
                            final result = await showDialog<int>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text('Custom duration'),
                                content: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    suffixText: 'minutes',
                                  ),
                                  autofocus: true,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final value = int.tryParse(
                                        controller.text,
                                      );
                                      if (value != null && value > 0) {
                                        Navigator.pop(context, value);
                                      }
                                    },
                                    child: const Text('Set'),
                                  ),
                                ],
                              ),
                            );
                            if (result != null) {
                              setDialogState(() => duration = result);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Strict mode',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: strict,
                      onChanged: (v) => setDialogState(() => strict = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final dateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    final session = PlannedSession(
                      id:
                          existing?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      dateTime: dateTime,
                      durationMinutes: duration,
                      strictMode: strict,
                      completed: false,
                    );

                    if (existing != null) {
                      context.read<PlannedSessionProvider>().updateSession(
                        session,
                      );
                      await NotificationService.cancelReminder(
                        existing.id.hashCode,
                      );
                      await NotificationService.cancelReminder(
                        existing.id.hashCode + 1,
                      ); // NEW
                    } else {
                      context.read<PlannedSessionProvider>().addSession(
                        session,
                      );
                    }

                    final alarmId = session.id.hashCode;
                    final headsUpTime = dateTime.subtract(
                      const Duration(minutes: 5),
                    );

                    // 5-min heads up (only if it's still in the future)
                    if (headsUpTime.isAfter(DateTime.now())) {
                      await NotificationService.scheduleReminder(
                        id: alarmId + 1,
                        scheduledTime: headsUpTime,
                        title: 'Starting soon ⏰',
                        body: 'Your ${duration}min session starts in 5 minutes',
                        payload: 'headsup',
                      );
                    }

                    if (strict) {
                      await scheduleStrictAlarm(
                        id: alarmId,
                        scheduledTime: dateTime,
                        focusMinutes: duration,
                        breakMinutes: 5,
                        sessionId: session.id,
                      );
                    } else {
                      await NotificationService.scheduleReminder(
                        id: alarmId,
                        scheduledTime: dateTime,
                        title: 'Time to focus! 🎯',
                        body: 'Your $duration min session is starting now',
                        payload: '$duration|5|$strict|${session.id}',
                      );
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(existing != null ? 'Save changes' : 'Plan it'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveSessionScreen(
          focusMinutes: _focusMinutes,
          breakMinutes: _breakMinutes,
          strictMode: _strictMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTask = context.watch<TodoProvider>().currentTask;

    return Scaffold(
      appBar: AppBar(title: const Text('Focus')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            // Focus now card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: const Color(0xFF7C5CBF),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Focus now',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3D2B6B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (currentTask != null)
                      Text(
                        'Working on: ${currentTask.title}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 16),

                    // duration chips
                    Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._presets.map(
                          (min) => _DurationChip(
                            label: '${min}m',
                            selected: _focusMinutes == min,
                            onTap: () => setState(() => _focusMinutes = min),
                          ),
                        ),
                        _DurationChip(
                          label: _presets.contains(_focusMinutes)
                              ? 'Custom'
                              : '${_focusMinutes}m',
                          selected: !_presets.contains(_focusMinutes),
                          onTap: _pickCustomDuration,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // strict mode
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F5FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Strict mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Locked overlay if you leave the app',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        value: _strictMode,
                        onChanged: (v) => setState(() => _strictMode = v),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startSession,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start focusing'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Planned sessions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                GestureDetector(
                  onTap: _openPlanDialog,
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_rounded,
                        size: 16,
                        color: const Color(0xFF7C5CBF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Plan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7C5CBF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<PlannedSessionProvider>(
              builder: (context, provider, _) {
                final now = DateTime.now();
                final graceWindow = const Duration(minutes: 2);
                final upcoming = provider.sessions
                    .where(
                      (s) =>
                          !s.completed &&
                          s.dateTime.isAfter(now.subtract(graceWindow)),
                    )
                    .toList();
                final missed = provider.sessions
                    .where(
                      (s) =>
                          !s.completed &&
                          s.dateTime.isBefore(now.subtract(graceWindow)),
                    )
                    .toList();

                if (upcoming.isEmpty && missed.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8F5FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '📅',
                                  style: TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No sessions planned yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    ...upcoming.map(
                      (s) => _PlannedSessionCard(
                        session: s,
                        isMissed: false,
                        onStart: () => _startPlannedSession(s),
                        onEdit: () => _openPlanDialog(existing: s),
                        onDelete: () => _deletePlannedSession(s),
                      ),
                    ),
                    if (missed.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Missed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...missed.map(
                        (s) => _PlannedSessionCard(
                          session: s,
                          isMissed: true,
                          onStart: () => _startPlannedSession(s),
                          onEdit: () => _openPlanDialog(existing: s),
                          onDelete: () => _deletePlannedSession(s),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7C5CBF) : const Color(0xFFF8F5FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF7C5CBF),
          ),
        ),
      ),
    );
  }
}

class _PlannedSessionCard extends StatelessWidget {
  final PlannedSession session;
  final bool isMissed;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlannedSessionCard({
    required this.session,
    required this.isMissed,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isMissed ? Colors.grey[200] : const Color(0xFFF8F5FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMissed ? Icons.event_busy_rounded : Icons.event_rounded,
                  color: isMissed ? Colors.grey[400] : const Color(0xFF7C5CBF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE, MMM d • HH:mm').format(session.dateTime),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isMissed
                            ? Colors.grey[500]
                            : const Color(0xFF3D2B6B),
                        decoration: isMissed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      '${session.durationMinutes}min'
                      '${session.strictMode ? ' • Strict mode' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Color(0xFF7C5CBF),
                ),
                onPressed: onStart,
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: Colors.grey[400],
                ),
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.grey[400],
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
