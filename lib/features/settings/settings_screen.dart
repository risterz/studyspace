import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/app/theme/subject_styles.dart';
import 'package:studyspace/app/widgets/pastel_card.dart';
import 'package:studyspace/app/widgets/subject_badge.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/db/sample_seeder.dart';
import 'package:studyspace/core/services/notification_service.dart';
import 'package:studyspace/features/settings/subject_manager_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _nameSeeded = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile(
    UserProfile? current, {
    String? displayName,
    String? avatarColorKey,
    String? themeMode,
    bool? notificationsEnabled,
    int? classLeadMinutes,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    await db.upsertProfile(
      UserProfilesCompanion(
        id: Value(current?.id ?? 'default-profile'),
        displayName: Value(displayName ?? current?.displayName ?? 'Student'),
        avatarColorKey: Value(avatarColorKey ?? current?.avatarColorKey ?? 'periwinkle'),
        themeMode: Value(themeMode ?? current?.themeMode ?? 'system'),
        onboardingDone: Value(current?.onboardingDone ?? true),
        focusMinutes: Value(current?.focusMinutes ?? 25),
        shortBreakMinutes: Value(current?.shortBreakMinutes ?? 5),
        longBreakMinutes: Value(current?.longBreakMinutes ?? 15),
        roundsPerCycle: Value(current?.roundsPerCycle ?? 4),
        autoStartBreak: Value(current?.autoStartBreak ?? false),
        chimeEnabled: Value(current?.chimeEnabled ?? true),
        notificationsEnabled:
            Value(notificationsEnabled ?? current?.notificationsEnabled ?? true),
        classLeadMinutes: Value(classLeadMinutes ?? current?.classLeadMinutes ?? 15),
        createdAt: Value(current?.createdAt ?? now),
        updatedAt: Value(now),
      ),
    );

    if (notificationsEnabled != null || classLeadMinutes != null) {
      await ref.read(notificationServiceProvider).syncAllReminders(
            enabled: notificationsEnabled ?? current?.notificationsEnabled ?? true,
            classLeadMinutes: classLeadMinutes ?? current?.classLeadMinutes ?? 15,
            events: await db.getAllTimetableEvents(),
            assignments: await db.getAllAssignments(),
            exams: await db.getAllExams(),
          );
    }
  }

  Future<void> _confirmAction({
    required String title,
    required String body,
    required String confirmLabel,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (ok == true) {
      await onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? const <Subject>[];

    if (profile != null && !_nameSeeded) {
      _nameController.text = profile.displayName;
      _nameSeeded = true;
    }

    final currentTheme = profile?.themeMode ?? 'system';
    final notificationsOn = profile?.notificationsEnabled ?? true;
    final leadMin = profile?.classLeadMinutes ?? 15;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text('Profile', style: t.titleMedium),
          const SizedBox(height: 10),
          PastelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  onSubmitted: (v) => _updateProfile(
                    profile,
                    displayName: v.trim().isEmpty ? 'Student' : v.trim(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Avatar color', style: t.bodyMedium),
                    const Spacer(),
                    Wrap(
                      spacing: 8,
                      children: SubjectColorKey.values.map((key) {
                        final selected =
                            (profile?.avatarColorKey ?? 'periwinkle') == key.name;
                        return InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _updateProfile(profile, avatarColorKey: key.name),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: subjectTint(key, c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? subjectAccent(key, c) : c.border,
                                width: selected ? 2.5 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () {
                      final v = _nameController.text.trim();
                      _updateProfile(
                        profile,
                        displayName: v.isEmpty ? 'Student' : v,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated')),
                      );
                    },
                    child: const Text('Save name'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Appearance', style: t.titleMedium),
          const SizedBox(height: 10),
          PastelCard(
            child: Row(
              children: [
                for (final entry in [
                  ('system', 'System'),
                  ('light', 'Light'),
                  ('dark', 'Dark'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Center(child: Text(entry.$2)),
                        selected: currentTheme == entry.$1,
                        onSelected: (_) =>
                            _updateProfile(profile, themeMode: entry.$1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: Text('Subjects', style: t.titleMedium)),
              TextButton.icon(
                onPressed: () => showSubjectEditorSheet(context),
                icon: const Icon(PhosphorIconsBold.plus, size: 16),
                label: const Text('Add subject'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          PastelCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: subjects.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('No subjects yet. Add your courses to organize everything.',
                        style: t.bodyMedium),
                  )
                : Column(
                    children: subjects.map((s) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        leading: SubjectBadge(subject: s, size: 40, iconSize: 18),
                        title: Text(s.name, style: t.titleSmall),
                        trailing: Icon(PhosphorIconsRegular.pencilSimple,
                            size: 18, color: c.inkSecondary),
                        onTap: () => showSubjectEditorSheet(context, existing: s),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 22),
          Text('Reminders', style: t.titleMedium),
          const SizedBox(height: 10),
          PastelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Study notifications'),
                  subtitle: const Text('Classes, assignment deadlines & exams'),
                  value: notificationsOn,
                  activeThumbColor: c.mint,
                  onChanged: (v) =>
                      _updateProfile(profile, notificationsEnabled: v),
                ),
                const Divider(height: 16),
                Text('Class reminder lead time', style: t.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [5, 10, 15, 30].map((m) {
                    return ChoiceChip(
                      label: Text('$m min'),
                      selected: leadMin == m,
                      onSelected: (_) =>
                          _updateProfile(profile, classLeadMinutes: m),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Data', style: t.titleMedium),
          const SizedBox(height: 10),
          PastelCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(PhosphorIconsRegular.sparkle, color: c.primary),
                  title: const Text('Load sample semester data'),
                  subtitle: const Text('Replaces current items with Maya demo semester'),
                  onTap: () => _confirmAction(
                    title: 'Load sample data?',
                    body: 'This replaces your current classes, assignments, exams, and notes with sample semester data.',
                    confirmLabel: 'Load sample',
                    onConfirm: () async {
                      await seedSampleSemester(
                        ref.read(appDatabaseProvider),
                        displayName: profile?.displayName ?? 'Student',
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(PhosphorIconsRegular.trash, color: c.danger),
                  title: Text('Clear all study data',
                      style: TextStyle(color: c.danger)),
                  subtitle: const Text('Deletes all classes, tasks, exams, notes & subjects'),
                  onTap: () => _confirmAction(
                    title: 'Clear all study data?',
                    body: 'This permanently removes all subjects, classes, tasks, exams, focus logs, and notes on this device.',
                    confirmLabel: 'Clear all',
                    onConfirm: () => ref.read(appDatabaseProvider).clearAllData(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
