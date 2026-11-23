import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyspace/app/theme/studyspace_theme.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/db/sample_seeder.dart';
import 'package:studyspace/core/services/notification_service.dart';
import 'package:studyspace/features/assignments/assignments_repository.dart';
import 'package:studyspace/features/assignments/assignments_screen.dart';

class _SpyNotificationService extends NoopNotificationService {
  _SpyNotificationService(this.onSync);
  final VoidCallback onSync;

  @override
  Future<void> syncAllReminders({
    required bool enabled,
    required int classLeadMinutes,
    required List<TimetableEvent> events,
    required List<Assignment> assignments,
    required List<Exam> exams,
  }) async {
    onSync();
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('filterAssignments handles Due soon (<=48h + overdue) and High priority cleanly', () {
    final now = DateTime(2026, 11, 23, 12, 0);
    Assignment make(String id, DateTime due, String priority, {bool done = false}) => Assignment(
          id: id,
          subjectId: null,
          title: id,
          notes: '',
          dueAt: due,
          priority: priority,
          isCompleted: done,
          completedAt: done ? now : null,
          reminderEnabled: true,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        );

    final list = [
      make('overdue', now.subtract(const Duration(hours: 3)), 'medium'),
      make('tomorrow', now.add(const Duration(hours: 20)), 'high'),
      make('laterHigh', now.add(const Duration(days: 5)), 'high'),
      make('doneHigh', now.add(const Duration(hours: 4)), 'high', done: true),
    ];

    expect(
      filterAssignments(list, AssignmentFilter.dueSoon, now).map((a) => a.id).toList(),
      ['overdue', 'tomorrow'],
    );
    expect(
      filterAssignments(list, AssignmentFilter.highPriority, now).map((a) => a.id).toList(),
      ['tomorrow', 'laterHigh'],
    );
  });

  test('computeExamCountdown maps >7d, 3-7d, <=2d, <24h, and past exams accurately', () {
    final now = DateTime(2026, 11, 23, 9, 0);
    final normal = computeExamCountdown(now.add(const Duration(days: 10)), now);
    expect(normal.label, '10d');
    expect(normal.urgency, ExamUrgency.normal);

    final soon = computeExamCountdown(now.add(const Duration(days: 4)), now);
    expect(soon.label, '4d');
    expect(soon.urgency, ExamUrgency.soon);

    final urgent = computeExamCountdown(now.add(const Duration(hours: 18)), now);
    expect(urgent.label, '18h');
    expect(urgent.urgency, ExamUrgency.urgent);

    final past = computeExamCountdown(now.subtract(const Duration(hours: 2)), now);
    expect(past.label, 'Done');
    expect(past.urgency, ExamUrgency.past);
  });

  test('formatDueLabel marks earlier-today deadlines as Overdue', () {
    final now = DateTime(2026, 11, 23, 15, 0);
    expect(formatDueLabel(DateTime(2026, 11, 23, 10, 0), now), 'Overdue');
    expect(formatDueLabel(DateTime(2026, 11, 23, 18, 0), now), 'Due today');
  });

  testWidgets(
    'AssignmentsScreen syncs reminders on completion toggle and lists upcoming exams before past exams',
    timeout: const Timeout(Duration(seconds: 20)),
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      var syncCalls = 0;
      final spyNotif = _SpyNotificationService(() => syncCalls++);
      final now = DateTime.now();
      await seedSampleSemester(db, displayName: 'Maya', referenceNow: now);
      // Add a past exam that would sort first under plain ASC ordering
      final repo = AssignmentsRepository(db);
      await repo.saveExam(
        title: 'Old Past Exam',
        examAt: now.subtract(const Duration(days: 5)),
        location: 'Old Hall',
        notes: '',
        reminderEnabled: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notificationServiceProvider.overrideWithValue(spyNotif),
          ],
          child: MaterialApp(
            theme: buildStudySpaceTheme(Brightness.light),
            home: const AssignmentsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      await tester.tap(find.byKey(const Key('toggle_assignment_Lab report')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(syncCalls, greaterThanOrEqualTo(1));

      await tester.tap(find.text('Exams'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final upcomingY = tester.getTopLeft(find.text('Cell Biology Practical')).dy;
      await tester.scrollUntilVisible(find.text('Old Past Exam'), 200);
      final pastY = tester.getTopLeft(find.text('Old Past Exam')).dy;
      expect(upcomingY, lessThan(pastY));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await db.close();
    },
  );

  testWidgets(
    'AssignmentsScreen toggles completion, filters tasks, and switches to Exams countdown view',
    timeout: const Timeout(Duration(seconds: 20)),
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await seedSampleSemester(db, displayName: 'Maya', referenceNow: DateTime(2026, 11, 23, 9, 30));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notificationServiceProvider.overrideWithValue(NoopNotificationService()),
          ],
          child: MaterialApp(
            theme: buildStudySpaceTheme(Brightness.light),
            home: const AssignmentsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Assignments'), findsOneWidget);
      expect(find.text('4 active · 2 completed'), findsOneWidget);
      expect(find.text('Lab report'), findsOneWidget);

      // Toggle Lab report completion
      await tester.tap(find.byKey(const Key('toggle_assignment_Lab report')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('3 active · 3 completed'), findsOneWidget);

      // Switch to Exams tab
      await tester.tap(find.text('Exams'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Calculus II Midterm'), findsOneWidget);
      expect(find.text('Add exam'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await db.close();
    },
  );
}
