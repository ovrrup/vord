import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vord/main.dart';
import 'package:vord/src/models/session_mode.dart';
import 'package:vord/src/screens/history_screen.dart';
import 'package:vord/src/services/session_service.dart';
import 'package:vord/src/services/sound_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.enableAudio = false; // Disable audio playback during unit/widget tests
  });

  testWidgets('App launches to white screen with strictly the 3 big minimal matte components', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(
      initialThemeMode: ThemeMode.light,
      animateBackground: false,
    ));

    // Component 1: Motivational & greeting banner
    expect(find.textContaining('Good '), findsOneWidget);
    expect(find.textContaining('Compete with yourself'), findsOneWidget);

    // Component 2: Retro matte disk with ZERO digital time numbers
    expect(find.text('00:00'), findsNothing);

    // Component 3: Physical matte controls (Play, Mode Switch, Settings)
    expect(find.text('START'), findsOneWidget);
    expect(find.text('FOCUS'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });

  testWidgets('Play button starts stopwatch and pause saves session; no time shown on main deck', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(
      initialThemeMode: ThemeMode.light,
      animateBackground: false,
    ));

    // Initial state: START button, no time on deck
    expect(find.text('START'), findsOneWidget);
    expect(find.text('PAUSE'), findsNothing);
    expect(find.text('00:00'), findsNothing);

    // Tap START transport key
    await tester.tap(find.text('START'));
    await tester.pump();

    // Now running
    expect(find.text('PAUSE'), findsOneWidget);
    expect(find.text('START'), findsNothing);
    expect(find.text('00:00'), findsNothing);

    // Tap PAUSE (pauses and saves focus session)
    await tester.tap(find.text('PAUSE'));
    await tester.pump();

    // Now paused / ready to resume; still no digital time on main deck
    expect(find.text('RESUME'), findsOneWidget);
    expect(find.text('00:00'), findsNothing);
  });

  testWidgets('Mode switch button switches between Focus and Rest', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(
      initialThemeMode: ThemeMode.light,
      animateBackground: false,
    ));

    expect(find.text('FOCUS'), findsOneWidget);

    // Tap Mode Switch button (top right of controls)
    await tester.tap(find.text('FOCUS'));
    await tester.pump();

    // Now in Rest mode
    expect(find.text('REST'), findsOneWidget);
    expect(find.text('FOCUS'), findsNothing);

    // Tap again to switch back to Focus mode
    await tester.tap(find.text('REST'));
    await tester.pump();

    expect(find.text('FOCUS'), findsOneWidget);
    expect(find.text('REST'), findsNothing);
  });

  testWidgets('Settings button opens modal with Category History and Theme options', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(
      initialThemeMode: ThemeMode.light,
      animateBackground: false,
    ));

    // Tap SETTINGS button
    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();

    // Verify Settings Options
    expect(find.text('SESSION HISTORY & TIME LOGS'), findsOneWidget);
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

  testWidgets('Settings history option navigates to category screen and back', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(
      initialThemeMode: ThemeMode.light,
      animateBackground: false,
    ));

    // Open Settings
    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();

    // Tap Category & Session History
    await tester.tap(find.text('SESSION HISTORY & TIME LOGS'));
    await tester.pumpAndSettle();

    // Verify Category & History Screen
    expect(find.text('SESSION LOG & HISTORY'), findsOneWidget);
    expect(find.text('ALL LOGS'), findsOneWidget);
    expect(find.text('FOCUS SESSIONS'), findsOneWidget);
    expect(find.text('REST INTERVALS'), findsOneWidget);
    expect(find.text('NO RECORDED SESSIONS YET'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // Back on main screen
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('HistoryScreen displays categorized sessions and recorded times', (WidgetTester tester) async {
    final sessionService = SessionService();
    sessionService.recordSession(SessionModeType.focus, 1500); // 25m
    sessionService.recordSession(SessionModeType.shortBreak, 300); // 5m

    await tester.pumpWidget(MaterialApp(
      home: HistoryScreen(sessionService: sessionService),
    ));

    expect(find.text('SESSION LOG & HISTORY'), findsOneWidget);
    expect(find.text('FOCUS SESSION'), findsOneWidget);
    expect(find.text('REST INTERVAL'), findsOneWidget);
    expect(find.text('25m 00s'), findsWidgets);
    expect(find.text('5m 00s'), findsOneWidget);
  });
}
