import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'app_settings_service.dart';

/// Service providing authentic physical tape recorder mechanical sounds
/// for transport keys and switches, with persistent user preferences.
class SoundService {
  static AudioPlayer? _latchPlayer;
  static AudioPlayer? _clickPlayer;

  // Master switch for testing / mock environments
  static bool enableAudio = true;

  // User-configurable toggles backed by AppSettingsService
  static bool get soundEnabled => AppSettingsService.instance.soundEnabled;
  static set soundEnabled(bool value) => AppSettingsService.instance.setSoundEnabled(value);

  static bool get hapticEnabled => AppSettingsService.instance.hapticEnabled;
  static set hapticEnabled(bool value) => AppSettingsService.instance.setHapticEnabled(value);

  static Future<void> init() async {
    try {
      await AppSettingsService.instance.init();
    } catch (_) {}

    if (!enableAudio || !soundEnabled) return;
    try {
      _latchPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _clickPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    } catch (_) {}
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    await AppSettingsService.instance.setSoundEnabled(enabled);
  }

  static Future<void> setHapticEnabled(bool enabled) async {
    await AppSettingsService.instance.setHapticEnabled(enabled);
  }

  static DateTime _lastPlayTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Heavy mechanical solenoid transport engagement sound (PLAY / STOP / RESTORE)
  static Future<void> playTapeTransportLatch() async {
    final now = DateTime.now();
    if (now.difference(_lastPlayTime).inMilliseconds < 40) return;
    _lastPlayTime = now;

    if (hapticEnabled) {
      HapticFeedback.heavyImpact();
    }

    if (!enableAudio || !soundEnabled) return;
    try {
      _latchPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await _latchPlayer?.stop();
      await _latchPlayer?.play(AssetSource('audio/tape_latch.wav'), volume: 1.0);
    } catch (_) {
      // Self-heal broken player instance so next click works
      try {
        await _latchPlayer?.dispose();
      } catch (_) {}
      _latchPlayer = null;
    }
  }

  /// Sharp mechanical switch click sound (MODE / SETTINGS / TABS)
  static Future<void> playTapeSwitchClick() async {
    final now = DateTime.now();
    if (now.difference(_lastPlayTime).inMilliseconds < 40) return;
    _lastPlayTime = now;

    if (hapticEnabled) {
      HapticFeedback.lightImpact();
    }

    if (!enableAudio || !soundEnabled) return;
    try {
      _clickPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await _clickPlayer?.stop();
      await _clickPlayer?.play(AssetSource('audio/tape_click.wav'), volume: 0.9);
    } catch (_) {
      // Self-heal broken player instance so next click works
      try {
        await _clickPlayer?.dispose();
      } catch (_) {}
      _clickPlayer = null;
    }
  }

  static void dispose() {
    try {
      _latchPlayer?.dispose();
      _clickPlayer?.dispose();
    } catch (_) {}
    _latchPlayer = null;
    _clickPlayer = null;
  }
}
