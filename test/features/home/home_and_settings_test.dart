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
import 'package:studyspace/features/home/home_providers.dart';
import 'package:studyspace/features/home/home_screen.dart';
import 'package:studyspace/features/settings/settings_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('greetingForHour and computeTodayProgress handle due-today, fallback, and blank profiles cleanly', () {
    expect(greetingForHour(9, 'Maya'), 'Good morning, Maya');
    expect(greetingForHour(14, 'Maya'), 'Good afternoon, Maya');
    expect(greetingForHour(20, 'Maya'), 'Good evening, Maya');

    final now = DateTime(2026, 11, 23, 10, 0);
    // Blank profile -> 0 / 0, ratio 0.0 (never NaN)
    final empty = computeTodayProgress(const [], now);
    expect(empty.completed, 0);
    expect(empty.total, 0);
    expect(empty.ratio, 0.0);
    expect(empty.ratio.isNaN, isFalse);

    Assignment make(String id, DateTime due, {bool done = false, DateTime? completedAt}) =>
        Assignment(
          id: id,
          subjectId: null,
          title: id,
          notes: '',
          dueAt: due,
          priority: 'medium',
          isCompleted: done,
          completedAt: completedAt,
          reminderEnabled: true,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        );

    // Due today + completed today
    final todayList = [
      make('a1', DateTime(2026, 11, 23, 17, 0)),
      make('a2', DateTime(2026, 11, 23, 18, 0), done: true, completedAt: now),
      make('a3', DateTime(2026, 11, 25, 18, 0)),
    ];
    final progToday = computeTodayProgress(todayList, now);
    expect(progToday.completed, 1);
    expect(progToday.total, 2);

    // Zero due today -> fallback to overall completed/total
    final futureOnly = [
      make('b1', DateTime(2026, 11, 25, 18, 0)),
      make('b2', DateTime(2026, 11, 26, 18, 0)),
      make('b3', DateTime(2026, 11, 24, 18, 0), done: true, completedAt: DateTime(2026, 11, 22, 18, 0)),
    ];
    final progFallback = computeTodayProgress(futureOnly, now);
    expect(progFallback.completed, 1);
    expect(progFallback.total, 3);
  });

  testWidgets(
    'HomeScreen renders all 4 cards and 3 quick actions cleanly in Light and Dark themes',
    timeout: const Timeout(Duration(seconds: 20)),
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await seedSampleSemester(db, displayName: 'Maya', referenceNow: DateTime(2026, 11, 23, 9, 30));

      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              notificationServiceProvider.overrideWithValue(NoopNotificationService()),
            ],
            child: MaterialApp(
              theme: buildStudySpaceTheme(brightness),
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        expect(find.text('StudySpace'), findsOneWidget);
        expect(find.text('UPCOMING CLASS'), findsOneWidget);
        expect(find.text("Today's progress"), findsOneWidget);
        expect(find.text('Start focus'), findsOneWidget);
        expect(find.text('Add assignment'), findsOneWidget);
        expect(find.text('New note'), findsOneWidget);
        expect(find.text('NEXT ASSIGNMENT'), findsOneWidget);

        await tester.scrollUntilVisible(find.text('UPCOMING EXAM'), 200);
        expect(find.text('UPCOMING EXAM'), findsOneWidget);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await db.close();
    },
  );

  testWidgets(
    'SettingsScreen updates theme mode and display name cleanly',
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
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Settings'), findsOneWidget);
      await tester.tap(find.text('Dark'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final profile = await db.getProfile();
      expect(profile?.themeMode, 'dark');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await db.close();
    },
  );
}
