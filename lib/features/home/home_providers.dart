import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/features/assignments/assignments_providers.dart';
import 'package:studyspace/features/timetable/timetable_providers.dart';
import 'package:studyspace/features/timetable/timetable_repository.dart';

String greetingForHour(int hour, String name) {
  final cleanName = name.trim().isEmpty ? 'Student' : name.trim();
  if (hour >= 5 && hour < 12) return 'Good morning, $cleanName';
  if (hour >= 12 && hour < 17) return 'Good afternoon, $cleanName';
  return 'Good evening, $cleanName';
}

@immutable
class TodayProgress {
  const TodayProgress({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  double get ratio => total <= 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

TodayProgress computeTodayProgress(List<Assignment> assignments, DateTime now) {
  final valid = assignments.where((a) => !a.isDeleted).toList();
  if (valid.isEmpty) {
    return const TodayProgress(completed: 0, total: 0);
  }

  final dueOrCompletedToday = valid.where((a) {
    final dueToday = _isSameDay(a.dueAt, now);
    final completedToday =
        a.isCompleted && a.completedAt != null && _isSameDay(a.completedAt!, now);
    return dueToday || completedToday;
  }).toList();

  if (dueOrCompletedToday.isNotEmpty) {
    final done = dueOrCompletedToday.where((a) => a.isCompleted).length;
    return TodayProgress(completed: done, total: dueOrCompletedToday.length);
  }

  final totalDone = valid.where((a) => a.isCompleted).length;
  return TodayProgress(completed: totalDone, total: valid.length);
}

final homeUpcomingClassProvider = Provider<TimetableOccurrence?>((ref) {
  final events = ref.watch(timetableEventsProvider).valueOrNull ?? const [];
  final subjects = ref.watch(subjectsByIdProvider);
  return ref
      .watch(timetableRepositoryProvider)
      .nextUpcomingClass(events, subjects, DateTime.now());
});

final homeTodayProgressProvider = Provider<TodayProgress>((ref) {
  final assignments = ref.watch(assignmentsProvider).valueOrNull ?? const [];
  return computeTodayProgress(assignments, DateTime.now());
});

final homeNextAssignmentProvider = Provider<Assignment?>((ref) {
  final assignments = ref.watch(assignmentsProvider).valueOrNull ?? const [];
  final active = assignments.where((a) => !a.isCompleted).toList()
    ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  return active.isEmpty ? null : active.first;
});

final homeUpcomingExamProvider = Provider<Exam?>((ref) {
  final exams = ref.watch(examsProvider).valueOrNull ?? const [];
  final now = DateTime.now();
  final upcoming = exams.where((e) => !e.examAt.isBefore(now)).toList()
    ..sort((a, b) => a.examAt.compareTo(b.examAt));
  return upcoming.isEmpty ? null : upcoming.first;
});
