import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app_settings_service.dart';

/// Service managing device overlays and deck display behaviour preferences.
///
/// Persistent toggles:
/// 1. `hideStatusBar` (Default: true) - Hides device status bar.
/// 2. `hideNavBar` (Default: false) - Hides device navigation bar.
/// 3. `showTime` (Default: false) - Shows 45° tilted time counter on the squircle deck.
class BehaviourService extends ChangeNotifier {
  static const String keyHideStatusBar = 'vord_hide_status_bar';
  static const String keyHideNavBar = 'vord_hide_nav_bar';
  static const String keyShowTime = 'vord_show_time';

  static final BehaviourService instance = BehaviourService._internal();

  factory BehaviourService() => instance;

  BehaviourService._internal() {
    // Listen to changes from AppSettingsService (e.g. on backup restore)
    AppSettingsService.instance.addListener(_syncFromAppSettings);
  }

  bool _hideStatusBar = true; // Default: true (User: only hide status bar should be enabled from default)
  bool _hideNavBar = false; // Default: false
  bool _showTime = false; // Default: false
  bool _isInitialized = false;

  bool get hideStatusBar => _hideStatusBar;
  bool get hideNavBar => _hideNavBar;
  bool get showTime => _showTime;
  bool get isInitialized => _isInitialized;

  void _syncFromAppSettings() {
    final settings = AppSettingsService.instance;
    bool changed = false;
    if (_hideStatusBar != settings.hideStatusBar) {
      _hideStatusBar = settings.hideStatusBar;
      changed = true;
    }
    if (_hideNavBar != settings.hideNavBar) {
      _hideNavBar = settings.hideNavBar;
      changed = true;
    }
    if (_showTime != settings.showTime) {
      _showTime = settings.showTime;
      changed = true;
    }
    if (changed) {
      applySystemUiMode();
      notifyListeners();
    }
  }

  /// Loads persisted preferences from AppSettingsService and applies system UI mode.
  Future<void> init() async {
    try {
      await AppSettingsService.instance.init();
      final settings = AppSettingsService.instance;
      _hideStatusBar = settings.hideStatusBar;
      _hideNavBar = settings.hideNavBar;
      _showTime = settings.showTime;
    } catch (e) {
      debugPrint('BehaviourService init fallback: $e');
      _hideStatusBar = true;
      _hideNavBar = false;
      _showTime = false;
    }

    _isInitialized = true;
    await applySystemUiMode();
    notifyListeners();
  }

  /// Sets whether the device status bar is hidden.
  Future<void> setHideStatusBar(bool value) async {
    if (_hideStatusBar == value) return;
    _hideStatusBar = value;
    notifyListeners();

    try {
      await AppSettingsService.instance.setHideStatusBar(value);
    } catch (e) {
      debugPrint('BehaviourService setHideStatusBar error: $e');
    }

    await applySystemUiMode();
  }

  /// Sets whether the device navigation bar is hidden.
  Future<void> setHideNavBar(bool value) async {
    if (_hideNavBar == value) return;
    _hideNavBar = value;
    notifyListeners();

    try {
      await AppSettingsService.instance.setHideNavBar(value);
    } catch (e) {
      debugPrint('BehaviourService setHideNavBar error: $e');
    }

    await applySystemUiMode();
  }

  /// Sets whether the 45° tilted counter on the squircle deck is shown.
  Future<void> setShowTime(bool value) async {
    if (_showTime == value) return;
    _showTime = value;
    notifyListeners();

    try {
      await AppSettingsService.instance.setShowTime(value);
    } catch (e) {
      debugPrint('BehaviourService setShowTime error: $e');
    }
  }

  /// Resets all toggles to their default values (only hide status bar enabled).
  Future<void> resetToDefaults() async {
    _hideStatusBar = true;
    _hideNavBar = false;
    _showTime = false;
    notifyListeners();

    try {
      await AppSettingsService.instance.resetBehaviourDefaults();
    } catch (e) {
      debugPrint('BehaviourService resetToDefaults error: $e');
    }

    await applySystemUiMode();
  }

  /// Applies the system UI overlay configuration to the device.
  Future<void> applySystemUiMode() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      if (_hideStatusBar && _hideNavBar) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else if (_hideStatusBar && !_hideNavBar) {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: const [SystemUiOverlay.bottom],
        );
      } else if (!_hideStatusBar && _hideNavBar) {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: const [SystemUiOverlay.top],
        );
      } else {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: const [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );
      }
    } catch (e) {
      debugPrint('SystemChrome applySystemUiMode fallback: $e');
    }
  }

  /// Helper for unit and widget testing to set mock state without persistence.
  @visibleForTesting
  void setMockValues({bool? hideStatusBar, bool? hideNavBar, bool? showTime}) {
    if (hideStatusBar != null) _hideStatusBar = hideStatusBar;
    if (hideNavBar != null) _hideNavBar = hideNavBar;
    if (showTime != null) _showTime = showTime;
    notifyListeners();
  }
}
