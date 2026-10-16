import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/screens/timer_screen.dart';
import 'src/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(VordApp(hasSeenOnboarding: hasSeenOnboarding));
}

class VordApp extends StatefulWidget {
  final bool? initialShowOnboarding;
  final bool hasSeenOnboarding;

  const VordApp({
    super.key,
    this.initialShowOnboarding,
    this.hasSeenOnboarding = false,
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
          : const TimerScreen(),
    );
  }
}
