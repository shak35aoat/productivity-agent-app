class Task {
  final String id;
  final String title;
  String? description;
  DateTime? dueDate;
  String priority; // low, medium, high
  String category; // study, bcs_prep, assignment, personal, other
  bool completed;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 'medium',
    this.category = 'other',
    this.completed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'due_date': dueDate?.toIso8601String(),
    'priority': priority,
    'category': category,
    'completed': completed ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
    priority: map['priority'] ?? 'medium',
    category: map['category'] ?? 'other',
    completed: (map['completed'] ?? 0) == 1,
    createdAt: DateTime.parse(map['created_at']),
  );
}
