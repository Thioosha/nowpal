import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../providers/todo_provider.dart';
import 'package:android_intent_plus/android_intent.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  int _focusMinutes = 25;
  int _breakMinutes = 5;

  int _secondsLeft = 10;
  bool _isRunning = false;
  bool _isBreak = false;
  bool _strictMode = false;

  Timer? _timer;
  StreamSubscription? _overlaySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToOverlay();
  }

  void _listenToOverlay() {
    try {
      _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((
        event,
      ) async {
        debugPrint('OVERLAY EVENT RECEIVED: $event');
        if (event == "return_to_app") {
          debugPrint('LAUNCHING INTENT...');
          final intent = AndroidIntent(
            action: 'action_main',
            category: 'category_launcher',
            package: 'com.example.nowpal',
            flags: [268435456, 67108864],
          );
          await intent.launch();
          debugPrint('INTENT LAUNCHED');
        }
      });
    } catch (e) {
      debugPrint('Overlay listener already active: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    debugPrint(
      'LIFECYCLE STATE: $state | strict: $_strictMode | running: $_isRunning | break: $_isBreak',
    );

    if (state == AppLifecycleState.paused &&
        _strictMode &&
        _isRunning &&
        !_isBreak) {
      // pause the timer itself, not just the countdown display
      _timer?.cancel();

      final permitted = await FlutterOverlayWindow.isPermissionGranted();
      debugPrint('OVERLAY PERMISSION GRANTED: $permitted');
      try {
        await FlutterOverlayWindow.showOverlay(
          height: WindowSize.matchParent,
          width: WindowSize.matchParent,
          alignment: OverlayAlignment.center,
          flag: OverlayFlag.focusPointer,
          enableDrag: false,
        );
        debugPrint('SHOW OVERLAY CALLED — no error thrown');
      } catch (e) {
        debugPrint('SHOW OVERLAY ERROR: $e');
      }
    }

    if (state == AppLifecycleState.resumed &&
        _strictMode &&
        _isRunning &&
        !_isBreak) {
      // user came back — resume the countdown
      _startTimer();
    }
  }

  Future<bool> _requestOverlayPermission() async {
    final status = await FlutterOverlayWindow.isPermissionGranted();
    if (!status) {
      final granted = await FlutterOverlayWindow.requestPermission();
      return granted ?? false;
    }
    return true;
  }

  void _toggleStrictMode(bool value) async {
    if (value) {
      final granted = await _requestOverlayPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Overlay permission needed for strict mode'),
            ),
          );
        }
        return;
      }
    }
    setState(() => _strictMode = value);
  }

  void _startTimer() {
    _timer
        ?.cancel(); // NEW — prevent double timers if called while one's active
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
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

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _secondsLeft = _focusMinutes * 60;
    });
  }

  void _switchMode() async {
    _timer?.cancel();

    if (!_isBreak) {
      final prefs = await SharedPreferences.getInstance();
      final sessionsRaw = prefs.getStringList('focus_sessions') ?? [];
      final today = DateTime.now().toIso8601String().substring(0, 10);
      sessionsRaw.add('$today|$_focusMinutes');
      await prefs.setStringList('focus_sessions', sessionsRaw);
    }

    setState(() {
      _isBreak = !_isBreak;
      _secondsLeft = _isBreak ? _breakMinutes * 60 : _focusMinutes * 60;
    });
    _startTimer();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlaySubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTask = context.watch<TodoProvider>().currentTask;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (currentTask != null) ...[
                Text(
                  'Working on:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  currentTask.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              Text(
                _isBreak ? 'Break time 🌿' : 'Focus time 🎯',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _formatTime(_secondsLeft),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    child: Text(_isRunning ? 'Pause' : 'Start'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: _resetTimer,
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Strict mode'),
                subtitle: const Text(
                  'Overlay warning if you leave during focus',
                ),
                value: _strictMode,
                onChanged: _toggleStrictMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
