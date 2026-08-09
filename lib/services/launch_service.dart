import 'package:flutter/services.dart';

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
}
