import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _controller = TextEditingController();

  void _addTodo() {
    if (_controller.text.trim().isEmpty) return;
    context.read<TodoProvider>().addTodo(_controller.text.trim());
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoProvider>();
    final todos = todoProvider.todos;

    return Scaffold(
      appBar: AppBar(title: const Text('Todo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Add a task...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 32),
                  onPressed: _addTodo,
                ),
              ],
            ),
          ),
          Expanded(
            child: todos.isEmpty
                ? const Center(child: Text('No tasks yet. Add one above.'))
                : ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      final isCurrent = todoProvider.currentTask?.id == todo.id;

                      return ListTile(
                        leading: Checkbox(
                          value: todo.isDone,
                          onChanged: (_) => todoProvider.toggleDone(todo.id),
                        ),
                        title: Text(
                          todo.title,
                          style: TextStyle(
                            decoration: todo.isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: todo.isDone ? Colors.grey : null,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isCurrent ? Icons.star : Icons.star_border,
                                color: isCurrent ? Colors.amber : Colors.grey,
                              ),
                              onPressed: () {
                                todoProvider.setCurrentTask(
                                  isCurrent ? null : todo.id,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => todoProvider.deleteTodo(todo.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
