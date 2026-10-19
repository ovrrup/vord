import 'dart:math' as math;
import 'session_mode.dart';

/// Immutable model representing a recorded focus or rest study session.
/// Engineered for 100% offline persistence, deduplication, and data integrity.
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

  /// Generates a collision-resistant unique session identifier
  /// using high-resolution microsecond timestamp combined with random entropy.
  static String generateId() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final entropy = math.Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '${micros}_$entropy';
  }

  /// Calculates the timestamp when the session began based on duration.
  DateTime get startedAt => completedAt.subtract(Duration(seconds: durationSeconds));

  /// Deduplication fingerprint based on physical session attributes
  /// (timestamp rounded to second, duration, and session mode).
  /// Used during backup imports to prevent duplicate entries even if IDs differ.
  String get deduplicationFingerprint {
    final epochSecond = completedAt.millisecondsSinceEpoch ~/ 1000;
    return '${epochSecond}_${durationSeconds}_${modeType.name}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'modeType': modeType.name,
    'durationSeconds': durationSeconds,
    'completedAt': completedAt.toUtc().toIso8601String(),
  };

  factory StudySession.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String?;
    final id = (rawId != null && rawId.trim().isNotEmpty) ? rawId : generateId();

    final rawMode = json['modeType'] as String?;
    final modeType = SessionModeType.values.firstWhere(
      (e) => e.name == rawMode,
      orElse: () => SessionModeType.focus,
    );

    final rawDuration = json['durationSeconds'];
    int duration = 0;
    if (rawDuration is int) {
      duration = rawDuration;
    } else if (rawDuration is num) {
      duration = rawDuration.toInt();
    } else if (rawDuration is String) {
      duration = int.tryParse(rawDuration) ?? 0;
    }
    // Safeguard: clamp duration between 1s and 86400s (24h)
    duration = duration.clamp(1, 86400);

    final rawDate = json['completedAt'];
    DateTime completed;
    if (rawDate is String) {
      try {
        completed = DateTime.parse(rawDate).toLocal();
      } catch (_) {
        completed = DateTime.now();
      }
    } else {
      completed = DateTime.now();
    }

    return StudySession(
      id: id,
      modeType: modeType,
      durationSeconds: duration,
      completedAt: completed,
    );
  }

  StudySession copyWith({
    String? id,
    SessionModeType? modeType,
    int? durationSeconds,
    DateTime? completedAt,
  }) {
    return StudySession(
      id: id ?? this.id,
      modeType: modeType ?? this.modeType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudySession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'StudySession(id: $id, mode: ${modeType.name}, duration: ${durationSeconds}s, completedAt: $completedAt)';
}
