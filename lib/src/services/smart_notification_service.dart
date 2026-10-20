import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/session_mode.dart';
import '../models/study_session.dart';
import 'app_settings_service.dart';
import 'session_service.dart';

/// Clean model representing a generated smart reminder notification.
class SmartNotificationMessage {
  final String title;
  final String body;
  final String payload;

  const SmartNotificationMessage({
    required this.title,
    required this.body,
    this.payload = 'vord://focus',
  });

  @override
  String toString() => 'SmartNotificationMessage(title: $title, body: $body)';
}

/// Offline intelligence engine that analyzes the user's historical study patterns,
/// computes peak focus hours, tracks recency gaps, and calculates optimal reminder timings.
class FocusTimingAnalyzer {
  /// Analyzes past focus sessions to find the hour of day (0-23) when the user
  /// historically accomplishes the highest focus volume, with recency weighting.
  static int analyzeOptimalFocusHour(
    List<StudySession> sessions, {
    int defaultHour = 14, // 2:00 PM default if no history
    DateTime? customNow,
  }) {
    final now = customNow ?? DateTime.now();
    final focusSessions =
        sessions.where((s) => s.modeType == SessionModeType.focus).toList();

    if (focusSessions.isEmpty) {
      return defaultHour;
    }

    final hourScores = <int, double>{};

    for (final session in focusSessions) {
      final localStart = session.startedAt.toLocal();
      final hour = localStart.hour;

      // Recency weighting: recent days contribute more significantly
      final daysAgo = now.difference(session.completedAt).inDays;
      final double recencyMultiplier;
      if (daysAgo <= 7) {
        recencyMultiplier = 1.6;
      } else if (daysAgo <= 30) {
        recencyMultiplier = 1.0;
      } else {
        recencyMultiplier = 0.5;
      }

      // Weight by minutes spent focusing
      final score = (session.durationSeconds / 60.0) * recencyMultiplier;
      hourScores[hour] = (hourScores[hour] ?? 0.0) + score;
    }

    if (hourScores.isEmpty) return defaultHour;

    int bestHour = defaultHour;
    double maxScore = -1.0;

    for (final entry in hourScores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        bestHour = entry.key;
      }
    }

    return bestHour;
  }

  /// Calculates hours elapsed since the user's most recent focus session.
  /// Returns -1 if no focus sessions exist.
  static int calculateHoursSinceLastFocus(
    List<StudySession> sessions,
    DateTime now,
  ) {
    final focusSessions =
        sessions.where((s) => s.modeType == SessionModeType.focus).toList();
    if (focusSessions.isEmpty) return -1;
    final last = focusSessions.last;
    return math.max(0, now.difference(last.completedAt).inHours);
  }

  /// Calculates the next optimal reminder timestamp based on historical habits.
  static DateTime calculateNextReminderTime(
    List<StudySession> sessions,
    DateTime now,
  ) {
    final optimalHour = analyzeOptimalFocusHour(sessions, customNow: now);
    final focusSessions =
        sessions.where((s) => s.modeType == SessionModeType.focus).toList();

    // Start with target at the optimal hour today
    var candidate = DateTime(now.year, now.month, now.day, optimalHour, 0);

    // If candidate has already passed today
    if (now.isAfter(candidate)) {
      if (now.hour == optimalHour && now.minute < 45) {
        // Still within the peak hour: schedule 15 minutes from now
        candidate = now.add(const Duration(minutes: 15));
      } else {
        // Target tomorrow's peak hour
        candidate = candidate.add(const Duration(days: 1));
      }
    }

    // Guard: if user completed a focus session in the last 90 minutes,
    // don't harass them immediately today; schedule for tomorrow
    if (focusSessions.isNotEmpty) {
      final lastCompleted = focusSessions.last.completedAt;
      final minutesSinceLast = now.difference(lastCompleted).inMinutes;
      if (minutesSinceLast < 90 && candidate.difference(now).inHours < 4) {
        candidate = DateTime(now.year, now.month, now.day + 1, optimalHour, 0);
      }
    }

    return candidate;
  }

  /// Generates a customized, respectful notification message tailored to
  /// whether the user is maintaining a streak, needs a re-engagement nudge,
  /// or is starting fresh.
  static SmartNotificationMessage generateNotificationMessage(
    List<StudySession> sessions,
    DateTime nextTime,
    DateTime now,
  ) {
    final focusSessions =
        sessions.where((s) => s.modeType == SessionModeType.focus).toList();
    final optimalHour = analyzeOptimalFocusHour(sessions, customNow: now);
    final formattedHour = formatHour(optimalHour);

    if (focusSessions.isEmpty) {
      return const SmartNotificationMessage(
        title: 'START YOUR FIRST SESSION',
        body: 'Set your first focus milestone today. Ready when you are.',
      );
    }

    final lastSession = focusSessions.last;
    final hoursSinceLast = now.difference(lastSession.completedAt).inHours;

    if (hoursSinceLast >= 48) {
      final days = math.max(2, hoursSinceLast ~/ 24);
      return SmartNotificationMessage(
        title: 'REBUILD YOUR MOMENTUM',
        body:
            'It has been $days days since your last focus mark. Step back to your desk and lock in.',
      );
    }

    if (hoursSinceLast >= 20) {
      return SmartNotificationMessage(
        title: 'PEAK FOCUS WINDOW',
        body:
            'You usually focus best around $formattedHour. Keep your study streak alive!',
      );
    }

    return SmartNotificationMessage(
      title: 'TIME TO FOCUS',
      body:
          'A quiet study interval awaits. Ready to beat your previous mark?',
    );
  }

  /// Formats an hour integer (0-23) into clean readable 12-hour format.
  static String formatHour(int hour) {
    final clamped = hour.clamp(0, 23);
    if (clamped == 0) return '12:00 AM';
    if (clamped < 12) return '$clamped:00 AM';
    if (clamped == 12) return '12:00 PM';
    return '${clamped - 12}:00 PM';
  }
}

