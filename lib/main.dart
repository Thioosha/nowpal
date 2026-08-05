import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_shell.dart';
import 'providers/todo_provider.dart';
import 'widgets/overlay_widget.dart';

void main() {
  runApp(const NowPalApp());
}

@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: OverlayWidget()),
  );
}

class NowPalApp extends StatelessWidget {
  const NowPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoProvider(),
      child: MaterialApp(
        title: 'NowPal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
        home: const MainShell(),
      ),
    );
  }
}
