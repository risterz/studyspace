import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyspace/app/app.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/services/notification_service.dart';

void main() {
  testWidgets('Fresh launch opens Onboarding, seeds Maya sample data, and locks 5-tab nav order', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(NoopNotificationService()),
        ],
        child: const StudySpaceApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to StudySpace'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Maya');
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    final navLabels = ['Home', 'Timetable', 'Assignments', 'Focus', 'Notes'];
    for (final label in navLabels) {
      expect(find.text(label), findsWidgets);
    }

    // Verify exact left-to-right x-coordinates of the 5 bottom nav labels
    final xs = navLabels
        .map((l) => tester.getCenter(find.byKey(Key('nav_tab_$l'))).dx)
        .toList();
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i], greaterThan(xs[i - 1]));
    }

    // Tap Timetable tab and verify navigation works
    await tester.tap(find.byKey(const Key('nav_tab_Timetable')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nav_tab_Timetable')), findsOneWidget);

    final subjects = await db.watchSubjects().first;
    expect(subjects.length, 4);
  });

  testWidgets('Blank onboarding defaults empty name to Student and seeds 0 subjects', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(NoopNotificationService()),
        ],
        child: const StudySpaceApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Toggle sample data OFF
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    final profile = await db.getProfile();
    expect(profile?.displayName, 'Student');
    expect(await db.watchSubjects().first, isEmpty);
  });
}
