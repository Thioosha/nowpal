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
}
