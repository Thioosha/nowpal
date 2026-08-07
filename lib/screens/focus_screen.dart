import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import 'active_session_screen.dart';

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
            Text(
              'Planned sessions',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Card(
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
                          child: Text('📅', style: TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No sessions planned yet',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
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
