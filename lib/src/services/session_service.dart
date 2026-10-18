import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_mode.dart';
import '../models/study_session.dart';

class SessionService extends ChangeNotifier {
  static const String _storageKey = 'vord_study_sessions_v1';
  final List<StudySession> _sessions = [];
  bool _initialized = false;

  SessionService() {
    _loadFromStorage();
  }

  bool get isInitialized => _initialized;
  List<StudySession> get sessions => List.unmodifiable(_sessions.reversed);

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey);
      if (jsonList != null && jsonList.isNotEmpty) {
        _sessions.clear();
        for (final item in jsonList) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            _sessions.add(StudySession.fromJson(map));
          } catch (_) {}
        }
        _sessions.sort((a, b) => a.completedAt.compareTo(b.completedAt));
      }
    } catch (_) {}
    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _sessions.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (_) {}
  }

  void recordSession(SessionModeType modeType, int durationSeconds) {
    if (durationSeconds <= 0) return;

    final session = StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      modeType: modeType,
      durationSeconds: durationSeconds,
      completedAt: DateTime.now(),
    );

    _sessions.add(session);
    _saveToStorage();
    notifyListeners();
  }

  Future<void> clearAllSessions() async {
    _sessions.clear();
    await _saveToStorage();
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

  /// Returns the duration in seconds of the most recent focus session,
  /// or 20 minutes (1200s) default baseline if no previous session has been logged yet.
  int get lastFocusDurationSeconds {
    final focusSessions =
        _sessions.where((s) => s.modeType == SessionModeType.focus).toList();
    if (focusSessions.isEmpty) {
      return 20 * 60; // 20 minutes default baseline
    }
    final lastDuration = focusSessions.last.durationSeconds;
    return lastDuration >= 300 ? lastDuration : 300;
  }

  int get lastFocusDurationMinutes => (lastFocusDurationSeconds / 60).round();
}
