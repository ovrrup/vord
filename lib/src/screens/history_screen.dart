import 'package:flutter/material.dart';
import '../models/session_mode.dart';
import '../models/study_session.dart';
import '../screens/data_backup_screen.dart';
import '../services/session_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/physical_matte_controls.dart';

/// Category and Session History Screen.
/// Displays categorized focus and rest logs with exact recorded times,
/// styled with razor-sharp industrial tape-recorder deck aesthetics.
class HistoryScreen extends StatefulWidget {
  final SessionService sessionService;

  const HistoryScreen({
    super.key,
    required this.sessionService,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Category filter: 0 = ALL, 1 = FOCUS, 2 = REST
  int _selectedCategoryIndex = 0;

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    }
    if (minutes > 0) {
      return '${minutes}m ${secs.toString().padLeft(2, '0')}s';
    }
    return '${secs}s';
  }

  String _formatTimestamp(DateTime dt) {
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = monthNames[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month ${dt.day} • $hour:$minute';
  }

  List<StudySession> _getFilteredSessions() {
    final all = widget.sessionService.sessions;
    if (_selectedCategoryIndex == 1) {
      return all.where((s) => s.modeType == SessionModeType.focus).toList();
    }
    if (_selectedCategoryIndex == 2) {
      return all.where((s) => s.modeType == SessionModeType.shortBreak).toList();
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final filteredSessions = _getFilteredSessions();
    final totalFocusSec = widget.sessionService.todayFocusSeconds;
    final bestFocusSec = widget.sessionService.todayBestFocusSeconds;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Sharp Tape Recorder Deck Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16191D) : const Color(0xFFF2F5F8),
                border: Border(
                  bottom: BorderSide(color: borderCol, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  // Sharp mechanical back transport button
                  SizedBox(
                    width: 44,
                    height: 38,
                    child: PhysicalMatteButton(
                      onTap: () {
                        SoundService.playTapeSwitchClick();
                        Navigator.pop(context);
                      },
                      borderRadius: 0.0,
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SESSION LOG & HISTORY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TAPE DECK RECORDER ARCHIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Backup shortcut button in header
                  SizedBox(
                    width: 44,
                    height: 38,
                    child: PhysicalMatteButton(
                      onTap: () {
                        SoundService.playTapeSwitchClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DataBackupScreen(sessionService: widget.sessionService),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      borderRadius: 0.0,
                      child: Center(
                        child: Icon(
                          Icons.storage_rounded,
                          size: 19,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Summary Stats Bar (Sharp industrial readout)
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141619) : const Color(0xFFF7F9FB),
                border: Border.all(color: borderCol, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL FOCUS TODAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(totalFocusSec),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.5,
                    height: 36,
                    color: borderCol,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BEST SESSION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(bestFocusSec),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Category Filter Selector (Sharp Tabs)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildCategoryTab(index: 0, label: 'ALL LOGS', isDark: isDark),
                  const SizedBox(width: 8),
                  _buildCategoryTab(index: 1, label: 'FOCUS SESSIONS', isDark: isDark),
                  const SizedBox(width: 8),
                  _buildCategoryTab(index: 2, label: 'REST INTERVALS', isDark: isDark),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 4. Session History List with Exact Recorded Time
            Expanded(
              child: filteredSessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.album_outlined,
                            size: 42,
                            color: textSecondary.withAlpha(120),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'NO RECORDED SESSIONS YET',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start a session from the main deck to record time.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: filteredSessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final session = filteredSessions[index];
                        final isFocus = session.modeType == SessionModeType.focus;
                        final durationStr = _formatDuration(session.durationSeconds);
                        final dateStr = _formatTimestamp(session.completedAt);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF181B1F) : const Color(0xFFFAFBFC),
                            border: Border.all(
                              color: isFocus
                                  ? (isDark ? const Color(0xFF28593D) : const Color(0xFFA8D5BA))
                                  : borderCol,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Category Tape Indicator
                              Container(
                                width: 4,
                                height: 32,
                                color: isFocus
                                    ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                    : (isDark ? const Color(0xFF8B949E) : const Color(0xFF656D76)),
                              ),
                              const SizedBox(width: 12),
                              // Category Tag & Timestamp
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isFocus ? 'FOCUS SESSION' : 'REST INTERVAL',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        color: isFocus
                                            ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                            : textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Recorded Time (High-Visibility Monospace Readout)
                              Text(
                                durationStr,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  SoundService.playTapeSwitchClick();
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                      title: Text(
                                        'DELETE ENTRY?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                          color: textPrimary,
                                        ),
                                      ),
                                      content: Text(
                                        'Delete this $durationStr ${isFocus ? "focus session" : "rest interval"}?',
                                        style: TextStyle(fontSize: 12, color: textSecondary),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: Text('CANCEL', style: TextStyle(color: textSecondary)),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text(
                                            'DELETE',
                                            style: TextStyle(color: Color(0xFFE5534B), fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    SoundService.playTapeTransportLatch();
                                    await widget.sessionService.deleteSession(session.id);
                                    setState(() {});
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: textSecondary.withAlpha(140),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab({
    required int index,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _selectedCategoryIndex == index;
    final activeBg = isDark ? const Color(0xFF1B2E24) : const Color(0xFFF2F9F3);
    final inactiveBg = isDark ? const Color(0xFF141619) : const Color(0xFFF4F6F9);
    final activeBorder = isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57);
    final inactiveBorder = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          SoundService.playTapeSwitchClick();
          setState(() => _selectedCategoryIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9.0),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            border: Border.all(
              color: isSelected ? activeBorder : inactiveBorder,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isSelected
                    ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
