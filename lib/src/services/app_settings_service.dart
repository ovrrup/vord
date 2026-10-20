import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized, ultra-resilient settings and preferences storage engine.
///
/// Features:
/// 1. Atomic disk file writes (`vord_settings.json` with rolling `.bak` backup)
///    guaranteeing zero data loss on unexpected process termination.
/// 2. Secondary SharedPreferences mirror for multi-tier redundancy.
/// 3. Unified serialization for full backup archive inclusion (export/import).
/// 4. Resilient self-healing corruption recovery.
class AppSettingsService extends ChangeNotifier {
  static const String _settingsFileName = 'vord_settings.json';
  static const String _settingsBackupFileName = 'vord_settings.bak';
  static const int currentSchemaVersion = 3;

  static final AppSettingsService instance = AppSettingsService._internal();
  factory AppSettingsService() => instance;
  AppSettingsService._internal();

  File? _settingsFile;
  File? _backupFile;
  Future<void>? _activeWriteChain;
  Future<void>? _initFuture;
  bool _isInitialized = false;

  // Cached preference values
  String _themeMode = 'light'; // 'light', 'dark', 'system'
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _hideStatusBar = true; // Default: true
  bool _hideNavBar = false; // Default: false
  bool _showTime = false; // Default: false
  String _updateChannel = 'release'; // 'release', 'commit'
  String? _lastInstalledCommitSha;

  // Getters
  bool get isInitialized => _isInitialized;
  String get themeMode => _themeMode;
  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;
  bool get hideStatusBar => _hideStatusBar;
  bool get hideNavBar => _hideNavBar;
  bool get showTime => _showTime;
  String get updateChannel => _updateChannel;
  String? get lastInstalledCommitSha => _lastInstalledCommitSha;

  // Test mode flag
  static bool isTestMode = false;
  static bool get _inTest =>
      isTestMode ||
      Platform.environment.containsKey('FLUTTER_TEST') ||
      (WidgetsBinding.instance.runtimeType.toString().contains('Test'));

  // Enable atomic disk file storage (disabled during tests to avoid unmocked platform channels)
  static bool enableDiskStorage = true;

