class Habit {
  final String id;
  String name;
  String frequency; // daily, weekly
  int streak;
  DateTime? lastCompleted;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    this.frequency = 'daily',
    this.streak = 0,
    this.lastCompleted,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCompletedToday {
    if (lastCompleted == null) return false;
    final now = DateTime.now();
    return lastCompleted!.year == now.year &&
        lastCompleted!.month == now.month &&
        lastCompleted!.day == now.day;
  }

  bool get isStreakAtRisk {
    if (lastCompleted == null) return streak > 0;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return !isCompletedToday &&
        !(lastCompleted!.year == yesterday.year &&
            lastCompleted!.month == yesterday.month &&
            lastCompleted!.day == yesterday.day);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'frequency': frequency,
        'streak': streak,
        'last_completed': lastCompleted?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
        id: map['id'],
        name: map['name'],
        frequency: map['frequency'] ?? 'daily',
        streak: map['streak'] ?? 0,
        lastCompleted: map['last_completed'] != null
            ? DateTime.parse(map['last_completed'])
            : null,
        createdAt: DateTime.parse(map['created_at']),
      );
}
