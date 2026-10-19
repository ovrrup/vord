import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vord/main.dart';
import 'package:vord/src/models/session_mode.dart';
import 'package:vord/src/screens/history_screen.dart';
import 'package:vord/src/services/session_service.dart';
import 'package:vord/src/services/sound_service.dart';
import 'package:vord/src/widgets/retro_matte_disk.dart';

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

    // Component 2: Squircle box deck with corner bolts, 4 box lights, and ZERO digital time numbers
    expect(find.byKey(const Key('info_area_stage_lights')), findsOneWidget);
    expect(find.byType(MachinedBolt), findsNWidgets(4));
    expect(find.byType(StageBoxLight), findsNWidgets(4));
    expect(find.text('00:00'), findsNothing);

    // Component 3: Physical matte controls (Play, Mode Switch, Settings)
    expect(find.text('START'), findsOneWidget);
    expect(find.text('FOCUS'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });

  testWidgets('Play button starts stopwatch and stop resets & saves session; no time shown on main deck', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(
      initialThemeMode: ThemeMode.light,
      animateBackground: false,
    ));

    // Initial state: START button, no time on deck
    expect(find.text('START'), findsOneWidget);
    expect(find.text('STOP'), findsNothing);
    expect(find.text('00:00'), findsNothing);

    // Tap START transport key
    await tester.tap(find.text('START'));
    await tester.pump();

    // Now running
    expect(find.text('STOP'), findsOneWidget);
    expect(find.text('START'), findsNothing);
    expect(find.text('00:00'), findsNothing);

    // Tap STOP (stops, resets stopwatch to 0, and saves focus session)
    await tester.tap(find.text('STOP'));
    await tester.pump();

    // Now reset to 0 and idle; still no digital time on main deck
    expect(find.text('START'), findsOneWidget);
    expect(find.text('STOP'), findsNothing);
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
    expect(find.text('SESSION HISTORY'), findsOneWidget);
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
    await tester.tap(find.text('SESSION HISTORY'));
    await tester.pumpAndSettle();

    // Verify Category & History Screen
    expect(find.text('SESSION HISTORY'), findsOneWidget);
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

    expect(find.text('SESSION HISTORY'), findsOneWidget);
    expect(find.text('FOCUS SESSION'), findsOneWidget);
    expect(find.text('REST INTERVAL'), findsOneWidget);
    expect(find.text('25m 00s'), findsWidgets);
    expect(find.text('5m 00s'), findsOneWidget);
  });

  testWidgets('Settings sheet contains Data & Backup and Sound toggles', (WidgetTester tester) async {
    await tester.pumpWidget(const VordApp(
      initialThemeMode: ThemeMode.light,
      animateBackground: false,
    ));

    // Open Settings
    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();

    expect(find.text('DATA & BACKUP'), findsOneWidget);
    expect(find.text('SOUND & HAPTICS'), findsOneWidget);
    expect(find.text('SOUND FX'), findsOneWidget);
    expect(find.text('HAPTICS'), findsOneWidget);

    // Toggle Sound FX
    await tester.tap(find.text('SOUND FX'));
    await tester.pump();
    expect(SoundService.soundEnabled, false);

    // Tap Data & Backup to navigate
    await tester.tap(find.text('DATA & BACKUP'));
    await tester.pumpAndSettle();

    // Verify Data & Backup screen
    expect(find.text('DATA & BACKUP'), findsOneWidget);
    expect(find.text('EXPORT BACKUP FILE'), findsOneWidget);
    expect(find.text('RESTORE FROM FILE'), findsOneWidget);
    expect(find.text('CLEAR ALL SESSIONS'), findsOneWidget);

    // Back to main
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('START'), findsOneWidget);
  });

  test('SessionService exports and imports backup archives cleanly', () async {
    final sessionService = SessionService();
    await sessionService.recordSession(SessionModeType.focus, 1800);
    await sessionService.recordSession(SessionModeType.shortBreak, 300);

    final exportedJson = sessionService.exportBackupJson();
    expect(exportedJson.contains('VORD'), isTrue);
    expect(exportedJson.contains('1800'), isTrue);
    expect(exportedJson.contains('300'), isTrue);
    expect(exportedJson.contains('checksum'), isTrue);

    // Clear and restore
    await sessionService.clearAllSessions();
    expect(sessionService.totalSessionCount, 0);

    final result = await sessionService.importBackupJson(exportedJson, replace: true);
    expect(result.success, isTrue);
    expect(result.importedCount, 2);
    expect(sessionService.totalSessionCount, 2);
    expect(sessionService.allTimeFocusSeconds, 1800);
    expect(sessionService.allTimeBreakSeconds, 300);
  });

  test('SessionService smart deduplication prevents duplicate sessions during merge imports', () async {
    final sessionService = SessionService();
    await sessionService.clearAllSessions();

    await sessionService.recordSession(SessionModeType.focus, 1500);
    await sessionService.recordSession(SessionModeType.shortBreak, 300);
    expect(sessionService.totalSessionCount, 2);

    final exportJson = sessionService.exportBackupJson();

    // Re-importing the same backup in MERGE mode should detect duplicates and skip them
    final mergeResult = await sessionService.importBackupJson(exportJson, replace: false);
    expect(mergeResult.success, isTrue);
    expect(mergeResult.importedCount, 0);
    expect(mergeResult.skippedCount, 2);
    expect(sessionService.totalSessionCount, 2); // No duplicates added!
  });

  test('SessionService offline analytics computes personal records and self-competition metrics', () async {
    final sessionService = SessionService();
    await sessionService.clearAllSessions();

    await sessionService.recordSession(SessionModeType.focus, 1200); // 20 min
    await sessionService.recordSession(SessionModeType.focus, 2400); // 40 min
    await sessionService.recordSession(SessionModeType.shortBreak, 600); // 10 min

    expect(sessionService.totalSessionCount, 3);
    expect(sessionService.personalRecordFocusSeconds, 2400);
    expect(sessionService.todayBestFocusSeconds, 2400);
    expect(sessionService.todayFocusSeconds, 3600);
    expect(sessionService.todayFocusMinutes, 60);
    expect(sessionService.todayBreakSeconds, 600);
    expect(sessionService.todayFocusCount, 2);
    expect(sessionService.todayBreakCount, 1);
    expect(sessionService.focusToBreakRatio, 6.0); // 3600 / 600 = 6.0
    expect(sessionService.lastFocusDurationSeconds, 2400);

    // Zero or negative durations must be safely rejected
    final invalidSession = await sessionService.recordSession(SessionModeType.focus, 0);
    expect(invalidSession, isNull);
    expect(sessionService.totalSessionCount, 3);
  });

  testWidgets('Squircle deck 4 box lights only illuminate when decided milestone times are up', (WidgetTester tester) async {
    // Stage thresholds with baseline = 1000s, extra3 = 100s, extra4 = 200s:
    // T1 = 700s, T2 = 1000s, T3 = 1100s, T4 = 1300s
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RetroMatteDisk(
          elapsedSeconds: 0,
          isRunning: true,
          isFocusMode: true,
          animate: false,
          baselineSeconds: 1000,
          extra3Seconds: 100,
          extra4Seconds: 200,
        ),
      ),
    ));

    // Initially (t = 0), all 4 lights are unlit
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_1'))).isLit, isFalse);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_2'))).isLit, isFalse);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_3'))).isLit, isFalse);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_4'))).isLit, isFalse);

    // At t = 699s (before T1=700s): all still unlit
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RetroMatteDisk(
          elapsedSeconds: 699,
          isRunning: true,
          isFocusMode: true,
          animate: false,
          baselineSeconds: 1000,
          extra3Seconds: 100,
          extra4Seconds: 200,
        ),
      ),
    ));
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_1'))).isLit, isFalse);

    // At t = 700s (T1 reached): Light 1 glows
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RetroMatteDisk(
          elapsedSeconds: 700,
          isRunning: true,
          isFocusMode: true,
          animate: false,
          baselineSeconds: 1000,
          extra3Seconds: 100,
          extra4Seconds: 200,
        ),
      ),
    ));
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_1'))).isLit, isTrue);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_2'))).isLit, isFalse);

    // At t = 1000s (T2 baseline reached): Lights 1 and 2 glow
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RetroMatteDisk(
          elapsedSeconds: 1000,
          isRunning: true,
          isFocusMode: true,
          animate: false,
          baselineSeconds: 1000,
          extra3Seconds: 100,
          extra4Seconds: 200,
        ),
      ),
    ));
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_1'))).isLit, isTrue);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_2'))).isLit, isTrue);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_3'))).isLit, isFalse);

    // At t = 1100s (T3 reached): Lights 1, 2, and 3 glow
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RetroMatteDisk(
          elapsedSeconds: 1100,
          isRunning: true,
          isFocusMode: true,
          animate: false,
          baselineSeconds: 1000,
          extra3Seconds: 100,
          extra4Seconds: 200,
        ),
      ),
    ));
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_1'))).isLit, isTrue);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_2'))).isLit, isTrue);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_3'))).isLit, isTrue);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_4'))).isLit, isFalse);

    // At t = 1300s (T4 surpassed): All 4 lights glow
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RetroMatteDisk(
          elapsedSeconds: 1300,
          isRunning: true,
          isFocusMode: true,
          animate: false,
          baselineSeconds: 1000,
          extra3Seconds: 100,
          extra4Seconds: 200,
        ),
      ),
    ));
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_1'))).isLit, isTrue);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_2'))).isLit, isTrue);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_3'))).isLit, isTrue);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_4'))).isLit, isTrue);

    // In Rest mode, lights remain unlit even with high elapsedSeconds
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RetroMatteDisk(
          elapsedSeconds: 1300,
          isRunning: true,
          isFocusMode: false, // Rest mode
          animate: false,
          baselineSeconds: 1000,
          extra3Seconds: 100,
          extra4Seconds: 200,
        ),
      ),
    ));
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_1'))).isLit, isFalse);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_2'))).isLit, isFalse);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_3'))).isLit, isFalse);
    expect(tester.widget<StageBoxLight>(find.byKey(const Key('box_light_4'))).isLit, isFalse);
  });
}
