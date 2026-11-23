import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyspace/app/app.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/services/notification_service.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'Fresh launch opens Onboarding, seeds Maya sample data, and locks 5-tab nav order',
    timeout: const Timeout(Duration(seconds: 20)),
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notificationServiceProvider.overrideWithValue(NoopNotificationService()),
          ],
          child: const StudySpaceApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Welcome to StudySpace'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Maya');
      await tester.tap(find.text('Get started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      final navLabels = ['Home', 'Timetable', 'Assignments', 'Focus', 'Notes'];
      for (final label in navLabels) {
        expect(find.byKey(Key('nav_tab_$label')), findsOneWidget);
      }

      final xs = navLabels
          .map((l) => tester.getCenter(find.byKey(Key('nav_tab_$l'))).dx)
          .toList();
      for (var i = 1; i < xs.length; i++) {
        expect(xs[i], greaterThan(xs[i - 1]));
      }

      await tester.tap(find.byKey(const Key('nav_tab_Timetable')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Timetable'), findsWidgets);

      final subjects = await db.getSubjects();
      expect(subjects.length, 4);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await db.close();
    },
  );

  testWidgets(
    'Blank onboarding defaults empty name to Student and seeds 0 subjects',
    timeout: const Timeout(Duration(seconds: 20)),
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notificationServiceProvider.overrideWithValue(NoopNotificationService()),
          ],
          child: const StudySpaceApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.text('Get started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      final profile = await db.getProfile();
      final subjects = await db.getSubjects();
      expect(profile?.displayName, 'Student');
      expect(subjects, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await db.close();
    },
  );
}
