import 'package:flutter/material.dart';

enum SessionModeType {
  focus,
  shortBreak,
  longBreak,
}

class SessionMode {
  final SessionModeType type;
  final String label;
  final int durationSeconds;
  final Color accentColor;

  const SessionMode({
    required this.type,
    required this.label,
    required this.durationSeconds,
    required this.accentColor,
  });

  static const SessionMode focus = SessionMode(
    type: SessionModeType.focus,
    label: 'Focus',
    durationSeconds: 25 * 60,
    accentColor: Color(0xFF3FA36C),
  );

  static const SessionMode rest = SessionMode(
    type: SessionModeType.shortBreak,
    label: 'Rest',
    durationSeconds: 5 * 60,
    accentColor: Color(0xFF2E8B57),
  );

  static const List<SessionMode> all = [
    focus,
    rest,
  ];
}
