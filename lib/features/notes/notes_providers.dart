import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/features/notes/notes_repository.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(appDatabaseProvider));
});

final notesProvider = StreamProvider<List<Note>>((ref) {
  return ref.watch(notesRepositoryProvider).watchNotes();
});

final notesSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredNotesProvider = Provider<List<Note>>((ref) {
  final all = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
  final subjects = ref.watch(subjectsByIdProvider);
  final query = ref.watch(notesSearchQueryProvider);
  return searchNotes(all, subjects, query);
});

final subjectNoteCountsProvider = Provider<Map<String, int>>((ref) {
  final all = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
  final map = <String, int>{};
  for (final n in all) {
    if (n.subjectId != null) {
      map[n.subjectId!] = (map[n.subjectId!] ?? 0) + 1;
    }
  }
  return map;
});
