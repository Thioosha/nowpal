import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'screens/main_shell.dart';
import 'screens/active_session_screen.dart';
import 'providers/todo_provider.dart';
import 'providers/planned_session_provider.dart';
import 'widgets/overlay_widget.dart';
import 'services/notification_service.dart';
import 'services/launch_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await NotificationService.init(
    onNotificationTap: (payload) {
      if (payload == null || payload == 'headsup') return; // NEW guard
      final parts = payload.split('|');
      final focusMin = int.tryParse(parts[0]) ?? 25;
      final breakMin = int.tryParse(parts[1]) ?? 5;
      final strict = parts[2] == 'true';

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ActiveSessionScreen(
            focusMinutes: focusMin,
            breakMinutes: breakMin,
            strictMode: strict,
          ),
        ),
      );
    },
  );
  runApp(const NowPalApp());
}

@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: OverlayWidget()),
  );
}

class NowPalApp extends StatefulWidget {
  const NowPalApp({super.key});

  @override
  State<NowPalApp> createState() => _NowPalAppState();
}

class _NowPalAppState extends State<NowPalApp> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _init();
    LaunchService.listenForNewLaunch((extras) {
      _launchSession(extras);
    });
  }

  Future<void> _init() async {
    Map<String, dynamic>? extras;
    try {
      extras = await LaunchService.getLaunchExtras().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('⚠️ getLaunchExtras TIMED OUT');
          return null;
        },
      );
    } catch (e) {
      print('⚠️ getLaunchExtras ERROR: $e');
    }

    setState(() => _checked = true);

    if (extras != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _launchSession(extras!);
      });
    }
  }

  void _launchSession(Map<String, dynamic> extras) async {
    final result = await navigatorKey.currentState?.push<bool>(
      MaterialPageRoute(
        builder: (context) => ActiveSessionScreen(
          focusMinutes: extras['focusMinutes'],
          breakMinutes: extras['breakMinutes'],
          strictMode: true,
        ),
      ),
    );
    final sessionId = extras['sessionId'] as String?;
    if (result == true && sessionId != null && sessionId.isNotEmpty) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        Provider.of<PlannedSessionProvider>(
          ctx,
          listen: false,
        ).markCompleted(sessionId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => PlannedSessionProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'NowPal',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: !_checked
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : const MainShell(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const primary = Color(0xFF7C5CBF);
    const primaryLight = Color(0xFFEDE7F6);
    const white = Color(0xFFFFFFFF);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: Color(0xFFB39DDB),
        surface: white,
        background: Color(0xFFF8F5FF),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F5FF),
      fontFamily: 'Nunito',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF3D2B6B),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Color(0xFF3D2B6B)),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Color(0xFFEDE7F6), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: Color(0xFF7C5CBF), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEDE7F6), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEDE7F6), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF7C5CBF), width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: Color(0xFF7C5CBF),
        unselectedItemColor: Color(0xFFB0A0CC),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? primary
              : Colors.grey[300],
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? primaryLight
              : Colors.grey[200],
        ),
      ),
    );
  }
}
