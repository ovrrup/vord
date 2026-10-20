import 'package:flutter/material.dart';
import '../services/app_settings_service.dart';
import '../services/behaviour_service.dart';
import '../services/smart_notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/physical_matte_controls.dart';

/// Clean, minimal screen allowing the user to configure system overlay toggles
/// (hide status bar, hide navigation bar) and squircle deck time counter.
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
                        // Toggle 1: Hide Status Bar (Device)
                        _buildToggleCard(
                          key: const Key('toggle_hide_status_bar'),
                          icon: Icons.visibility_off_rounded,
                          title: 'HIDE STATUS BAR (DEVICE)',
                          isEnabled: hideStatusBar,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onToggle: () =>
                              _service.setHideStatusBar(!hideStatusBar),
                        ),

                        const SizedBox(height: 12),

                        // Toggle 2: Hide Navigation Bar (Device)
                        _buildToggleCard(
                          key: const Key('toggle_hide_nav_bar'),
                          icon: Icons.navigation_rounded,
                          title: 'HIDE NAVIGATION BAR (DEVICE)',
                          isEnabled: hideNavBar,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onToggle: () => _service.setHideNavBar(!hideNavBar),
                        ),

                        const SizedBox(height: 12),

                        // Toggle 3: Show Time
                        _buildToggleCard(
                          key: const Key('toggle_show_time'),
                          icon: Icons.schedule_rounded,
                          title: 'SHOW TIME COUNTER',
                          isEnabled: showTime,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          onToggle: () => _service.setShowTime(!showTime),
                        ),

                        const SizedBox(height: 12),

                        // Toggle 4: Smart Study Reminders
                        ListenableBuilder(
                          listenable: AppSettingsService.instance,
                          builder: (context, _) {
                            final notificationsEnabled =
                                AppSettingsService.instance.notificationsEnabled;
                            final optimalHour = SmartNotificationService
                                .instance.optimalFocusHour;
                            final formattedHour =
                                FocusTimingAnalyzer.formatHour(optimalHour);

                            return _buildToggleCard(
                              key: const Key('toggle_smart_notifications'),
                              icon: Icons.notifications_active_rounded,
                              title: 'SMART STUDY REMINDERS',
                              subtitle:
                                  'Analyzes study habits · Peak focus at $formattedHour',
                              isEnabled: notificationsEnabled,
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              onToggle: () async {
                                final current = notificationsEnabled;
                                if (!current) {
                                  await SmartNotificationService.instance
                                      .requestPermissions();
                                  await AppSettingsService.instance
                                      .setNotificationsEnabled(true);
                                  await SmartNotificationService.instance
                                      .scheduleSmartReminder();
                                } else {
                                  await AppSettingsService.instance
                                      .setNotificationsEnabled(false);
                                  await SmartNotificationService.instance
                                      .cancelAllReminders();
                                }
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Test Instant Notification Action
                        PhysicalMatteButton(
                          key: const Key('test_instant_notification'),
                          onTap: () async {
                            await SmartNotificationService.instance
                                .showInstantReminder();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Test study reminder notification triggered.',
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
                            horizontal: 16.0,
                            vertical: 13.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none_rounded,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFF3FA36C)
                                    : const Color(0xFF2E8B57),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'TEST REMINDER NOTIFICATION',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Restore Defaults Button
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
    required IconData icon,
    required String title,
    String? subtitle,
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isEnabled ? activeColor : textSecondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Tactile Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
