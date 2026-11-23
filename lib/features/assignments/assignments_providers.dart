import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/features/assignments/assignments_repository.dart';

final assignmentsRepositoryProvider = Provider<AssignmentsRepository>((ref) {
  return AssignmentsRepository(ref.watch(appDatabaseProvider));
});

final assignmentsProvider = StreamProvider<List<Assignment>>((ref) {
  return ref.watch(assignmentsRepositoryProvider).watchAssignments();
});

final examsProvider = StreamProvider<List<Exam>>((ref) {
  return ref.watch(assignmentsRepositoryProvider).watchExams();
});

final assignmentsTabModeProvider = StateProvider<AssignmentsTabMode>(
  (ref) => AssignmentsTabMode.tasks,
);

final assignmentFilterProvider = StateProvider<AssignmentFilter>(
  (ref) => AssignmentFilter.all,
);
