import 'package:flutter/material.dart';
import '../screens/data_backup_screen.dart';
import '../screens/history_screen.dart';
import '../screens/info_updates_screen.dart';
import '../services/session_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

/// Reusable physical matte button with solid physical presence,
/// deep mechanical travel depression, and real mechanical latch/click audio.
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
    if (_isPressed) return;
    setState(() => _isPressed = true);
    if (widget.isTransportKey) {
      SoundService.playTapeTransportLatch();
    } else {
      SoundService.playTapeSwitchClick();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isPressed) return;
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    if (!_isPressed) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isDark ? const Color(0xFF1B1E23) : const Color(0xFFF0F3F7);
    final borderCol = widget.borderColor ?? (isDark ? const Color(0xFF2C323B) : const Color(0xFFCAD1D9));
    final bg = widget.backgroundColor ?? defaultBg;

    final shadowHard = isDark ? const Color(0xFF090A0C) : const Color(0xFFA8B1BB);
    final shadowAmbient = isDark ? const Color(0x66000000) : const Color(0x22000000);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 35),
        margin: EdgeInsets.only(
          top: _isPressed ? 5.5 : 0.0,
          bottom: _isPressed ? 0.0 : 5.5,
        ),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _isPressed
              ? (isDark ? const Color(0xFF131518) : const Color(0xFFDFE4EA))
              : bg,
          borderRadius: widget.borderRadius > 0
              ? BorderRadius.circular(widget.borderRadius)
              : BorderRadius.zero,
          border: Border.all(
            color: borderCol,
            width: 1.5,
          ),
          boxShadow: [
            // Solid physical extrusion edge
            BoxShadow(
              color: shadowHard,
              offset: Offset(0, _isPressed ? 1.0 : 5.5),
              blurRadius: 0,
            ),
            // Diffuse ambient contact shadow
            if (!_isPressed)
              BoxShadow(
                color: shadowAmbient,
                offset: const Offset(0, 8.0),
                blurRadius: 12.0,
              ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Component 3: Big, minimal, solid realistic matte controls.
/// - Left: A very very large Play / Pause / Resume button.
/// - Right: Mode switch button (top, exactly 1/3rd size) and Options button (bottom, exactly 2/3rd size).
class BottomControls extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final bool isFocusMode;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleMode;
  final VoidCallback? onOpenOptions;
  final VoidCallback? onOpenSettings;

  const BottomControls({
    super.key,
    required this.isRunning,
    required this.isPaused,
    required this.isFocusMode,
    required this.onPlayPause,
    required this.onToggleMode,
    this.onOpenOptions,
    this.onOpenSettings,
  });

  VoidCallback get _openOptions => onOpenOptions ?? onOpenSettings ?? () {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const controlsHeight = 135.0;
    const buttonSpacing = 10.0;

    const availableRightHeight = controlsHeight - buttonSpacing;
    const modeButtonHeight = availableRightHeight * (1.0 / 3.0);
    const settingsButtonHeight = availableRightHeight * (2.0 / 3.0);

    return SizedBox(
      height: controlsHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Very Very Large Play / Pause / Resume Button (Left)
          Expanded(
            flex: 3,
            child: PhysicalMatteButton(
              onTap: onPlayPause,
              isTransportKey: true,
              borderRadius: 0.0,
              backgroundColor: isRunning
                  ? (isDark ? const Color(0xFF1B271F) : const Color(0xFFE9F5ED))
                  : (isDark ? const Color(0xFF1C2025) : const Color(0xFFF4F6F9)),
              borderColor: isRunning
                  ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                  : (isDark ? const Color(0xFF2E353F) : const Color(0xFFCFD6DE)),
              child: Stack(
                children: [
                  // Discrete solid active indicator bar along the top edge
                  if (isRunning)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 3.5,
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
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          size: 42,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isRunning ? 'STOP' : 'START',
                          style: TextStyle(
                            fontSize: 24,
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

          // 2. Right Side Column: Mode Switch (1/3rd) & Options (2/3rd)
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Top: Mode Switch Button (exactly 1/3rd size)
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
                              fontSize: 11.5,
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

                // Bottom: Options Button (exactly 2/3rd size)
                SizedBox(
                  height: settingsButtonHeight,
                  width: double.infinity,
                  child: PhysicalMatteButton(
                    onTap: _openOptions,
                    borderRadius: 0.0,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 22,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'OPTIONS',
                            style: TextStyle(
                              fontSize: 10.5,
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

/// Solid, clean Options Modal with Category History, Data & Backup, Info & Updates, Sound FX, and Theme controls.
class OptionsSheet extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final SessionService sessionService;

  const OptionsSheet({
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
      builder: (context) => OptionsSheet(
        currentThemeMode: currentThemeMode,
        onThemeChanged: onThemeChanged,
        sessionService: sessionService,
      ),
    );
  }

  @override
  State<OptionsSheet> createState() => _OptionsSheetState();
}

typedef ThemeSettingsSheet = OptionsSheet;

class _OptionsSheetState extends State<OptionsSheet> {
  late bool _soundEnabled;
  late bool _hapticEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = SoundService.soundEnabled;
    _hapticEnabled = SoundService.hapticEnabled;
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(
          color: borderCol,
          width: 1.5,
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  color: isDark ? const Color(0xFF404854) : const Color(0xFFC0C7D0),
                ),
              ),
              const SizedBox(height: 16),

              // 1. DATA & ARCHIVES
              Text(
                'DATA & ARCHIVES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              // History button
              PhysicalMatteButton(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryScreen(sessionService: widget.sessionService),
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
                      child: Text(
                        'SESSION HISTORY',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: textPrimary,
                        ),
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

              const SizedBox(height: 8),

              // Data & Backup button
              PhysicalMatteButton(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DataBackupScreen(sessionService: widget.sessionService),
                    ),
                  );
                },
                borderRadius: 0.0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.storage_rounded,
                      size: 20,
                      color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'DATA & BACKUP',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: textPrimary,
                        ),
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

              const SizedBox(height: 20),

              // 2. SYSTEM & UPDATES
              Text(
                'SYSTEM & UPDATES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              // Info & Updates button
              PhysicalMatteButton(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InfoUpdatesScreen(sessionService: widget.sessionService),
                    ),
                  );
                },
                borderRadius: 0.0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'INFO & UPDATES',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: textPrimary,
                        ),
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

              const SizedBox(height: 20),

              // 3. SOUND & HAPTICS
              Text(
                'SOUND & HAPTICS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: PhysicalMatteButton(
                      onTap: () {
                        final next = !_soundEnabled;
                        setState(() => _soundEnabled = next);
                        SoundService.setSoundEnabled(next);
                      },
                      borderRadius: 0.0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            size: 18,
                            color: _soundEnabled
                                ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                : textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'SOUND FX',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            _soundEnabled ? 'ON' : 'OFF',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: _soundEnabled
                                  ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                  : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PhysicalMatteButton(
                      onTap: () {
                        final next = !_hapticEnabled;
                        setState(() => _hapticEnabled = next);
                        SoundService.setHapticEnabled(next);
                      },
                      borderRadius: 0.0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            _hapticEnabled ? Icons.vibration_rounded : Icons.smartphone_rounded,
                            size: 18,
                            color: _hapticEnabled
                                ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                : textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'HAPTICS',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            _hapticEnabled ? 'ON' : 'OFF',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: _hapticEnabled
                                  ? (isDark ? const Color(0xFF3FA36C) : const Color(0xFF2E8B57))
                                  : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. THEME OPTIONS
              Text(
                'THEME OPTIONS',
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
        ),
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
    final isSelected = widget.currentThemeMode == mode;

    return PhysicalMatteButton(
      onTap: () {
        widget.onThemeChanged(mode);
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
