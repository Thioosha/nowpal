import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';

class LaunchService {
  static const _channel = MethodChannel('com.example.nowpal/launch');

  static Future<Map<String, dynamic>?> getLaunchExtras() async {
    final result = await _channel.invokeMethod('getLaunchExtras');
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  static void listenForNewLaunch(
    void Function(Map<String, dynamic>) onNewLaunch,
  ) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewLaunchExtras') {
        onNewLaunch(Map<String, dynamic>.from(call.arguments));
      }
    });
  }

  static Future<bool> isAccessibilityEnabled() async {
    final result = await _channel.invokeMethod('isAccessibilityEnabled');
    return result == true;
  }

  static Future<void> openAccessibilitySettings() async {
    final intent = AndroidIntent(
      action: 'android.settings.ACCESSIBILITY_SETTINGS',
    );
    await intent.launch();
  }
}
