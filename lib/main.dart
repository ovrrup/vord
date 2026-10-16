import 'package:flutter/material.dart';
import 'src/screens/timer_screen.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const VordApp());
}

class VordApp extends StatelessWidget {
  const VordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vord',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const TimerScreen(),
    );
  }
}
