import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/sample_seeder.dart';
import 'package:studyspace/core/services/entitlement_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('seedSampleSemester populates realistic subjects, classes, tasks, exams, streak, and notes', () async {
    final now = DateTime(2026, 11, 23, 9, 30);
    await seedSampleSemester(db, displayName: 'Maya', referenceNow: now);

    final profile = await db.getProfile();
    expect(profile, isNotNull);
    expect(profile!.displayName, 'Maya');
    expect(profile.onboardingDone, isTrue);

    final subjects = await db.watchSubjects().first;
    expect(subjects.map((s) => s.name), containsAll(['Biology', 'Calculus II', 'Design Research', 'Literature']));

    final events = await db.watchAllTimetableEvents().first;
    expect(events.length, greaterThanOrEqualTo(4));

    final assignments = await db.watchAllAssignments().first;
    expect(assignments.where((a) => !a.isCompleted).length, 4);
    expect(assignments.where((a) => a.isCompleted).length, 2);

    final exams = await db.watchAllExams().first;
    expect(exams.length, greaterThanOrEqualTo(2));

    final sessions = await db.watchAllFocusSessions().first;
    expect(sessions.length, 12);

    final notes = await db.watchAllNotes().first;
    expect(notes.length, greaterThanOrEqualTo(4));
    expect(notes.any((n) => n.body.contains('- [ ]') || n.body.contains('- [x]')), isTrue);
  });

  test('softDeleteSubjectAndUnlink unlinks all dependent entities cleanly without FK crash', () async {
    await seedSampleSemester(db, displayName: 'Maya', referenceNow: DateTime(2026, 11, 23, 9, 30));
    final subjects = await db.watchSubjects().first;
    final biology = subjects.firstWhere((s) => s.name == 'Biology');

    await db.softDeleteSubjectAndUnlink(biology.id);

    final remainingSubjects = await db.watchSubjects().first;
    expect(remainingSubjects.any((s) => s.id == biology.id), isFalse);

    final assignments = await db.watchAllAssignments().first;
    expect(assignments.any((a) => a.subjectId == biology.id), isFalse);

    final exams = await db.watchAllExams().first;
    expect(exams.any((e) => e.subjectId == biology.id), isFalse);

    final notes = await db.watchAllNotes().first;
    expect(notes.any((n) => n.subjectId == biology.id), isFalse);

    final events = await db.watchAllTimetableEvents().first;
    expect(events.any((ev) => ev.subjectId == biology.id), isFalse);
  });

  test('clearAllData empties all domain tables cleanly', () async {
    await seedSampleSemester(db, displayName: 'Maya', referenceNow: DateTime(2026, 11, 23, 9, 30));
    await db.clearAllData();

    expect(await db.watchSubjects().first, isEmpty);
    expect(await db.watchAllTimetableEvents().first, isEmpty);
    expect(await db.watchAllAssignments().first, isEmpty);
    expect(await db.watchAllExams().first, isEmpty);
    expect(await db.watchAllFocusSessions().first, isEmpty);
    expect(await db.watchAllNotes().first, isEmpty);
  });

  test('FreeEntitlementService exposes clean non-blocking v1 flags', () {
    const svc = FreeEntitlementService();
    expect(svc.canCloudSync, isFalse);
    expect(svc.canExportPdf, isFalse);
    expect(svc.hasProThemes, isFalse);
  });
}
