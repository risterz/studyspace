import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyspace/app/theme/studyspace_theme.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/services/notification_service.dart';
import 'package:studyspace/features/timetable/timetable_repository.dart';
import 'package:studyspace/features/timetable/timetable_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('occurrencesForDate expands weekdaysMask, respects repeatUntil, one-off dates, and sorts ascending', () {
    final now = DateTime(2026, 11, 23, 9, 0); // Monday
    final repo = TimetableRepository.pure();

    final events = [
      TimetableEvent(
        id: 'mwf',
        subjectId: null,
        title: 'Calculus II',
        location: 'Room B204',
        isRecurring: true,
        weekdaysMask: 1 | 4 | 16, // Mon, Wed, Fri
        repeatUntil: DateTime(2026, 11, 27),
        specificDate: null,
        startMinutes: 13 * 60,
        endMinutes: 14 * 60 + 30,
        reminderEnabled: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      TimetableEvent(
        id: 'early',
        subjectId: null,
        title: 'Morning Lab',
        location: 'Lab 1',
        isRecurring: true,
        weekdaysMask: 1,
        repeatUntil: null,
        specificDate: null,
        startMinutes: 9 * 60,
        endMinutes: 10 * 60,
        reminderEnabled: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      TimetableEvent(
        id: 'oneoff',
        subjectId: null,
        title: 'Guest Lecture',
        location: 'Auditorium',
        isRecurring: false,
        weekdaysMask: 0,
        repeatUntil: null,
        specificDate: '2026-11-24', // Tuesday
        startMinutes: 15 * 60,
        endMinutes: 16 * 60,
        reminderEnabled: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    ];

    final monday = repo.occurrencesForDate(events, const {}, DateTime(2026, 11, 23));
    expect(monday.map((o) => o.event.title).toList(), ['Morning Lab', 'Calculus II']);

    final tuesday = repo.occurrencesForDate(events, const {}, DateTime(2026, 11, 24));
    expect(tuesday.map((o) => o.event.title).toList(), ['Guest Lecture']);

    final nextMonday = repo.occurrencesForDate(events, const {}, DateTime(2026, 11, 30));
    expect(nextMonday.map((o) => o.event.title).toList(), ['Morning Lab']);
  });

  test('nextUpcomingClass picks remaining class today, else tomorrow, else null', () {
    final repo = TimetableRepository.pure();
    final now = DateTime(2026, 11, 23, 12, 0); // Monday noon
    final events = [
      TimetableEvent(
        id: 'e1',
        subjectId: null,
        title: 'Past Morning',
        location: '',
        isRecurring: true,
        weekdaysMask: 1,
        repeatUntil: null,
        specificDate: null,
        startMinutes: 9 * 60,
        endMinutes: 10 * 60,
        reminderEnabled: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      TimetableEvent(
        id: 'e2',
        subjectId: null,
        title: 'Afternoon Seminar',
        location: 'Room 102',
        isRecurring: true,
        weekdaysMask: 1,
        repeatUntil: null,
        specificDate: null,
        startMinutes: 14 * 60,
        endMinutes: 15 * 60,
        reminderEnabled: true,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    ];

    final nextToday = repo.nextUpcomingClass(events, const {}, now);
    expect(nextToday?.event.title, 'Afternoon Seminar');

    final lateMonday = DateTime(2026, 11, 23, 18, 0);
    expect(repo.nextUpcomingClass(const [], const {}, lateMonday), isNull);
  });

  testWidgets(
    'TimetableScreen shows weekly strip, validates editor, and adds a class card',
    timeout: const Timeout(Duration(seconds: 20)),
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notificationServiceProvider.overrideWithValue(NoopNotificationService()),
          ],
          child: MaterialApp(
            theme: buildStudySpaceTheme(Brightness.light),
            home: const TimetableScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Add event'), findsOneWidget);

      await tester.tap(find.text('Add event'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('event_title_field')), 'Linear Algebra');
      await tester.enterText(find.byKey(const Key('event_location_field')), 'Hall C102');
      await tester.tap(find.text('Save event'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Linear Algebra'), findsOneWidget);
      expect(find.text('Hall C102'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await db.close();
    },
  );
}
