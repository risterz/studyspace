import 'package:drift/drift.dart';

class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().withDefault(const Constant('Student'))();
  TextColumn get avatarColorKey => text().withDefault(const Constant('periwinkle'))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  BoolColumn get onboardingDone => boolean().withDefault(const Constant(false))();
  IntColumn get focusMinutes => integer().withDefault(const Constant(25))();
  IntColumn get shortBreakMinutes => integer().withDefault(const Constant(5))();
  IntColumn get longBreakMinutes => integer().withDefault(const Constant(15))();
  IntColumn get roundsPerCycle => integer().withDefault(const Constant(4))();
  BoolColumn get autoStartBreak => boolean().withDefault(const Constant(false))();
  BoolColumn get chimeEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get notificationsEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get classLeadMinutes => integer().withDefault(const Constant(15))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorKey => text().withDefault(const Constant('periwinkle'))();
  TextColumn get iconKey => text().withDefault(const Constant('book'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class TimetableEvents extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get location => text().withDefault(const Constant(''))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(true))();
  IntColumn get weekdaysMask => integer().withDefault(const Constant(0))();
  DateTimeColumn get repeatUntil => dateTime().nullable()();
  TextColumn get specificDate => text().nullable()();
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Assignments extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get dueAt => dateTime()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Exams extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().nullable()();
  TextColumn get title => text()();
  DateTimeColumn get examAt => dateTime()();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class FocusSessions extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().nullable()();
  TextColumn get assignmentId => text().nullable()();
  IntColumn get durationSeconds => integer()();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get sessionType => text().withDefault(const Constant('focus'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get body => text().withDefault(const Constant(''))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
