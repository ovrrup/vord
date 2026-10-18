import 'package:flutter/foundation.dart';
import '../models/session_mode.dart';
import '../models/study_session.dart';

class SessionService extends ChangeNotifier {
  final List<StudySession> _sessions = [];

  List<StudySession> get sessions => List.unmodifiable(_sessions.reversed);

  void recordSession(SessionModeType modeType, int durationSeconds) {
    final session = StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      modeType: modeType,
      durationSeconds: durationSeconds,
      completedAt: DateTime.now(),
    );

    _sessions.add(session);
    notifyListeners();
  }

  int get todayFocusSeconds {
    final now = DateTime.now();
    return _sessions
        .where((s) =>
            s.modeType == SessionModeType.focus &&
            s.completedAt.year == now.year &&
            s.completedAt.month == now.month &&
            s.completedAt.day == now.day)
        .fold(0, (sum, s) => sum + s.durationSeconds);
  }

  int get todayFocusMinutes => (todayFocusSeconds / 60).round();

  int get todayBestFocusSeconds {
    final now = DateTime.now();
    final todayFocusSessions = _sessions.where((s) =>
        s.modeType == SessionModeType.focus &&
        s.completedAt.year == now.year &&
        s.completedAt.month == now.month &&
        s.completedAt.day == now.day);
    if (todayFocusSessions.isEmpty) return 0;
    return todayFocusSessions
        .map((s) => s.durationSeconds)
        .reduce((curr, next) => curr > next ? curr : next);
  }

  int get todayBestFocusMinutes => (todayBestFocusSeconds / 60).round();

  int get todayFocusCount {
    final now = DateTime.now();
    return _sessions
        .where((s) =>
            s.modeType == SessionModeType.focus &&
            s.completedAt.year == now.year &&
            s.completedAt.month == now.month &&
            s.completedAt.day == now.day)
        .length;
  }
}
