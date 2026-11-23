import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyspace/app/theme/studyspace_theme.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/db/sample_seeder.dart';
import 'package:studyspace/core/services/ambient_audio_service.dart';
import 'package:studyspace/core/services/notification_service.dart';
import 'package:studyspace/features/focus/focus_controller.dart';
import 'package:studyspace/features/focus/focus_screen.dart';

class _FakeAmbientAudio implements AmbientAudioService {
  AmbientSound _sound = AmbientSound.rain;
  bool _playing = false;
  int chimeCount = 0;
  final _ctrl = StreamController<AmbientAudioState>.broadcast();

  @override
  AmbientSound get currentSound => _sound;

  @override
  bool get isPlaying => _playing;

  @override
  Stream<AmbientAudioState> watchState() => _ctrl.stream;

  @override
  Future<void> init() async {}

  @override
  Future<void> selectSound(AmbientSound sound, {bool autoPlay = true}) async {
    _sound = sound;
    _playing = sound != AmbientSound.off && autoPlay;
    _ctrl.add(AmbientAudioState(sound: _sound, isPlaying: _playing));
  }

  @override
  Future<void> togglePlay() async {
    _playing = !_playing;
    _ctrl.add(AmbientAudioState(sound: _sound, isPlaying: _playing));
  }

  @override
  Future<void> stop() async {
    _playing = false;
    _ctrl.add(AmbientAudioState(sound: _sound, isPlaying: _playing));
  }

  @override
  Future<void> playChime() async {
    chimeCount++;
  }

  @override
  Future<void> dispose() async {
    await _ctrl.close();
  }
}

class _FakeNotificationService extends NoopNotificationService {
  DateTime? lastScheduledFocusEnd;
  int cancelCount = 0;

  @override
  Future<void> scheduleFocusEnd(DateTime endAt, String phaseLabel) async {
    lastScheduledFocusEnd = endAt;
  }

  @override
  Future<void> cancelFocusEnd() async {
    cancelCount++;
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('computeFocusStats computes consecutive day streak and current-week sessions', () {
    final now = DateTime(2026, 11, 23, 16, 0);
    FocusSession make(int daysAgo, {String type = 'focus'}) {
      final dt = now.subtract(Duration(days: daysAgo, hours: 1));
      return FocusSession(
        id: 's-$daysAgo-${dt.microsecondsSinceEpoch}',
        subjectId: null,
        assignmentId: null,
        durationSeconds: 1500,
        completedAt: dt,
        sessionType: type,
        createdAt: dt,
        updatedAt: dt,
        isDeleted: false,
      );
    }

    final stats = computeFocusStats(
      [make(0), make(0), make(1), make(2), make(4), make(0, type: 'shortBreak')],
      now,
    );
    expect(stats.dayStreak, 3);
    expect(stats.sessionsThisWeek, 5);
  });

  test('FocusController handles background clock jump without negative digits or double-logging', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final fakeAudio = _FakeAmbientAudio();
    final fakeNotif = _FakeNotificationService();
    var fakeNow = DateTime(2026, 11, 23, 10, 0, 0);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        ambientAudioServiceProvider.overrideWithValue(fakeAudio),
        notificationServiceProvider.overrideWithValue(fakeNotif),
        focusClockProvider.overrideWithValue(() => fakeNow),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final ctrl = container.read(focusControllerProvider.notifier);
    await ctrl.start();

    expect(container.read(focusControllerProvider).isRunning, isTrue);
    expect(fakeNotif.lastScheduledFocusEnd, DateTime(2026, 11, 23, 10, 25, 0));

    // Jump 30 minutes forward (past 25:00 session end) and sync twice
    fakeNow = DateTime(2026, 11, 23, 10, 30, 0);
    await ctrl.syncWithClock(fakeNow);
    await ctrl.syncWithClock(fakeNow);

    final state = container.read(focusControllerProvider);
    expect(state.remainingSeconds, greaterThanOrEqualTo(0));
    expect(state.phase, FocusPhase.shortBreak);
    expect(fakeAudio.chimeCount, 1);

    final logged = await db.watchAllFocusSessions().first;
    expect(logged.length, 1);

    // Ambient sound selection delegates cleanly
    await ctrl.selectAmbient(AmbientSound.cafe);
    expect(fakeAudio.currentSound, AmbientSound.cafe);
    expect(fakeAudio.isPlaying, isTrue);
  });

  testWidgets(
    'FocusScreen renders 25:00 ring, controls, streak card, working-on card, and ambient card',
    timeout: const Timeout(Duration(seconds: 20)),
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await seedSampleSemester(db, displayName: 'Maya', referenceNow: DateTime(2026, 11, 23, 9, 30));
      final fakeAudio = _FakeAmbientAudio();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            ambientAudioServiceProvider.overrideWithValue(fakeAudio),
            notificationServiceProvider.overrideWithValue(NoopNotificationService()),
          ],
          child: MaterialApp(
            theme: buildStudySpaceTheme(Brightness.light),
            home: const FocusScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Pomodoro 1 of 4'), findsOneWidget);
      expect(find.text('Start focus'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Rain'), 200);
      expect(find.text('Rain'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await db.close();
    },
  );
}
