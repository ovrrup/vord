import 'package:flutter/material.dart';
import '../screens/history_screen.dart';
import '../services/session_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

/// Reusable physical matte button styled as a razor-sharp vintage tape recorder transport key.
/// Features sharp 90-degree industrial corners, mechanical travel depression,
/// and plays real mechanical solenoid / switch click audio.
class PhysicalMatteButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isTransportKey;

  const PhysicalMatteButton({
    super.key,
    required this.onTap,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 0.0,
    this.padding = EdgeInsets.zero,
    this.isTransportKey = false,
  });

  @override
  State<PhysicalMatteButton> createState() => _PhysicalMatteButtonState();
}

class _PhysicalMatteButtonState extends State<PhysicalMatteButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    if (widget.isTransportKey) {
      SoundService.playTapeTransportLatch();
    } else {
      SoundService.playTapeSwitchClick();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isDark ? const Color(0xFF181B20) : const Color(0xFFF2F5F8);
    final borderCol = widget.borderColor ?? (isDark ? const Color(0xFF2C323A) : const Color(0xFFCBD2DA));
    final bg = widget.backgroundColor ?? defaultBg;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 40),
        margin: EdgeInsets.only(
          top: _isPressed ? 4.0 : 0.0,
          bottom: _isPressed ? 0.0 : 4.0,
        ),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _isPressed
              ? (isDark ? const Color(0xFF121417) : const Color(0xFFE2E7ED))
              : bg,
          borderRadius: widget.borderRadius > 0 ? BorderRadius.circular(widget.borderRadius) : BorderRadius.zero,
          border: Border.all(
            color: borderCol,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0xFF08090A) : const Color(0xFFB0B8C2),
              offset: Offset(0, _isPressed ? 0.0 : 4.0),
              blurRadius: 0,
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Component 3: Controls styled strictly as razor-sharp tape recorder transport keys.
/// - Left: Very large Play / Pause / Resume transport key (with solenoid latch sound).
/// - Right: Mode Switch (1/3rd size) on top + Settings (2/3rd size) on bottom.
class BottomControls extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final bool isFocusMode;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleMode;
  final VoidCallback onOpenSettings;

  const BottomControls({
    super.key,
    required this.isRunning,
    required this.isPaused,
    required this.isFocusMode,
    required this.onPlayPause,
    required this.onToggleMode,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const controlsHeight = 120.0;
    const buttonSpacing = 8.0;

    final availableRightHeight = controlsHeight - buttonSpacing;
    final modeButtonHeight = availableRightHeight * (1.0 / 3.0);
    final settingsButtonHeight = availableRightHeight * (2.0 / 3.0);

    return SizedBox(
      height: controlsHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Very Large Tape Recorder Transport Key (Left: Play/Pause/Resume)
          Expanded(
            flex: 3,
            child: PhysicalMatteButton(
              onTap: onPlayPause,
              isTransportKey: true,
              borderRadius: 0.0,
              backgroundColor: isRunning
                  ? (isDark ? const Color(0xFF1B261E) : const Color(0xFFEAF5EE))
                  : (isDark ? const Color(0xFF191D22) : const Color(0xFFF4F6F9)),
              borderColor: isRunning
                  ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                  : (isDark ? const Color(0xFF2C323A) : const Color(0xFFD0D7DE)),
              child: Stack(
                children: [
                  // Tape Deck Active Transport Tally Lamp (glow strip when running)
                  if (isRunning)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 3,
                      child: Container(
                        color: isDark
                            ? const Color(0xFF3FA36C)
                            : const Color(0xFF2E8B57),
                      ),
                    ),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isRunning
                              ? Icons.pause_rounded
                              : (isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.play_arrow_rounded),
                          size: 38,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isRunning
                              ? 'PAUSE'
                              : (isPaused ? 'RESUME' : 'START'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: buttonSpacing),

          // 2. Right Side Column: Tape Deck Selector Switches
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Top: Mode Switch Key (exactly 1/3rd height)
                SizedBox(
                  height: modeButtonHeight,
                  width: double.infinity,
                  child: PhysicalMatteButton(
                    onTap: onToggleMode,
                    borderRadius: 0.0,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            color: isFocusMode
                                ? (isDark
                                    ? const Color(0xFF3FA36C)
                                    : const Color(0xFF2E8B57))
                                : (isDark
                                    ? const Color(0xFF8B949E)
                                    : const Color(0xFF656D76)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isFocusMode ? 'FOCUS' : 'REST',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: buttonSpacing),

                // Bottom: Settings Key (exactly 2/3rd height)
                SizedBox(
                  height: settingsButtonHeight,
                  width: double.infinity,
                  child: PhysicalMatteButton(
                    onTap: onOpenSettings,
                    borderRadius: 0.0,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'SETTINGS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sharp Settings Modal with direct Category & Session History access and Theme controls.
class ThemeSettingsSheet extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final SessionService sessionService;

  const ThemeSettingsSheet({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
    required this.sessionService,
  });

  static Future<void> show(
    BuildContext context, {
    required ThemeMode currentThemeMode,
    required ValueChanged<ThemeMode> onThemeChanged,
    required SessionService sessionService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ThemeSettingsSheet(
        currentThemeMode: currentThemeMode,
        onThemeChanged: onThemeChanged,
        sessionService: sessionService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(
          color: borderCol,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sharp machine drag handle
          Center(
            child: Container(
              width: 40,
              height: 3,
              color: isDark ? const Color(0xFF404854) : const Color(0xFFC0C7D0),
            ),
          ),
          const SizedBox(height: 18),

          // CATEGORIES & HISTORY OPTION
          Text(
            'DATA & CATEGORIES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          PhysicalMatteButton(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(sessionService: sessionService),
                ),
              );
            },
            borderRadius: 0.0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SESSION HISTORY & TIME LOGS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View recorded focus times & rest intervals',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // THEME SETTINGS
          Text(
            'THEME SETTING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          _buildThemeOption(
            context,
            label: 'White Mode (Light)',
            icon: Icons.light_mode_outlined,
            mode: ThemeMode.light,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildThemeOption(
            context,
            label: 'Black Theme (Dark)',
            icon: Icons.dark_mode_outlined,
            mode: ThemeMode.dark,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildThemeOption(
            context,
            label: 'System Default',
            icon: Icons.brightness_auto_outlined,
            mode: ThemeMode.system,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required bool isDark,
  }) {
    final isSelected = currentThemeMode == mode;

    return PhysicalMatteButton(
      onTap: () {
        onThemeChanged(mode);
        Navigator.pop(context);
      },
      borderRadius: 0.0,
      backgroundColor: isSelected
          ? (isDark
              ? const Color(0xFF1B2E24)
              : const Color(0xFFF2F9F3))
          : (isDark
              ? AppTheme.darkSurface
              : AppTheme.lightSurface),
      borderColor: isSelected
          ? (isDark
              ? const Color(0xFF3FA36C)
              : const Color(0xFF2E8B57))
          : (isDark
              ? AppTheme.darkBorder
              : AppTheme.lightBorder),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected
                ? (isDark
                    ? const Color(0xFF3FA36C)
                    : const Color(0xFF2E8B57))
                : (isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? (isDark
                        ? const Color(0xFF3FA36C)
                        : const Color(0xFF2E8B57))
                    : (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary),
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: isDark
                  ? const Color(0xFF3FA36C)
                  : const Color(0xFF2E8B57),
            ),
        ],
      ),
    );
  }
}
