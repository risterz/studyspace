import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/app/theme/subject_styles.dart';
import 'package:studyspace/app/widgets/pastel_card.dart';
import 'package:studyspace/app/widgets/subject_badge.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/features/timetable/event_editor_sheet.dart';
import 'package:studyspace/features/timetable/timetable_providers.dart';
import 'package:studyspace/features/timetable/timetable_repository.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  DateTime _mondayOfWeek(DateTime d) {
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
  }

  String _formatWeekRange(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    final startMonth = DateFormat('MMM').format(monday).toUpperCase();
    final endMonth = DateFormat('MMM').format(sunday).toUpperCase();
    if (startMonth == endMonth) {
      return '$startMonth ${monday.day}–${sunday.day}';
    }
    return '$startMonth ${monday.day}–$endMonth ${sunday.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
    final selectedDate = ref.watch(selectedTimetableDateProvider);
    final allEvents = ref.watch(timetableEventsProvider).valueOrNull ?? const [];
    final subjects = ref.watch(subjectsByIdProvider);
    final repo = ref.watch(timetableRepositoryProvider);
    final occurrences = ref.watch(dayOccurrencesProvider);
    final monday = _mondayOfWeek(selectedDate);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                Expanded(child: Text('Timetable', style: t.displaySmall)),
                Material(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      final now = DateTime.now();
                      ref.read(selectedTimetableDateProvider.notifier).state =
                          DateTime(now.year, now.month, now.day);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        PhosphorIconsRegular.calendarBlank,
                        size: 22,
                        color: c.inkPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Week switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous week',
                  onPressed: () {
                    ref.read(selectedTimetableDateProvider.notifier).state =
                        selectedDate.subtract(const Duration(days: 7));
                  },
                  icon: Icon(PhosphorIconsRegular.caretLeft, color: c.inkPrimary, size: 18),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _formatWeekRange(monday),
                    style: t.titleSmall?.copyWith(letterSpacing: 0.6),
                  ),
                ),
                IconButton(
                  tooltip: 'Next week',
                  onPressed: () {
                    ref.read(selectedTimetableDateProvider.notifier).state =
                        selectedDate.add(const Duration(days: 7));
                  },
                  icon: Icon(PhosphorIconsRegular.caretRight, color: c.inkPrimary, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 7-day pill strip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (idx) {
                final date = monday.add(Duration(days: idx));
                final isSelected = date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;
                final hasEvents =
                    repo.occurrencesForDate(allEvents, subjects, date).isNotEmpty;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        ref.read(selectedTimetableDateProvider.notifier).state = date;
                      },
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 160),
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSelected ? c.primary : c.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? c.primary : c.border,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _dayLetters[idx],
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? c.onPrimary : c.inkPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasEvents
                                    ? (isSelected ? c.onPrimary : c.primaryRing)
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
            Text(
              DateFormat('EEEE, MMM d').format(selectedDate),
              style: t.titleLarge,
            ),
            const SizedBox(height: 16),
            if (occurrences.isEmpty)
              PastelCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Column(
                  children: [
                    Icon(
                      PhosphorIconsRegular.sunHorizon,
                      size: 36,
                      color: c.inkSecondary,
                    ),
                    const SizedBox(height: 10),
                    Text('No classes scheduled', style: t.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Enjoy your free time or add a class or study session below.',
                      textAlign: TextAlign.center,
                      style: t.bodyMedium,
                    ),
                  ],
                ),
              )
            else
              ...List.generate(occurrences.length, (i) {
                final occ = occurrences[i];
                final isLast = i == occurrences.length - 1;
                final colorKey = occ.subject == null
                    ? SubjectColorKey.periwinkle
                    : parseSubjectColorKey(occ.subject!.colorKey);
                final cardTint = subjectTint(colorKey, c);
                final dotColor = subjectAccent(colorKey, c);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 50,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                formatMinutes(occ.event.startMinutes),
                                style: t.titleSmall?.copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatMinutes(occ.event.endMinutes),
                                style: t.bodyMedium?.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 22,
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 1.5,
                                    margin: const EdgeInsets.only(top: 4),
                                    color: c.border,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PastelCard(
                            backgroundColor: cardTint,
                            borderColor: dotColor.withValues(alpha: 0.18),
                            padding: const EdgeInsets.all(14),
                            onTap: () => showEventEditorSheet(
                              context,
                              existing: occ.event,
                              initialDate: selectedDate,
                            ),
                            child: Row(
                              children: [
                                SubjectBadge(
                                  subject: occ.subject,
                                  size: 48,
                                  iconSize: 22,
                                  overrideBackground: c.surface,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        occ.event.title,
                                        style: t.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${formatMinutes(occ.event.startMinutes)} – ${formatMinutes(occ.event.endMinutes)}',
                                        style: t.bodyMedium?.copyWith(fontSize: 13),
                                      ),
                                      if (occ.event.location.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              PhosphorIconsRegular.mapPin,
                                              size: 14,
                                              color: c.inkSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                occ.event.location,
                                                style: t.bodyMedium?.copyWith(fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 10),
            // Dashed-feel Add Event button matching mockup
            InkWell(
              onTap: () => showEventEditorSheet(context, initialDate: selectedDate),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: c.surface.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: c.primary.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsRegular.plusCircle, size: 20, color: c.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Add event',
                      style: t.titleSmall?.copyWith(color: c.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
