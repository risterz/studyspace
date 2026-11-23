import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/services/notification_scheduler.dart';
import 'package:studyspace/core/services/notification_service.dart';
import 'package:studyspace/features/assignments/assignments_providers.dart';
import 'package:studyspace/features/timetable/timetable_providers.dart';

Future<void> showUpcomingAlertsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const UpcomingAlertsSheet(),
  );
}

class UpcomingAlertsSheet extends ConsumerWidget {
  const UpcomingAlertsSheet({super.key});

  Future<void> _muteSource(WidgetRef ref, ScheduledAlert alert) async {
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    switch (alert.sourceType) {
      case AlertSourceType.timetable:
        final events = await db.getAllTimetableEvents();
        final match = events.where((e) => e.id == alert.sourceId);
        if (match.isNotEmpty) {
          final e = match.first;
          await db.upsertTimetableEvent(
            e.toCompanion(true).copyWith(
                  reminderEnabled: const Value(false),
                  updatedAt: Value(now),
                ),
          );
        }
      case AlertSourceType.assignment:
        final items = await db.getAllAssignments();
        final match = items.where((a) => a.id == alert.sourceId);
        if (match.isNotEmpty) {
          final a = match.first;
          await db.upsertAssignment(
            a.toCompanion(true).copyWith(
                  reminderEnabled: const Value(false),
                  updatedAt: Value(now),
                ),
          );
        }
      case AlertSourceType.exam:
        final items = await db.getAllExams();
        final match = items.where((x) => x.id == alert.sourceId);
        if (match.isNotEmpty) {
          final x = match.first;
          await db.upsertExam(
            x.toCompanion(true).copyWith(
                  reminderEnabled: const Value(false),
                  updatedAt: Value(now),
                ),
          );
        }
      case AlertSourceType.focus:
        break;
    }

    final profile = await db.getProfile();
    if (profile != null) {
      await ref.read(notificationServiceProvider).syncAllReminders(
            enabled: profile.notificationsEnabled,
            classLeadMinutes: profile.classLeadMinutes,
            events: await db.getAllTimetableEvents(),
            assignments: await db.getAllAssignments(),
            exams: await db.getAllExams(),
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final events = ref.watch(timetableEventsProvider).valueOrNull ?? const [];
    final assignments = ref.watch(assignmentsProvider).valueOrNull ?? const [];
    final exams = ref.watch(examsProvider).valueOrNull ?? const [];

    final alerts = (profile?.notificationsEnabled ?? true)
        ? buildRollingAlerts(
            now: DateTime.now(),
            classLeadMinutes: profile?.classLeadMinutes ?? 15,
            events: events,
            assignments: assignments,
            exams: exams,
            maxAlerts: 20,
          )
        : const <ScheduledAlert>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('Upcoming alerts', style: t.titleLarge)),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/settings');
                },
                child: const Text('Settings'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Column(
                  children: [
                    Icon(PhosphorIconsRegular.bellSlash,
                        size: 34, color: c.inkSecondary),
                    const SizedBox(height: 8),
                    Text('No upcoming alerts scheduled', style: t.titleSmall),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: alerts.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  final icon = switch (alert.sourceType) {
                    AlertSourceType.timetable => PhosphorIconsRegular.calendarBlank,
                    AlertSourceType.assignment => PhosphorIconsRegular.clipboardText,
                    AlertSourceType.exam => PhosphorIconsRegular.hourglassMedium,
                    AlertSourceType.focus => PhosphorIconsRegular.timer,
                  };
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 20, color: c.primary),
                    ),
                    title: Text(alert.title, style: t.titleSmall),
                    subtitle: Text(
                      '${DateFormat('EEE, MMM d · h:mm a').format(alert.fireAt)}\n${alert.subtitle}',
                      style: t.bodyMedium?.copyWith(fontSize: 12),
                    ),
                    trailing: IconButton(
                      tooltip: 'Mute reminder',
                      onPressed: () => _muteSource(ref, alert),
                      icon: Icon(PhosphorIconsRegular.bellSlash,
                          size: 18, color: c.inkSecondary),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
