import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => StatsScreenState();
}

class StatsScreenState extends State<StatsScreen> {
  List<String> _moodHistory = [];
  List<String> _focusSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _moodHistory = prefs.getStringList('mood_history') ?? [];
      _focusSessions = prefs.getStringList('focus_sessions') ?? [];
      _isLoading = false;
    });
  }

  Future<void> loadStats() => _loadStats();

  int get _totalFocusMinutes {
    int total = 0;
    for (final entry in _focusSessions) {
      final parts = entry.split('|');
      total += int.tryParse(parts[1]) ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Sessions completed',
                    value: '${_focusSessions.length}',
                    icon: Icons.timer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Total focus time',
                    value: '${_totalFocusMinutes}m',
                    icon: Icons.access_time,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Mood history',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _moodHistory.isEmpty
                ? const Text('No mood logs yet.')
                : Column(
                    children: _moodHistory.reversed.map((entry) {
                      final parts = entry.split('|');
                      return ListTile(
                        leading: Text(
                          parts[1],
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(parts[0]),
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),
            const Text(
              'Focus sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _focusSessions.isEmpty
                ? const Text('No sessions completed yet.')
                : Column(
                    children: _focusSessions.reversed.map((entry) {
                      final parts = entry.split('|');
                      return ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: Text('${parts[1]} min session'),
                        subtitle: Text(parts[0]),
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
