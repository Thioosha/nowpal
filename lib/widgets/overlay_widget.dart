import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:android_intent_plus/android_intent.dart';

class OverlayWidget extends StatelessWidget {
  const OverlayWidget({super.key});

  Future<void> _returnToApp() async {
    final intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      category: 'android.intent.category.LAUNCHER',
      package: 'com.example.nowpal',
      componentName: 'com.example.nowpal.MainActivity',
      flags: [268435456, 67108864],
    );
    await intent.launch();
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Get back to focus!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _returnToApp,
              child: const Text('Back to NowPal'),
            ),
          ],
        ),
      ),
    );
  }
}
