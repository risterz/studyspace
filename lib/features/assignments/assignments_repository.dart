import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum AssignmentFilter { all, dueSoon, highPriority }

enum AssignmentsTabMode { tasks, exams }

enum ExamUrgency { normal, soon, urgent, past }

class ExamCountdownInfo {
  const ExamCountdownInfo({
    required this.label,
    required this.urgency,
  });

  final String label;
  final ExamUrgency urgency;
}

ExamCountdownInfo computeExamCountdown(DateTime examAt, DateTime now) {
  final diff = examAt.difference(now);
  if (diff.isNegative) {
    return const ExamCountdownInfo(label: 'Done', urgency: ExamUrgency.past);
  }
  final hours = diff.inHours;
  if (hours < 24) {
    final displayHours = hours <= 0 ? 1 : hours;
    return ExamCountdownInfo(
      label: '${displayHours}h',
      urgency: ExamUrgency.urgent,
    );
  }
  final days = (hours / 24).ceil();
  final urgency = days <= 2
      ? ExamUrgency.urgent
      : (days <= 7 ? ExamUrgency.soon : ExamUrgency.normal);
  return ExamCountdownInfo(label: '${days}d', urgency: urgency);
}

List<Assignment> filterAssignments(
  List<Assignment> items,
  AssignmentFilter filter,
  DateTime now,
) {
  return switch (filter) {
    AssignmentFilter.all => items,
    AssignmentFilter.dueSoon => items
        .where(
          (a) =>
              !a.isCompleted &&
              a.dueAt.isBefore(now.add(const Duration(hours: 48))),
        )
        .toList(),
    AssignmentFilter.highPriority => items
        .where((a) => !a.isCompleted && a.priority == 'high')
        .toList(),
  };
}

String formatDueLabel(DateTime dueAt, DateTime now) {
  if (dueAt.isBefore(now)) return 'Overdue';
  final todayUtc = DateTime.utc(now.year, now.month, now.day);
  final dueDayUtc = DateTime.utc(dueAt.year, dueAt.month, dueAt.day);
  final diffDays = dueDayUtc.difference(todayUtc).inDays;

  if (diffDays <= 0) return 'Due today';
  if (diffDays == 1) return 'Due tomorrow';
  if (diffDays <= 6) {
    return 'Due ${DateFormat('EEE').format(dueAt)}';
  }
  return 'Due ${DateFormat('MMM d').format(dueAt)}';
}

class AssignmentsRepository {
  AssignmentsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Assignment>> watchAssignments() => _db.watchAllAssignments();

  Stream<List<Exam>> watchExams() => _db.watchAllExams();

  Future<void> saveAssignment({
    String? id,
    required String title,
    String? subjectId,
    required String notes,
    required DateTime dueAt,
    required String priority,
    required bool isCompleted,
    DateTime? completedAt,
    required bool reminderEnabled,
    DateTime? existingCreatedAt,
  }) async {
    final now = DateTime.now();
    await _db.upsertAssignment(
      AssignmentsCompanion(
        id: Value(id ?? _uuid.v4()),
        subjectId: Value(subjectId),
        title: Value(title.trim()),
        notes: Value(notes.trim()),
        dueAt: Value(dueAt),
        priority: Value(priority),
        isCompleted: Value(isCompleted),
        completedAt: Value(completedAt),
        reminderEnabled: Value(reminderEnabled),
        createdAt: Value(existingCreatedAt ?? now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
      ),
    );
  }

  Future<void> toggleCompleted(Assignment item, bool completed) async {
    final now = DateTime.now();
    await _db.upsertAssignment(
      AssignmentsCompanion(
        id: Value(item.id),
        subjectId: Value(item.subjectId),
        title: Value(item.title),
        notes: Value(item.notes),
        dueAt: Value(item.dueAt),
        priority: Value(item.priority),
        isCompleted: Value(completed),
        completedAt: Value(completed ? now : null),
        reminderEnabled: Value(item.reminderEnabled),
        createdAt: Value(item.createdAt),
        updatedAt: Value(now),
        isDeleted: const Value(false),
      ),
    );
  }

  Future<void> deleteAssignment(String id) => _db.softDeleteAssignment(id);

  Future<void> saveExam({
    String? id,
    required String title,
    String? subjectId,
    required DateTime examAt,
    required String location,
    required String notes,
    required bool reminderEnabled,
    DateTime? existingCreatedAt,
  }) async {
    final now = DateTime.now();
    await _db.upsertExam(
      ExamsCompanion(
        id: Value(id ?? _uuid.v4()),
        subjectId: Value(subjectId),
        title: Value(title.trim()),
        examAt: Value(examAt),
        location: Value(location.trim()),
        notes: Value(notes.trim()),
        reminderEnabled: Value(reminderEnabled),
        createdAt: Value(existingCreatedAt ?? now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
      ),
    );
  }

  Future<void> deleteExam(String id) => _db.softDeleteExam(id);
}
