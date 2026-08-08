import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../providers/todo_provider.dart';

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

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.focusMinutes * 60;
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionIfNeeded();
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
          if (!_isBreak) _secondsFocused++; // NEW
        });
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
      sessionsRaw.add('$today|$minutesFocused');
      await prefs.setStringList('focus_sessions', sessionsRaw);
      _secondsFocused = 0; // reset after logging
    }

    setState(() {
      _isBreak = !_isBreak;
      _secondsLeft = _isBreak
          ? widget.breakMinutes * 60
          : widget.focusMinutes * 60;
    });
    _startTimer();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _endSession() async {
    _timer?.cancel();

    if (_secondsFocused > 0 && !_isBreak) {
      final prefs = await SharedPreferences.getInstance();
      final sessionsRaw = prefs.getStringList('focus_sessions') ?? [];
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final minutesFocused = (_secondsFocused / 60).round();
      sessionsRaw.add('$today|$minutesFocused');
      await prefs.setStringList('focus_sessions', sessionsRaw);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF3D2B6B),
                    onPressed: (!widget.strictMode || _isBreak)
                        ? _endSession
                        : null,
                  ),
                ),
                const Spacer(),
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
                  const SizedBox(height: 24),
                ],
                Text(
                  _isBreak ? 'Break time 🌿' : 'Focus time 🎯',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C5CBF),
                  ),
                ),
                const SizedBox(height: 16),
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
        ),
      ),
    );
  }
}
