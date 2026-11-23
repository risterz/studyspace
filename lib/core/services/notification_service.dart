import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/services/notification_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationService {
  Future<void> init();

  Future<void> syncAllReminders({
    required bool enabled,
    required int classLeadMinutes,
    required List<TimetableEvent> events,
    required List<Assignment> assignments,
    required List<Exam> exams,
  });

  Future<void> scheduleFocusEnd(DateTime endAt, String phaseLabel);
  Future<void> cancelFocusEnd();
}

class NoopNotificationService implements NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> syncAllReminders({
    required bool enabled,
    required int classLeadMinutes,
    required List<TimetableEvent> events,
    required List<Assignment> assignments,
    required List<Exam> exams,
  }) async {}

  @override
  Future<void> scheduleFocusEnd(DateTime endAt, String phaseLabel) async {}

  @override
  Future<void> cancelFocusEnd() async {}
}

class LocalNotificationService implements NotificationService {
  static const int _focusNotificationId = 999999;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      );
      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _initialized = true;
    } catch (_) {
      // Ignore initialization errors on unsupported desktop test hosts.
    }
  }

  @override
  Future<void> syncAllReminders({
    required bool enabled,
    required int classLeadMinutes,
    required List<TimetableEvent> events,
    required List<Assignment> assignments,
    required List<Exam> exams,
  }) async {
    if (!_initialized) return;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final req in pending) {
        if (req.id != _focusNotificationId) {
          await _plugin.cancel(req.id);
        }
      }
      if (!enabled) return;

      final alerts = buildRollingAlerts(
        now: DateTime.now(),
        classLeadMinutes: classLeadMinutes,
        events: events,
        assignments: assignments,
        exams: exams,
      );

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'studyspace_reminders',
          'Study Reminders',
          channelDescription: 'Upcoming class, assignment, and exam reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      for (final alert in alerts) {
        final scheduled = tz.TZDateTime.from(alert.fireAt.toUtc(), tz.UTC);
        await _plugin.zonedSchedule(
          alert.notificationId,
          alert.title,
          alert.subtitle,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {
      // Never crash user flow if OS denies scheduling permission.
    }
  }

  @override
  Future<void> scheduleFocusEnd(DateTime endAt, String phaseLabel) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(_focusNotificationId);
      if (!endAt.isAfter(DateTime.now())) return;
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'studyspace_focus',
          'Focus Timer',
          channelDescription: 'Pomodoro session completion alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.zonedSchedule(
        _focusNotificationId,
        'StudySpace Focus Complete',
        '$phaseLabel finished — time for a break.',
        tz.TZDateTime.from(endAt.toUtc(), tz.UTC),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  @override
  Future<void> cancelFocusEnd() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(_focusNotificationId);
    } catch (_) {}
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});
