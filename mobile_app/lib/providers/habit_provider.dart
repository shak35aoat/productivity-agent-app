import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/habit_model.dart';
import '../services/database_service.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> _habits = [];
  bool _loading = false;

  List<Habit> get habits => _habits;
  bool get loading => _loading;

  int get completedToday => _habits.where((h) => h.isCompletedToday).length;
  int get streaksAtRisk => _habits.where((h) => h.isStreakAtRisk && h.streak > 0).length;

  Future<void> loadHabits() async {
    _loading = true;
    notifyListeners();
    _habits = await DatabaseService.instance.getHabits();
    _loading = false;
    notifyListeners();
  }

  Future<void> addHabit(String name, {String frequency = 'daily'}) async {
    final habit = Habit(
      id: const Uuid().v4(),
      name: name,
      frequency: frequency,
    );
    await DatabaseService.instance.insertHabit(habit);
    await loadHabits();
  }

  Future<void> completeHabit(String id) async {
    final habit = _habits.firstWhere((h) => h.id == id);
    if (habit.isCompletedToday) return;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final wasYesterday = habit.lastCompleted != null &&
        habit.lastCompleted!.year == yesterday.year &&
        habit.lastCompleted!.month == yesterday.month &&
        habit.lastCompleted!.day == yesterday.day;

    // Increment streak if completed yesterday or first time
    habit.streak = (habit.lastCompleted == null || wasYesterday) ? habit.streak + 1 : 1;
    habit.lastCompleted = now;

    await DatabaseService.instance.updateHabit(habit);
    await loadHabits();
  }

  Future<void> deleteHabit(String id) async {
    await DatabaseService.instance.deleteHabit(id);
    await loadHabits();
  }
}
