class Todo {
  String id;
  String title;
  bool isDone;

  Todo({required this.id, required this.title, this.isDone = false});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'isDone': isDone};

  factory Todo.fromJson(Map<String, dynamic> json) =>
      Todo(id: json['id'], title: json['title'], isDone: json['isDone']);
}
