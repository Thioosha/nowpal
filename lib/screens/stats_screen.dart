import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

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
      total += int.tryParse(entry.split('|')[1]) ?? 0;
    }
    return total;
  }

  Map<String, String> get _moodByDate {
    final map = <String, String>{};
    for (final entry in _moodHistory) {
      final parts = entry.split('|');
      map[parts[0]] = parts[1]; // last mood of the day wins
    }
    return map;
  }

  Map<String, int> get _minutesByDayLast7 {
    final map = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final key = day.toIso8601String().substring(0, 10);
      map[key] = 0;
    }
    for (final entry in _focusSessions) {
      final parts = entry.split('|');
      if (map.containsKey(parts[0])) {
        map[parts[0]] = map[parts[0]]! + (int.tryParse(parts[1]) ?? 0);
      }
    }
    return map;
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final minutesMap = _minutesByDayLast7;
    final maxY =
        (minutesMap.values.isEmpty
                ? 30
                : (minutesMap.values.reduce((a, b) => a > b ? a : b)))
            .toDouble()
            .clamp(30, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Sessions completed',
                    value: '${_focusSessions.length}',
                    icon: Icons.timer_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Total focus time',
                    value: '${_totalFocusMinutes}m',
                    icon: Icons.access_time_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // bar chart
            Text(
              'Last 7 days',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                child: SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      maxY:
                          maxY.toDouble() *
                          1.3, // headroom for tooltip + bar top
                      alignment: BarChartAlignment.spaceAround,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => const Color(0xFF3D2B6B),
                          tooltipRoundedRadius: 10,
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${rod.toY.toInt()}m',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final keys = minutesMap.keys.toList();
                              if (value.toInt() >= keys.length) {
                                return const SizedBox();
                              }
                              final date = DateTime.parse(keys[value.toInt()]);
                              const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  days[date.weekday - 1],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: minutesMap.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((e) {
                            final index = e.key;
                            final minutes = e.value.value;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: minutes.toDouble(),
                                  color: const Color(0xFF7C5CBF),
                                  width: 18,
                                  borderRadius: BorderRadius.circular(6),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxY.toDouble() * 1.3,
                                    color: const Color(0xFFF8F5FF),
                                  ),
                                ),
                              ],
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // mood calendar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mood calendar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: const Color(0xFF7C5CBF),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3D2B6B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: const Color(0xFF7C5CBF),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _MoodCalendar(
                  month: _visibleMonth,
                  moodByDate: _moodByDate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
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
            Icon(icon, color: const Color(0xFF7C5CBF)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D2B6B),
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodCalendar extends StatelessWidget {
  final DateTime month;
  final Map<String, String> moodByDate;

  const _MoodCalendar({required this.month, required this.moodByDate});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1 = Monday

    final cells = <Widget>[];

    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final key = date.toIso8601String().substring(0, 10);
      final mood = moodByDate[key];
      final isToday = DateTime.now().toIso8601String().substring(0, 10) == key;

      cells.add(
        Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: mood != null ? const Color(0xFFF8F5FF) : Colors.transparent,
            border: isToday
                ? Border.all(color: const Color(0xFF7C5CBF), width: 1.5)
                : null,
          ),
          child: Center(
            child: mood != null
                ? Text(mood, style: const TextStyle(fontSize: 16))
                : Text(
                    '$day',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ],
    );
  }
}
