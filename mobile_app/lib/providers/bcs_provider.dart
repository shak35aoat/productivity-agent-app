import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/bcs_model.dart';
import '../services/database_service.dart';

const _defaultSubjects = [
  ('bcs-bn-1', 'Bangla Literature', 20, 'bangla'),
  ('bcs-bn-2', 'Bangla Grammar', 15, 'bangla'),
  ('bcs-en-1', 'English Grammar', 20, 'english'),
  ('bcs-en-2', 'English Literature', 10, 'english'),
  ('bcs-ma-1', 'Mathematics', 25, 'math'),
  ('bcs-ma-2', 'Mental Ability', 15, 'math'),
  ('bcs-gk-1', 'Bangladesh Affairs', 20, 'gk'),
  ('bcs-gk-2', 'International Affairs', 15, 'gk'),
  ('bcs-gk-3', 'Science & Technology', 15, 'gk'),
  ('bcs-gk-4', 'Geography & Environment', 10, 'gk'),
  ('bcs-eee-1', 'Circuit Theory', 15, 'eee'),
  ('bcs-eee-2', 'Electronics', 15, 'eee'),
  ('bcs-eee-3', 'Power Systems', 15, 'eee'),
  ('bcs-eee-4', 'Control Systems', 10, 'eee'),
  ('bcs-eee-5', 'Electrical Machines', 10, 'eee'),
];

class BcsProvider extends ChangeNotifier {
  List<BcsSubject> _subjects = [];
  List<MockTestResult> _mockTests = [];
  bool _loading = false;

  List<BcsSubject> get subjects => _subjects;
  List<MockTestResult> get mockTests => _mockTests;
  bool get loading => _loading;

  double get overallProgress {
    if (_subjects.isEmpty) return 0;
    final totalTopics = _subjects.fold(0, (sum, s) => sum + s.totalTopics);
    final completedTopics = _subjects.fold(0, (sum, s) => sum + s.completedTopics);
    return totalTopics == 0 ? 0 : completedTopics / totalTopics;
  }

  List<BcsSubject> subjectsByCategory(String category) =>
      _subjects.where((s) => s.category == category).toList();

  double categoryProgress(String category) {
    final subs = subjectsByCategory(category);
    if (subs.isEmpty) return 0;
    final total = subs.fold(0, (sum, s) => sum + s.totalTopics);
    final done = subs.fold(0, (sum, s) => sum + s.completedTopics);
    return total == 0 ? 0 : done / total;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _subjects = await DatabaseService.instance.getBcsSubjects();

    // Seed default subjects if none exist
    if (_subjects.isEmpty) {
      final seedSubjects = _defaultSubjects.map((s) => BcsSubject(
        id: s.$1,
        name: s.$2,
        totalTopics: s.$3,
        category: s.$4,
      )).toList();
      await DatabaseService.instance.batchInsertBcsSubjects(seedSubjects);
      _subjects = await DatabaseService.instance.getBcsSubjects();
    }

    _mockTests = await DatabaseService.instance.getMockTests();
    _loading = false;
    notifyListeners();
  }

  Future<void> renameSubject(String subjectId, String newName) async {
    final subject = _subjects.firstWhere((s) => s.id == subjectId);
    subject.name = newName;
    await DatabaseService.instance.updateBcsSubject(subject);
    await load();
  }

  Future<void> updateProgress(String subjectId, int completed) async {
    final subject = _subjects.firstWhere((s) => s.id == subjectId);
    subject.completedTopics = completed.clamp(0, subject.totalTopics);
    subject.lastStudied = DateTime.now();
    await DatabaseService.instance.updateBcsSubject(subject);
    await load();
  }

  Future<void> addMockTest({
    required String subject,
    required String testName,
    required int score,
    required int totalMarks,
  }) async {
    final result = MockTestResult(
      id: const Uuid().v4(),
      subject: subject,
      testName: testName,
      score: score,
      totalMarks: totalMarks,
    );
    await DatabaseService.instance.insertMockTest(result);
    await load();
  }

  Future<void> deleteMockTest(String id) async {
    await DatabaseService.instance.deleteMockTest(id);
    await load();
  }
}
