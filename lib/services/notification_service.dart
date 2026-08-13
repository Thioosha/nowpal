import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init({
    required void Function(String? payload) onNotificationTap,
  }) async {
    tzdata.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('ic_notification');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap(response.payload);
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleReminder({
    required int id,
    required DateTime scheduledTime,
    required String title,
    required String body,
    required String payload, // NEW
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
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
        payload: payload, // NEW
      );
    } catch (e) {
      print('NOTIFICATION SCHEDULE ERROR: $e');
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
