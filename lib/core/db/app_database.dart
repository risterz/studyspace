import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:studyspace/core/db/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    UserProfiles,
    Subjects,
    TimetableEvents,
    Assignments,
    Exams,
    FocusSessions,
    Notes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'studyspace_db'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // Profile
  Future<UserProfile?> getProfile() {
    return (select(userProfiles)..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Stream<UserProfile?> watchProfile() {
    return (select(userProfiles)..where((t) => t.isDeleted.equals(false)))
        .watchSingleOrNull();
  }

  Future<void> upsertProfile(UserProfilesCompanion data) {
    return into(userProfiles).insertOnConflictUpdate(data);
  }

  // Subjects
  Future<List<Subject>> getSubjects() {
    return (select(subjects)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  Stream<List<Subject>> watchSubjects() {
    return (select(subjects)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  Future<void> upsertSubject(SubjectsCompanion data) {
    return into(subjects).insertOnConflictUpdate(data);
  }

  Future<void> softDeleteSubjectAndUnlink(String subjectId) {
    final now = DateTime.now();
    return transaction(() async {
      await (update(timetableEvents)
            ..where((t) => t.subjectId.equals(subjectId)))
          .write(TimetableEventsCompanion(
        subjectId: const Value(null),
        updatedAt: Value(now),
      ));
      await (update(assignments)..where((t) => t.subjectId.equals(subjectId)))
          .write(AssignmentsCompanion(
        subjectId: const Value(null),
        updatedAt: Value(now),
      ));
      await (update(exams)..where((t) => t.subjectId.equals(subjectId)))
          .write(ExamsCompanion(
        subjectId: const Value(null),
        updatedAt: Value(now),
      ));
      await (update(focusSessions)..where((t) => t.subjectId.equals(subjectId)))
          .write(FocusSessionsCompanion(
        subjectId: const Value(null),
        updatedAt: Value(now),
      ));
      await (update(notes)..where((t) => t.subjectId.equals(subjectId)))
          .write(NotesCompanion(
        subjectId: const Value(null),
        updatedAt: Value(now),
      ));
      await (update(subjects)..where((t) => t.id.equals(subjectId)))
          .write(SubjectsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
      ));
    });
  }

  // Timetable Events
  Future<List<TimetableEvent>> getAllTimetableEvents() {
    return (select(timetableEvents)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.startMinutes)]))
        .get();
  }

  Stream<List<TimetableEvent>> watchAllTimetableEvents() {
    return (select(timetableEvents)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.startMinutes)]))
        .watch();
  }

  Future<void> upsertTimetableEvent(TimetableEventsCompanion data) {
    return into(timetableEvents).insertOnConflictUpdate(data);
  }

  Future<void> softDeleteTimetableEvent(String id) {
    return (update(timetableEvents)..where((t) => t.id.equals(id))).write(
      TimetableEventsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Assignments
  Future<List<Assignment>> getAllAssignments() {
    return (select(assignments)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.asc(t.dueAt),
          ]))
        .get();
  }

  Stream<List<Assignment>> watchAllAssignments() {
    return (select(assignments)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.asc(t.dueAt),
          ]))
        .watch();
  }

  Future<void> upsertAssignment(AssignmentsCompanion data) {
    return into(assignments).insertOnConflictUpdate(data);
  }

  Future<void> softDeleteAssignment(String id) {
    return (update(assignments)..where((t) => t.id.equals(id))).write(
      AssignmentsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Exams
  Future<List<Exam>> getAllExams() {
    return (select(exams)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.examAt)]))
        .get();
  }

  Stream<List<Exam>> watchAllExams() {
    return (select(exams)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.examAt)]))
        .watch();
  }

  Future<void> upsertExam(ExamsCompanion data) {
    return into(exams).insertOnConflictUpdate(data);
  }

  Future<void> softDeleteExam(String id) {
    return (update(exams)..where((t) => t.id.equals(id))).write(
      ExamsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Focus Sessions
  Stream<List<FocusSession>> watchAllFocusSessions() {
    return (select(focusSessions)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .watch();
  }

  Future<void> insertFocusSession(FocusSessionsCompanion data) {
    return into(focusSessions).insertOnConflictUpdate(data);
  }

  // Notes
  Future<List<Note>> getAllNotes() {
    return (select(notes)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  Stream<List<Note>> watchAllNotes() {
    return (select(notes)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  Future<Note?> getNoteById(String id) {
    return (select(notes)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<void> upsertNote(NotesCompanion data) {
    return into(notes).insertOnConflictUpdate(data);
  }

  Future<void> softDeleteNote(String id) {
    return (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> clearAllData() {
    return transaction(() async {
      await delete(notes).go();
      await delete(focusSessions).go();
      await delete(exams).go();
      await delete(assignments).go();
      await delete(timetableEvents).go();
      await delete(subjects).go();
    });
  }
}
