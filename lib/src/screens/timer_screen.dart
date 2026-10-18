import 'dart:async';
import 'package:flutter/material.dart';
import '../models/session_mode.dart';
import '../services/session_service.dart';
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
  Timer? _ticker;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isFocusMode = true; // Focus vs Rest mode

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    _sessionService.dispose();
    super.dispose();
  }

  void _startStopwatch() {
    _ticker?.cancel();
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

    // User requirement: "once pause is clicked the session will be saved"
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
    );
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // 1. Motivational & self-competition greeting banner
              MotivationBanner(
                sessionService: _sessionService,
                isFocusMode: _isFocusMode,
              ),

              // 2. Rotating physical matte disk with center-outward color spread
              Expanded(
                child: Center(
                  child: RetroMatteDisk(
                    elapsedSeconds: _elapsedSeconds,
                    isRunning: _isRunning,
                    isFocusMode: _isFocusMode,
                    animate: widget.animateBackground,
                    formattedTime: _formatTime(_elapsedSeconds),
                  ),
                ),
              ),

              // 3. Physical matte controls: Very large play/pause on left,
              //    Mode switch (1/3rd) + Settings (2/3rd) on right.
              BottomControls(
                isRunning: _isRunning,
                isPaused: _isPaused,
                isFocusMode: _isFocusMode,
                onPlayPause: _handlePlayPause,
                onToggleMode: _toggleMode,
                onOpenSettings: _openSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
