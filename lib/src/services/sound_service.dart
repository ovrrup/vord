import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Service providing authentic physical tape recorder mechanical sounds
/// for transport keys and switches.
class SoundService {
  static AudioPlayer? _latchPlayer;
  static AudioPlayer? _clickPlayer;
  static bool enableAudio = true;

  static void init() {
    if (!enableAudio) return;
    try {
      _latchPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _clickPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    } catch (_) {}
  }

  /// Heavy mechanical solenoid transport engagement sound (PLAY / PAUSE / RESUME)
  static Future<void> playTapeTransportLatch() async {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);

    if (!enableAudio) return;
    try {
      _latchPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await _latchPlayer?.stop();
      await _latchPlayer?.play(AssetSource('audio/tape_latch.wav'), volume: 1.0);
    } catch (_) {
      // Graceful fallback for widget tests or devices with muted audio
    }
  }

  /// Sharp mechanical switch click sound (MODE / SETTINGS)
  static Future<void> playTapeSwitchClick() async {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);

    if (!enableAudio) return;
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
