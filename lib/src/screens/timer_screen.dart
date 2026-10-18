import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/session_mode.dart';
import '../services/session_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/motivation_banner.dart';
import '../widgets/physical_matte_controls.dart';
import '../widgets/retro_matte_disk.dart';

class TimerScreen extends StatefulWidget {
  final bool animateBackground;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const TimerScreen({
    super.key,
    this.animateBackground = true,
    this.currentThemeMode = ThemeMode.light,
    required this.onThemeChanged,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final SessionService _sessionService = SessionService();
  final Stopwatch _stopwatch = Stopwatch();
  final math.Random _random = math.Random();

  Timer? _ticker;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isFocusMode = true; // Focus vs Rest mode

  // Dynamic self-competition milestones
  int _baselineSeconds = 1200; // Default 20m baseline
  int _extra3Seconds = 180;    // Stage 3 extra time (120-240s)
  int _extra4Seconds = 240;    // Stage 4 extra time (180-360s)

  @override
  void initState() {
    super.initState();
    SoundService.init();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    _sessionService.dispose();
    SoundService.dispose();
    super.dispose();
  }

  void _startStopwatch() {
    _ticker?.cancel();

    // If starting a fresh session (not resuming), compute baseline and randomized extensions
    if (!_isPaused) {
      _baselineSeconds = _sessionService.lastFocusDurationSeconds;
      _extra3Seconds = 120 + _random.nextInt(121); // 120 to 240 seconds (2 to 4 min)
      _extra4Seconds = 180 + _random.nextInt(181); // 180 to 360 seconds (3 to 6 min)
    }

    _stopwatch.start();
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedSeconds = _stopwatch.elapsed.inSeconds;
      });
    });
  }

  void _pauseStopwatch() {
    _ticker?.cancel();
    _stopwatch.stop();

    // Save session upon pause
    if (_isFocusMode && _elapsedSeconds > 0) {
      _sessionService.recordSession(SessionModeType.focus, _elapsedSeconds);
    } else if (!_isFocusMode && _elapsedSeconds > 0) {
      _sessionService.recordSession(SessionModeType.shortBreak, _elapsedSeconds);
    }

    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _handlePlayPause() {
    if (_isRunning) {
      _pauseStopwatch();
    } else {
      _startStopwatch();
    }
  }

  void _toggleMode() {
    // If running or paused, save session and reset
    if (_isRunning || _isPaused) {
      if (_isFocusMode && _elapsedSeconds > 0) {
        _sessionService.recordSession(SessionModeType.focus, _elapsedSeconds);
      } else if (!_isFocusMode && _elapsedSeconds > 0) {
        _sessionService.recordSession(SessionModeType.shortBreak, _elapsedSeconds);
      }
      _ticker?.cancel();
      _stopwatch.reset();
    }

    setState(() {
      _isFocusMode = !_isFocusMode;
      _elapsedSeconds = 0;
      _isRunning = false;
      _isPaused = false;
    });
  }

  void _openSettings() {
    ThemeSettingsSheet.show(
      context,
      currentThemeMode: widget.currentThemeMode,
      onThemeChanged: widget.onThemeChanged,
      sessionService: _sessionService,
    );
  }

  Widget _buildChassisScrew(bool isDark) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF24282E) : const Color(0xFFD6DCE2),
        border: Border.all(
          color: isDark ? const Color(0xFF3E4550) : const Color(0xFF9AA4B0),
          width: 1.0,
        ),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 1.2,
          color: isDark ? const Color(0xFF0F1114) : const Color(0xFF5A626E),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
          child: Column(
            children: [
              // Sharp Tape Deck Top Faceplate Header with corner screws
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildChassisScrew(isDark),
                  Text(
                    'VORD • MASTER TAPE TRANSPORT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  _buildChassisScrew(isDark),
                ],
              ),

              const SizedBox(height: 8),

              // 1. Motivation greeting banner (sharp & minimal, zero time display)
              MotivationBanner(
                sessionService: _sessionService,
                isFocusMode: _isFocusMode,
                isRunning: _isRunning,
                isPaused: _isPaused,
              ),

              // 2. Sharp tape recorder spool disk with center-outward color spread
              // (NO digital time on the disk - time is viewed in Category & History under Settings)
              Expanded(
                child: Center(
                  child: RetroMatteDisk(
                    elapsedSeconds: _elapsedSeconds,
                    isRunning: _isRunning,
                    isFocusMode: _isFocusMode,
                    animate: widget.animateBackground,
                    baselineSeconds: _baselineSeconds,
                    extra3Seconds: _extra3Seconds,
                    extra4Seconds: _extra4Seconds,
                  ),
                ),
              ),

              // 3. Razor-sharp physical tape recorder controls
              BottomControls(
                isRunning: _isRunning,
                isPaused: _isPaused,
                isFocusMode: _isFocusMode,
                onPlayPause: _handlePlayPause,
                onToggleMode: _toggleMode,
                onOpenSettings: _openSettings,
              ),

              const SizedBox(height: 8),

              // Tape Deck Bottom Chassis Screws
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildChassisScrew(isDark),
                  Text(
                    'MODEL TC-01 • HIGH BIAS',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary).withAlpha(150),
                    ),
                  ),
                  _buildChassisScrew(isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
