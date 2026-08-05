import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _todayMood;
  bool _isLoading = true; // NEW
  final List<String> _moods = ['😔', '😐', '🙂', '😄', '🔥'];

  @override
  void initState() {
    super.initState();
    _loadMood();
  }

  Future<void> _loadMood() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('mood_date');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (savedDate == today) {
      setState(() {
        _todayMood = prefs.getString('mood_value');
      });
    }

    setState(() {
      _isLoading = false; // NEW — loading done, safe to render properly
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 13) return 'Good morning 🌅';
    if (hour < 18) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  Future<void> _saveMood(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    await prefs.setString('mood_date', today);
    await prefs.setString('mood_value', mood);

    // NEW: append to history log
    final historyRaw = prefs.getStringList('mood_history') ?? [];
    historyRaw.add('$today|$mood');
    await prefs.setStringList('mood_history', historyRaw);

    setState(() {
      _todayMood = mood;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _todayMood == null
                          ? 'How are you feeling today?'
                          : 'You\'re feeling $_todayMood today',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    if (_todayMood == null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _moods.map((mood) {
                          return GestureDetector(
                            onTap: () => _saveMood(mood),
                            child: Text(
                              mood,
                              style: const TextStyle(fontSize: 32),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
