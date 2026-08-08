import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    print('🎤 LOCAL TIMEZONE: ${tz.local}');

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final notifGranted = await androidPlugin.requestNotificationsPermission();
      print('❤️ NOTIFICATION PERMISSION GRANTED: $notifGranted');
      final exactGranted = await androidPlugin.requestExactAlarmsPermission();
      print('🤍 EXACT ALARM PERMISSION GRANTED: $exactGranted');
    }
  }

  static Future<void> scheduleReminder({
    required int id,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    print('📆SCHEDULING FOR: $tzTime | TZ NOW: ${tz.TZDateTime.now(tz.local)}');

    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) {
      print('⚠️ WARNING: scheduled time is in the PAST relative to tz.now()');
    }

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'session_reminders',
            'Session Reminders',
            channelDescription: 'Reminders for planned focus sessions',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('✨NOTIFICATION SCHEDULED SUCCESSFULLY');
    } catch (e) {
      print('😔NOTIFICATION SCHEDULE ERROR: $e');
    }
  }

  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> showTestNotification() async {
    await _plugin.show(
      999,
      '📆Test notification',
      '❤️If you see this, notifications work',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'session_reminders',
          'Session Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
