import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/services/notification_service.dart';
import 'package:studyspace/features/assignments/assignments_providers.dart';

Future<void> showExamEditorSheet(
  BuildContext context, {
  Exam? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ExamEditorSheet(existing: existing),
  );
}

class ExamEditorSheet extends ConsumerStatefulWidget {
  const ExamEditorSheet({super.key, this.existing});

  final Exam? existing;

  @override
  ConsumerState<ExamEditorSheet> createState() => _ExamEditorSheetState();
}

class _ExamEditorSheetState extends ConsumerState<ExamEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  String? _subjectId;
  late DateTime _examDate;
  late TimeOfDay _examTime;
  bool _reminderEnabled = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _subjectId = e?.subjectId;
    final defaultDate = e?.examAt ?? DateTime.now().add(const Duration(days: 7));
    _examDate = DateTime(defaultDate.year, defaultDate.month, defaultDate.day);
    _examTime = TimeOfDay(
      hour: e != null ? e.examAt.hour : 9,
      minute: e != null ? e.examAt.minute : 0,
    );
    _reminderEnabled = e?.reminderEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
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
      setState(() => _errorText = 'Please enter an exam name.');
      return;
    }
    final examAt = DateTime(
      _examDate.year,
      _examDate.month,
      _examDate.day,
      _examTime.hour,
      _examTime.minute,
    );
    await ref.read(assignmentsRepositoryProvider).saveExam(
          id: widget.existing?.id,
          title: title,
          subjectId: _subjectId,
          examAt: examAt,
          location: _locationController.text,
          notes: _notesController.text,
          reminderEnabled: _reminderEnabled,
          existingCreatedAt: widget.existing?.createdAt,
        );
    await _resync();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    await ref.read(assignmentsRepositoryProvider).deleteExam(widget.existing!.id);
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
                    isEditing ? 'Edit exam' : 'Add exam',
                    style: t.titleLarge,
                  ),
                ),
                if (isEditing)
                  IconButton(
                    tooltip: 'Delete exam',
                    onPressed: _delete,
                    icon: Icon(PhosphorIconsRegular.trash, color: c.danger),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('exam_title_field'),
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Exam title',
                hintText: 'e.g., Calculus II Midterm',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Room / seat (optional)',
                hintText: 'e.g., Hall A · Seat 24',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Topics to revise (optional)',
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _examDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2032),
                      );
                      if (picked != null) setState(() => _examDate = picked);
                    },
                    icon: const Icon(PhosphorIconsRegular.calendarBlank, size: 18),
                    label: Text(DateFormat('MMM d, y').format(_examDate)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _examTime,
                      );
                      if (picked != null) setState(() => _examTime = picked);
                    },
                    icon: const Icon(PhosphorIconsRegular.clock, size: 18),
                    label: Text(_examTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Exam countdown alerts'),
              subtitle: const Text('3 days and 1 day before exam'),
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
                child: const Text('Save exam'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
