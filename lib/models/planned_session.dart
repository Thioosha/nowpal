class PlannedSession {
  String id;
  DateTime dateTime;
  int durationMinutes;
  bool strictMode;

  PlannedSession({
    required this.id,
    required this.dateTime,
    required this.durationMinutes,
    required this.strictMode,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dateTime': dateTime.toIso8601String(),
    'durationMinutes': durationMinutes,
    'strictMode': strictMode,
  };

  factory PlannedSession.fromJson(Map<String, dynamic> json) => PlannedSession(
    id: json['id'],
    dateTime: DateTime.parse(json['dateTime']),
    durationMinutes: json['durationMinutes'],
    strictMode: json['strictMode'],
  );
}
