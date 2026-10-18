import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/screens/timer_screen.dart';
import 'src/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pure black OLED status bar and navigation bar for Android
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  bool hasSeenOnboarding = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  } catch (e) {
    debugPrint('SharedPreferences init fallback: $e');
  }

  runApp(VordApp(hasSeenOnboarding: hasSeenOnboarding));
}

class VordApp extends StatefulWidget {
  final bool? initialShowOnboarding;
  final bool hasSeenOnboarding;
  final bool animateBackground;

  const VordApp({
    super.key,
    this.initialShowOnboarding,
    this.hasSeenOnboarding = false,
    this.animateBackground = true,
  });

  @override
  State<VordApp> createState() => _VordAppState();
}

class _VordAppState extends State<VordApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.initialShowOnboarding ?? !widget.hasSeenOnboarding;
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _showOnboarding = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vord',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _showOnboarding
          ? OnboardingScreen(onComplete: _completeOnboarding)
          : TimerScreen(animateBackground: widget.animateBackground),
    );
  }
}
