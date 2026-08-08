import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:android_intent_plus/android_intent.dart';

@pragma('vm:entry-point')
void strictSessionAlarmCallback(int id, Map<String, dynamic> params) async {
  final focusMinutes = params['focusMinutes'] as int;
  final breakMinutes = params['breakMinutes'] as int;

  final intent = AndroidIntent(
    action: 'action_main',
    package: 'com.example.nowpal',
    componentName: 'com.example.nowpal.MainActivity',
    arguments: {
      'launchStrictSession': true,
      'focusMinutes': focusMinutes,
      'breakMinutes': breakMinutes,
    },
    flags: [
      268435456,
      67108864,
      65536,
    ], // NEW_TASK + CLEAR_TOP + FROM_BACKGROUND
  );
  await intent.launch();
}

Future<void> scheduleStrictAlarm({
  required int id,
  required DateTime scheduledTime,
  required int focusMinutes,
  required int breakMinutes,
}) async {
  await AndroidAlarmManager.oneShotAt(
    scheduledTime,
    id,
    strictSessionAlarmCallback,
    exact: true,
    wakeup: true,
    params: {'focusMinutes': focusMinutes, 'breakMinutes': breakMinutes},
  );
}
