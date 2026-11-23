import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/app/theme/subject_styles.dart';
import 'package:studyspace/app/widgets/pastel_card.dart';
import 'package:studyspace/app/widgets/subject_badge.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/features/assignments/assignment_editor_sheet.dart';
import 'package:studyspace/features/assignments/assignments_providers.dart';
import 'package:studyspace/features/assignments/assignments_repository.dart';
import 'package:studyspace/features/home/home_providers.dart';
import 'package:studyspace/features/home/upcoming_alerts_sheet.dart';
import 'package:studyspace/features/home/widgets/desk_wash_painter.dart';
import 'package:studyspace/features/timetable/timetable_providers.dart';
import 'package:studyspace/features/timetable/timetable_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _safeGo(BuildContext context, String location) {
    final router = GoRouter.maybeOf(context);
    router?.go(location);
  }

  void _safePush(BuildContext context, String location) {
    final router = GoRouter.maybeOf(context);
    router?.push(location);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final subjects = ref.watch(subjectsByIdProvider);
    final upcomingClass = ref.watch(homeUpcomingClassProvider);
    final progress = ref.watch(homeTodayProgressProvider);
    final nextAssignment = ref.watch(homeNextAssignmentProvider);
    final upcomingExam = ref.watch(homeUpcomingExamProvider);

    final now = DateTime.now();
    final name = profile?.displayName ?? 'Student';
    final initial = name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase();
    final avatarColorKey = parseSubjectColorKey(profile?.avatarColorKey);

    return Scaffold(
      body: CustomPaint(
        painter: DeskWashPainter(
          washColor: c.primarySoft,
          lineColor: c.primary,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              // Top bar: StudySpace + bell + avatar
              Row(
                children: [
                  Text('StudySpace', style: t.titleLarge),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Upcoming alerts',
                    onPressed: () => showUpcomingAlertsSheet(context),
                    icon: Icon(
                      PhosphorIconsRegular.bell,
                      size: 22,
                      color: c.inkPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    key: const Key('home_profile_avatar'),
                    customBorder: const CircleBorder(),
                    onTap: () => _safePush(context, '/settings'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: subjectTint(avatarColorKey, c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: subjectAccent(avatarColorKey, c)
                              .withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: subjectAccent(avatarColorKey, c),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Greeting + Date
              Text(greetingForHour(now.hour, name), style: t.headlineMedium),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMMM d').format(now),
                style: t.bodyLarge?.copyWith(color: c.inkSecondary),
              ),
              const SizedBox(height: 22),
              // Card 1: UPCOMING CLASS
              PastelCard(
                onTap: () {
                  if (upcomingClass != null) {
                    ref.read(selectedTimetableDateProvider.notifier).state =
                        upcomingClass.date;
                  }
                  _safeGo(context, '/timetable');
                },
                child: Row(
                  children: [
                    SubjectBadge(
                      subject: upcomingClass?.subject,
                      size: 48,
                      iconSize: 22,
                      isCircle: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UPCOMING CLASS', style: t.labelSmall),
                          const SizedBox(height: 4),
                          Text(
                            upcomingClass?.event.title ?? 'No upcoming classes',
                            style: t.titleLarge?.copyWith(fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            upcomingClass == null
                                ? 'Tap to add your weekly schedule'
                                : '${formatMinutesWithPeriod(upcomingClass.event.startMinutes)}${upcomingClass.event.location.isEmpty ? '' : ' · ${upcomingClass.event.location}'}',
                            style: t.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      PhosphorIconsRegular.caretRight,
                      size: 18,
                      color: c.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Card 2: Today's progress
              PastelCard(
                onTap: () => _safeGo(context, '/assignments'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: c.mintSoft,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            PhosphorIconsRegular.checkCircle,
                            size: 24,
                            color: c.mint,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Today's progress", style: t.titleLarge?.copyWith(fontSize: 18)),
                              const SizedBox(height: 3),
                              Text(
                                progress.total == 0
                                    ? 'No tasks yet — add one below'
                                    : '${progress.completed} of ${progress.total} tasks complete',
                                style: t.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: TweenAnimationBuilder<double>(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 350),
                        tween: Tween(begin: 0, end: progress.ratio),
                        builder: (_, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          backgroundColor: c.mintSoft,
                          valueColor: AlwaysStoppedAnimation(c.mint),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Quick Action Row (3 equal tiles matching Home mockup)
              Row(
                children: [
                  Expanded(
                    child: _QuickActionTile(
                      label: 'Start focus',
                      icon: PhosphorIconsRegular.target,
                      tint: c.primarySoft,
                      accent: c.primary,
                      onTap: () => _safeGo(context, '/focus'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionTile(
                      label: 'Add assignment',
                      icon: PhosphorIconsRegular.filePlus,
                      tint: c.mintSoft,
                      accent: c.mint,
                      onTap: () => showAssignmentEditorSheet(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionTile(
                      label: 'New note',
                      icon: PhosphorIconsRegular.notePencil,
                      tint: c.primarySoft,
                      accent: c.primary,
                      onTap: () => _safePush(context, '/notes/new'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Card 3: NEXT ASSIGNMENT
              PastelCard(
                onTap: () {
                  ref.read(assignmentsTabModeProvider.notifier).state =
                      AssignmentsTabMode.tasks;
                  _safeGo(context, '/assignments');
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: c.mintSoft,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        PhosphorIconsRegular.fileText,
                        size: 22,
                        color: c.mint,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NEXT ASSIGNMENT', style: t.labelSmall),
                          const SizedBox(height: 4),
                          Text(
                            nextAssignment?.title ?? 'All assignments complete',
                            style: t.titleLarge?.copyWith(fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (nextAssignment != null)
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(PhosphorIconsRegular.calendarBlank,
                                        size: 14, color: c.mint),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatDueLabel(nextAssignment.dueAt, now),
                                      style: t.bodyMedium?.copyWith(fontSize: 13),
                                    ),
                                  ],
                                ),
                                if (nextAssignment.priority == 'high')
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(PhosphorIconsRegular.flag,
                                          size: 14, color: c.danger),
                                      const SizedBox(width: 4),
                                      Text(
                                        'High priority',
                                        style: t.bodyMedium?.copyWith(
                                          fontSize: 13,
                                          color: c.danger,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            )
                          else
                            Text(
                              'Tap to add upcoming coursework',
                              style: t.bodyMedium?.copyWith(fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      PhosphorIconsRegular.caretRight,
                      size: 18,
                      color: c.inkSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Card 4: UPCOMING EXAM (User-Confirmed Exam Countdown integration)
              Builder(
                builder: (context) {
                  final countdown = upcomingExam == null
                      ? null
                      : computeExamCountdown(upcomingExam.examAt, now);
                  final subject = upcomingExam?.subjectId == null
                      ? null
                      : subjects[upcomingExam!.subjectId];
                  final (badgeBg, badgeFg) = switch (countdown?.urgency) {
                    ExamUrgency.urgent => (c.coralSoft, c.danger),
                    ExamUrgency.soon => (c.amberSoft, c.warning),
                    _ => (c.primarySoft, c.primary),
                  };

                  return PastelCard(
                    onTap: () {
                      ref.read(assignmentsTabModeProvider.notifier).state =
                          AssignmentsTabMode.exams;
                      _safeGo(context, '/assignments');
                    },
                    child: Row(
                      children: [
                        SubjectBadge(
                          subject: subject,
                          size: 48,
                          iconSize: 22,
                          isCircle: true,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('UPCOMING EXAM', style: t.labelSmall),
                              const SizedBox(height: 4),
                              Text(
                                upcomingExam?.title ?? 'No upcoming exams',
                                style: t.titleLarge?.copyWith(fontSize: 18),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                upcomingExam == null
                                    ? 'Track midterms & finals countdowns'
                                    : '${DateFormat('MMM d · h:mm a').format(upcomingExam.examAt)}${upcomingExam.location.isEmpty ? '' : ' · ${upcomingExam.location}'}',
                                style: t.bodyMedium?.copyWith(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (countdown != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${countdown.label} left',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: badgeFg,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          )
                        else
                          Icon(
                            PhosphorIconsRegular.caretRight,
                            size: 18,
                            color: c.inkSecondary,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.tint,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    return PastelCard(
      backgroundColor: tint.withValues(alpha: 0.72),
      borderColor: accent.withValues(alpha: 0.16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      borderRadius: 16,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.inkPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
