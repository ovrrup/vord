import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vord/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App launches directly to white screen with the 3 components only', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(
      initialThemeMode: ThemeMode.light,
      animateBackground: false,
    ));

    // Component 1: Motivational & self-competition greeting banner
    expect(find.textContaining('Good '), findsOneWidget);
    expect(find.textContaining('Compete with yourself'), findsOneWidget);

    // Component 2: Retro matte disk with initial 00:00 time
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('FOCUSING'), findsOneWidget);

    // Component 3: Physical matte controls (Play, Mode Switch, Settings)
    expect(find.text('START'), findsOneWidget);
    expect(find.text('FOCUS'), findsWidgets);
    expect(find.text('SETTINGS'), findsOneWidget);
  });

  testWidgets('Play button starts stopwatch, hides time while running, and pause saves session', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(
      initialThemeMode: ThemeMode.light,
      animateBackground: false,
    ));

    // Initial state: time is visible
    expect(find.text('START'), findsOneWidget);
    expect(find.text('PAUSE'), findsNothing);
    expect(find.text('00:00'), findsOneWidget);

    // Tap large START button
    await tester.tap(find.text('START'));
    await tester.pump();

    // Now running: time is hidden per user requirement
    expect(find.text('PAUSE'), findsOneWidget);
    expect(find.text('START'), findsNothing);
    expect(find.text('00:00'), findsNothing);

    // Tap PAUSE (pauses and saves focus session)
    await tester.tap(find.text('PAUSE'));
    await tester.pump();

    // Now paused / ready to resume, time becomes visible again
    expect(find.text('RESUME'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
  });

  testWidgets('Mode switch button switches between Focus and Rest', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(
      initialThemeMode: ThemeMode.light,
      animateBackground: false,
    ));

    expect(find.text('FOCUSING'), findsOneWidget);

    // Tap Mode Switch button (top right of controls)
    await tester.tap(find.text('FOCUS').last);
    await tester.pump();

    // Now in Rest mode
    expect(find.text('RESTING'), findsOneWidget);
    expect(find.text('REST'), findsWidgets);

    // Tap again to switch back to Focus mode
    await tester.tap(find.text('REST').last);
    await tester.pump();

    expect(find.text('FOCUSING'), findsOneWidget);
  });

  testWidgets('Settings button opens theme settings with Light, Dark, System options', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(
      initialThemeMode: ThemeMode.light,
      animateBackground: false,
    ));

    // Tap SETTINGS button
    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();

    // Verify Theme Settings Modal
    expect(find.text('THEME SETTING'), findsOneWidget);
    expect(find.text('White Mode (Light)'), findsOneWidget);
    expect(find.text('Black Theme (Dark)'), findsOneWidget);
    expect(find.text('System Default'), findsOneWidget);

    // Tap Black Theme
    await tester.tap(find.text('Black Theme (Dark)'));
    await tester.pumpAndSettle();

    // Verify modal dismissed and preference persisted
    expect(find.text('THEME SETTING'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });
}
