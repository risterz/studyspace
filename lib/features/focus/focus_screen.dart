import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/app/widgets/pastel_card.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/services/ambient_audio_service.dart';
import 'package:studyspace/features/assignments/assignments_providers.dart';
import 'package:studyspace/features/focus/focus_controller.dart';
import 'package:studyspace/features/focus/focus_settings_sheet.dart';
import 'package:studyspace/features/focus/widgets/focus_ring_painter.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(focusControllerProvider.notifier).syncWithClock(DateTime.now());
    }
  }

  Future<void> _showWorkingOnPicker(
    BuildContext context,
    List<Assignment> activeAssignments,
    List<Subject> subjects,
  ) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Working on', style: t.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(PhosphorIconsRegular.sparkle, color: c.mint),
                title: const Text('General study'),
                onTap: () {
                  ref.read(focusControllerProvider.notifier).setWorkingOn(
                        assignmentId: null,
                        subjectId: null,
                      );
                  Navigator.of(context).pop();
                },
              ),
              if (activeAssignments.isEmpty && subjects.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Add subjects or assignments to link specific focus sessions.',
                    style: t.bodyMedium,
                  ),
                ),
              if (activeAssignments.isNotEmpty) ...[
                Text('Assignments', style: t.labelMedium),
                const SizedBox(height: 6),
                ...activeAssignments.take(6).map(
                      (a) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(PhosphorIconsRegular.clipboardText, color: c.primary),
                        title: Text(a.title),
                        onTap: () {
                          ref.read(focusControllerProvider.notifier).setWorkingOn(
                                assignmentId: a.id,
                                subjectId: a.subjectId,
                              );
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
              ],
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Subjects', style: t.labelMedium),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subjects
                      .map(
                        (s) => ActionChip(
                          label: Text(s.name),
                          onPressed: () {
                            ref.read(focusControllerProvider.notifier).setWorkingOn(
                                  assignmentId: null,
                                  subjectId: s.id,
                                );
                            Navigator.of(context).pop();
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAmbientPicker(BuildContext context, AmbientSound current) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ambient sound', style: t.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Loops offline and stays on when your screen locks.',
                style: t.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...AmbientSound.values.map((sound) {
                final icon = switch (sound) {
                  AmbientSound.off => PhosphorIconsRegular.speakerSlash,
                  AmbientSound.rain => PhosphorIconsRegular.cloudRain,
                  AmbientSound.cafe => PhosphorIconsRegular.coffee,
                  AmbientSound.whiteNoise => PhosphorIconsRegular.waveform,
                };
                final selected = sound == current;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected ? c.primarySoft : c.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: selected ? c.primary : c.inkSecondary),
                  ),
                  title: Text(sound.label, style: t.titleSmall),
                  trailing: selected
                      ? Icon(PhosphorIconsBold.check, color: c.primary, size: 18)
                      : null,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await ref
                        .read(focusControllerProvider.notifier)
                        .selectAmbient(sound);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
    final state = ref.watch(focusControllerProvider);
    final ctrl = ref.read(focusControllerProvider.notifier);
    final stats = ref.watch(focusStatsProvider);
    final assignments =
        (ref.watch(assignmentsProvider).valueOrNull ?? const <Assignment>[])
            .where((a) => !a.isCompleted)
            .toList();
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? const <Subject>[];
    final subjectsMap = ref.watch(subjectsByIdProvider);

    // Resolve "Working on" label accurately (matches persisted focus session linkage)
    String workingOnLabel = 'General study';
    if (state.linkedAssignmentId != null) {
      final match = assignments.where((a) => a.id == state.linkedAssignmentId);
      if (match.isNotEmpty) workingOnLabel = match.first.title;
    } else if (state.linkedSubjectId != null &&
        subjectsMap.containsKey(state.linkedSubjectId)) {
      workingOnLabel = subjectsMap[state.linkedSubjectId]!.name;
    }

    final isBreak = state.phase != FocusPhase.focus;
    final primaryBtnLabel = state.isRunning
        ? (isBreak ? 'Skip break' : 'Running...')
        : (state.isPaused
            ? 'Resume focus'
            : (isBreak ? 'Start break' : 'Start focus'));

    final soundIcon = switch (state.ambientSound) {
      AmbientSound.off => PhosphorIconsRegular.speakerSlash,
      AmbientSound.rain => PhosphorIconsRegular.cloudRain,
      AmbientSound.cafe => PhosphorIconsRegular.coffee,
      AmbientSound.whiteNoise => PhosphorIconsRegular.waveform,
    };

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Focus', style: t.displaySmall),
                      const SizedBox(height: 2),
                      Text(
                        'Stay focused, get things done.',
                        style: t.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Material(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => showFocusSettingsSheet(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        PhosphorIconsRegular.gearSix,
                        size: 22,
                        color: c.inkPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Glowing circular timer ring matching Focus mockup
            Center(
              child: SizedBox(
                width: 256,
                height: 256,
                child: CustomPaint(
                  painter: FocusRingPainter(
                    progress: state.progress,
                    ringColor: isBreak ? c.mint : c.primaryRing,
                    progressArcColor: isBreak ? c.primaryRing : c.mint,
                    glowColor: isBreak ? c.mint : c.primaryRing,
                    centerSurface: c.canvas,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isBreak ? c.mintSoft : c.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          isBreak
                              ? PhosphorIconsRegular.coffee
                              : PhosphorIconsRegular.brain,
                          size: 18,
                          color: isBreak ? c.mint : c.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(state.phase.label,
                          style: t.bodyMedium?.copyWith(fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        state.formattedRemaining,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          color: c.inkPrimary,
                          letterSpacing: -1.2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIconsRegular.timer,
                              size: 13,
                              color: c.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Pomodoro ${state.currentRound} of ${state.roundsPerCycle}',
                              style: t.labelSmall?.copyWith(
                                color: c.primary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Primary Start / Resume button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isRunning
                    ? (isBreak ? ctrl.skipPhase : null)
                    : ctrl.start,
                icon: Icon(
                  state.isRunning
                      ? (isBreak
                          ? PhosphorIconsRegular.skipForward
                          : PhosphorIconsFill.timer)
                      : PhosphorIconsRegular.play,
                  size: 18,
                ),
                label: Text(primaryBtnLabel),
              ),
            ),
            const SizedBox(height: 10),
            // Secondary Pause | Reset row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isRunning ? ctrl.pause : null,
                    icon: const Icon(PhosphorIconsRegular.pause, size: 18),
                    label: const Text('Pause'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: ctrl.reset,
                    icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise,
                        size: 18),
                    label: const Text('Reset'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Card 1: Streak
            PastelCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.mintSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(PhosphorIconsFill.fire, color: c.mint, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${stats.dayStreak} day streak', style: t.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${stats.sessionsThisWeek} sessions this week',
                          style: t.bodyMedium?.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c.mintSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(PhosphorIconsBold.trendUp, color: c.mint, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Card 2: Working on
            PastelCard(
              padding: const EdgeInsets.all(14),
              onTap: () => _showWorkingOnPicker(context, assignments, subjects),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(PhosphorIconsFill.folder, color: c.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Working on:', style: t.bodyMedium?.copyWith(fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          workingOnLabel,
                          style: t.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(PhosphorIconsRegular.caretRight,
                      size: 18, color: c.inkSecondary),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Card 3: Ambient sound
            PastelCard(
              padding: const EdgeInsets.all(14),
              onTap: () => _showAmbientPicker(context, state.ambientSound),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(soundIcon, color: c.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.ambientSound.label, style: t.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          state.isAudioPlaying
                              ? 'Playing · screen-lock ready'
                              : 'Tap to choose ambient sound',
                          style: t.bodyMedium?.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: state.isAudioPlaying ? c.primary : c.primarySoft,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: ctrl.toggleAmbientPlayback,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          state.isAudioPlaying
                              ? PhosphorIconsFill.waveform
                              : PhosphorIconsRegular.waveform,
                          size: 20,
                          color: state.isAudioPlaying ? c.onPrimary : c.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
