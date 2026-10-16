import 'package:flutter/material.dart';
import '../models/session_mode.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

class SessionHistorySheet extends StatelessWidget {
  final SessionService sessionService;

  const SessionHistorySheet({
    super.key,
    required this.sessionService,
  });

  static Future<void> show(BuildContext context, SessionService sessionService) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SessionHistorySheet(sessionService: sessionService),
    );
  }

  String _formatSessionTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTotalTime(int totalMinutes) {
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return mins == 0 ? '${hours}h' : '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = sessionService.sessions;
    final totalFocusMins = sessionService.todayFocusMinutes;
    final totalSessions = sessionService.todayFocusCount;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x667A7F8D),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header with daily summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'TODAY',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatTotalTime(totalFocusMins),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            '$totalSessions completed focus ${totalSessions == 1 ? 'block' : 'blocks'}',
            style: theme.textTheme.bodyMedium,
          ),

          const SizedBox(height: 24),
          const Divider(color: Color(0x337A7F8D), height: 1),
          const SizedBox(height: 16),

          // Session timeline list
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'No sessions recorded yet.\nStart a focus session to begin tracking.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sessions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final isFocus = session.modeType == SessionModeType.focus;
                  final durationMin = (session.durationSeconds / 60).round();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFocus
                                  ? AppTheme.textPrimary
                                  : const Color(0xFF81E6D9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isFocus ? 'Focus Session' : 'Break',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '$durationMin m',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _formatSessionTime(session.completedAt),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
