import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/services/ambient_audio_service.dart';
import 'package:studyspace/core/services/notification_service.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum FocusPhase {
  focus,
  shortBreak,
  longBreak;

  String get label => switch (this) {
        FocusPhase.focus => 'Deep work session',
        FocusPhase.shortBreak => 'Short break',
        FocusPhase.longBreak => 'Long break',
      };
}

@immutable
class FocusStats {
  const FocusStats({
    required this.dayStreak,
    required this.sessionsThisWeek,
  });

  final int dayStreak;
  final int sessionsThisWeek;
}

FocusStats computeFocusStats(List<FocusSession> sessions, DateTime now) {
  final focusOnly =
      sessions.where((s) => !s.isDeleted && s.sessionType == 'focus').toList();

  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(const Duration(days: 6));
  final sessionsThisWeek = focusOnly.where((s) {
    final d = DateTime(s.completedAt.year, s.completedAt.month, s.completedAt.day);
    return !d.isBefore(weekStart) && !d.isAfter(today);
  }).length;

  final activeDays = <DateTime>{
    for (final s in focusOnly)
      DateTime(s.completedAt.year, s.completedAt.month, s.completedAt.day),
  };

  var streak = 0;
  var cursor = activeDays.contains(today)
      ? today
      : today.subtract(const Duration(days: 1));
  while (activeDays.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return FocusStats(dayStreak: streak, sessionsThisWeek: sessionsThisWeek);
}

@immutable
class FocusState {
  const FocusState({
    required this.phase,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
    required this.isPaused,
    required this.currentRound,
    required this.roundsPerCycle,
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.autoStartBreak,
    required this.chimeEnabled,
    this.sessionEndAt,
    this.linkedAssignmentId,
    this.linkedSubjectId,
    this.ambientSound = AmbientSound.rain,
    this.isAudioPlaying = false,
  });

  final FocusPhase phase;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool isPaused;
  final int currentRound;
  final int roundsPerCycle;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final bool autoStartBreak;
  final bool chimeEnabled;
  final DateTime? sessionEndAt;
  final String? linkedAssignmentId;
  final String? linkedSubjectId;
  final AmbientSound ambientSound;
  final bool isAudioPlaying;

  double get progress {
    if (totalSeconds <= 0) return 0;
    return ((totalSeconds - remainingSeconds) / totalSeconds).clamp(0.0, 1.0);
  }

  String get formattedRemaining {
    final clamped = remainingSeconds < 0 ? 0 : remainingSeconds;
    final mins = clamped ~/ 60;
    final secs = clamped % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  FocusState copyWith({
    FocusPhase? phase,
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    bool? isPaused,
    int? currentRound,
    int? roundsPerCycle,
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    bool? autoStartBreak,
    bool? chimeEnabled,
    DateTime? sessionEndAt,
    bool clearSessionEndAt = false,
    String? linkedAssignmentId,
    bool clearLinkedAssignment = false,
    String? linkedSubjectId,
    bool clearLinkedSubject = false,
    AmbientSound? ambientSound,
    bool? isAudioPlaying,
  }) {
    return FocusState(
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      currentRound: currentRound ?? this.currentRound,
      roundsPerCycle: roundsPerCycle ?? this.roundsPerCycle,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      autoStartBreak: autoStartBreak ?? this.autoStartBreak,
      chimeEnabled: chimeEnabled ?? this.chimeEnabled,
      sessionEndAt:
          clearSessionEndAt ? null : (sessionEndAt ?? this.sessionEndAt),
      linkedAssignmentId: clearLinkedAssignment
          ? null
          : (linkedAssignmentId ?? this.linkedAssignmentId),
      linkedSubjectId: clearLinkedSubject
          ? null
          : (linkedSubjectId ?? this.linkedSubjectId),
      ambientSound: ambientSound ?? this.ambientSound,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
    );
  }
}

final focusClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final focusSessionsProvider = StreamProvider<List<FocusSession>>((ref) {
  return ref.watch(appDatabaseProvider).watchAllFocusSessions();
});

final focusStatsProvider = Provider<FocusStats>((ref) {
  final sessions = ref.watch(focusSessionsProvider).valueOrNull ?? const [];
  final now = ref.watch(focusClockProvider)();
  return computeFocusStats(sessions, now);
});

class FocusController extends Notifier<FocusState> {
  Timer? _ticker;
  StreamSubscription<AmbientAudioState>? _audioSub;
  bool _completing = false;

  @override
  FocusState build() {
    final profile = ref.read(userProfileProvider).valueOrNull;
    final audio = ref.read(ambientAudioServiceProvider);

    ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (_, next) {
      final p = next.valueOrNull;
      if (p == null || state.isRunning || state.isPaused) return;
      final total = switch (state.phase) {
        FocusPhase.focus => p.focusMinutes * 60,
        FocusPhase.shortBreak => p.shortBreakMinutes * 60,
        FocusPhase.longBreak => p.longBreakMinutes * 60,
      };
      state = state.copyWith(
        focusMinutes: p.focusMinutes,
        shortBreakMinutes: p.shortBreakMinutes,
        longBreakMinutes: p.longBreakMinutes,
        roundsPerCycle: p.roundsPerCycle,
        autoStartBreak: p.autoStartBreak,
        chimeEnabled: p.chimeEnabled,
        remainingSeconds: total,
        totalSeconds: total,
      );
    });

    _audioSub?.cancel();
    _audioSub = audio.watchState().listen((audioState) {
      state = state.copyWith(
        ambientSound: audioState.sound,
        isAudioPlaying: audioState.isPlaying,
      );
    });

    ref.onDispose(() {
      _ticker?.cancel();
      _audioSub?.cancel();
    });

    final focusM = profile?.focusMinutes ?? 25;
    final shortM = profile?.shortBreakMinutes ?? 5;
    final longM = profile?.longBreakMinutes ?? 15;
    final rounds = profile?.roundsPerCycle ?? 4;

    return FocusState(
      phase: FocusPhase.focus,
      remainingSeconds: focusM * 60,
      totalSeconds: focusM * 60,
      isRunning: false,
      isPaused: false,
      currentRound: 1,
      roundsPerCycle: rounds,
      focusMinutes: focusM,
      shortBreakMinutes: shortM,
      longBreakMinutes: longM,
      autoStartBreak: profile?.autoStartBreak ?? false,
      chimeEnabled: profile?.chimeEnabled ?? true,
      ambientSound: audio.currentSound,
      isAudioPlaying: audio.isPlaying,
    );
  }

  int _durationForPhase(FocusPhase phase) {
    return switch (phase) {
      FocusPhase.focus => state.focusMinutes * 60,
      FocusPhase.shortBreak => state.shortBreakMinutes * 60,
      FocusPhase.longBreak => state.longBreakMinutes * 60,
    };
  }

  Future<void> start() async {
    if (state.isRunning) return;
    final now = ref.read(focusClockProvider)();
    final remaining = state.remainingSeconds > 0
        ? state.remainingSeconds
        : _durationForPhase(state.phase);
    final endAt = now.add(Duration(seconds: remaining));

    state = state.copyWith(
      remainingSeconds: remaining,
      isRunning: true,
      isPaused: false,
      sessionEndAt: endAt,
    );

    await ref
        .read(notificationServiceProvider)
        .scheduleFocusEnd(endAt, state.phase.label);

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      syncWithClock(ref.read(focusClockProvider)());
    });
  }

  Future<void> pause() async {
    if (!state.isRunning) return;
    _ticker?.cancel();
    final now = ref.read(focusClockProvider)();
    final remaining = state.sessionEndAt == null
        ? state.remainingSeconds
        : state.sessionEndAt!.difference(now).inSeconds.clamp(0, state.totalSeconds);

    final audio = ref.read(ambientAudioServiceProvider);
    if (audio.isPlaying) {
      await audio.togglePlay();
    }

    state = state.copyWith(
      remainingSeconds: remaining,
      isRunning: false,
      isPaused: true,
      clearSessionEndAt: true,
      isAudioPlaying: audio.isPlaying,
    );
    await ref.read(notificationServiceProvider).cancelFocusEnd();
  }

  Future<void> reset() async {
    _ticker?.cancel();
    final audio = ref.read(ambientAudioServiceProvider);
    if (audio.isPlaying) {
      await audio.stop();
    }
    final total = _durationForPhase(state.phase);
    state = state.copyWith(
      remainingSeconds: total,
      totalSeconds: total,
      isRunning: false,
      isPaused: false,
      clearSessionEndAt: true,
      isAudioPlaying: audio.isPlaying,
    );
    await ref.read(notificationServiceProvider).cancelFocusEnd();
  }

  Future<void> syncWithClock(DateTime now) async {
    if (!state.isRunning || state.sessionEndAt == null || _completing) return;
    final remaining = state.sessionEndAt!.difference(now).inSeconds;
    if (remaining > 0) {
      if (remaining != state.remainingSeconds) {
        state = state.copyWith(remainingSeconds: remaining);
      }
      return;
    }

    _completing = true;
    _ticker?.cancel();
    try {
      final completedPhase = state.phase;
      final completedDuration = state.totalSeconds;
      final completionTime = state.sessionEndAt!;

      // Log completed focus session once
      if (completedPhase == FocusPhase.focus) {
        await ref.read(appDatabaseProvider).insertFocusSession(
              FocusSessionsCompanion(
                id: Value(_uuid.v4()),
                subjectId: Value(state.linkedSubjectId),
                assignmentId: Value(state.linkedAssignmentId),
                durationSeconds: Value(completedDuration),
                completedAt: Value(completionTime),
                sessionType: const Value('focus'),
                createdAt: Value(completionTime),
                updatedAt: Value(completionTime),
              ),
            );
      }

      if (state.chimeEnabled) {
        await ref.read(ambientAudioServiceProvider).playChime();
      }
      await ref.read(notificationServiceProvider).cancelFocusEnd();

      // Advance phase and round cleanly
      FocusPhase nextPhase;
      int nextRound = state.currentRound;
      if (completedPhase == FocusPhase.focus) {
        if (state.currentRound >= state.roundsPerCycle) {
          nextPhase = FocusPhase.longBreak;
        } else {
          nextPhase = FocusPhase.shortBreak;
        }
      } else {
        nextPhase = FocusPhase.focus;
        nextRound = completedPhase == FocusPhase.longBreak
            ? 1
            : (state.currentRound + 1).clamp(1, state.roundsPerCycle);
      }

      final nextTotal = _durationForPhase(nextPhase);
      state = state.copyWith(
        phase: nextPhase,
        currentRound: nextRound,
        remainingSeconds: nextTotal,
        totalSeconds: nextTotal,
        isRunning: false,
        isPaused: false,
        clearSessionEndAt: true,
      );

      if (state.autoStartBreak && nextPhase != FocusPhase.focus) {
        _completing = false;
        await start();
        return;
      }

      final audio = ref.read(ambientAudioServiceProvider);
      if (audio.isPlaying) {
        await audio.stop();
        state = state.copyWith(isAudioPlaying: false);
      }
    } finally {
      _completing = false;
    }
  }

  Future<void> skipPhase() async {
    _ticker?.cancel();
    await ref.read(notificationServiceProvider).cancelFocusEnd();
    final nextPhase =
        state.phase == FocusPhase.focus ? FocusPhase.shortBreak : FocusPhase.focus;
    final nextRound = state.phase == FocusPhase.focus
        ? state.currentRound
        : ((state.currentRound % state.roundsPerCycle) + 1);
    final nextTotal = _durationForPhase(nextPhase);
    state = state.copyWith(
      phase: nextPhase,
      currentRound: nextRound,
      remainingSeconds: nextTotal,
      totalSeconds: nextTotal,
      isRunning: false,
      isPaused: false,
      clearSessionEndAt: true,
    );
  }

  void setWorkingOn({String? assignmentId, String? subjectId}) {
    state = state.copyWith(
      linkedAssignmentId: assignmentId,
      clearLinkedAssignment: assignmentId == null,
      linkedSubjectId: subjectId,
      clearLinkedSubject: subjectId == null,
    );
  }

  Future<void> selectAmbient(AmbientSound sound) async {
    final audio = ref.read(ambientAudioServiceProvider);
    await audio.selectSound(sound, autoPlay: sound != AmbientSound.off);
    state = state.copyWith(
      ambientSound: audio.currentSound,
      isAudioPlaying: audio.isPlaying,
    );
  }

  Future<void> toggleAmbientPlayback() async {
    final audio = ref.read(ambientAudioServiceProvider);
    await audio.togglePlay();
    state = state.copyWith(
      ambientSound: audio.currentSound,
      isAudioPlaying: audio.isPlaying,
    );
  }

  Future<void> updateSettings({
    required int focusMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    required int roundsPerCycle,
    required bool autoStartBreak,
    required bool chimeEnabled,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final profile = await db.getProfile();
    final now = DateTime.now();
    await db.upsertProfile(
      UserProfilesCompanion(
        id: Value(profile?.id ?? 'default-profile'),
        displayName: Value(profile?.displayName ?? 'Student'),
        avatarColorKey: Value(profile?.avatarColorKey ?? 'periwinkle'),
        themeMode: Value(profile?.themeMode ?? 'system'),
        onboardingDone: Value(profile?.onboardingDone ?? true),
        focusMinutes: Value(focusMinutes),
        shortBreakMinutes: Value(shortBreakMinutes),
        longBreakMinutes: Value(longBreakMinutes),
        roundsPerCycle: Value(roundsPerCycle),
        autoStartBreak: Value(autoStartBreak),
        chimeEnabled: Value(chimeEnabled),
        notificationsEnabled: Value(profile?.notificationsEnabled ?? true),
        classLeadMinutes: Value(profile?.classLeadMinutes ?? 15),
        createdAt: Value(profile?.createdAt ?? now),
        updatedAt: Value(now),
      ),
    );
    if (!state.isRunning) {
      final total = switch (state.phase) {
        FocusPhase.focus => focusMinutes * 60,
        FocusPhase.shortBreak => shortBreakMinutes * 60,
        FocusPhase.longBreak => longBreakMinutes * 60,
      };
      state = state.copyWith(
        focusMinutes: focusMinutes,
        shortBreakMinutes: shortBreakMinutes,
        longBreakMinutes: longBreakMinutes,
        roundsPerCycle: roundsPerCycle,
        autoStartBreak: autoStartBreak,
        chimeEnabled: chimeEnabled,
        remainingSeconds: total,
        totalSeconds: total,
      );
    }
  }
}

final focusControllerProvider =
    NotifierProvider<FocusController, FocusState>(FocusController.new);
