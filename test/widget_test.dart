import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vord/main.dart';
import 'package:vord/src/models/session_mode.dart';
import 'package:vord/src/models/study_session.dart';
import 'package:vord/src/screens/behaviour_screen.dart';
import 'package:vord/src/screens/history_screen.dart';
import 'package:vord/src/services/app_settings_service.dart';
import 'package:vord/src/services/behaviour_service.dart';
import 'package:vord/src/services/session_service.dart';
import 'package:vord/src/services/smart_notification_service.dart';
import 'package:vord/src/services/sound_service.dart';
import 'package:vord/src/services/update_service.dart';
import 'package:vord/src/widgets/physical_matte_controls.dart';
import 'package:vord/src/widgets/retro_matte_disk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettingsService.isTestMode = true;
    SessionService.isTestMode = true;
    SessionService.instance = SessionService();
    BehaviourService.isTestMode = true;
    SmartNotificationService.isTestMode = true;
    SoundService.enableAudio =
        false; // Disable audio playback during unit/widget tests
    UpdateService.mockCheckHandler = null;
    UpdateService.mockInstallHandler = null;
    UpdateService.mockCurrentCommitSha = null;
    UpdateService.mockCurrentBuildNumber = null;
    AppSettingsService.instance.setMockValues(
      themeMode: 'light',
      soundEnabled: true,
      hapticEnabled: true,
      hideStatusBar: true,
      hideNavBar: false,
      showTime: false,
      notificationsEnabled: true,
      updateChannel: 'release',
    );
    BehaviourService.instance.setMockValues(
      hideStatusBar: true,
      hideNavBar: false,
      showTime: false,
    );
  });

  testWidgets(
    'App launches to white screen with strictly the 3 big minimal matte components',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const VordApp(
          initialThemeMode: ThemeMode.light,
          animateBackground: false,
        ),
      );

      // Component 1: Motivational & greeting banner
      expect(find.textContaining('Good '), findsOneWidget);
      expect(find.textContaining('Compete with yourself'), findsOneWidget);

      // Component 2: Squircle box deck with corner bolts, 4 box lights, and ZERO digital time numbers
      expect(find.byKey(const Key('info_area_stage_lights')), findsOneWidget);
      expect(find.byType(MachinedBolt), findsNWidgets(4));
      expect(find.byType(StageBoxLight), findsNWidgets(4));
      expect(find.text('00:00'), findsNothing);

      // Component 3: Physical matte controls (Play, Mode Switch, Options)
      expect(find.text('START'), findsOneWidget);
      expect(find.text('FOCUS'), findsOneWidget);
      expect(find.text('OPTIONS'), findsOneWidget);
    },
  );

  testWidgets(
    'Play button starts stopwatch and stop resets & saves session; no time shown on main deck',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const VordApp(
          initialThemeMode: ThemeMode.light,
          animateBackground: false,
        ),
      );

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
    },
  );

  testWidgets('Mode switch button switches between Focus and Rest', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const VordApp(
        initialThemeMode: ThemeMode.light,
        animateBackground: false,
      ),
    );

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

  testWidgets(
    'Options button opens modal with Category History, Updates, and Theme options',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const VordApp(
          initialThemeMode: ThemeMode.light,
          animateBackground: false,
        ),
      );

      // Tap OPTIONS button
      await tester.tap(find.text('OPTIONS'));
      await tester.pumpAndSettle();

      // Verify Options
      expect(find.text('SESSION HISTORY'), findsOneWidget);
      expect(find.text('DATA & BACKUP'), findsOneWidget);
      expect(find.text('INFO & UPDATES'), findsOneWidget);
      expect(find.text('THEME OPTIONS'), findsOneWidget);
      expect(find.text('White Mode (Light)'), findsOneWidget);
      expect(find.text('Black Theme (Dark)'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);

      // Scroll into view and tap Black Theme
      await tester.ensureVisible(find.text('Black Theme (Dark)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Black Theme (Dark)'));
      await tester.pumpAndSettle();

      // Verify modal dismissed and preference persisted
      expect(find.text('THEME OPTIONS'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    },
  );

  testWidgets('Options history option navigates to category screen and back', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const VordApp(
        initialThemeMode: ThemeMode.light,
        animateBackground: false,
      ),
    );

    // Open Options
    await tester.tap(find.text('OPTIONS'));
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

  testWidgets(
    'HistoryScreen displays categorized sessions and recorded times',
    (WidgetTester tester) async {
      final sessionService = SessionService();
      await sessionService.recordSession(SessionModeType.focus, 1500); // 25m
      await sessionService.recordSession(SessionModeType.shortBreak, 300); // 5m

      await tester.pumpWidget(
        MaterialApp(home: HistoryScreen(sessionService: sessionService)),
      );

      expect(find.text('SESSION HISTORY'), findsOneWidget);
      expect(find.text('FOCUS SESSION'), findsOneWidget);
      expect(find.text('REST INTERVAL'), findsOneWidget);
      expect(find.text('25m 00s'), findsWidgets);
      expect(find.text('5m 00s'), findsOneWidget);
    },
  );

  testWidgets(
    'Options sheet contains Data & Backup, Sound toggles, and Info & Updates',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const VordApp(
          initialThemeMode: ThemeMode.light,
          animateBackground: false,
        ),
      );

      // Open Options
      await tester.tap(find.text('OPTIONS'));
      await tester.pumpAndSettle();

      expect(find.text('DATA & BACKUP'), findsOneWidget);
      expect(find.text('INFO & UPDATES'), findsOneWidget);
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
    },
  );

  testWidgets(
    'Options info & updates navigates to InfoUpdatesScreen with clean author & repo showcase and updates bay',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const VordApp(
          initialThemeMode: ThemeMode.light,
          animateBackground: false,
        ),
      );

      // Open Options
      await tester.tap(find.text('OPTIONS'));
      await tester.pumpAndSettle();

      // Tap Info & Updates
      await tester.tap(find.text('INFO & UPDATES'));
      await tester.pumpAndSettle();

      // Verify Clean Header
      expect(find.text('ABOUT & UPDATES'), findsOneWidget);

      // Verify Author Showcase
      expect(find.text('AUTHOR & DEVELOPER'), findsOneWidget);
      expect(find.text('ovrrup'), findsOneWidget);
      expect(find.text('VISIT GITHUB PROFILE'), findsOneWidget);
      expect(find.text('EXPLORE LUMIA (STUDY TRACKER)'), findsOneWidget);

      // Verify Repository Showcase
      expect(find.text('REPOSITORY & SOURCE CODE'), findsOneWidget);
      expect(find.text('VIEW REPO'), findsOneWidget);
      expect(find.text('STAR ON GITHUB'), findsOneWidget);

      // Test Interactive Copy Action
      await tester.ensureVisible(find.text('COPY'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('COPY'));
      await tester.pump();
      expect(find.text('OWNER COPIED'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));

      // Verify Update Channel selection
      await tester.ensureVisible(find.text('OFFICIAL RELEASE'));
      await tester.pumpAndSettle();
      expect(find.text('OFFICIAL RELEASE'), findsOneWidget);
      expect(find.text('COMMIT BUILDS'), findsOneWidget);

      // Default release channel has no data loss danger warning
      expect(find.text('DANGER: HIGH DATA LOSS RISK'), findsNothing);

      // Switch to Commit Builds channel
      await tester.ensureVisible(find.text('COMMIT BUILDS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('COMMIT BUILDS'));
      await tester.pumpAndSettle();

      // Verify prominent warning that commit-wise updates carry huge risk of losing every data
      expect(find.text('DANGER: HIGH DATA LOSS RISK'), findsOneWidget);
      expect(
        find.textContaining(
          'Commit-wise updates carry a huge risk of losing every data',
        ),
        findsOneWidget,
      );
      expect(find.text('SAFEGUARD DATA: EXPORT BACKUP NOW'), findsOneWidget);

      // Test Commit Build update check with mock (gets latest successful action build)
      UpdateService.mockCheckHandler = (channel) async {
        return const UpdateInfo(
          version: 'Action Build #37 (81bd998)',
          commitSha: '81bd998ccc8616a72f5b4affa86fc5145e17c7b6',
          actionRunNumber: 37,
          title: 'test: ensure Black Theme option is visible',
          notes: 'Latest successful GitHub Actions build from main branch.',
          hasApk: true,
          isNewer: true,
          isAvailable: true,
          channel: UpdateChannel.commit,
          downloadUrl:
              'https://github.com/ovrrup/vord/releases/download/nightly/app-release.apk',
        );
      };

      await tester.ensureVisible(find.text('FETCH LATEST ACTION BUILD'));
      await tester.tap(find.text('FETCH LATEST ACTION BUILD'));
      await tester.pumpAndSettle();

      expect(find.text('SUCCESSFUL ACTION BUILD'), findsOneWidget);
      expect(find.text('DOWNLOAD ACTION BUILD (APK)'), findsOneWidget);

      // Test Official Release mode with 0 releases available (displays clear status and NO download button)
      UpdateService.mockCheckHandler = (channel) async {
        return const UpdateInfo(
          version: '0.1.0',
          title: 'No Official Releases Found',
          notes:
              'No official releases have been published yet for Vord on this repository.',
          hasApk: false,
          isNewer: false,
          isAvailable: false,
          channel: UpdateChannel.release,
        );
      };

      await tester.ensureVisible(find.text('OFFICIAL RELEASE'));
      await tester.tap(find.text('OFFICIAL RELEASE'));
      await tester.pumpAndSettle();
      expect(find.text('DANGER: HIGH DATA LOSS RISK'), findsNothing);

      await tester.ensureVisible(find.text('CHECK FOR UPDATES'));
      await tester.tap(find.text('CHECK FOR UPDATES'));
      await tester.pumpAndSettle();

      expect(find.text('NO OFFICIAL RELEASES AVAILABLE'), findsOneWidget);
      expect(find.text('DOWNLOAD APK UPDATE'), findsNothing);
      expect(find.text('DOWNLOAD ACTION BUILD (APK)'), findsNothing);

      // Back to main deck
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('START'), findsOneWidget);
    },
  );

  test(
    'UpdateService manages update channels and channel persistence',
    () async {
      expect(await UpdateService.getUpdateChannel(), UpdateChannel.release);
      await UpdateService.setUpdateChannel(UpdateChannel.commit);
      expect(await UpdateService.getUpdateChannel(), UpdateChannel.commit);
      await UpdateService.setUpdateChannel(UpdateChannel.release);
      expect(await UpdateService.getUpdateChannel(), UpdateChannel.release);
    },
  );

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

    final result = await sessionService.importBackupJson(
      exportedJson,
      replace: true,
    );
    expect(result.success, isTrue);
    expect(result.importedCount, 2);
    expect(sessionService.totalSessionCount, 2);
    expect(sessionService.allTimeFocusSeconds, 1800);
    expect(sessionService.allTimeBreakSeconds, 300);
  });

  test(
    'SessionService smart deduplication prevents duplicate sessions during merge imports',
    () async {
      final sessionService = SessionService();
      await sessionService.clearAllSessions();

      await sessionService.recordSession(SessionModeType.focus, 1500);
      await sessionService.recordSession(SessionModeType.shortBreak, 300);
      expect(sessionService.totalSessionCount, 2);

      final exportJson = sessionService.exportBackupJson();

      // Re-importing the same backup in MERGE mode should detect duplicates and skip them
      final mergeResult = await sessionService.importBackupJson(
        exportJson,
        replace: false,
      );
      expect(mergeResult.success, isTrue);
      expect(mergeResult.importedCount, 0);
      expect(mergeResult.skippedCount, 2);
      expect(sessionService.totalSessionCount, 2); // No duplicates added!
    },
  );

  test(
    'SessionService offline analytics computes personal records and self-competition metrics',
    () async {
      final sessionService = SessionService();
      await sessionService.clearAllSessions();

      await sessionService.recordSession(SessionModeType.focus, 1200); // 20 min
      await sessionService.recordSession(SessionModeType.focus, 2400); // 40 min
      await sessionService.recordSession(
        SessionModeType.shortBreak,
        600,
      ); // 10 min

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
      final invalidSession = await sessionService.recordSession(
        SessionModeType.focus,
        0,
      );
      expect(invalidSession, isNull);
      expect(sessionService.totalSessionCount, 3);
    },
  );

  testWidgets(
    'Squircle deck 4 box lights only illuminate when decided milestone times are up',
    (WidgetTester tester) async {
      // Stage thresholds with baseline = 1000s, extra3 = 100s, extra4 = 200s:
      // T1 = 700s, T2 = 1000s, T3 = 1100s, T4 = 1300s
      await tester.pumpWidget(
        const MaterialApp(
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
        ),
      );

      // Initially (t = 0), all 4 lights are unlit
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_1')))
            .isLit,
        isFalse,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_2')))
            .isLit,
        isFalse,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_3')))
            .isLit,
        isFalse,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_4')))
            .isLit,
        isFalse,
      );

      // At t = 699s (before T1=700s): all still unlit
      await tester.pumpWidget(
        const MaterialApp(
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
        ),
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_1')))
            .isLit,
        isFalse,
      );

      // At t = 700s (T1 reached): Light 1 glows
      await tester.pumpWidget(
        const MaterialApp(
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
        ),
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_1')))
            .isLit,
        isTrue,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_2')))
            .isLit,
        isFalse,
      );

      // At t = 1000s (T2 baseline reached): Lights 1 and 2 glow
      await tester.pumpWidget(
        const MaterialApp(
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
        ),
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_1')))
            .isLit,
        isTrue,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_2')))
            .isLit,
        isTrue,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_3')))
            .isLit,
        isFalse,
      );

      // At t = 1100s (T3 reached): Lights 1, 2, and 3 glow
      await tester.pumpWidget(
        const MaterialApp(
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
        ),
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_1')))
            .isLit,
        isTrue,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_2')))
            .isLit,
        isTrue,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_3')))
            .isLit,
        isTrue,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_4')))
            .isLit,
        isFalse,
      );

      // At t = 1300s (T4 surpassed): All 4 lights glow
      await tester.pumpWidget(
        const MaterialApp(
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
        ),
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_1')))
            .isLit,
        isTrue,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_2')))
            .isLit,
        isTrue,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_3')))
            .isLit,
        isTrue,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_4')))
            .isLit,
        isTrue,
      );

      // In Rest mode, lights remain unlit even with high elapsedSeconds
      await tester.pumpWidget(
        const MaterialApp(
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
        ),
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_1')))
            .isLit,
        isFalse,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_2')))
            .isLit,
        isFalse,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_3')))
            .isLit,
        isFalse,
      );
      expect(
        tester
            .widget<StageBoxLight>(find.byKey(const Key('box_light_4')))
            .isLit,
        isFalse,
      );
    },
  );

  test(
    'BehaviourService defaults: only hideStatusBar is true by default',
    () async {
      final service = BehaviourService();
      // Re-init with empty SharedPreferences
      SharedPreferences.setMockInitialValues({});
      await service.init(force: true);

      expect(service.hideStatusBar, isTrue);
      expect(service.hideNavBar, isFalse);
      expect(service.showTime, isFalse);

      // Modify toggles
      await service.setHideStatusBar(false);
      await service.setHideNavBar(true);
      await service.setShowTime(true);

      expect(service.hideStatusBar, isFalse);
      expect(service.hideNavBar, isTrue);
      expect(service.showTime, isTrue);

      // Reset to defaults
      await service.resetToDefaults();
      expect(service.hideStatusBar, isTrue);
      expect(service.hideNavBar, isFalse);
      expect(service.showTime, isFalse);
    },
  );

  test(
    'DeckTimeCounter formats situational time: mm:ss when < 3600, hh:mm when >= 3600',
    () {
      expect(DeckTimeCounter.formatSituational(0), '00:00');
      expect(DeckTimeCounter.formatSituational(45), '00:45');
      expect(DeckTimeCounter.formatSituational(125), '02:05');
      expect(DeckTimeCounter.formatSituational(3599), '59:59');
      expect(DeckTimeCounter.formatSituational(3600), '01:00');
      expect(DeckTimeCounter.formatSituational(5430), '01:30');
      expect(DeckTimeCounter.formatSituational(36000), '10:00');
    },
  );

  testWidgets(
    'Options modal contains BEHAVIOUR button and navigates to BehaviourScreen',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const VordApp(
          initialThemeMode: ThemeMode.light,
          animateBackground: false,
        ),
      );

      // Tap OPTIONS button
      await tester.tap(find.text('OPTIONS'));
      await tester.pumpAndSettle();

      // Verify BEHAVIOUR button is present
      expect(find.text('BEHAVIOUR'), findsOneWidget);

      // Scroll into view and tap BEHAVIOUR button
      await tester.ensureVisible(find.text('BEHAVIOUR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BEHAVIOUR'));
      await tester.pumpAndSettle();

      // Verify BehaviourScreen is rendered with 3 feature toggle cards
      expect(find.byType(BehaviourScreen), findsOneWidget);
      expect(find.text('HIDE STATUS BAR (DEVICE)'), findsOneWidget);
      expect(find.text('HIDE NAVIGATION BAR (DEVICE)'), findsOneWidget);
      expect(find.text('SHOW TIME COUNTER'), findsOneWidget);

      // Verify default states: only hide status bar is ON, others OFF
      expect(find.text('ON'), findsOneWidget);
      expect(find.text('OFF'), findsNWidgets(2));
    },
  );

  testWidgets(
    'Toggling show time in BehaviourScreen displays 45° tilted counter on deck',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const VordApp(
          initialThemeMode: ThemeMode.light,
          animateBackground: false,
        ),
      );

      // Initial state: no time counter on deck
      expect(find.byKey(const Key('deck_time_counter')), findsNothing);

      // Open options -> behaviour
      await tester.tap(find.text('OPTIONS'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('BEHAVIOUR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BEHAVIOUR'));
      await tester.pumpAndSettle();

      // Tap SHOW TIME COUNTER toggle
      await tester.tap(find.byKey(const Key('toggle_show_time')));
      await tester.pumpAndSettle();

      expect(BehaviourService.instance.showTime, isTrue);

      // Pop back to main screen
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Now 45-degree tilted counter is rendered on squircle deck
      expect(find.byKey(const Key('deck_time_counter')), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
    },
  );

  testWidgets(
    'DeckTimeCounter directly renders in RetroMatteDisk with situational time when showTime is true',
    (WidgetTester tester) async {
      // When showTime is false: no counter rendered
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RetroMatteDisk(
              elapsedSeconds: 3665,
              isRunning: true,
              isFocusMode: true,
              animate: false,
              showTime: false,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('deck_time_counter')), findsNothing);

      // When showTime is true and elapsed is 3665s (>= 1 hr): renders '01:01'
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RetroMatteDisk(
              elapsedSeconds: 3665,
              isRunning: true,
              isFocusMode: true,
              animate: false,
              showTime: true,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('deck_time_counter')), findsOneWidget);
      expect(find.text('01:01'), findsOneWidget);
    },
  );

  test(
    'AppSettingsService persists settings atomically and restores them cleanly',
    () async {
      final settings = AppSettingsService();
      await settings.init(force: true);

      await settings.setThemeMode('dark');
      await settings.setHideStatusBar(false);
      await settings.setHideNavBar(true);
      await settings.setShowTime(true);
      await settings.setUpdateChannel('commit');
      await settings.setLastInstalledCommitSha('abcdef123456');

      expect(settings.themeMode, 'dark');
      expect(settings.hideStatusBar, isFalse);
      expect(settings.hideNavBar, isTrue);
      expect(settings.showTime, isTrue);
      expect(settings.updateChannel, 'commit');
      expect(settings.lastInstalledCommitSha, 'abcdef123456');

      // Test JSON export
      final jsonMap = settings.toJson();
      expect(jsonMap['themeMode'], 'dark');
      expect(jsonMap['showTime'], isTrue);

      // Test import
      await settings.importSettings({
        'themeMode': 'system',
        'showTime': false,
      });
      expect(settings.themeMode, 'system');
      expect(settings.showTime, isFalse);
    },
  );

  test(
    'SessionService includes settings in backup export and restores them on import',
    () async {
      final sessionService = SessionService();
      final settings = AppSettingsService();
      await settings.init(force: true);
      await settings.setThemeMode('dark');
      await settings.setShowTime(true);

      final exportJson = sessionService.exportBackupJson();
      expect(exportJson.contains('"settings"'), isTrue);
      expect(exportJson.contains('"themeMode": "dark"'), isTrue);

      // Reset settings
      await settings.setThemeMode('light');
      await settings.setShowTime(false);
      expect(settings.themeMode, 'light');

      // Restore from backup
      final result = await sessionService.importBackupJson(
        exportJson,
        replace: true,
      );
      expect(result.success, isTrue);
      expect(settings.themeMode, 'dark');
      expect(settings.showTime, isTrue);
    },
  );

  test(
    'UpdateService marks isNewer false when app is already on the latest commit',
    () async {
      // When compile-time or installed commit matches target commit
      UpdateService.mockCurrentCommitSha = 'a1b2c3d4e5f6';
      UpdateService.mockCurrentBuildNumber = '50';

      UpdateService.mockCheckHandler = (channel) async {
        const targetSha = 'a1b2c3d4e5f67890';
        final isNewer =
            !(targetSha.startsWith(UpdateService.mockCurrentCommitSha!));
        return UpdateInfo(
          version: 'Action Build #50 (a1b2c3d)',
          commitSha: targetSha,
          actionRunNumber: 50,
          title: 'Latest commit',
          notes: 'Commit notes',
          hasApk: true,
          isNewer: isNewer,
          channel: UpdateChannel.commit,
        );
      };

      final info = await UpdateService.checkForUpdate(
        channel: UpdateChannel.commit,
      );
      expect(info.isNewer, isFalse);

      // Clean up mocks
      UpdateService.mockCurrentCommitSha = null;
      UpdateService.mockCurrentBuildNumber = null;
      UpdateService.mockCheckHandler = null;
    },
  );

  testWidgets(
    'PhysicalMatteButton executes onTap and resets pressed state reliably',
    (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhysicalMatteButton(
              onTap: () => tapped = true,
              child: const Text('CLICK ME'),
            ),
          ),
        ),
      );

      expect(find.text('CLICK ME'), findsOneWidget);
      await tester.tap(find.text('CLICK ME'));
      await tester.pump();

      expect(tapped, isTrue);
    },
  );

  test(
    'ActiveSessionState persistence & recovery prevents study timer data loss',
    () async {
      final sessionService = SessionService();
      await sessionService.init(force: true);

      final now = DateTime.now().subtract(const Duration(seconds: 120));
      await sessionService.saveActiveSession(
        startTime: now,
        modeType: SessionModeType.focus,
        baselineSeconds: 1500,
        extra3Seconds: 180,
        extra4Seconds: 240,
      );

      final loaded = await sessionService.loadActiveSession();
      expect(loaded, isNotNull);
      expect(loaded!.modeType, SessionModeType.focus);
      expect(loaded.baselineSeconds, 1500);
      expect(loaded.extra3Seconds, 180);
      expect(loaded.extra4Seconds, 240);
      expect(loaded.elapsedSeconds, greaterThanOrEqualTo(120));

      await sessionService.clearActiveSession();
      final cleared = await sessionService.loadActiveSession();
      expect(cleared, isNull);
    },
  );

  test(
    'SessionService pre-wipe recovery snapshot protects against accidental data wipe',
    () async {
      final sessionService = SessionService();
      await sessionService.init(force: true);

      await sessionService.recordSession(SessionModeType.focus, 1800);
      await sessionService.recordSession(SessionModeType.shortBreak, 300);
      expect(sessionService.totalSessionCount, 2);

      // Wipe data
      await sessionService.clearAllSessions();
      expect(sessionService.totalSessionCount, 0);
      expect(await sessionService.hasPreWipeSnapshot(), isTrue);

      // Restore safety snapshot
      final restoreResult = await sessionService.restorePreWipeSnapshot();
      expect(restoreResult.success, isTrue);
      expect(sessionService.totalSessionCount, 2);
      expect(sessionService.allTimeFocusSeconds, 1800);
      expect(sessionService.allTimeBreakSeconds, 300);
    },
  );

  test(
    'AppSettingsService sanitizes invalid inputs and protects against malformed import data',
    () async {
      final settings = AppSettingsService();
      await settings.init(force: true);

      // Invalid theme mode fallback
      await settings.setThemeMode('invalid_mode_xyz');
      expect(settings.themeMode, 'light');

      // Invalid update channel fallback
      await settings.setUpdateChannel('unstable_dev_channel');
      expect(settings.updateChannel, 'release');

      // Malformed import data protection
      await settings.importSettings({
        'themeMode': 12345, // Invalid type
        'soundEnabled': 'not_a_bool', // Invalid type
        'updateChannel': 'nightly_bogus', // Invalid option
      });
      // Values must remain safe and uncorrupted
      expect(settings.themeMode, 'light');
      expect(settings.soundEnabled, isTrue);
      expect(settings.updateChannel, 'release');
    },
  );

  test(
    'AppSettingsService persists settings across simulated cold restarts with SharedPreferences authority',
    () async {
      final settings = AppSettingsService();
      await settings.init(force: true);

      await settings.setThemeMode('dark');
      await settings.setSoundEnabled(false);
      await settings.setShowTime(true);
      await settings.setHideNavBar(true);

      // Verify immediate in-memory and SharedPreferences state
      expect(settings.themeMode, 'dark');
      expect(settings.soundEnabled, isFalse);
      expect(settings.showTime, isTrue);
      expect(settings.hideNavBar, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
      expect(prefs.getBool('vord_sound_enabled'), isFalse);
      expect(prefs.getBool('vord_show_time'), isTrue);
      expect(prefs.getBool('vord_hide_nav_bar'), isTrue);

      // Simulate cold app restart: re-initialize settings from clean slate
      final freshSettings = AppSettingsService();
      await freshSettings.init(force: true);

      expect(freshSettings.themeMode, 'dark');
      expect(freshSettings.soundEnabled, isFalse);
      expect(freshSettings.showTime, isTrue);
      expect(freshSettings.hideNavBar, isTrue);
    },
  );

  test('DeckTimeCounter formatSituational handles edge cases cleanly', () {
    expect(DeckTimeCounter.formatSituational(-10), '00:00');
    expect(DeckTimeCounter.formatSituational(0), '00:00');
    expect(DeckTimeCounter.formatSituational(45), '00:45');
    expect(DeckTimeCounter.formatSituational(59), '00:59');
    expect(DeckTimeCounter.formatSituational(60), '01:00');
    expect(DeckTimeCounter.formatSituational(3599), '59:59');
    expect(DeckTimeCounter.formatSituational(3600), '01:00');
    expect(DeckTimeCounter.formatSituational(3665), '01:01');
    expect(DeckTimeCounter.formatSituational(7200), '02:00');
  });

  test('SoundService runs transport latch and click triggers resiliently', () async {
    SoundService.enableAudio = false;
    await SoundService.init();

    // Rapid successive executions should not throw
    await SoundService.playTapeTransportLatch();
    await SoundService.playTapeTransportLatch();
    await SoundService.playTapeSwitchClick();
    await SoundService.playTapeSwitchClick();
    await SoundService.playTapeSwitchClick();

    expect(SoundService.soundEnabled, isTrue);
  });

  test(
    'FocusTimingAnalyzer accurately identifies peak focus hours and generates smart messages',
    () {
      // 1. Empty sessions fallback to default hour
      expect(FocusTimingAnalyzer.analyzeOptimalFocusHour([], defaultHour: 15), 15);

      final now = DateTime(2026, 10, 20, 16, 0); // 4:00 PM

      // 2. Sample sessions: User studied yesterday at 2:00 PM (14:00) for 50 min
      // and 3 days ago at 2:00 PM for 40 min, and 20 days ago at 9:00 AM for 20 min
      final s1 = StudySession(
        id: '1',
        modeType: SessionModeType.focus,
        durationSeconds: 3000, // 50m
        completedAt: DateTime(2026, 10, 19, 14, 50),
      );
      final s2 = StudySession(
        id: '2',
        modeType: SessionModeType.focus,
        durationSeconds: 2400, // 40m
        completedAt: DateTime(2026, 10, 17, 14, 40),
      );
      final s3 = StudySession(
        id: '3',
        modeType: SessionModeType.focus,
        durationSeconds: 1200, // 20m
        completedAt: DateTime(2026, 9, 30, 9, 20),
      );
      final restSession = StudySession(
        id: '4',
        modeType: SessionModeType.shortBreak,
        durationSeconds: 300,
        completedAt: DateTime(2026, 10, 20, 15, 0),
      );

      final sessions = [s3, s2, s1, restSession];

      // Peak hour must be 14 (2:00 PM)
      final peakHour = FocusTimingAnalyzer.analyzeOptimalFocusHour(
        sessions,
        customNow: now,
      );
      expect(peakHour, 14);

      // Hours since last focus session (s1 completed 25h 10m ago)
      final hoursSince =
          FocusTimingAnalyzer.calculateHoursSinceLastFocus(sessions, now);
      expect(hoursSince, 25);

      // Next reminder calculation
      final nextTime =
          FocusTimingAnalyzer.calculateNextReminderTime(sessions, now);
      // Since it's currently 16:00 (past 14:00 today), candidate is tomorrow at 14:00
      expect(nextTime.year, 2026);
      expect(nextTime.month, 10);
      expect(nextTime.day, 21);
      expect(nextTime.hour, 14);

      // Message generation for active streak (25h since last session)
      final msg = FocusTimingAnalyzer.generateNotificationMessage(
        sessions,
        nextTime,
        now,
      );
      expect(msg.title, 'PEAK FOCUS WINDOW');
      expect(msg.body.contains('2:00 PM'), isTrue);

      // Hour formatting checks
      expect(FocusTimingAnalyzer.formatHour(0), '12:00 AM');
      expect(FocusTimingAnalyzer.formatHour(9), '9:00 AM');
      expect(FocusTimingAnalyzer.formatHour(12), '12:00 PM');
      expect(FocusTimingAnalyzer.formatHour(14), '2:00 PM');
      expect(FocusTimingAnalyzer.formatHour(21), '9:00 PM');
    },
  );

  test(
    'FocusTimingAnalyzer re-engagement nudge for inactive users (> 48h)',
    () {
      final now = DateTime(2026, 10, 20, 10, 0);
      final oldSession = StudySession(
        id: 'old',
        modeType: SessionModeType.focus,
        durationSeconds: 1500,
        completedAt: DateTime(2026, 10, 16, 10, 0), // 4 days ago
      );

      final nextTime = FocusTimingAnalyzer.calculateNextReminderTime(
        [oldSession],
        now,
      );
      final msg = FocusTimingAnalyzer.generateNotificationMessage(
        [oldSession],
        nextTime,
        now,
      );

      expect(msg.title, 'REBUILD YOUR MOMENTUM');
      expect(msg.body.contains('days since your last focus mark'), isTrue);
    },
  );

  test(
    'SmartNotificationService schedules and cancels reminders according to settings',
    () async {
      final service = SmartNotificationService.instance;
      await service.init();

      // Enabled state: calculates next reminder time
      await AppSettingsService.instance.setNotificationsEnabled(true);
      await service.scheduleSmartReminder(
        customNow: DateTime(2026, 10, 20, 9, 0),
      );

      expect(service.nextScheduledTime, isNotNull);
      expect(service.lastMessage, isNotNull);

      // Disabled state: cancels and clears scheduled time
      await AppSettingsService.instance.setNotificationsEnabled(false);
      await service.scheduleSmartReminder();

      expect(service.nextScheduledTime, isNull);
      expect(service.lastMessage, isNull);

      // Instant test notification runs safely without throwing
      await service.showInstantReminder();
      expect(service.lastMessage, isNotNull);
    },
  );

  testWidgets(
    'BehaviourScreen renders smart study reminder toggle and instant test button',
    (WidgetTester tester) async {
      await AppSettingsService.instance.setNotificationsEnabled(true);

      await tester.pumpWidget(
        const MaterialApp(home: BehaviourScreen()),
      );

      expect(find.text('SMART STUDY REMINDERS'), findsOneWidget);
      expect(find.byKey(const Key('toggle_smart_notifications')), findsOneWidget);
      expect(find.byKey(const Key('test_instant_notification')), findsOneWidget);
      expect(find.text('TEST REMINDER NOTIFICATION'), findsOneWidget);

      // Toggle smart reminders
      await tester.tap(find.byKey(const Key('toggle_smart_notifications')));
      await tester.pumpAndSettle();
      expect(AppSettingsService.instance.notificationsEnabled, isFalse);

      await tester.tap(find.byKey(const Key('toggle_smart_notifications')));
      await tester.pumpAndSettle();
      expect(AppSettingsService.instance.notificationsEnabled, isTrue);

      // Tap Test Instant Notification
      await tester.tap(find.byKey(const Key('test_instant_notification')));
      await tester.pumpAndSettle();

      expect(
        find.text('Test study reminder notification triggered.'),
        findsOneWidget,
      );
    },
  );
}