  /// Initializes the storage engine, loading from disk, backup, or cache.
  Future<void> init({bool force = false}) {
    if (_isInitialized && !force) return Future.value();
    if (_initFuture != null && !force) return _initFuture!;
    final completer = Completer<void>();
    _initFuture = completer.future;

    () async {
      try {
        if (!_inTest && enableDiskStorage) {
          try {
            final docsDir = await getApplicationDocumentsDirectory();
            _settingsFile = File('${docsDir.path}/$_settingsFileName');
            _backupFile = File('${docsDir.path}/$_settingsBackupFileName');
          } catch (_) {
            _settingsFile = null;
            _backupFile = null;
          }
        } else {
          _settingsFile = null;
          _backupFile = null;
        }

        bool loaded = false;

        // 1. Primary disk file
        if (_settingsFile != null && await _settingsFile!.exists()) {
          try {
            final content = await _settingsFile!.readAsString();
            loaded = _parseAndApply(content);
          } catch (_) {
            loaded = false;
          }
        }

        // 2. Rolling backup file
        if (!loaded && _backupFile != null && await _backupFile!.exists()) {
          try {
            final content = await _backupFile!.readAsString();
            loaded = _parseAndApply(content);
          } catch (_) {
            loaded = false;
          }
        }

        // 3. SharedPreferences secondary cache
        if (!loaded) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final cached = prefs.getString('vord_settings_json');
            if (cached != null && cached.isNotEmpty) {
              loaded = _parseAndApply(cached);
            }

            if (!loaded) {
              // Read legacy individual keys
              _themeMode = prefs.getString('theme_mode') ?? 'light';
              _soundEnabled = prefs.getBool('vord_sound_enabled') ?? true;
              _hapticEnabled = prefs.getBool('vord_haptic_enabled') ?? true;
              _hideStatusBar = prefs.getBool('vord_hide_status_bar') ?? true;
              _hideNavBar = prefs.getBool('vord_hide_nav_bar') ?? false;
              _showTime = prefs.getBool('vord_show_time') ?? false;
              _updateChannel = prefs.getString('vord_update_channel') ?? 'release';
              _lastInstalledCommitSha = prefs.getString('vord_installed_commit_sha');
              loaded = true;
            }
          } catch (_) {}
        }

        if (loaded && !_inTest) {
          await _queueDiskWrite();
        }
      } catch (_) {
      } finally {
        _isInitialized = true;
        completer.complete();
        notifyListeners();
      }
    }();

    return _initFuture!;
  }

  bool _parseAndApply(String jsonContent) {
    if (jsonContent.trim().isEmpty) return false;
    try {
      final decoded = jsonDecode(jsonContent);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('themeMode')) {
          _themeMode = decoded['themeMode'] as String? ?? 'light';
        }
        if (decoded.containsKey('soundEnabled')) {
          _soundEnabled = decoded['soundEnabled'] as bool? ?? true;
        }
        if (decoded.containsKey('hapticEnabled')) {
          _hapticEnabled = decoded['hapticEnabled'] as bool? ?? true;
        }
        if (decoded.containsKey('hideStatusBar')) {
          _hideStatusBar = decoded['hideStatusBar'] as bool? ?? true;
        }
        if (decoded.containsKey('hideNavBar')) {
          _hideNavBar = decoded['hideNavBar'] as bool? ?? false;
        }
        if (decoded.containsKey('showTime')) {
          _showTime = decoded['showTime'] as bool? ?? false;
        }
        if (decoded.containsKey('updateChannel')) {
          _updateChannel = decoded['updateChannel'] as String? ?? 'release';
        }
        if (decoded.containsKey('lastInstalledCommitSha')) {
          _lastInstalledCommitSha = decoded['lastInstalledCommitSha'] as String?;
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': currentSchemaVersion,
      'themeMode': _themeMode,
      'soundEnabled': _soundEnabled,
      'hapticEnabled': _hapticEnabled,
      'hideStatusBar': _hideStatusBar,
      'hideNavBar': _hideNavBar,
      'showTime': _showTime,
      'updateChannel': _updateChannel,
      'lastInstalledCommitSha': _lastInstalledCommitSha,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Restores settings directly from a Map (e.g. during backup import).
  Future<void> importSettings(Map<String, dynamic> data) async {
    if (data.containsKey('themeMode') && data['themeMode'] is String) {
      final mode = data['themeMode'] as String;
      if (const {'light', 'dark', 'system'}.contains(mode)) {
        _themeMode = mode;
      }
    }
    if (data.containsKey('soundEnabled') && data['soundEnabled'] is bool) {
      _soundEnabled = data['soundEnabled'] as bool;
    }
    if (data.containsKey('hapticEnabled') && data['hapticEnabled'] is bool) {
      _hapticEnabled = data['hapticEnabled'] as bool;
    }
    if (data.containsKey('hideStatusBar') && data['hideStatusBar'] is bool) {
      _hideStatusBar = data['hideStatusBar'] as bool;
    }
    if (data.containsKey('hideNavBar') && data['hideNavBar'] is bool) {
      _hideNavBar = data['hideNavBar'] as bool;
    }
    if (data.containsKey('showTime') && data['showTime'] is bool) {
      _showTime = data['showTime'] as bool;
    }
    if (data.containsKey('updateChannel') && data['updateChannel'] is String) {
      final ch = data['updateChannel'] as String;
      if (const {'release', 'commit'}.contains(ch)) {
        _updateChannel = ch;
      }
    }
    if (data.containsKey('lastInstalledCommitSha')) {
      _lastInstalledCommitSha = data['lastInstalledCommitSha'] as String?;
    }

    notifyListeners();
    await _queueDiskWrite();
  }

  Future<void> setThemeMode(String mode) async {
    const validModes = {'light', 'dark', 'system'};
    final sanitized = validModes.contains(mode) ? mode : 'light';
    if (_themeMode == sanitized) return;
    _themeMode = sanitized;
    notifyListeners();
    await _queueDiskWrite();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    if (_soundEnabled == enabled) return;
    _soundEnabled = enabled;
    notifyListeners();
    await _queueDiskWrite();
  }

  Future<void> setHapticEnabled(bool enabled) async {
    if (_hapticEnabled == enabled) return;
    _hapticEnabled = enabled;
    notifyListeners();
    await _queueDiskWrite();
  }

  Future<void> setHideStatusBar(bool hide) async {
    if (_hideStatusBar == hide) return;
    _hideStatusBar = hide;
    notifyListeners();
    await _queueDiskWrite();
  }

  Future<void> setHideNavBar(bool hide) async {
    if (_hideNavBar == hide) return;
    _hideNavBar = hide;
    notifyListeners();
    await _queueDiskWrite();
  }

  Future<void> setShowTime(bool show) async {
    if (_showTime == show) return;
    _showTime = show;
    notifyListeners();
    await _queueDiskWrite();
  }

  Future<void> setUpdateChannel(String channel) async {
    const validChannels = {'release', 'commit'};
    final sanitized = validChannels.contains(channel) ? channel : 'release';
    if (_updateChannel == sanitized) return;
    _updateChannel = sanitized;
    notifyListeners();
    await _queueDiskWrite();
  }

  Future<void> setLastInstalledCommitSha(String? sha) async {
    if (_lastInstalledCommitSha == sha) return;
    _lastInstalledCommitSha = sha;
    notifyListeners();
    await _queueDiskWrite();
  }

  Future<void> resetBehaviourDefaults() async {
    _hideStatusBar = true;
    _hideNavBar = false;
    _showTime = false;
    notifyListeners();
    await _queueDiskWrite();
  }

  Future<void> _queueDiskWrite() {
    if (_inTest) {
      return _performAtomicDiskWrite();
    }
    final previousChain = _activeWriteChain ?? Future.value();
    final completer = Completer<void>();
    _activeWriteChain = completer.future;

    previousChain.then((_) async {
      try {
        await _performAtomicDiskWrite();
      } catch (_) {
      } finally {
        completer.complete();
      }
    }).catchError((_) {
      completer.complete();
    });

    return completer.future;
  }

  Future<void> _performAtomicDiskWrite() async {
    try {
      final jsonString = jsonEncode(toJson());

      // 1. Primary write to atomic file with .bak rolling backup
      if (!_inTest && _settingsFile != null) {
        final parentDir = _settingsFile!.parent;
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }

        if (await _settingsFile!.exists() && _backupFile != null) {
          try {
            final len = await _settingsFile!.length();
            if (len > 10) {
              await _settingsFile!.copy(_backupFile!.path);
            }
          } catch (_) {}
        }

        final tmpFile = File('${_settingsFile!.path}.tmp');
        await tmpFile.writeAsString(jsonString, flush: true);
        try {
          await tmpFile.rename(_settingsFile!.path);
        } catch (_) {
          if (await _settingsFile!.exists()) {
            await _settingsFile!.delete();
          }
          await tmpFile.rename(_settingsFile!.path);
        }
      }

      // 2. Secondary mirror to SharedPreferences cache & individual legacy keys
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vord_settings_json', jsonString);
      await prefs.setString('theme_mode', _themeMode);
      await prefs.setBool('vord_sound_enabled', _soundEnabled);
      await prefs.setBool('vord_haptic_enabled', _hapticEnabled);
      await prefs.setBool('vord_hide_status_bar', _hideStatusBar);
      await prefs.setBool('vord_hide_nav_bar', _hideNavBar);
      await prefs.setBool('vord_show_time', _showTime);
      await prefs.setString('vord_update_channel', _updateChannel);
      if (_lastInstalledCommitSha != null) {
        await prefs.setString('vord_installed_commit_sha', _lastInstalledCommitSha!);
      }
    } catch (_) {}
  }

  @visibleForTesting
  void setMockValues({
    String? themeMode,
    bool? soundEnabled,
    bool? hapticEnabled,
    bool? hideStatusBar,
    bool? hideNavBar,
    bool? showTime,
    String? updateChannel,
    String? lastInstalledCommitSha,
  }) {
    isTestMode = true;
    _isInitialized = true;
    if (themeMode != null) _themeMode = themeMode;
    if (soundEnabled != null) _soundEnabled = soundEnabled;
    if (hapticEnabled != null) _hapticEnabled = hapticEnabled;
    if (hideStatusBar != null) _hideStatusBar = hideStatusBar;
    if (hideNavBar != null) _hideNavBar = hideNavBar;
    if (showTime != null) _showTime = showTime;
    if (updateChannel != null) _updateChannel = updateChannel;
    if (lastInstalledCommitSha != null) _lastInstalledCommitSha = lastInstalledCommitSha;
    notifyListeners();
  }
}
