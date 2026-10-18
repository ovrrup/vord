import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

/// Reusable physical matte button styled as a vintage tape recorder transport key.
/// Features authentic mechanical chamfers, physical key travel depression,
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
    this.borderRadius = 8.0,
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

    final defaultBg = isDark ? const Color(0xFF191C20) : const Color(0xFFF2F5F8);
    final topHighlight = isDark ? const Color(0xFF323840) : const Color(0xFFFFFFFF);
    final bottomShadow = isDark ? const Color(0xFF0D0E10) : const Color(0xFFBAC2CB);
    final borderCol = widget.borderColor ?? (isDark ? const Color(0xFF282D33) : const Color(0xFFCBD2DA));

    final bg = widget.backgroundColor ?? defaultBg;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        margin: EdgeInsets.only(
          top: _isPressed ? 3.5 : 0.0,
          bottom: _isPressed ? 0.0 : 3.5,
        ),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _isPressed
              ? (isDark ? const Color(0xFF141619) : const Color(0xFFE2E7ED))
              : bg,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border(
            top: BorderSide(
              color: _isPressed ? borderCol : topHighlight,
              width: 1.5,
            ),
            left: BorderSide(
              color: borderCol,
              width: 1.5,
            ),
            right: BorderSide(
              color: borderCol,
              width: 1.5,
            ),
            bottom: BorderSide(
              color: _isPressed ? borderCol : bottomShadow,
              width: _isPressed ? 1.5 : 3.0,
            ),
          ),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: isDark ? const Color(0xFF08090A) : const Color(0xFFB0B8C2),
                offset: const Offset(0, 3.0),
                blurRadius: 0,
              ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Component 3: Controls styled strictly as vintage tape recorder transport keys.
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

    const controlsHeight = 118.0;
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
              borderRadius: 10.0,
              backgroundColor: isRunning
                  ? (isDark ? const Color(0xFF1E2620) : const Color(0xFFEAF5EE))
                  : (isDark ? const Color(0xFF1C1F24) : const Color(0xFFF4F6F9)),
              borderColor: isRunning
                  ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                  : (isDark ? const Color(0xFF2C323A) : const Color(0xFFD0D7DE)),
              child: Stack(
                children: [
                  // Tape Deck Active Transport Tally Lamp (glow strip when running)
                  if (isRunning)
                    Positioned(
                      top: 4,
                      left: 12,
                      right: 12,
                      height: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3FA36C)
                              : const Color(0xFF2E8B57),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
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
                    borderRadius: 8.0,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFocusMode
                                  ? (isDark
                                      ? const Color(0xFF3FA36C)
                                      : const Color(0xFF2E8B57))
                                  : (isDark
                                      ? const Color(0xFF8B949E)
                                      : const Color(0xFF656D76)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isFocusMode ? 'FOCUS' : 'REST',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
                    borderRadius: 8.0,
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
                              fontWeight: FontWeight.w700,
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

/// Theme settings modal with Dark, Light, and System choices.
class ThemeSettingsSheet extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const ThemeSettingsSheet({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required ThemeMode currentThemeMode,
    required ValueChanged<ThemeMode> onThemeChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ThemeSettingsSheet(
        currentThemeMode: currentThemeMode,
        onThemeChanged: onThemeChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1.5,
        ),
      ),
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
                color: isDark
                    ? const Color(0xFF40464E)
                    : const Color(0xFFD0D7DE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'THEME SETTING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 14),

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
      borderRadius: 10.0,
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
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
