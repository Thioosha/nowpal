import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../providers/todo_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';

class ActiveSessionScreen extends StatefulWidget {
  final int focusMinutes;
  final int breakMinutes;
  final bool strictMode;

  const ActiveSessionScreen({
    super.key,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.strictMode,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with WidgetsBindingObserver {
  late int _secondsLeft;
  int _secondsFocused = 0;
  bool _isRunning = false;
  bool _isBreak = false;
  bool _focusCompletedNaturally = false;

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _selectedSound;

  final Map<String, String> _sounds = {
    'Rain': 'audio/rain.mp3',
    'Fireplace': 'audio/fireplace.mp3',
    'Ocean': 'audio/ocean.mp3',
    'Piano': 'audio/piano.mp3',
  };

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.focusMinutes * 60;
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionIfNeeded();
    if (widget.strictMode) _setStrictActive(true); // NEW
  }

  Future<void> _requestPermissionIfNeeded() async {
    if (widget.strictMode) {
      final granted = await FlutterOverlayWindow.isPermissionGranted();
      if (!granted) {
        await FlutterOverlayWindow.requestPermission();
      }
    }
    _startTimer();
  }

  Future<void> _setStrictActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('strict_session_active', active);
  }

  Future<void> _playSound(String assetPath) async {
    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource(assetPath));
  }

