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

  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> clearAllSessions() async {
    _sessions.clear();
    await _saveToStorage();
    notifyListeners();
  }

  int get totalSessionCount => _sessions.length;

  int get allTimeFocusSeconds => _sessions
      .where((s) => s.modeType == SessionModeType.focus)
      .fold(0, (sum, s) => sum + s.durationSeconds);

  int get allTimeBreakSeconds => _sessions
      .where((s) => s.modeType == SessionModeType.shortBreak)
      .fold(0, (sum, s) => sum + s.durationSeconds);

  int get storageSizeBytes {
    try {
      final jsonList = _sessions.map((s) => jsonEncode(s.toJson())).toList();
      return utf8.encode(jsonList.toString()).length;
    } catch (_) {
      return 0;
    }
  }

  /// Exports all sessions and metadata formatted as a clean, standardized JSON backup archive.
  String exportBackupJson() {
    final payload = {
      'app': 'VORD',
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'totalSessions': _sessions.length,
      'allTimeFocusSeconds': allTimeFocusSeconds,
      'allTimeBreakSeconds': allTimeBreakSeconds,
      'sessions': _sessions.map((s) => s.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Imports sessions from a JSON backup archive.
  /// If [replace] is true, replaces existing sessions; otherwise merges and deduplicates.
  Future<BackupImportResult> importBackupJson(String jsonString, {bool replace = false}) async {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const BackupImportResult(
          success: false,
          importedCount: 0,
          message: 'Invalid format: Expected a JSON backup object.',
        );
      }

      final rawSessions = decoded['sessions'];
      if (rawSessions is! List) {
        return const BackupImportResult(
          success: false,
          importedCount: 0,
          message: 'Invalid backup: "sessions" list was not found.',
        );
      }

      final parsed = <StudySession>[];
      for (final item in rawSessions) {
        if (item is Map<String, dynamic>) {
          try {
            parsed.add(StudySession.fromJson(item));
          } catch (_) {}
        }
      }

      if (parsed.isEmpty && rawSessions.isNotEmpty) {
        return const BackupImportResult(
          success: false,
          importedCount: 0,
          message: 'No valid sessions could be decoded from this backup.',
        );
      }

      if (replace) {
        _sessions.clear();
        _sessions.addAll(parsed);
      } else {
        final existingIds = _sessions.map((s) => s.id).toSet();
        for (final s in parsed) {
          if (!existingIds.contains(s.id)) {
            _sessions.add(s);
            existingIds.add(s.id);
          }
        }
      }

      _sessions.sort((a, b) => a.completedAt.compareTo(b.completedAt));
      await _saveToStorage();
      notifyListeners();

      return BackupImportResult(
        success: true,
        importedCount: parsed.length,
        message: replace
            ? 'Successfully restored ${parsed.length} sessions (data replaced).'
            : 'Successfully imported ${parsed.length} sessions.',
      );
    } catch (e) {
      return BackupImportResult(
        success: false,
        importedCount: 0,
        message: 'Import failed: ${e.toString()}',
      );
    }
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

/// Result object returned by [SessionService.importBackupJson].
class BackupImportResult {
  final bool success;
  final int importedCount;
  final String message;

  const BackupImportResult({
    required this.success,
    required this.importedCount,
    required this.message,
  });
}
