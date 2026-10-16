import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
    accentColor: AppTheme.textPrimary,
  );

  static const SessionMode shortBreak = SessionMode(
    type: SessionModeType.shortBreak,
    label: 'Short Break',
    durationSeconds: 5 * 60,
    accentColor: Color(0xFF81E6D9), // Soft muted teal
  );

  static const SessionMode longBreak = SessionMode(
    type: SessionModeType.longBreak,
    label: 'Long Break',
    durationSeconds: 15 * 60,
    accentColor: Color(0xFFB794F4), // Gentle muted lavender
  );

  static const List<SessionMode> all = [
    focus,
    shortBreak,
    longBreak,
  ];
}
