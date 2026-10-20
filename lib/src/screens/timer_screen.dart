import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/session_mode.dart';
import '../services/behaviour_service.dart';
import '../services/session_service.dart';
import '../services/sound_service.dart';
import '../widgets/motivation_banner.dart';
import '../widgets/physical_matte_controls.dart';
import '../widgets/retro_matte_disk.dart';

class TimerScreen extends StatefulWidget {
  final bool animateBackground;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final BehaviourService? behaviourService;

  const TimerScreen({
    super.key,
    this.animateBackground = true,
    this.currentThemeMode = ThemeMode.light,
    required this.onThemeChanged,
    this.behaviourService,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  final SessionService _sessionService = SessionService.instance;
  final Stopwatch _stopwatch = Stopwatch();
  final math.Random _random = math.Random();

  Timer? _ticker;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _isFocusMode = true; // Focus vs Rest mode

  // Dynamic self-competition milestones
  int _baselineSeconds = 1200; // Default 20m baseline
  int _extra3Seconds = 180; // Stage 3 extra time (120-240s)
  int _extra4Seconds = 240; // Stage 4 extra time (180-360s)

  BehaviourService get _behaviourService =>
      widget.behaviourService ?? BehaviourService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoundService.init();
    _behaviourService.addListener(_onBehaviourChanged);
    _behaviourService.applySystemUiMode();
    _checkAndRestoreActiveSession();
  }

  Future<void> _checkAndRestoreActiveSession() async {
    await _sessionService.ready;
    final active = await _sessionService.loadActiveSession();
    if (active == null || !mounted) return;

    final elapsed = active.elapsedSeconds;
    if (elapsed <= 0) return;

    if (elapsed < 14400) {
      setState(() {
        _isFocusMode = active.modeType == SessionModeType.focus;
        _baselineSeconds = active.baselineSeconds;
        _extra3Seconds = active.extra3Seconds;
        _extra4Seconds = active.extra4Seconds;
        _elapsedSeconds = elapsed;
        _isRunning = true;
      });

      _stopwatch.reset();
      _stopwatch.start();
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _elapsedSeconds = active.elapsedSeconds;
        });
      });
    } else {
      await _sessionService.recordSession(
        active.modeType,
        active.baselineSeconds,
      );
      await _sessionService.clearActiveSession();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRunning) {
      final active = _sessionService.activeSession;
      if (active != null && mounted) {
        setState(() {
          _elapsedSeconds = active.elapsedSeconds;
        });
      }
    }
  }

  void _onBehaviourChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _behaviourService.removeListener(_onBehaviourChanged);
    _ticker?.cancel();
    _stopwatch.stop();
    SoundService.dispose();
    super.dispose();
  }

  void _startStopwatch() {
    _ticker?.cancel();
    _stopwatch.reset();
    _stopwatch.start();

    // Compute baseline and randomized extensions for this session
    _baselineSeconds = _sessionService.lastFocusDurationSeconds;
    _extra3Seconds =
        120 + _random.nextInt(121); // 120 to 240 seconds (2 to 4 min)
    _extra4Seconds =
        180 + _random.nextInt(181); // 180 to 360 seconds (3 to 6 min)

    setState(() {
      _elapsedSeconds = 0;
      _isRunning = true;
    });

    final now = DateTime.now();
    _sessionService.saveActiveSession(
      startTime: now,
      modeType: _isFocusMode ? SessionModeType.focus : SessionModeType.shortBreak,
      baselineSeconds: _baselineSeconds,
      extra3Seconds: _extra3Seconds,
      extra4Seconds: _extra4Seconds,
    );

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

  void _stopStopwatch() {
    _ticker?.cancel();
    _stopwatch.stop();
    _sessionService.clearActiveSession();

    // Save session upon stop immediately
    if (_elapsedSeconds > 0) {
      if (_isFocusMode) {
        _sessionService.recordSession(SessionModeType.focus, _elapsedSeconds);
      } else {
        _sessionService.recordSession(
          SessionModeType.shortBreak,
          _elapsedSeconds,
        );
      }
    }

    // Reset when stopped so the stopwatch cleanly resets to 0
    _stopwatch.reset();
    setState(() {
      _elapsedSeconds = 0;
      _isRunning = false;
    });
  }

  void _handlePlayPause() {
    if (_isRunning) {
      _stopStopwatch();
    } else {
      _startStopwatch();
    }
  }

  void _toggleMode() {
    // If running when toggled, save session and reset
    if (_isRunning) {
      _sessionService.clearActiveSession();
      if (_elapsedSeconds > 0) {
        if (_isFocusMode) {
          _sessionService.recordSession(SessionModeType.focus, _elapsedSeconds);
        } else {
          _sessionService.recordSession(
            SessionModeType.shortBreak,
            _elapsedSeconds,
          );
        }
      }
      _ticker?.cancel();
      _stopwatch.reset();
    }

    setState(() {
      _isFocusMode = !_isFocusMode;
      _elapsedSeconds = 0;
      _isRunning = false;
    });
  }

  void _openOptions() {
    OptionsSheet.show(
      context,
      currentThemeMode: widget.currentThemeMode,
      onThemeChanged: widget.onThemeChanged,
      sessionService: _sessionService,
    );
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Component 1: Minimal motivation greeting banner
              MotivationBanner(
                sessionService: _sessionService,
                isFocusMode: _isFocusMode,
                isRunning: _isRunning,
                isPaused: false,
              ),

              // Component 2: Squircle deck housing rotating spool disk, corner bolts, and 4 box lights
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
                    showTime: _behaviourService.showTime,
                  ),
                ),
              ),

              // Component 3: Big solid realistic matte controls
              BottomControls(
                isRunning: _isRunning,
                isPaused: false,
                isFocusMode: _isFocusMode,
                onPlayPause: _handlePlayPause,
                onToggleMode: _toggleMode,
                onOpenOptions: _openOptions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
