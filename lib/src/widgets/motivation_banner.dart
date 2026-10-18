import 'package:flutter/material.dart';
import '../services/session_service.dart';

/// Component 1: Area where motivational info and self-competition insights are shown.
/// Designed modularly so it can easily be expanded with advanced analytics in the future.
class MotivationBanner extends StatelessWidget {
  final SessionService sessionService;
  final bool isFocusMode;

  const MotivationBanner({
    super.key,
    required this.sessionService,
    required this.isFocusMode,
  });

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getMotivationText() {
    if (!isFocusMode) {
      return 'Rest and recharge. Your next session awaits.';
    }

    final bestMinutes = sessionService.todayBestFocusMinutes;
    final totalMinutes = sessionService.todayFocusMinutes;

    if (bestMinutes > 0) {
      return 'Today\'s longest: ${bestMinutes}m • Compete to beat it';
    } else if (totalMinutes > 0) {
      return 'Session logged: ${totalMinutes}m • Keep building your focus';
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
                    greeting,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isFocusMode
                          ? (isDark
                              ? const Color(0x333FA36C)
                              : const Color(0x222E8B57))
                          : (isDark
                              ? const Color(0x338B949E)
                              : const Color(0x22656D76)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isFocusMode
                            ? (isDark
                                ? const Color(0xFF3FA36C)
                                : const Color(0xFF2E8B57))
                            : (isDark
                                ? const Color(0xFF8B949E)
                                : const Color(0xFF656D76)),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isFocusMode ? 'FOCUS' : 'REST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isFocusMode
                            ? (isDark
                                ? const Color(0xFF3FA36C)
                                : const Color(0xFF2E8B57))
                            : (isDark
                                ? const Color(0xFF8B949E)
                                : const Color(0xFF656D76)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                motivation,
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
