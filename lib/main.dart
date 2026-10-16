import 'package:flutter/material.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/screens/timer_screen.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const VordApp());
}

class VordApp extends StatefulWidget {
  final bool initialShowOnboarding;

  const VordApp({
    super.key,
    this.initialShowOnboarding = true,
  });

  @override
  State<VordApp> createState() => _VordAppState();
}

class _VordAppState extends State<VordApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.initialShowOnboarding;
  }

  void _completeOnboarding() {
    setState(() {
      _showOnboarding = false;
    });
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
