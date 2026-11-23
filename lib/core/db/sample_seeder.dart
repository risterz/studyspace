import 'package:drift/drift.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

Future<void> seedSampleSemester(
  AppDatabase db, {
  required String displayName,
  DateTime? referenceNow,
}) async {
  final now = referenceNow ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final existingProfile = await db.getProfile();

  await db.transaction(() async {
    await db.clearAllData();

    await db.upsertProfile(
      UserProfilesCompanion(
        id: Value(existingProfile?.id ?? 'default-profile'),
        displayName: Value(displayName.trim().isEmpty ? 'Student' : displayName.trim()),
        avatarColorKey: Value(existingProfile?.avatarColorKey ?? 'periwinkle'),
        themeMode: Value(existingProfile?.themeMode ?? 'system'),
        onboardingDone: const Value(true),
        focusMinutes: Value(existingProfile?.focusMinutes ?? 25),
        shortBreakMinutes: Value(existingProfile?.shortBreakMinutes ?? 5),
        longBreakMinutes: Value(existingProfile?.longBreakMinutes ?? 15),
        roundsPerCycle: Value(existingProfile?.roundsPerCycle ?? 4),
        autoStartBreak: Value(existingProfile?.autoStartBreak ?? false),
        chimeEnabled: Value(existingProfile?.chimeEnabled ?? true),
        notificationsEnabled: Value(existingProfile?.notificationsEnabled ?? true),
        classLeadMinutes: Value(existingProfile?.classLeadMinutes ?? 15),
        createdAt: Value(existingProfile?.createdAt ?? now),
        updatedAt: Value(now),
      ),
    );

    final bioId = _uuid.v4();
    final calcId = _uuid.v4();
    final designId = _uuid.v4();
    final litId = _uuid.v4();

    final subjectRows = [
      SubjectsCompanion.insert(
        id: bioId,
        name: 'Biology',
        colorKey: const Value('mint'),
        iconKey: const Value('flask'),
        sortOrder: const Value(0),
        createdAt: now,
        updatedAt: now,
      ),
      SubjectsCompanion.insert(
        id: calcId,
        name: 'Calculus II',
        colorKey: const Value('periwinkle'),
        iconKey: const Value('function'),
        sortOrder: const Value(1),
        createdAt: now,
        updatedAt: now,
      ),
      SubjectsCompanion.insert(
        id: designId,
        name: 'Design Research',
        colorKey: const Value('lilac'),
        iconKey: const Value('pencil'),
        sortOrder: const Value(2),
        createdAt: now,
        updatedAt: now,
      ),
      SubjectsCompanion.insert(
        id: litId,
        name: 'Literature',
        colorKey: const Value('sky'),
        iconKey: const Value('book'),
        sortOrder: const Value(3),
        createdAt: now,
        updatedAt: now,
      ),
    ];
    for (final s in subjectRows) {
      await db.upsertSubject(s);
    }

    // Weekday bitmasks: Mon=1, Tue=2, Wed=4, Thu=8, Fri=16
    final todayBit = 1 << (now.weekday - 1);
    final events = [
      TimetableEventsCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(calcId),
        title: 'Calculus II',
        location: const Value('Room B204'),
        isRecurring: const Value(true),
        weekdaysMask: Value(1 | 4 | 16 | todayBit), // Mon/Wed/Fri + today
        startMinutes: 10 * 60,
        endMinutes: 11 * 60 + 30,
        createdAt: now,
        updatedAt: now,
      ),
      TimetableEventsCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(designId),
        title: 'Design Research',
        location: const Value('Room B204'),
        isRecurring: const Value(true),
        weekdaysMask: Value(1 | 8 | todayBit), // Mon/Thu + today
        startMinutes: 13 * 60,
        endMinutes: 14 * 60 + 30,
        createdAt: now,
        updatedAt: now,
      ),
      TimetableEventsCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(bioId),
        title: 'Biology Lab',
        location: const Value('Science Wing 3A'),
        isRecurring: const Value(true),
        weekdaysMask: const Value(2 | 8), // Tue/Thu
        startMinutes: 11 * 60,
        endMinutes: 12 * 60 + 30,
        createdAt: now,
        updatedAt: now,
      ),
      TimetableEventsCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(litId),
        title: 'Study group',
        location: const Value('Library 2F'),
        isRecurring: const Value(true),
        weekdaysMask: Value(1 | 4 | todayBit),
        startMinutes: 16 * 60,
        endMinutes: 17 * 60,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    for (final e in events) {
      await db.upsertTimetableEvent(e);
    }

    // 4 active + 2 completed assignments
    final labReportId = _uuid.v4();
    final assignmentRows = [
      AssignmentsCompanion.insert(
        id: labReportId,
        subjectId: Value(bioId),
        title: 'Lab report',
        notes: const Value('Include cell osmosis table and microscope diagrams.'),
        dueAt: today.add(const Duration(days: 1, hours: 17)),
        priority: const Value('high'),
        isCompleted: const Value(false),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ),
      AssignmentsCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(calcId),
        title: 'Problem set 6',
        notes: const Value('Integration by parts and improper integrals.'),
        dueAt: today.add(const Duration(days: 2, hours: 23)),
        priority: const Value('medium'),
        isCompleted: const Value(false),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ),
      AssignmentsCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(designId),
        title: 'User interview guide',
        notes: const Value('Prepare 8 open-ended questions for commuter study.'),
        dueAt: today.add(const Duration(days: 4, hours: 18)),
        priority: const Value('medium'),
        isCompleted: const Value(false),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
      AssignmentsCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(litId),
        title: 'Modernism essay outline',
        notes: const Value('Thesis + 3 primary source quotes.'),
        dueAt: today.add(const Duration(days: 6, hours: 15)),
        priority: const Value('low'),
        isCompleted: const Value(false),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
      AssignmentsCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(litId),
        title: 'Reading response',
        notes: const Value('Chapters 4-6 synthesis.'),
        dueAt: today.add(const Duration(hours: 18)),
        priority: const Value('medium'),
        isCompleted: const Value(true),
        completedAt: Value(now.subtract(const Duration(hours: 2))),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now,
      ),
      AssignmentsCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(designId),
        title: 'Studio critique prep',
        notes: const Value('Export 3 wireframe variations.'),
        dueAt: today.add(const Duration(hours: 14)),
        priority: const Value('high'),
        isCompleted: const Value(true),
        completedAt: Value(now.subtract(const Duration(hours: 1))),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now,
      ),
    ];
    for (final a in assignmentRows) {
      await db.upsertAssignment(a);
    }

    // 3 upcoming exams
    final examRows = [
      ExamsCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(calcId),
        title: 'Calculus II Midterm',
        examAt: today.add(const Duration(days: 6, hours: 9)),
        location: const Value('Hall A · Seat 24'),
        notes: const Value('Chapters 5–8: series, Taylor polynomials, polar area.'),
        createdAt: now,
        updatedAt: now,
      ),
      ExamsCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(bioId),
        title: 'Cell Biology Practical',
        examAt: today.add(const Duration(days: 2, hours: 13, minutes: 30)),
        location: const Value('Bio Lab 3B'),
        notes: const Value('Membrane transport and staining protocol.'),
        createdAt: now,
        updatedAt: now,
      ),
      ExamsCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(litId),
        title: '20th Century Lit Final',
        examAt: today.add(const Duration(days: 14, hours: 10)),
        location: const Value('Humanities 101'),
        notes: const Value('Closed book essay format.'),
        createdAt: now,
        updatedAt: now,
      ),
    ];
    for (final ex in examRows) {
      await db.upsertExam(ex);
    }

    // 12 focus sessions across a 7-day consecutive streak (including today)
    final sessionOffsetsDays = [0, 0, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6];
    for (var i = 0; i < sessionOffsetsDays.length; i++) {
      final completedAt = now
          .subtract(Duration(days: sessionOffsetsDays[i], hours: (i % 3) + 1));
      await db.insertFocusSession(
        FocusSessionsCompanion.insert(
          id: _uuid.v4(),
          subjectId: Value(i.isEven ? bioId : calcId),
          assignmentId: Value(i < 3 ? labReportId : null),
          durationSeconds: 25 * 60,
          completedAt: completedAt,
          sessionType: const Value('focus'),
          createdAt: completedAt,
          updatedAt: completedAt,
        ),
      );
    }

    // Sample notes matching the Notes mockup
    final noteRows = [
      NotesCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(bioId),
        title: 'Cell membrane review',
        body: const Value(
          '# Phospholipid Bilayer\n'
          'Hydrophilic heads face outward while hydrophobic tails face inward.\n'
          '- Selective permeability controls ion flow\n'
          '- Cholesterol buffers membrane fluidity\n'
          '- [x] Diagram active vs passive transport\n'
          '- [ ] Review sodium-potassium pump stoichiometry',
        ),
        isPinned: const Value(true),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      NotesCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(calcId),
        title: 'Week 8 formulas',
        body: const Value(
          '# Integration Techniques\n'
          '- Integration by parts: integral u dv = uv - integral v du\n'
          '- Ratio test for power series convergence\n'
          '- [x] Memorize Maclaurin series for sin(x) and e^x\n'
          '- [ ] Finish Problem Set 6 questions 7–10',
        ),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      NotesCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(designId),
        title: 'Interview synthesis',
        body: const Value(
          '# Key Themes from 5 Student Interviews\n'
          '- Students switch between 3–4 apps daily to track deadlines\n'
          '- Exam countdowns reduce last-minute cramming anxiety\n'
          '- [x] Cluster sticky notes by pain point\n'
          '- [ ] Draft persona summary for studio critique',
        ),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      NotesCompanion.insert(
        id: _uuid.v4(),
        subjectId: Value(litId),
        title: 'Stream of consciousness notes',
        body: const Value(
          '# Virginia Woolf & Interior Monologue\n'
          '- Time shifts between external clocks and inner memory\n'
          '- [ ] Pull 2 passages from Mrs Dalloway for seminar',
        ),
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
    for (final n in noteRows) {
      await db.upsertNote(n);
    }
  });
}
