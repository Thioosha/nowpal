import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class TodoProvider extends ChangeNotifier {
  List<Todo> _todos = [];
  String? _currentTaskId;

  List<Todo> get todos => _todos;
  Todo? get currentTask {
    if (_currentTaskId == null) return null;
    try {
      return _todos.firstWhere((t) => t.id == _currentTaskId);
    } catch (e) {
      return null;
    }
  }

  TodoProvider() {
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('todos');
    if (data != null) {
      final List decoded = jsonDecode(data);
      _todos = decoded.map((e) => Todo.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_todos.map((e) => e.toJson()).toList());
    await prefs.setString('todos', data);
  }

  void addTodo(String title) {
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    _todos.add(todo);
    _saveTodos();
    notifyListeners();
  }

  void toggleDone(String id) {
    final todo = _todos.firstWhere((t) => t.id == id);
    todo.isDone = !todo.isDone;
    _saveTodos();
    notifyListeners();
  }

  void deleteTodo(String id) {
    _todos.removeWhere((t) => t.id == id);
    if (_currentTaskId == id) _currentTaskId = null;
    _saveTodos();
    notifyListeners();
  }

  void setCurrentTask(String? id) {
    _currentTaskId = id;
    notifyListeners();
  }

  void reorderTodos(int oldIndex, int newIndex, List<String> pendingIds) {
    if (newIndex > oldIndex) newIndex -= 1;
    final movedId = pendingIds.removeAt(oldIndex);
    pendingIds.insert(newIndex, movedId);

    // rebuild _todos so pending order matches, done items stay at the end untouched
    final doneItems = _todos.where((t) => t.isDone).toList();
    final reorderedPending = pendingIds
        .map((id) => _todos.firstWhere((t) => t.id == id))
        .toList();

    _todos = [...reorderedPending, ...doneItems];
    _saveTodos();
    notifyListeners();
  }
}
