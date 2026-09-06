class BcsSubject {
  final String id;
  String name;
  int totalTopics;
  int completedTopics;
  final String category; // bangla, english, math, gk, eee
  DateTime? lastStudied;

  BcsSubject({
    required this.id,
    required this.name,
    required this.totalTopics,
    this.completedTopics = 0,
    required this.category,
    this.lastStudied,
  });

  double get progressPercent =>
      totalTopics == 0 ? 0 : completedTopics / totalTopics;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'total_topics': totalTopics,
        'completed_topics': completedTopics,
        'category': category,
        'last_studied': lastStudied?.toIso8601String(),
      };

  factory BcsSubject.fromMap(Map<String, dynamic> map) => BcsSubject(
        id: map['id'],
        name: map['name'],
        totalTopics: map['total_topics'],
        completedTopics: map['completed_topics'] ?? 0,
        category: map['category'],
        lastStudied: map['last_studied'] != null
            ? DateTime.parse(map['last_studied'])
            : null,
      );
}

class MockTestResult {
  final String id;
  final String subject;
  final int score;
  final int totalMarks;
  final String testName;
  final DateTime date;

  MockTestResult({
    required this.id,
    required this.subject,
    required this.score,
    required this.totalMarks,
    required this.testName,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  double get percentage => totalMarks == 0 ? 0 : score / totalMarks * 100;

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject': subject,
        'score': score,
        'total_marks': totalMarks,
        'test_name': testName,
        'date': date.toIso8601String(),
      };

  factory MockTestResult.fromMap(Map<String, dynamic> map) => MockTestResult(
        id: map['id'],
        subject: map['subject'],
        score: map['score'],
        totalMarks: map['total_marks'],
        testName: map['test_name'],
        date: DateTime.parse(map['date']),
      );
}
