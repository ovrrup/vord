import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'app_settings_service.dart';

/// Service providing authentic physical tape recorder mechanical sounds
/// for transport keys and switches, with persistent user preferences,
/// low-latency pooled playback, and resilient native fallback.
class SoundService {
  static AudioPlayer? _latchPlayer;
  static final List<AudioPlayer> _clickPlayers = [];
  static int _clickIndex = 0;
  static const int _clickPoolSize = 3;

  // Master switch for testing / mock environments
  static bool enableAudio = true;

  // User-configurable toggles backed by AppSettingsService
  static bool get soundEnabled => AppSettingsService.instance.soundEnabled;
  static set soundEnabled(bool value) =>
      AppSettingsService.instance.setSoundEnabled(value);

  static bool get hapticEnabled => AppSettingsService.instance.hapticEnabled;
  static set hapticEnabled(bool value) =>
      AppSettingsService.instance.setHapticEnabled(value);

  static bool _initialized = false;

  static Future<void> init() async {
    try {
      await AppSettingsService.instance.init();
    } catch (_) {}

    if (!enableAudio || !soundEnabled) return;

    try {
      _initPlayers();
    } catch (_) {}
  }

  static void _initPlayers() {
    if (_initialized) return;
    _initialized = true;

    try {
      _latchPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    } catch (_) {}

    try {
      if (_clickPlayers.isEmpty) {
        for (int i = 0; i < _clickPoolSize; i++) {
          final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
          _clickPlayers.add(player);
        }
      }
    } catch (_) {}
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    await AppSettingsService.instance.setSoundEnabled(enabled);
    if (enabled && enableAudio && !_initialized) {
      _initPlayers();
    }
  }

  static Future<void> setHapticEnabled(bool enabled) async {
    await AppSettingsService.instance.setHapticEnabled(enabled);
  }

  static DateTime _lastLatchTime = DateTime.fromMillisecondsSinceEpoch(0);
  static DateTime _lastClickTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Heavy mechanical solenoid transport engagement sound (PLAY / STOP / RESTORE)
  static Future<void> playTapeTransportLatch() async {
    final now = DateTime.now();
    if (now.difference(_lastLatchTime).inMilliseconds < 25) return;
    _lastLatchTime = now;

    if (hapticEnabled) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    if (!enableAudio || !soundEnabled) return;

    try {
      _latchPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await _latchPlayer!.stop();
      await _latchPlayer!.play(
        AssetSource('audio/tape_latch.wav'),
        volume: 1.0,
      );
    } catch (_) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  /// Sharp mechanical switch click sound (MODE / SETTINGS / TABS)
  static Future<void> playTapeSwitchClick() async {
    final now = DateTime.now();
    if (now.difference(_lastClickTime).inMilliseconds < 20) return;
    _lastClickTime = now;

    if (hapticEnabled) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }

    if (!enableAudio || !soundEnabled) return;

    try {
      if (_clickPlayers.isEmpty) {
        _clickPlayers.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      }

      final player = _clickPlayers[_clickIndex];
      _clickIndex = (_clickIndex + 1) % _clickPlayers.length;

      await player.stop();
      await player.play(
        AssetSource('audio/tape_click.wav'),
        volume: 0.95,
      );
    } catch (_) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  static void dispose() {
    try {
      _latchPlayer?.dispose();
      for (final p in _clickPlayers) {
        p.dispose();
      }
    } catch (_) {}
    _latchPlayer = null;
    _clickPlayers.clear();
    _initialized = false;
  }
}
