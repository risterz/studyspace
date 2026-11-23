import 'package:flutter_test/flutter_test.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/services/notification_scheduler.dart';

void main() {
  final now = DateTime(2026, 11, 23, 8, 0); // Monday 08:00

  TimetableEvent makeEvent({
    required String id,
    required String title,
    int weekdaysMask = 1,
    int startMinutes = 10 * 60,
    bool reminderEnabled = true,
  }) {
    return TimetableEvent(
      id: id,
      subjectId: null,
      title: title,
      location: 'Room B204',
      isRecurring: true,
      weekdaysMask: weekdaysMask,
      repeatUntil: null,
      specificDate: null,
      startMinutes: startMinutes,
      endMinutes: startMinutes + 60,
      reminderEnabled: reminderEnabled,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }

  Assignment makeAssignment({
    required String id,
    required String title,
    required DateTime dueAt,
    bool isCompleted = false,
    bool reminderEnabled = true,
  }) {
    return Assignment(
      id: id,
      subjectId: null,
      title: title,
      notes: '',
      dueAt: dueAt,
      priority: 'high',
      isCompleted: isCompleted,
      completedAt: null,
      reminderEnabled: reminderEnabled,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }

  Exam makeExam({
    required String id,
    required String title,
    required DateTime examAt,
    bool reminderEnabled = true,
  }) {
    return Exam(
      id: id,
      subjectId: null,
      title: title,
      examAt: examAt,
      location: 'Hall A',
      notes: '',
      reminderEnabled: reminderEnabled,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
  }

  test('schedules class lead time, assignment 24h+1h, and exam 3d+1d triggers skipping past/muted/completed', () {
    final alerts = buildRollingAlerts(
      now: now,
      classLeadMinutes: 15,
      events: [
        makeEvent(id: 'e1', title: 'Calculus II', weekdaysMask: 1, startMinutes: 10 * 60),
        makeEvent(id: 'e2', title: 'Muted Class', weekdaysMask: 1, startMinutes: 11 * 60, reminderEnabled: false),
      ],
      assignments: [
        makeAssignment(id: 'a1', title: 'Lab report', dueAt: DateTime(2026, 11, 25, 17, 0)),
        makeAssignment(id: 'a2', title: 'Done task', dueAt: DateTime(2026, 11, 25, 17, 0), isCompleted: true),
        makeAssignment(id: 'a3', title: 'Past task', dueAt: DateTime(2026, 11, 22, 12, 0)),
      ],
      exams: [
        makeExam(id: 'x1', title: 'Calc Midterm', examAt: DateTime(2026, 11, 29, 9, 0)),
      ],
    );

    final firstClass = alerts.firstWhere((a) => a.sourceId == 'e1');
    expect(firstClass.fireAt, DateTime(2026, 11, 23, 9, 45));
    expect(alerts.any((a) => a.sourceId == 'e2'), isFalse);
    expect(alerts.any((a) => a.sourceId == 'a2'), isFalse);
    expect(alerts.any((a) => a.sourceId == 'a3'), isFalse);

    final a1Triggers = alerts.where((a) => a.sourceId == 'a1').map((a) => a.fireAt).toList();
    expect(a1Triggers, [DateTime(2026, 11, 24, 17, 0), DateTime(2026, 11, 25, 16, 0)]);

    final x1Triggers = alerts.where((a) => a.sourceId == 'x1').map((a) => a.fireAt).toList();
    expect(x1Triggers, [DateTime(2026, 11, 26, 9, 0), DateTime(2026, 11, 28, 9, 0)]);
  });

  test('caps heavy semester schedule at <= 48 alerts sorted ascending so imminent reminders are never dropped', () {
    final events = List.generate(
      6,
      (i) => makeEvent(
        id: 'ev-$i',
        title: 'Class $i',
        weekdaysMask: 127, // every day
        startMinutes: (9 + i) * 60,
      ),
    );
    final assignments = List.generate(
      20,
      (i) => makeAssignment(
        id: 'as-$i',
        title: 'Assignment $i',
        dueAt: now.add(Duration(days: (i % 10) + 1, hours: 12)),
      ),
    );
    final exams = List.generate(
      8,
      (i) => makeExam(
        id: 'ex-$i',
        title: 'Exam $i',
        examAt: now.add(Duration(days: i + 2, hours: 9)),
      ),
    );

    final alerts = buildRollingAlerts(
      now: now,
      classLeadMinutes: 15,
      events: events,
      assignments: assignments,
      exams: exams,
      windowDays: 14,
      maxAlerts: 48,
    );

    expect(alerts.length, 48);
    expect(alerts.first.fireAt, DateTime(2026, 11, 23, 8, 45));
    for (var i = 1; i < alerts.length; i++) {
      expect(alerts[i].fireAt.isBefore(alerts[i - 1].fireAt), isFalse);
    }
  });
}
