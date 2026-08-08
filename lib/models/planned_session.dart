class PlannedSession {
  String id;
  DateTime dateTime;
  int durationMinutes;
  bool strictMode;
  bool completed; // NEW

  PlannedSession({
    required this.id,
    required this.dateTime,
    required this.durationMinutes,
    required this.strictMode,
    this.completed = false, // NEW
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dateTime': dateTime.toIso8601String(),
    'durationMinutes': durationMinutes,
    'strictMode': strictMode,
    'completed': completed, // NEW
  };

  factory PlannedSession.fromJson(Map<String, dynamic> json) => PlannedSession(
    id: json['id'],
    dateTime: DateTime.parse(json['dateTime']),
    durationMinutes: json['durationMinutes'],
    strictMode: json['strictMode'],
    completed: json['completed'] ?? false, // NEW, defaults false for old data
  );
}
