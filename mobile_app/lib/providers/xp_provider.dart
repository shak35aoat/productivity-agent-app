import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _levelThresholds = [0, 100, 250, 500, 900, 1400, 2100, 3000, 4200, 6000];
const _levelNames = ['Freshman', 'Sophomore', 'Junior', 'Senior', 'Engineer I', 'Engineer II', 'Expert', 'Master', 'Elite', 'Legend'];

class XpProvider extends ChangeNotifier {
  int _xp = 0;
  int _level = 0;
  List<String> _badges = [];

  int get xp => _xp;
  int get level => _level;
  String get levelName => _levelNames[_level.clamp(0, _levelNames.length - 1)];
  List<String> get badges => _badges;

  int get xpForCurrentLevel => _levelThresholds[_level.clamp(0, _levelThresholds.length - 1)];
  int get xpForNextLevel => _level + 1 < _levelThresholds.length
      ? _levelThresholds[_level + 1]
      : _levelThresholds.last + 1000;

  double get levelProgress {
    final current = xpForCurrentLevel;
    final next = xpForNextLevel;
    if (next <= current) return 1.0;
    return ((_xp - current) / (next - current)).clamp(0.0, 1.0);
  }

  int get xpToNextLevel => (xpForNextLevel - _xp).clamp(0, 9999);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt('xp') ?? 0;
    _badges = prefs.getStringList('badges') ?? [];
    _recalcLevel();
    notifyListeners();
  }

  Future<bool> addXp(int amount, {String? reason}) async {
    final oldLevel = _level;
    _xp += amount;
    _recalcLevel();
    final leveledUp = _level > oldLevel;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('xp', _xp);
    notifyListeners();
    return leveledUp;
  }

  Future<void> awardBadge(String badge) async {
    if (_badges.contains(badge)) return;
    _badges.add(badge);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('badges', _badges);
    notifyListeners();
  }

  void _recalcLevel() {
    _level = 0;
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (_xp >= _levelThresholds[i]) {
        _level = i;
        break;
      }
    }
  }
}

// XP rewards per action
class XpRewards {
  static const int taskComplete = 20;
  static const int habitComplete = 15;
  static const int pomodoroComplete = 25;
  static const int bcsTopicComplete = 10;
  static const int mockTestLogged = 30;
  static const int morningCheckin = 10;
  static const int streak7Days = 100;
}
