import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/todo_provider.dart';
import '../providers/planned_session_provider.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onSwitchTab;

  const HomeScreen({super.key, required this.onSwitchTab});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String? _todayMood;
  bool _isLoading = true;
  int _streak = 0;
  int _todayFocusMinutes = 0;
  int _todaySessionCount = 0;
  final List<String> _moods = ['😔', '😐', '🙂', '😄', '🔥'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // mood
    final savedDate = prefs.getString('mood_date');
    String? mood;
    if (savedDate == today) mood = prefs.getString('mood_value');

    // streak
    final moodHistory = prefs.getStringList('mood_history') ?? [];
    int streak = 0;
    DateTime check = DateTime.now();
    for (int i = moodHistory.length - 1; i >= 0; i--) {
      final date = moodHistory[i].split('|')[0];
      final expected = check.toIso8601String().substring(0, 10);
      if (date == expected) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // today's focus
    final sessions = prefs.getStringList('focus_sessions') ?? [];
    int totalMin = 0;
    int sessionCount = 0;
    for (final s in sessions) {
      final parts = s.split('|');
      if (parts[0] == today) {
        totalMin += int.tryParse(parts[1]) ?? 0;
        if (parts.length > 2 && parts[2] == 'true') {
          sessionCount++;
        }
      }
    }

    setState(() {
      _todayMood = mood;
      _streak = streak;
      _todayFocusMinutes = totalMin;
      _todaySessionCount = sessionCount;
      _isLoading = false;
    });
  }

  Future<void> loadData() => _loadData();

  Future<void> _saveMood(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('mood_date', today);
    await prefs.setString('mood_value', mood);
    final historyRaw = prefs.getStringList('mood_history') ?? [];
    historyRaw.add('$today|$mood');
    await prefs.setStringList('mood_history', historyRaw);
    setState(() => _todayMood = mood);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 18) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final todos = context.watch<TodoProvider>().todos;
    final pendingTodos = todos.where((t) => !t.isDone).toList();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // greeting + bear
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 26, // was 22
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D2B6B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _streak > 0
                              ? '$_streak day streak 🔥'
                              : 'Start your streak today!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BearWidget(),
                ],
              ),
              const SizedBox(height: 20),

              // mood card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 16,
                            color: Color(0xFF7C5CBF),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Today\'s mood',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7C5CBF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_todayMood == null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _moods.map((mood) {
                            return GestureDetector(
                              onTap: () => _saveMood(mood),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F5FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  mood,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Row(
                          children: [
                            Text(
                              _todayMood!,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Feeling noted ✓',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // focus stats row
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => widget.onSwitchTab(3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'See all stats',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7C5CBF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF7C5CBF),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              color: Color(0xFF7C5CBF),
                              size: 20,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_todayFocusMinutes}m',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3D2B6B),
                              ),
                            ),
                            Text(
                              'focused today',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF7C5CBF),
                              size: 20,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_todaySessionCount',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3D2B6B),
                              ),
                            ),
                            Text(
                              'sessions done',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // todo preview
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 16,
                            color: Color(0xFF7C5CBF),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tasks',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7C5CBF),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => widget.onSwitchTab(2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'See all',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7C5CBF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: Color(0xFF7C5CBF),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (pendingTodos.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F5FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '🎉',
                                      style: TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'All done!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3D2B6B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Nothing pending today ✓',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...pendingTodos
                            .take(3)
                            .map(
                              (todo) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF7C5CBF),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        todo.title,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      if (pendingTodos.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${pendingTodos.length - 3} more',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Consumer<PlannedSessionProvider>(
                builder: (context, provider, _) {
                  final now = DateTime.now();
                  final upcoming =
                      provider.sessions
                          .where((s) => !s.completed && s.dateTime.isAfter(now))
                          .toList()
                        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

                  if (upcoming.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8F5FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.event_busy_rounded,
                                  color: Color(0xFFB0A0CC),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No upcoming sessions',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Plan one from the Focus tab',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => widget.onSwitchTab(1),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final next = upcoming.first;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8F5FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.event_rounded,
                                color: Color(0xFF7C5CBF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next session',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'EEE, MMM d • HH:mm',
                                  ).format(next.dateTime),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3D2B6B),
                                  ),
                                ),
                                Text(
                                  '${next.durationMinutes}min'
                                  '${next.strictMode ? ' • Strict mode' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => widget.onSwitchTab(1),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: const Color(0xFF7C5CBF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// SVG-style bear widget built in Flutter
class _BearWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(64, 64), painter: _BearPainter());
  }
}

class _BearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final purple = const Color(0xFF7C5CBF);
    final white = Colors.white;
    final lightPurple = const Color(0xFFEDE7F6);

    final bodyPaint = Paint()..color = white;
    final accentPaint = Paint()..color = lightPurple;
    final outlinePaint = Paint()
      ..color = purple.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final eyePaint = Paint()..color = purple;
    final nosePaint = Paint()..color = purple.withOpacity(0.6);

    final cx = size.width / 2;
    final cy = size.height / 2 + 4;

    // ears
    canvas.drawCircle(Offset(cx - 16, cy - 18), 10, bodyPaint);
    canvas.drawCircle(Offset(cx + 16, cy - 18), 10, bodyPaint);
    canvas.drawCircle(Offset(cx - 16, cy - 18), 10, outlinePaint);
    canvas.drawCircle(Offset(cx + 16, cy - 18), 10, outlinePaint);
    canvas.drawCircle(Offset(cx - 16, cy - 18), 5, accentPaint);
    canvas.drawCircle(Offset(cx + 16, cy - 18), 5, accentPaint);

    // head
    canvas.drawCircle(Offset(cx, cy - 10), 20, bodyPaint);
    canvas.drawCircle(Offset(cx, cy - 10), 20, outlinePaint);

    // snout
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 3), width: 14, height: 9),
      accentPaint,
    );

    // eyes
    canvas.drawCircle(Offset(cx - 6, cy - 14), 2.5, eyePaint);
    canvas.drawCircle(Offset(cx + 6, cy - 14), 2.5, eyePaint);

    // eye shine
    canvas.drawCircle(Offset(cx - 5, cy - 15), 1, Paint()..color = white);
    canvas.drawCircle(Offset(cx + 7, cy - 15), 1, Paint()..color = white);

    // nose
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 5), width: 5, height: 3.5),
      nosePaint,
    );

    // body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 16), width: 30, height: 24),
      const Radius.circular(12),
    );
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(bodyRect, outlinePaint);

    // belly
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 16), width: 16, height: 13),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
