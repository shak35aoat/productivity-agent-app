import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/study_session_model.dart';
import 'package:uuid/uuid.dart';

enum PomodoroState { idle, focusing, onBreak, longBreak }

class PomodoroProvider extends ChangeNotifier {
  static const int focusDuration = 25 * 60;      // 25 minutes
  static const int shortBreakDuration = 5 * 60;  // 5 minutes
  static const int longBreakDuration = 15 * 60;  // 15 minutes
  static const int sessionsBeforeLongBreak = 4;

  PomodoroState _state = PomodoroState.idle;
  int _secondsRemaining = focusDuration;
  int _completedSessions = 0;
  String _currentSubject = 'General Study';
  Timer? _timer;

  // Callbacks set by the screen for notifications
  VoidCallback? onFocusComplete;
  VoidCallback? onBreakComplete;

  PomodoroState get state => _state;
  int get secondsRemaining => _secondsRemaining;
  int get completedSessions => _completedSessions;
  String get currentSubject => _currentSubject;
  bool get isRunning => _timer?.isActive ?? false;

  int get totalDuration {
    switch (_state) {
      case PomodoroState.focusing:
        return focusDuration;
      case PomodoroState.onBreak:
        return shortBreakDuration;
      case PomodoroState.longBreak:
        return longBreakDuration;
      case PomodoroState.idle:
        return focusDuration;
    }
  }

  double get progress {
    if (totalDuration == 0) return 0;
    return 1.0 - (_secondsRemaining / totalDuration);
  }

  String get formattedTime {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get stateLabel {
    switch (_state) {
      case PomodoroState.idle:
        return 'Ready to Focus';
      case PomodoroState.focusing:
        return 'Focus Time';
      case PomodoroState.onBreak:
        return 'Short Break';
      case PomodoroState.longBreak:
        return 'Long Break — Well Earned!';
    }
  }

  void setSubject(String subject) {
    _currentSubject = subject;
    notifyListeners();
  }

  void start() {
    if (_state == PomodoroState.idle) {
      _state = PomodoroState.focusing;
      _secondsRemaining = focusDuration;
    }
    _startTimer();
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    notifyListeners();
  }

  void resume() {
    _startTimer();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _state = PomodoroState.idle;
    _secondsRemaining = focusDuration;
    notifyListeners();
  }

  void skipToBreak() {
    _timer?.cancel();
    _completeFocusSession(skipped: true);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
        _onTimerComplete();
      }
    });
  }

  Future<void> _onTimerComplete() async {
    if (_state == PomodoroState.focusing) {
      await _completeFocusSession();
    } else {
      // Break ended — go back to idle
      _state = PomodoroState.idle;
      _secondsRemaining = focusDuration;
      onBreakComplete?.call();
      notifyListeners();
    }
  }

  Future<void> _completeFocusSession({bool skipped = false}) async {
    _completedSessions++;

    if (!skipped) {
      // Save study session to local DB
      await DatabaseService.instance.insertStudySession(
        StudySession(
          id: const Uuid().v4(),
          subject: _currentSubject,
          durationMinutes: focusDuration ~/ 60,
        ),
      );
      onFocusComplete?.call();
    }

    // Determine next break type
    if (_completedSessions % sessionsBeforeLongBreak == 0) {
      _state = PomodoroState.longBreak;
      _secondsRemaining = longBreakDuration;
    } else {
      _state = PomodoroState.onBreak;
      _secondsRemaining = shortBreakDuration;
    }

    notifyListeners();
    _startTimer(); // Auto-start the break
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
