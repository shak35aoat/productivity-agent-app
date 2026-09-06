class StudySession {
  final String id;
  final String subject;
  final int durationMinutes;
  int? focusScore; // 1-10
  String? notes;
  final DateTime timestamp;

  StudySession({
    required this.id,
    required this.subject,
    required this.durationMinutes,
    this.focusScore,
    this.notes,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'subject': subject,
    'duration_minutes': durationMinutes,
    'focus_score': focusScore,
    'notes': notes,
    'timestamp': timestamp.toIso8601String(),
  };

  factory StudySession.fromMap(Map<String, dynamic> map) => StudySession(
    id: map['id'],
    subject: map['subject'],
    durationMinutes: map['duration_minutes'],
    focusScore: map['focus_score'],
    notes: map['notes'],
    timestamp: DateTime.parse(map['timestamp']),
  );
}
