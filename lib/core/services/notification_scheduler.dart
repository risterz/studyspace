import 'package:intl/intl.dart';
import 'package:studyspace/core/db/app_database.dart';

enum AlertSourceType { timetable, assignment, exam, focus }

class ScheduledAlert {
  const ScheduledAlert({
    required this.notificationId,
    required this.sourceId,
    required this.sourceType,
    required this.title,
    required this.subtitle,
    required this.fireAt,
  });

  final int notificationId;
  final String sourceId;
  final AlertSourceType sourceType;
  final String title;
  final String subtitle;
  final DateTime fireAt;
}

int _stableNotificationId(String key) {
  var hash = 2166136261;
  for (final codeUnit in key.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  // Reserve 999999 for Focus timer end alert.
  return (hash % 900000) + 1000;
}

List<ScheduledAlert> buildRollingAlerts({
  required DateTime now,
  required List<TimetableEvent> events,
  required List<Assignment> assignments,
  required List<Exam> exams,
  required int classLeadMinutes,
  int windowDays = 14,
  int maxAlerts = 48,
}) {
  final horizon = now.add(Duration(days: windowDays));
  final alerts = <ScheduledAlert>[];
  final timeFmt = DateFormat.jm();

  // 1. Timetable events (recurring + one-off) within rolling window
  final today = DateTime(now.year, now.month, now.day);
  for (final ev in events) {
    if (ev.isDeleted || !ev.reminderEnabled) continue;

    if (ev.isRecurring) {
      for (var dayOffset = 0; dayOffset <= windowDays; dayOffset++) {
        final d = today.add(Duration(days: dayOffset));
        if (ev.repeatUntil != null &&
            d.isAfter(DateTime(
              ev.repeatUntil!.year,
              ev.repeatUntil!.month,
              ev.repeatUntil!.day,
            ))) {
          continue;
        }
        final bit = 1 << (d.weekday - 1);
        if ((ev.weekdaysMask & bit) == 0) continue;

        final startAt = d.add(Duration(minutes: ev.startMinutes));
        final fireAt = startAt.subtract(Duration(minutes: classLeadMinutes));
        if (fireAt.isAfter(now) && !fireAt.isAfter(horizon)) {
          final loc = ev.location.isEmpty ? '' : ' · ${ev.location}';
          alerts.add(
            ScheduledAlert(
              notificationId: _stableNotificationId('tt:${ev.id}:${d.toIso8601String()}'),
              sourceId: ev.id,
              sourceType: AlertSourceType.timetable,
              title: '${ev.title} in $classLeadMinutes min',
              subtitle: '${timeFmt.format(startAt)}$loc',
              fireAt: fireAt,
            ),
          );
        }
      }
    } else if (ev.specificDate != null) {
      final parsed = DateTime.tryParse(ev.specificDate!);
      if (parsed != null) {
        final d = DateTime(parsed.year, parsed.month, parsed.day);
        final startAt = d.add(Duration(minutes: ev.startMinutes));
        final fireAt = startAt.subtract(Duration(minutes: classLeadMinutes));
        if (fireAt.isAfter(now) && !fireAt.isAfter(horizon)) {
          final loc = ev.location.isEmpty ? '' : ' · ${ev.location}';
          alerts.add(
            ScheduledAlert(
              notificationId: _stableNotificationId('tt:${ev.id}:oneoff'),
              sourceId: ev.id,
              sourceType: AlertSourceType.timetable,
              title: '${ev.title} in $classLeadMinutes min',
              subtitle: '${timeFmt.format(startAt)}$loc',
              fireAt: fireAt,
            ),
          );
        }
      }
    }
  }

  // 2. Assignments: 24h and 1h before dueAt
  for (final a in assignments) {
    if (a.isDeleted || a.isCompleted || !a.reminderEnabled) continue;
    final triggers = <(Duration, String)>[
      (const Duration(hours: 24), 'Due tomorrow'),
      (const Duration(hours: 1), 'Due in 1 hour'),
    ];
    for (final (lead, label) in triggers) {
      final fireAt = a.dueAt.subtract(lead);
      if (fireAt.isAfter(now) && !fireAt.isAfter(horizon)) {
        alerts.add(
          ScheduledAlert(
            notificationId: _stableNotificationId('as:${a.id}:${lead.inMinutes}'),
            sourceId: a.id,
            sourceType: AlertSourceType.assignment,
            title: a.title,
            subtitle: '$label · ${DateFormat('MMM d, h:mm a').format(a.dueAt)}',
            fireAt: fireAt,
          ),
        );
      }
    }
  }

  // 3. Exams: 3d and 1d before examAt
  for (final ex in exams) {
    if (ex.isDeleted || !ex.reminderEnabled) continue;
    final triggers = <(Duration, String)>[
      (const Duration(days: 3), 'Exam in 3 days'),
      (const Duration(days: 1), 'Exam tomorrow'),
    ];
    for (final (lead, label) in triggers) {
      final fireAt = ex.examAt.subtract(lead);
      if (fireAt.isAfter(now) && !fireAt.isAfter(horizon)) {
        final loc = ex.location.isEmpty ? '' : ' · ${ex.location}';
        alerts.add(
          ScheduledAlert(
            notificationId: _stableNotificationId('ex:${ex.id}:${lead.inHours}'),
            sourceId: ex.id,
            sourceType: AlertSourceType.exam,
            title: ex.title,
            subtitle: '$label$loc',
            fireAt: fireAt,
          ),
        );
      }
    }
  }

  alerts.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  if (alerts.length > maxAlerts) {
    return alerts.sublist(0, maxAlerts);
  }
  return alerts;
}
