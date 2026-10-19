import 'package:flutter/material.dart';
import '../services/behaviour_service.dart';
import '../theme/app_theme.dart';
import '../widgets/physical_matte_controls.dart';

/// Screen allowing the user to configure system overlay toggles (status bar, navigation bar)
/// and deck readouts (45° tilted time counter).
class BehaviourScreen extends StatelessWidget {
  final BehaviourService? behaviourService;

  const BehaviourScreen({super.key, this.behaviourService});

  BehaviourService get _service =>
      behaviourService ?? BehaviourService.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF16191D)
                    : const Color(0xFFF2F5F8),
                border: Border(
                  bottom: BorderSide(color: borderCol, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 38,
                    child: PhysicalMatteButton(
                      onTap: () => Navigator.pop(context),
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
                    child: Text(
                      'BEHAVIOUR',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Content Scroll Area
            Expanded(
              child: ListenableBuilder(
                listenable: _service,
                builder: (context, _) {
                  final hideStatusBar = _service.hideStatusBar;
                  final hideNavBar = _service.hideNavBar;
                  final showTime = _service.showTime;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Subtitle Telemetry Bar
                        Container(
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF16191D)
                                : const Color(0xFFF2F5F8),
                            border: Border.all(color: borderCol, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 16,
                                    color: isDark
                                        ? const Color(0xFF3FA36C)
                                        : const Color(0xFF2E8B57),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SYSTEM OVERLAYS & DECK READOUTS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Manage device immersion, full-screen system overlays, and squircle deck time counter.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Section 1: DEVICE SYSTEM BARS
                        Text(
                          'DEVICE SYSTEM BARS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Toggle 1: Hide Status Bar (Device)
                        _buildToggleCard(
                          key: const Key('toggle_hide_status_bar'),
                          title: 'HIDE STATUS BAR (DEVICE)',
                          subtitle:
                              'Hides top device status bar for immersive focus.',
                          badgeLabel: 'DEFAULT: ON',
                          isEnabled: hideStatusBar,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onToggle: () =>
                              _service.setHideStatusBar(!hideStatusBar),
                        ),

                        const SizedBox(height: 10),

                        // Toggle 2: Hide Navigation Bar (Device)
                        _buildToggleCard(
                          key: const Key('toggle_hide_nav_bar'),
                          title: 'HIDE NAVIGATION BAR (DEVICE)',
                          subtitle:
                              'Hides system navigation gestures / soft keys.',
                          badgeLabel: 'DEFAULT: OFF',
                          isEnabled: hideNavBar,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onToggle: () => _service.setHideNavBar(!hideNavBar),
                        ),

                        const SizedBox(height: 24),

                        // Section 2: SQUIRCLE DECK READOUTS
                        Text(
                          'SQUIRCLE DECK READOUTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Toggle 3: Show Time
                        _buildToggleCard(
                          key: const Key('toggle_show_time'),
                          title: 'SHOW TIME COUNTER',
                          subtitle:
                              'Displays a 45° tilted counter (hh:mm or mm:ss) in the top-left of the squircle deck.',
                          badgeLabel: 'DEFAULT: OFF',
                          isEnabled: showTime,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onToggle: () => _service.setShowTime(!showTime),
                        ),

                        const SizedBox(height: 28),

                        // Reset Button
                        PhysicalMatteButton(
                          key: const Key('reset_behaviour_defaults'),
                          onTap: () async {
                            await _service.resetToDefaults();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Reset behaviour preferences to defaults.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: isDark
                                      ? const Color(0xFF1E242B)
                                      : const Color(0xFF2C323B),
                                ),
                              );
                            }
                          },
                          borderRadius: 0.0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.restart_alt_rounded,
                                  size: 18,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'RESTORE DEFAULTS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
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

  Widget _buildToggleCard({
    required Key key,
    required String title,
    required String subtitle,
    required String badgeLabel,
    required bool isEnabled,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onToggle,
  }) {
    final activeColor = isDark
        ? const Color(0xFF3FA36C)
        : const Color(0xFF2E8B57);
    final inactiveColor = isDark
        ? const Color(0xFF48515E)
        : const Color(0xFF9AA4B2);

    return PhysicalMatteButton(
      key: key,
      onTap: onToggle,
      borderRadius: 0.0,
      padding: const EdgeInsets.all(14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B2026)
                            : const Color(0xFFE4E9EF),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2E3640)
                              : const Color(0xFFCAD1DA),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Tactile Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isEnabled
                  ? (isDark ? const Color(0xFF142B1E) : const Color(0xFFE2F3E9))
                  : (isDark
                        ? const Color(0xFF181B20)
                        : const Color(0xFFE8ECEF)),
              border: Border.all(
                color: isEnabled ? activeColor : inactiveColor,
                width: 1.2,
              ),
            ),
            child: Text(
              isEnabled ? 'ON' : 'OFF',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: isEnabled ? activeColor : textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
