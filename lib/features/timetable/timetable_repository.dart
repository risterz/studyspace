import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class TimetableOccurrence {
  const TimetableOccurrence({
    required this.event,
    required this.subject,
    required this.date,
    required this.startAt,
    required this.endAt,
  });

  final TimetableEvent event;
  final Subject? subject;
  final DateTime date;
  final DateTime startAt;
  final DateTime endAt;
}

String formatMinutes(int minutesFromMidnight) {
  final h24 = (minutesFromMidnight ~/ 60) % 24;
  final m = minutesFromMidnight % 60;
  final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
  return '$h12:${m.toString().padLeft(2, '0')}';
}

String formatMinutesWithPeriod(int minutesFromMidnight) {
  final h24 = (minutesFromMidnight ~/ 60) % 24;
  final m = minutesFromMidnight % 60;
  final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
  final period = h24 < 12 ? 'AM' : 'PM';
  return '$h12:${m.toString().padLeft(2, '0')} $period';
}

class TimetableRepository {
  TimetableRepository(this._db);

  TimetableRepository.pure() : _db = null;

  final AppDatabase? _db;

  Stream<List<TimetableEvent>> watchAll() {
    return _db!.watchAllTimetableEvents();
  }

  List<TimetableOccurrence> occurrencesForDate(
    List<TimetableEvent> events,
    Map<String, Subject> subjects,
    DateTime date,
  ) {
    final day = DateTime(date.year, date.month, date.day);
    final dayIso = DateFormat('yyyy-MM-dd').format(day);
    final weekdayBit = 1 << (day.weekday - 1);

    final out = <TimetableOccurrence>[];
    for (final ev in events) {
      if (ev.isDeleted) continue;
      bool matches = false;
      if (ev.isRecurring) {
        final withinBounds = ev.repeatUntil == null ||
            !day.isAfter(DateTime(
              ev.repeatUntil!.year,
              ev.repeatUntil!.month,
              ev.repeatUntil!.day,
            ));
        matches = withinBounds && (ev.weekdaysMask & weekdayBit) != 0;
      } else {
        matches = ev.specificDate == dayIso;
      }
      if (!matches) continue;
      out.add(
        TimetableOccurrence(
          event: ev,
          subject: ev.subjectId == null ? null : subjects[ev.subjectId],
          date: day,
          startAt: day.add(Duration(minutes: ev.startMinutes)),
          endAt: day.add(Duration(minutes: ev.endMinutes)),
        ),
      );
    }

    out.sort((a, b) => a.event.startMinutes.compareTo(b.event.startMinutes));
    return out;
  }

  TimetableOccurrence? nextUpcomingClass(
    List<TimetableEvent> events,
    Map<String, Subject> subjects,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    for (var offset = 0; offset < 7; offset++) {
      final d = today.add(Duration(days: offset));
      final list = occurrencesForDate(events, subjects, d);
      for (final occ in list) {
        if (occ.endAt.isAfter(now)) {
          return occ;
        }
      }
    }
    return null;
  }

  Future<void> saveEvent({
    String? id,
    required String title,
    String? subjectId,
    required String location,
    required bool isRecurring,
    required int weekdaysMask,
    DateTime? repeatUntil,
    String? specificDate,
    required int startMinutes,
    required int endMinutes,
    required bool reminderEnabled,
    DateTime? existingCreatedAt,
  }) async {
    final now = DateTime.now();
    await _db!.upsertTimetableEvent(
      TimetableEventsCompanion(
        id: Value(id ?? _uuid.v4()),
        subjectId: Value(subjectId),
        title: Value(title.trim()),
        location: Value(location.trim()),
        isRecurring: Value(isRecurring),
        weekdaysMask: Value(isRecurring ? weekdaysMask : 0),
        repeatUntil: Value(isRecurring ? repeatUntil : null),
        specificDate: Value(isRecurring ? null : specificDate),
        startMinutes: Value(startMinutes),
        endMinutes: Value(endMinutes),
        reminderEnabled: Value(reminderEnabled),
        createdAt: Value(existingCreatedAt ?? now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
      ),
    );
  }

  Future<void> deleteEvent(String id) async {
    await _db!.softDeleteTimetableEvent(id);
  }
}
