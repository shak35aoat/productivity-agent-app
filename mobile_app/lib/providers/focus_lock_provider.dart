import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FocusLock {
  final String id;
  final String label;
  final String startTime; // "HH:MM"
  final String endTime;
  final List<String> days; // ["Mon","Tue",...]
  final bool enabled;

  FocusLock({
    required this.id,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.days,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'label': label, 'startTime': startTime,
    'endTime': endTime, 'days': days.join(','), 'enabled': enabled ? 1 : 0,
  };

  factory FocusLock.fromMap(Map<String, dynamic> m) => FocusLock(
    id: m['id'], label: m['label'], startTime: m['startTime'],
    endTime: m['endTime'], days: (m['days'] as String).split(','),
    enabled: (m['enabled'] ?? 1) == 1,
  );

  bool isActiveNow() {
    if (!enabled) return false;
    final now = DateTime.now();
    final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][now.weekday - 1];
    if (!days.contains(dayName)) return false;

    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    final nowMinutes = now.hour * 60 + now.minute;

    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  String get timeRange => '$startTime – $endTime';
  String get daysDisplay => days.join(', ');
}

class FocusLockProvider extends ChangeNotifier {
  List<FocusLock> _locks = [];

  List<FocusLock> get locks => _locks;
  bool get anyActiveNow => _locks.any((l) => l.isActiveNow());
  List<FocusLock> get activeLocks => _locks.where((l) => l.isActiveNow()).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('focus_locks') ?? [];
    _locks = raw.map((s) {
      final parts = s.split('|');
      return FocusLock(
        id: parts[0], label: parts[1], startTime: parts[2],
        endTime: parts[3], days: parts[4].split(','),
        enabled: parts[5] == '1',
      );
    }).toList();
    notifyListeners();
  }

  Future<void> addLock(FocusLock lock) async {
    _locks.add(lock);
    await _save();
    notifyListeners();
  }

  Future<void> toggleLock(String id) async {
    final idx = _locks.indexWhere((l) => l.id == id);
    if (idx == -1) return;
    final l = _locks[idx];
    _locks[idx] = FocusLock(
      id: l.id, label: l.label, startTime: l.startTime,
      endTime: l.endTime, days: l.days, enabled: !l.enabled,
    );
    await _save();
    notifyListeners();
  }

  Future<void> deleteLock(String id) async {
    _locks.removeWhere((l) => l.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('focus_locks', _locks.map((l) =>
      '${l.id}|${l.label}|${l.startTime}|${l.endTime}|${l.days.join(',')}|${l.enabled ? 1 : 0}'
    ).toList());
  }
}
