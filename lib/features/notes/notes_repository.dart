import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

List<Note> searchNotes(
  List<Note> notes,
  Map<String, Subject> subjectsById,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return notes;
  return notes.where((n) {
    final subjectName =
        n.subjectId == null ? '' : (subjectsById[n.subjectId]?.name ?? '');
    return n.title.toLowerCase().contains(q) ||
        n.body.toLowerCase().contains(q) ||
        subjectName.toLowerCase().contains(q);
  }).toList();
}

String formatRelativeEdited(DateTime updatedAt, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return 'Edited today';
  if (diff == 1) return 'Edited yesterday';
  return 'Edited ${DateFormat('MMM d').format(updatedAt)}';
}

class NotesRepository {
  NotesRepository(this._db);

  final AppDatabase _db;

  Stream<List<Note>> watchNotes() => _db.watchAllNotes();

  Future<Note?> getById(String id) => _db.getNoteById(id);

  Future<String> saveNote({
    String? id,
    String? subjectId,
    required String title,
    required String body,
    bool isPinned = false,
    DateTime? existingCreatedAt,
  }) async {
    final now = DateTime.now();
    final noteId = id ?? _uuid.v4();
    await _db.upsertNote(
      NotesCompanion(
        id: Value(noteId),
        subjectId: Value(subjectId),
        title: Value(title.trim().isEmpty ? 'Untitled note' : title.trim()),
        body: Value(body),
        isPinned: Value(isPinned),
        createdAt: Value(existingCreatedAt ?? now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
      ),
    );
    return noteId;
  }

  Future<void> togglePin(Note note) async {
    await saveNote(
      id: note.id,
      subjectId: note.subjectId,
      title: note.title,
      body: note.body,
      isPinned: !note.isPinned,
      existingCreatedAt: note.createdAt,
    );
  }

  Future<void> moveNote(Note note, String? subjectId) async {
    await saveNote(
      id: note.id,
      subjectId: subjectId,
      title: note.title,
      body: note.body,
      isPinned: note.isPinned,
      existingCreatedAt: note.createdAt,
    );
  }

  Future<void> deleteNote(String id) => _db.softDeleteNote(id);
}