/// Service providing intelligent, 100% offline local notifications
/// that schedule reminders according to the user's analyzed study patterns.
class SmartNotificationService {
  static const int reminderNotificationId = 101;
  static const int instantTestNotificationId = 102;
  static const String channelId = 'vord_study_reminders';
  static const String channelName = 'Study & Focus Reminders';
  static const String channelDescription =
      'Intelligent offline reminders analyzing your optimal study habits.';

  static final SmartNotificationService instance =
      SmartNotificationService._internal();

  factory SmartNotificationService() => instance;

  SmartNotificationService._internal();

  // Test mode flag
  static bool isTestMode = false;
  static bool get _inTest =>
      isTestMode ||
      Platform.environment.containsKey('FLUTTER_TEST') ||
      (WidgetsBinding.instance.runtimeType.toString().contains('Test'));

  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;
  DateTime? _nextScheduledTime;
  SmartNotificationMessage? _lastMessage;

  bool get isInitialized => _initialized;
  DateTime? get nextScheduledTime => _nextScheduledTime;
  SmartNotificationMessage? get lastMessage => _lastMessage;

  int get optimalFocusHour => FocusTimingAnalyzer.analyzeOptimalFocusHour(
        SessionService.instance.sessions,
      );

  /// Initializes timezone data and local notifications plugin.
  Future<void> init() async {
    if (_initialized) return;

    if (_inTest) {
      _initialized = true;
      return;
    }

    try {
      tz.initializeTimeZones();

      _plugin = FlutterLocalNotificationsPlugin();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin?.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Create Android Notification Channel
      final androidPlugin = _plugin?.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }

      _initialized = true;
    } catch (e) {
      debugPrint('SmartNotificationService init error: $e');
      _initialized = true;
    }
  }

  /// Requests notification permissions on Android 13+ and iOS.
  Future<bool> requestPermissions() async {
    if (_inTest) return true;

    try {
      if (Platform.isAndroid) {
        final androidPlugin = _plugin?.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted =
            await androidPlugin?.requestNotificationsPermission() ?? false;
        return granted;
      } else if (Platform.isIOS) {
        final iosPlugin = _plugin?.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        return granted;
      }
    } catch (e) {
      debugPrint('Notification permission request error: $e');
    }
    return false;
  }

  /// Analyzes past session patterns and schedules the next smart reminder.
  Future<void> scheduleSmartReminder({DateTime? customNow}) async {
    final now = customNow ?? DateTime.now();
    final isEnabled = AppSettingsService.instance.notificationsEnabled;

    if (!isEnabled) {
      await cancelAllReminders();
      _nextScheduledTime = null;
      _lastMessage = null;
      return;
    }

    final sessions = SessionService.instance.sessions;
    final nextTime = FocusTimingAnalyzer.calculateNextReminderTime(sessions, now);
    final message = FocusTimingAnalyzer.generateNotificationMessage(
      sessions,
      nextTime,
      now,
    );

    _nextScheduledTime = nextTime;
    _lastMessage = message;

    if (_inTest || _plugin == null) return;

    try {
      // Cancel previous reminder so only one optimal reminder is pending
      await _plugin?.cancel(reminderNotificationId);

      final tzDateTime = tz.TZDateTime.from(nextTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin?.zonedSchedule(
        reminderNotificationId,
        message.title,
        message.body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: message.payload,
      );
    } catch (e) {
      debugPrint('Failed to schedule smart notification: $e');
    }
  }

  /// Displays an instant notification immediately so the user can test the feature.
  Future<void> showInstantReminder() async {
    final now = DateTime.now();
    final sessions = SessionService.instance.sessions;
    final nextTime = FocusTimingAnalyzer.calculateNextReminderTime(sessions, now);
    final message = FocusTimingAnalyzer.generateNotificationMessage(
      sessions,
      nextTime,
      now,
    );

    _lastMessage = message;

    if (_inTest || _plugin == null) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _plugin?.show(
        instantTestNotificationId,
        message.title,
        message.body,
        notificationDetails,
        payload: message.payload,
      );
    } catch (e) {
      debugPrint('Failed to display instant test notification: $e');
    }
  }

  /// Cancels all scheduled or active reminder notifications.
  Future<void> cancelAllReminders() async {
    _nextScheduledTime = null;
    if (_inTest || _plugin == null) return;

    try {
      await _plugin?.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel notifications: $e');
    }
  }
}
