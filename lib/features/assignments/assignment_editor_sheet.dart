import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/services/notification_service.dart';
import 'package:studyspace/features/assignments/assignments_providers.dart';

Future<void> showAssignmentEditorSheet(
  BuildContext context, {
  Assignment? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AssignmentEditorSheet(existing: existing),
  );
}

class AssignmentEditorSheet extends ConsumerStatefulWidget {
  const AssignmentEditorSheet({super.key, this.existing});

  final Assignment? existing;

  @override
  ConsumerState<AssignmentEditorSheet> createState() =>
      _AssignmentEditorSheetState();
}

class _AssignmentEditorSheetState extends ConsumerState<AssignmentEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  String? _subjectId;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late String _priority;
  bool _reminderEnabled = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _titleController = TextEditingController(text: a?.title ?? '');
    _notesController = TextEditingController(text: a?.notes ?? '');
    _subjectId = a?.subjectId;
    final defaultDue = a?.dueAt ?? DateTime.now().add(const Duration(days: 1));
    _dueDate = DateTime(defaultDue.year, defaultDue.month, defaultDue.day);
    _dueTime = TimeOfDay(
      hour: a != null ? a.dueAt.hour : 17,
      minute: a != null ? a.dueAt.minute : 0,
    );
    _priority = a?.priority ?? 'medium';
    _reminderEnabled = a?.reminderEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _resync() async {
    final db = ref.read(appDatabaseProvider);
    final profile = await db.getProfile();
    if (profile == null) return;
    await ref.read(notificationServiceProvider).syncAllReminders(
          enabled: profile.notificationsEnabled,
          classLeadMinutes: profile.classLeadMinutes,
          events: await db.getAllTimetableEvents(),
          assignments: await db.getAllAssignments(),
          exams: await db.getAllExams(),
        );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = 'Please enter an assignment title.');
      return;
    }
    final dueAt = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );
    await ref.read(assignmentsRepositoryProvider).saveAssignment(
          id: widget.existing?.id,
          title: title,
          subjectId: _subjectId,
          notes: _notesController.text,
          dueAt: dueAt,
          priority: _priority,
          isCompleted: widget.existing?.isCompleted ?? false,
          completedAt: widget.existing?.completedAt,
          reminderEnabled: _reminderEnabled,
          existingCreatedAt: widget.existing?.createdAt,
        );
    await _resync();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    await ref
        .read(assignmentsRepositoryProvider)
        .deleteAssignment(widget.existing!.id);
    await _resync();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? const <Subject>[];
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
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
                Expanded(
                  child: Text(
                    isEditing ? 'Edit assignment' : 'Add assignment',
                    style: t.titleLarge,
                  ),
                ),
                if (isEditing)
                  IconButton(
                    tooltip: 'Delete assignment',
                    onPressed: _delete,
                    icon: Icon(PhosphorIconsRegular.trash, color: c.danger),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('assignment_title_field'),
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
            ),
            const SizedBox(height: 14),
            if (subjects.isNotEmpty) ...[
              Text('Subject', style: t.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('General'),
                    selected: _subjectId == null,
                    onSelected: (_) => setState(() => _subjectId = null),
                  ),
                  ...subjects.map(
                    (s) => ChoiceChip(
                      label: Text(s.name),
                      selected: _subjectId == s.id,
                      onSelected: (_) => setState(() => _subjectId = s.id),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            Text('Priority', style: t.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: ['low', 'medium', 'high'].map((p) {
                final label = '${p[0].toUpperCase()}${p.substring(1)}';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Center(child: Text(label)),
                      selected: _priority == p,
                      onSelected: (_) => setState(() => _priority = p),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2032),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                    icon: const Icon(PhosphorIconsRegular.calendarBlank, size: 18),
                    label: Text(DateFormat('MMM d, y').format(_dueDate)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _dueTime,
                      );
                      if (picked != null) setState(() => _dueTime = picked);
                    },
                    icon: const Icon(PhosphorIconsRegular.clock, size: 18),
                    label: Text(_dueTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deadline reminders'),
              subtitle: const Text('24 hours and 1 hour before due'),
              value: _reminderEnabled,
              activeThumbColor: c.mint,
              onChanged: (v) => setState(() => _reminderEnabled = v),
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_errorText!, style: t.bodyMedium?.copyWith(color: c.danger)),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save assignment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
