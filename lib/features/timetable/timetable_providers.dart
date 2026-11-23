import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/features/timetable/timetable_repository.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository(ref.watch(appDatabaseProvider));
});

final timetableEventsProvider = StreamProvider<List<TimetableEvent>>((ref) {
  return ref.watch(timetableRepositoryProvider).watchAll();
});

final selectedTimetableDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final dayOccurrencesProvider = Provider<List<TimetableOccurrence>>((ref) {
  final events = ref.watch(timetableEventsProvider).valueOrNull ?? const [];
  final subjects = ref.watch(subjectsByIdProvider);
  final selectedDate = ref.watch(selectedTimetableDateProvider);
  return ref
      .watch(timetableRepositoryProvider)
      .occurrencesForDate(events, subjects, selectedDate);
});
