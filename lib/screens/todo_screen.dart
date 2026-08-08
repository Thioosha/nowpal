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
    final pending = todos.where((t) => !t.isDone).toList();
    final done = todos.where((t) => t.isDone).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Todo')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Add a task...',
                        prefixIcon: Icon(Icons.add_task_rounded),
                      ),
                      onSubmitted: (_) => _addTodo(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C5CBF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _addTodo,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: todos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8F5FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('📝', style: TextStyle(fontSize: 32)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No tasks yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add one above to get started',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      children: [
                        if (pending.isNotEmpty) ...[
                          _SectionLabel(text: 'To do (${pending.length})'),
                          const SizedBox(height: 8),
                          ReorderableListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            proxyDecorator: (child, index, animation) {
                              return Material(
                                color: Colors.transparent,
                                child: child,
                              );
                            },
                            onReorder: (oldIndex, newIndex) {
                              final ids = pending.map((t) => t.id).toList();
                              todoProvider.reorderTodos(
                                oldIndex,
                                newIndex,
                                ids,
                              );
                            },
                            children: pending
                                .map(
                                  (todo) => _TodoCard(
                                    key: ValueKey(todo.id),
                                    todo: todo,
                                    isCurrent:
                                        todoProvider.currentTask?.id == todo.id,
                                    onToggle: () =>
                                        todoProvider.toggleDone(todo.id),
                                    onStar: () => todoProvider.setCurrentTask(
                                      todoProvider.currentTask?.id == todo.id
                                          ? null
                                          : todo.id,
                                    ),
                                    onDelete: () =>
                                        todoProvider.deleteTodo(todo.id),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (done.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _SectionLabel(text: 'Done (${done.length})'),
                          const SizedBox(height: 8),
                          ...done.map(
                            (todo) => _TodoCard(
                              todo: todo,
                              isCurrent: false,
                              onToggle: () => todoProvider.toggleDone(todo.id),
                              onStar: () {},
                              onDelete: () => todoProvider.deleteTodo(todo.id),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey[500],
        letterSpacing: 0.5,
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  final dynamic todo;
  final bool isCurrent;
  final VoidCallback onToggle;
  final VoidCallback onStar;
  final VoidCallback onDelete;

  const _TodoCard({
    super.key,
    required this.todo,
    required this.isCurrent,
    required this.onToggle,
    required this.onStar,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isCurrent
                ? const Color(0xFF7C5CBF)
                : const Color(0xFFEDE7F6),
            width: isCurrent ? 1.5 : 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: todo.isDone ? const Color(0xFF7C5CBF) : Colors.white,
                    border: Border.all(
                      color: todo.isDone
                          ? const Color(0xFF7C5CBF)
                          : const Color(0xFFB0A0CC),
                      width: 1.5,
                    ),
                  ),
                  child: todo.isDone
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 15,
                    decoration: todo.isDone ? TextDecoration.lineThrough : null,
                    color: todo.isDone
                        ? Colors.grey[400]
                        : const Color(0xFF3D2B6B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!todo.isDone)
                IconButton(
                  icon: Icon(
                    isCurrent ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isCurrent ? Colors.amber : Colors.grey[400],
                  ),
                  onPressed: onStar,
                ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.grey[400],
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