  Future<void> _stopSound() async {
    await _audioPlayer.stop();
    setState(() => _selectedSound = null);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused && widget.strictMode && !_isBreak) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      try {
        await FlutterOverlayWindow.showOverlay(
          height: WindowSize.matchParent,
          width: WindowSize.matchParent,
          alignment: OverlayAlignment.center,
          flag: OverlayFlag.focusPointer,
          enableDrag: false,
        );
      } catch (_) {}
    }

    if (state == AppLifecycleState.resumed &&
        widget.strictMode &&
        !_isBreak &&
        !_isRunning) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
          if (!_isBreak) _secondsFocused++;
        });
        if (_secondsLeft == 3) {
          _sfxPlayer.play(AssetSource('audio/countdown.mp3'));
        }
      } else {
        _switchMode();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _switchMode() async {
    _timer?.cancel();

    if (!_isBreak) {
      final prefs = await SharedPreferences.getInstance();
      final sessionsRaw = prefs.getStringList('focus_sessions') ?? [];
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final minutesFocused = (_secondsFocused / 60).round();
      sessionsRaw.add('$today|$minutesFocused|true'); // natural completion
      await prefs.setStringList('focus_sessions', sessionsRaw);
      _secondsFocused = 0;
      _focusCompletedNaturally = true;
    }

    setState(() {
      _isBreak = !_isBreak;
      _secondsLeft = _isBreak
          ? widget.breakMinutes * 60
          : widget.focusMinutes * 60;
    });
    if (_isBreak)
      await _setStrictActive(false); // NEW — safe to leave during break
    if (!_isBreak)
      await _setStrictActive(true); // NEW — back to strict when focus resumes
    _startTimer();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _endSession() async {
    _timer?.cancel();
    await _setStrictActive(false);

    if (_secondsFocused > 0 && !_isBreak) {
      final prefs = await SharedPreferences.getInstance();
      final sessionsRaw = prefs.getStringList('focus_sessions') ?? [];
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final minutesFocused = (_secondsFocused / 60).round();
      sessionsRaw.add('$today|$minutesFocused|false'); // interrupted
      await prefs.setStringList('focus_sessions', sessionsRaw);
    }

    if (mounted) Navigator.pop(context, _focusCompletedNaturally);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _audioPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTask = context.watch<TodoProvider>().currentTask;

    return PopScope(
      canPop: !widget.strictMode || _isBreak,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F5FF),
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: const Color(0xFF3D2B6B),
                          onPressed: (!widget.strictMode || _isBreak)
                              ? _endSession
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.checklist_rounded),
                          color: const Color(0xFF3D2B6B),
                          onPressed: _openTodoSheet,
                        ),
                      ],
                    ),
                    const Spacer(),

                    Text(
                      _isBreak ? 'Break time 🌿' : 'Focus time 🎯',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C5CBF),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 190,
                      child: Lottie.asset(
                        _isBreak
                            ? 'assets/lottie/bear_resting.json'
                            : 'assets/lottie/bear_studying.json',
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 12),
                    if (currentTask != null) ...[
                      Text(
                        'Working on',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentTask.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3D2B6B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                    ],

                    const SizedBox(height: 12),
                    Text(
                      _formatTime(_secondsLeft),
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3D2B6B),
                      ),
                    ),

                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isRunning ? _pauseTimer : _startTimer,
                          icon: Icon(
                            _isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(_isRunning ? 'Pause' : 'Resume'),
                        ),
                      ],
                    ),
                    if (widget.strictMode && !_isBreak) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Strict mode is on — finish the session to exit',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedSound != null
                          ? const Color(0xFF7C5CBF)
                          : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C5CBF).withOpacity(0.15),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: _selectedSound != null
                          ? Colors.white
                          : const Color(0xFF7C5CBF),
                      size: 20,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  offset: const Offset(0, -180),
                  itemBuilder: (context) => [
                    ..._sounds.entries.map((entry) {
                      final isSelected = _selectedSound == entry.key;
                      return PopupMenuItem<String>(
                        value: entry.key,
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 18,
                              color: isSelected
                                  ? const Color(0xFF7C5CBF)
                                  : Colors.grey[400],
                            ),
                            const SizedBox(width: 10),
                            Text(entry.key),
                          ],
                        ),
                      );
                    }),
                    if (_selectedSound != null)
                      const PopupMenuItem<String>(
                        value: '__stop__',
                        child: Row(
                          children: [
                            Icon(
                              Icons.stop_circle_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            SizedBox(width: 10),
                            Text('Stop sound'),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    if (value == '__stop__') {
                      _stopSound();
                    } else {
                      setState(() => _selectedSound = value);
                      _playSound(_sounds[value]!);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTodoSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, // NEW — lets sheet resize with keyboard
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(
              context,
            ).viewInsets.bottom, // NEW — avoids keyboard overlap
          ),
          child: Consumer<TodoProvider>(
            builder: (context, todoProvider, _) {
              final pending = todoProvider.todos
                  .where((t) => !t.isDone)
                  .toList();
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your tasks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D2B6B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: 'Add a task...',
                              isDense: true,
                            ),
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                todoProvider.addTodo(value.trim());
                                controller.clear();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_rounded,
                            color: Color(0xFF7C5CBF),
                          ),
                          onPressed: () {
                            if (controller.text.trim().isNotEmpty) {
                              todoProvider.addTodo(controller.text.trim());
                              controller.clear();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (pending.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No pending tasks 🎉',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: ReorderableListView(
                          shrinkWrap: true,
                          proxyDecorator: (child, index, animation) {
                            return Material(
                              color: Colors.transparent,
                              child: child,
                            );
                          },
                          onReorder: (oldIndex, newIndex) {
                            final ids = pending.map((t) => t.id).toList();
                            todoProvider.reorderTodos(oldIndex, newIndex, ids);
                          },
                          children: pending.map((todo) {
                            final isCurrent =
                                todoProvider.currentTask?.id == todo.id;
                            return ListTile(
                              key: ValueKey(
                                todo.id,
                              ), // required for ReorderableListView
                              contentPadding: EdgeInsets.zero,
                              leading: GestureDetector(
                                onTap: () => todoProvider.toggleDone(todo.id),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFB0A0CC),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                todo.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isCurrent
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: isCurrent
                                      ? Colors.amber
                                      : Colors.grey[400],
                                ),
                                onPressed: () => todoProvider.setCurrentTask(
                                  isCurrent ? null : todo.id,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
