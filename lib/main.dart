import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/screens/timer_screen.dart';
import 'src/services/app_settings_service.dart';
import 'src/services/behaviour_service.dart';
import 'src/services/session_service.dart';
import 'src/services/sound_service.dart';
import 'src/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize atomic settings, behaviour preferences, offline database, and audio FX
  await AppSettingsService.instance.init();
  await BehaviourService.instance.init();
  await SessionService.instance.init();
  await SoundService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  ThemeMode initialThemeMode = ThemeMode.light;
  final savedMode = AppSettingsService.instance.themeMode;
  if (savedMode == 'dark') {
    initialThemeMode = ThemeMode.dark;
  } else if (savedMode == 'system') {
    initialThemeMode = ThemeMode.system;
  } else {
    initialThemeMode = ThemeMode.light;
  }

  runApp(VordApp(initialThemeMode: initialThemeMode));
}

class VordApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final bool animateBackground;

  const VordApp({
    super.key,
    this.initialThemeMode = ThemeMode.light,
    this.animateBackground = true,
  });

  @override
  State<VordApp> createState() => _VordAppState();
}

class _VordAppState extends State<VordApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    AppSettingsService.instance.addListener(_syncThemeFromSettings);
  }

  @override
  void dispose() {
    AppSettingsService.instance.removeListener(_syncThemeFromSettings);
    super.dispose();
  }

  void _syncThemeFromSettings() {
    final modeStr = AppSettingsService.instance.themeMode;
    final mode = modeStr == 'dark'
        ? ThemeMode.dark
        : (modeStr == 'system' ? ThemeMode.system : ThemeMode.light);
    if (_themeMode != mode && mounted) {
      setState(() {
        _themeMode = mode;
      });
    }
  }

  Future<void> _updateThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });

    try {
      final modeStr = mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.system ? 'system' : 'light');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', modeStr);
      await AppSettingsService.instance.setThemeMode(modeStr);
    } catch (e) {
      debugPrint('Theme save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VORD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: TimerScreen(
        animateBackground: widget.animateBackground,
        currentThemeMode: _themeMode,
        onThemeChanged: _updateThemeMode,
      ),
    );
  }
}
