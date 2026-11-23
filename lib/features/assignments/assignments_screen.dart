import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/app/widgets/pastel_card.dart';
import 'package:studyspace/app/widgets/subject_badge.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/features/assignments/assignment_editor_sheet.dart';
import 'package:studyspace/features/assignments/assignments_providers.dart';
import 'package:studyspace/features/assignments/assignments_repository.dart';
import 'package:studyspace/features/assignments/exam_editor_sheet.dart';

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key, this.onBellTap});

  final VoidCallback? onBellTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
    final mode = ref.watch(assignmentsTabModeProvider);
    final filter = ref.watch(assignmentFilterProvider);
    final assignments = ref.watch(assignmentsProvider).valueOrNull ?? const <Assignment>[];
    final exams = ref.watch(examsProvider).valueOrNull ?? const <Exam>[];
    final subjects = ref.watch(subjectsByIdProvider);
    final now = DateTime.now();

    final activeCount = assignments.where((a) => !a.isCompleted).length;
    final completedCount = assignments.where((a) => a.isCompleted).length;
    final upcomingExamsCount = exams.where((e) => !e.examAt.isBefore(now)).length;

    final filteredTasks = filterAssignments(assignments, filter, now);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            // Top brand bar matching mockup
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c.mintSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    PhosphorIconsRegular.graduationCap,
                    size: 18,
                    color: c.mint,
                  ),
                ),
                const SizedBox(width: 10),
                Text('StudySpace', style: t.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: 'Upcoming alerts',
                  onPressed: onBellTap,
                  icon: Icon(PhosphorIconsRegular.bell, color: c.inkPrimary, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Assignments', style: t.displaySmall),
            const SizedBox(height: 4),
            Text(
              mode == AssignmentsTabMode.tasks
                  ? '$activeCount active · $completedCount completed'
                  : '$upcomingExamsCount upcoming ${upcomingExamsCount == 1 ? 'exam' : 'exams'}',
              style: t.bodyLarge?.copyWith(color: c.inkSecondary),
            ),
            const SizedBox(height: 16),
            // Tasks | Exams segmented switch
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  _SegmentButton(
                    label: 'Tasks',
                    selected: mode == AssignmentsTabMode.tasks,
                    onTap: () => ref
                        .read(assignmentsTabModeProvider.notifier)
                        .state = AssignmentsTabMode.tasks,
                  ),
                  _SegmentButton(
                    label: 'Exams',
                    selected: mode == AssignmentsTabMode.exams,
                    onTap: () => ref
                        .read(assignmentsTabModeProvider.notifier)
                        .state = AssignmentsTabMode.exams,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (mode == AssignmentsTabMode.tasks) ...[
              // Filter pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterPill(
                      label: 'All',
                      selected: filter == AssignmentFilter.all,
                      onTap: () => ref
                          .read(assignmentFilterProvider.notifier)
                          .state = AssignmentFilter.all,
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'Due soon',
                      selected: filter == AssignmentFilter.dueSoon,
                      onTap: () => ref
                          .read(assignmentFilterProvider.notifier)
                          .state = AssignmentFilter.dueSoon,
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'High priority',
                      selected: filter == AssignmentFilter.highPriority,
                      onTap: () => ref
                          .read(assignmentFilterProvider.notifier)
                          .state = AssignmentFilter.highPriority,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (filteredTasks.isEmpty)
                PastelCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Column(
                    children: [
                      Icon(PhosphorIconsRegular.checkCircle, size: 36, color: c.mint),
                      const SizedBox(height: 10),
                      Text('All caught up', style: t.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'No assignments match this filter right now.',
                        style: t.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...filteredTasks.map((item) {
                  final subject =
                      item.subjectId == null ? null : subjects[item.subjectId];
                  final dueLabel = item.isCompleted
                      ? 'Completed'
                      : formatDueLabel(item.dueAt, now);
                  final isOverdue = !item.isCompleted && dueLabel == 'Overdue';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PastelCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      onTap: () => showAssignmentEditorSheet(context, existing: item),
                      child: Row(
                        children: [
                          InkWell(
                            key: Key('toggle_assignment_${item.title}'),
                            customBorder: const CircleBorder(),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(assignmentsRepositoryProvider)
                                  .toggleCompleted(item, !item.isCompleted);
                            },
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: item.isCompleted
                                        ? c.mint.withValues(alpha: 0.25)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: item.isCompleted ? c.mint : c.primaryRing,
                                      width: 2,
                                    ),
                                  ),
                                  child: item.isCompleted
                                      ? Icon(
                                          PhosphorIconsBold.check,
                                          size: 16,
                                          color: c.mint,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.titleMedium?.copyWith(
                                    decoration: item.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: item.isCompleted
                                        ? c.inkSecondary
                                        : c.inkPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      dueLabel,
                                      style: t.bodyMedium?.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: item.isCompleted
                                            ? c.mint
                                            : (isOverdue ? c.danger : c.primary),
                                      ),
                                    ),
                                    if (subject != null)
                                      Text(
                                        '· ${subject.name}',
                                        style: t.bodyMedium?.copyWith(fontSize: 13),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SubjectBadge(subject: subject, size: 40, iconSize: 20),
                          if (!item.isCompleted && item.priority == 'high') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: c.primarySoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'High',
                                style: t.labelSmall?.copyWith(
                                  color: c.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
              _SoftActionButton(
                label: 'Add assignment',
                onTap: () => showAssignmentEditorSheet(context),
              ),
            ] else ...[
              // Exams Countdown View
              if (exams.isEmpty)
                PastelCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Column(
                    children: [
                      Icon(PhosphorIconsRegular.hourglassMedium,
                          size: 36, color: c.primary),
                      const SizedBox(height: 10),
                      Text('No exams added yet', style: t.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Add midterms or finals to track live countdowns and get study alerts.',
                        style: t.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...exams.map((exam) {
                  final subject =
                      exam.subjectId == null ? null : subjects[exam.subjectId];
                  final info = computeExamCountdown(exam.examAt, now);
                  final (pillBg, pillFg) = switch (info.urgency) {
                    ExamUrgency.urgent => (c.coralSoft, c.danger),
                    ExamUrgency.soon => (c.amberSoft, c.warning),
                    ExamUrgency.normal => (c.primarySoft, c.primary),
                    ExamUrgency.past => (c.mintSoft, c.mint),
                  };

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PastelCard(
                      onTap: () => showExamEditorSheet(context, existing: exam),
                      child: Row(
                        children: [
                          SubjectBadge(subject: subject, size: 46, iconSize: 22),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exam.title,
                                  style: t.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat('MMM d · h:mm a').format(exam.examAt)}${exam.location.isEmpty ? '' : ' · ${exam.location}'}',
                                  style: t.bodyMedium?.copyWith(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subject != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subject.name,
                                    style: t.labelMedium?.copyWith(color: c.primary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              info.label,
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: pillFg,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
              _SoftActionButton(
                label: 'Add exam',
                onTap: () => showExamEditorSheet(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected ? Border.all(color: c.border) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? c.inkPrimary : c.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.primarySoft : c.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? c.primary.withValues(alpha: 0.4) : c.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? c.primary : c.inkPrimary,
          ),
        ),
      ),
    );
  }
}

class _SoftActionButton extends StatelessWidget {
  const _SoftActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
    return Material(
      color: c.primarySoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsBold.plus, size: 18, color: c.inkPrimary),
              const SizedBox(width: 8),
              Text(label, style: t.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
