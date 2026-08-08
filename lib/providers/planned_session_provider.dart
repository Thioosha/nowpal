import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/planned_session.dart';

class PlannedSessionProvider extends ChangeNotifier {
  List<PlannedSession> _sessions = [];

  List<PlannedSession> get sessions =>
      _sessions..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<PlannedSession> get upcoming =>
      sessions.where((s) => s.dateTime.isAfter(DateTime.now())).toList();

  PlannedSessionProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('planned_sessions');
    if (data != null) {
      final List decoded = jsonDecode(data);
      _sessions = decoded.map((e) => PlannedSession.fromJson(e)).toList();
      notifyListeners();
    }
    pruneOldMissed(); // NEW
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_sessions.map((e) => e.toJson()).toList());
    await prefs.setString('planned_sessions', data);
  }

  void addSession(PlannedSession session) {
    _sessions.add(session);
    _save();
    notifyListeners();
  }

  void deleteSession(String id) {
    _sessions.removeWhere((s) => s.id == id);
    _save();
    notifyListeners();
  }

  void markCompleted(String id) {
    final session = _sessions.firstWhere((s) => s.id == id);
    session.completed = true;
    _save();
    notifyListeners();
  }

  void pruneOldMissed() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    _sessions.removeWhere((s) => !s.completed && s.dateTime.isBefore(cutoff));
    _save();
    notifyListeners();
  }

  void updateSession(PlannedSession updated) {
    final index = _sessions.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      _sessions[index] = updated;
      _save();
      notifyListeners();
    }
  }
}
