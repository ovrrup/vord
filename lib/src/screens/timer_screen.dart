import 'dart:async';
import 'package:flutter/material.dart';
import '../models/session_mode.dart';
import '../models/timer_status.dart';
import '../theme/app_theme.dart';
import '../widgets/mode_selector.dart';
import '../widgets/timer_ring.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  SessionMode _currentMode = SessionMode.focus;
  late int _totalSeconds;
  late int _remainingSeconds;
  TimerStatus _status = TimerStatus.ready;
  Timer? _timer;
  int _completedFocusSessions = 0;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _currentMode.durationSeconds;
    _remainingSeconds = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _switchMode(SessionMode mode) {
    if (_currentMode.type == mode.type && _status != TimerStatus.completed) {
      return;
    }
    _timer?.cancel();
    setState(() {
      _currentMode = mode;
      _totalSeconds = mode.durationSeconds;
      _remainingSeconds = _totalSeconds;
      _status = TimerStatus.ready;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _status = TimerStatus.running;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _handleSessionComplete();
      }
    });
  }

  void _handleSessionComplete() {
    setState(() {
      _status = TimerStatus.completed;
      if (_currentMode.type == SessionModeType.focus) {
        _completedFocusSessions++;
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _status = TimerStatus.paused;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _status = TimerStatus.ready;
    });
  }

  void _handleTap() {
    switch (_status) {
      case TimerStatus.ready:
      case TimerStatus.paused:
        _startTimer();
        break;
      case TimerStatus.running:
        _pauseTimer();
        break;
      case TimerStatus.completed:
        // Automatically switch to recommended next mode on tap
        if (_currentMode.type == SessionModeType.focus) {
          if (_completedFocusSessions % 4 == 0) {
            _switchMode(SessionMode.longBreak);
          } else {
            _switchMode(SessionMode.shortBreak);
          }
        } else {
          _switchMode(SessionMode.focus);
        }
        break;
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  String get _statusLabel {
    switch (_status) {
      case TimerStatus.ready:
        return 'Tap to begin ${_currentMode.label.toLowerCase()}';
      case TimerStatus.running:
        return '${_currentMode.label} • Tap to pause';
      case TimerStatus.paused:
        return 'Paused • Tap to resume';
      case TimerStatus.completed:
        return _currentMode.type == SessionModeType.focus
            ? 'Focus finished! Tap for break'
            : 'Break finished! Tap for focus';
    }
  }

  Color get _statusIndicatorColor {
    switch (_status) {
      case TimerStatus.ready:
        return AppTheme.textSecondary;
      case TimerStatus.running:
        return _currentMode.accentColor;
      case TimerStatus.paused:
        return const Color(0xFFE5A93C); // Warm amber
      case TimerStatus.completed:
        return const Color(0xFF68D391); // Soft calm green
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header: App Title & Focus Cycle Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'VORD',
                    style: theme.textTheme.labelLarge?.copyWith(
                      letterSpacing: 3.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Completed sessions in current 4-cycle
                  Row(
                    children: List.generate(4, (index) {
                      final isFilled = index < (_completedFocusSessions % 4);
                      return Container(
                        margin: const EdgeInsets.only(left: 6),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? AppTheme.textPrimary
                              : const Color(0x662E323D),
                        ),
                      );
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Mode Selector (Focus / Short Break / Long Break)
              ModeSelector(
                currentMode: _currentMode,
                onModeChanged: _switchMode,
              ),

              // Main Interactive Timer Display
              Expanded(
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _handleTap,
                    onLongPress: _resetTimer,
                    child: TimerRing(
                      progress: progress,
                      size: 280,
                      strokeWidth: 2.0,
                      accentColor: _currentMode.accentColor,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(_remainingSeconds),
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              _statusLabel,
                              key: ValueKey<String>('$_statusLabel-$_remainingSeconds'),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Bar: Status dot and subtle reset button
              SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _statusIndicatorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _status.name.toUpperCase(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.5,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    // Reset action when session is active or paused
                    if (_status != TimerStatus.ready)
                      TextButton(
                        onPressed: _resetTimer,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'RESET',
                          style: theme.textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.5,
                            fontSize: 11,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
