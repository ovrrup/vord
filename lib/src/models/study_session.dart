import 'session_mode.dart';

class StudySession {
  final String id;
  final SessionModeType modeType;
  final int durationSeconds;
  final DateTime completedAt;

  const StudySession({
    required this.id,
    required this.modeType,
    required this.durationSeconds,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'modeType': modeType.name,
    'durationSeconds': durationSeconds,
    'completedAt': completedAt.toIso8601String(),
  };

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as String,
      modeType: SessionModeType.values.firstWhere(
        (e) => e.name == json['modeType'],
        orElse: () => SessionModeType.focus,
      ),
      durationSeconds: json['durationSeconds'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}
