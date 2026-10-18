import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/screens/timer_screen.dart';
import 'src/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  ThemeMode initialThemeMode = ThemeMode.light;
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('theme_mode');
    if (savedMode == 'dark') {
      initialThemeMode = ThemeMode.dark;
    } else if (savedMode == 'system') {
      initialThemeMode = ThemeMode.system;
    } else {
      initialThemeMode = ThemeMode.light;
    }
  } catch (e) {
    debugPrint('SharedPreferences theme load fallback: $e');
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
  }

  Future<void> _updateThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'theme_mode',
        mode == ThemeMode.dark
            ? 'dark'
            : (mode == ThemeMode.system ? 'system' : 'light'),
      );
    } catch (e) {
      debugPrint('SharedPreferences theme save error: $e');
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
