import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service providing authentic physical tape recorder mechanical sounds
/// for transport keys and switches, with persistent user preferences.
class SoundService {
  static AudioPlayer? _latchPlayer;
  static AudioPlayer? _clickPlayer;

  // Master switch for testing / mock environments
  static bool enableAudio = true;

  // User-configurable toggles
  static bool soundEnabled = true;
  static bool hapticEnabled = true;

  static const String _soundPrefKey = 'vord_sound_enabled';
  static const String _hapticPrefKey = 'vord_haptic_enabled';

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      soundEnabled = prefs.getBool(_soundPrefKey) ?? true;
      hapticEnabled = prefs.getBool(_hapticPrefKey) ?? true;
    } catch (_) {}

    if (!enableAudio || !soundEnabled) return;
    try {
      _latchPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _clickPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    } catch (_) {}
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundPrefKey, enabled);
    } catch (_) {}
  }

  static Future<void> setHapticEnabled(bool enabled) async {
    hapticEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticPrefKey, enabled);
    } catch (_) {}
  }

  /// Heavy mechanical solenoid transport engagement sound (PLAY / STOP / RESTORE)
  static Future<void> playTapeTransportLatch() async {
    if (hapticEnabled) {
      HapticFeedback.heavyImpact();
    }
    SystemSound.play(SystemSoundType.click);

    if (!enableAudio || !soundEnabled) return;
    try {
      _latchPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await _latchPlayer?.stop();
      await _latchPlayer?.play(AssetSource('audio/tape_latch.wav'), volume: 1.0);
    } catch (_) {
      // Graceful fallback for widget tests or devices with muted audio
    }
  }

  /// Sharp mechanical switch click sound (MODE / SETTINGS / TABS)
  static Future<void> playTapeSwitchClick() async {
    if (hapticEnabled) {
      HapticFeedback.lightImpact();
    }
    SystemSound.play(SystemSoundType.click);

    if (!enableAudio || !soundEnabled) return;
    try {
      _clickPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await _clickPlayer?.stop();
      await _clickPlayer?.play(AssetSource('audio/tape_click.wav'), volume: 0.9);
    } catch (_) {
      // Graceful fallback
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
