import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

/// Component 1: Minimal greeting and motivation area.
/// Kept ultra-minimal with zero extra boxes or chips per user specification.
class MotivationBanner extends StatelessWidget {
  final SessionService sessionService;
  final bool isFocusMode;
  final bool isRunning;
  final bool isPaused;

  const MotivationBanner({
    super.key,
    required this.sessionService,
    required this.isFocusMode,
    this.isRunning = false,
    this.isPaused = false,
  });

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getMotivationText() {
    if (isRunning) {
      return isFocusMode
          ? 'Focus session in progress.'
          : 'Rest interval in progress.';
    }

    if (isPaused) {
      return 'Session paused and saved.';
    }

    if (!isFocusMode) {
      return 'Rest and recharge.';
    }

    final lastMinutes = sessionService.lastFocusDurationMinutes;
    if (sessionService.todayFocusMinutes > 0) {
      return 'Previous session: ${lastMinutes}m • Compete to beat it by at least 2m.';
    }
    return 'Compete with yourself. Focus longer than before.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: sessionService,
      builder: (context, _) {
        final greeting = _getTimeGreeting();
        final motivation = _getMotivationText();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4.0, right: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greeting,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                motivation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
