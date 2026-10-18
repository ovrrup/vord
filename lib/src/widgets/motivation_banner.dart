import 'package:flutter/material.dart';
import '../services/session_service.dart';

/// Component 1: Area where motivational info and self-competition insights are shown.
/// Designed modularly so it can easily be expanded with advanced analytics in the future.
class MotivationBanner extends StatelessWidget {
  final SessionService sessionService;
  final bool isFocusMode;
  final bool isRunning;
  final bool isPaused;
  final int elapsedSeconds;
  final int baselineSeconds;
  final int extra3Seconds;

  const MotivationBanner({
    super.key,
    required this.sessionService,
    required this.isFocusMode,
    this.isRunning = false,
    this.isPaused = false,
    this.elapsedSeconds = 0,
    this.baselineSeconds = 1200,
    this.extra3Seconds = 180,
  });

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  int _calculateCurrentStage() {
    if (!isFocusMode || elapsedSeconds <= 0) return 0;
    final b = baselineSeconds > 0 ? baselineSeconds : 1200;
    final t1 = (b * 0.70).round();
    final t2 = b;
    final t3 = t2 + extra3Seconds;

    if (elapsedSeconds < t1) return 1;
    if (elapsedSeconds < t2) return 2;
    if (elapsedSeconds < t3) return 3;
    return 4;
  }

  String _getTitle() {
    if (isRunning) {
      if (!isFocusMode) return 'Rest Interval';
      final stage = _calculateCurrentStage();
      switch (stage) {
        case 1:
          return 'Deep Focus';
        case 2:
          return 'Approaching Target';
        case 3:
          return 'Milestone Crossed!';
        case 4:
          return 'Limit Surpassed!';
        default:
          return 'Deep Focus';
      }
    }

    if (isPaused) {
      return 'Session Paused';
    }

    return _getTimeGreeting();
  }

  String _getSubtitle() {
    if (isRunning) {
      if (!isFocusMode) {
        return 'Recharging your mind. Take purposeful rest.';
      }
      final stage = _calculateCurrentStage();
      switch (stage) {
        case 1:
          return 'Finding your flow. Time is hidden to keep you immersed.';
        case 2:
          return 'Nearing your previous mark. Keep locked in.';
        case 3:
          return 'You passed your baseline! Pushing into new territory.';
        case 4:
          return 'Outstanding focus. You have surpassed your previous limit.';
        default:
          return 'Building focus without distraction.';
      }
    }

    if (isPaused) {
      return 'Session saved. Tap resume when you are ready to continue.';
    }

    if (!isFocusMode) {
      return 'Rest and recharge. Your next session awaits.';
    }

    final lastMinutes = sessionService.lastFocusDurationMinutes;
    final totalFocus = sessionService.todayFocusMinutes;

    if (totalFocus > 0) {
      return 'Previous session: ${lastMinutes}m • Compete to beat it by at least 2m.';
    }
    return 'Compete with yourself. Focus longer than before.';
  }

  String _getBadgeLabel() {
    if (isRunning) {
      if (!isFocusMode) return 'RESTING';
      final stage = _calculateCurrentStage();
      return 'STAGE $stage';
    }
    if (isPaused) return 'PAUSED';
    return isFocusMode ? 'FOCUS' : 'REST';
  }

  Color _getBadgeColor(bool isDark) {
    if (!isFocusMode) {
      return isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76);
    }
    if (isRunning) {
      final stage = _calculateCurrentStage();
      if (stage >= 3) {
        return isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57);
      }
      if (stage == 2) {
        return isDark ? const Color(0xFF28593D) : const Color(0xFFA8D5BA);
      }
    }
    return isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: sessionService,
      builder: (context, _) {
        final title = _getTitle();
        final subtitle = _getSubtitle();
        final badgeLabel = _getBadgeLabel();
        final badgeColor = _getBadgeColor(isDark);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171A1D) : const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF282D33) : const Color(0xFFE1E4E8),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withAlpha(isDark ? 50 : 35),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: badgeColor,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
