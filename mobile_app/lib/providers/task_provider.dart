import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  bool _loading = false;

  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _todayTasks;
  bool get loading => _loading;

  int get completedToday => _todayTasks.where((t) => t.completed).length;
  int get pendingToday => _todayTasks.where((t) => !t.completed).length;

  Future<void> loadTasks() async {
    _loading = true;
    notifyListeners();

    _tasks = await DatabaseService.instance.getTasks();
    _todayTasks = await DatabaseService.instance.getTodayTasks();

    _loading = false;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    await DatabaseService.instance.insertTask(task);

    if (task.dueDate != null) {
      await NotificationService.instance.scheduleTaskReminder(
        task.id,
        task.title,
        task.dueDate!,
      );
    }

    await loadTasks();
  }

  Future<Task> createAndAdd({
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
    String category = 'other',
  }) async {
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      category: category,
    );

    await addTask(task);
    return task;
  }

  Future<void> completeTask(String id) async {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.completed = true;
    await DatabaseService.instance.updateTask(task);
    await loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await DatabaseService.instance.deleteTask(id);
    await NotificationService.instance.cancelNotification(id.hashCode);
    await loadTasks();
  }
}
