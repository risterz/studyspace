import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/services/notification_service.dart';
import 'package:studyspace/features/timetable/timetable_providers.dart';
import 'package:studyspace/features/timetable/timetable_repository.dart';

Future<void> showEventEditorSheet(
  BuildContext context, {
  TimetableEvent? existing,
  required DateTime initialDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => EventEditorSheet(
      existing: existing,
      initialDate: initialDate,
    ),
  );
}

class EventEditorSheet extends ConsumerStatefulWidget {
  const EventEditorSheet({
    super.key,
    this.existing,
    required this.initialDate,
  });

  final TimetableEvent? existing;
  final DateTime initialDate;

  @override
  ConsumerState<EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends ConsumerState<EventEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  String? _subjectId;
  bool _isRecurring = true;
  late int _weekdaysMask;
  late DateTime _specificDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _reminderEnabled = true;
  String? _errorText;

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _subjectId = e?.subjectId;
    _isRecurring = e?.isRecurring ?? true;
    _weekdaysMask = e != null && e.weekdaysMask > 0
        ? e.weekdaysMask
        : (1 << (widget.initialDate.weekday - 1));
    _specificDate = e?.specificDate != null
        ? (DateTime.tryParse(e!.specificDate!) ?? widget.initialDate)
        : widget.initialDate;
    final startMin = e?.startMinutes ?? 10 * 60;
    final endMin = e?.endMinutes ?? 11 * 60 + 30;
    _startTime = TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60);
    _endTime = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);
    _reminderEnabled = e?.reminderEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
        if (_toMinutes(_endTime) <= _toMinutes(_startTime)) {
          final nextEnd = (_toMinutes(_startTime) + 60).clamp(0, 23 * 60 + 59);
          _endTime = TimeOfDay(hour: nextEnd ~/ 60, minute: nextEnd % 60);
        }
      } else {
        _endTime = picked;
      }
      _errorText = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _specificDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );
    if (picked != null) {
      setState(() => _specificDate = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = 'Please enter a class or event title.');
      return;
    }
    final startM = _toMinutes(_startTime);
    final endM = _toMinutes(_endTime);
    if (endM <= startM) {
      setState(() => _errorText = 'End time must be after start time.');
      return;
    }
    if (_isRecurring && _weekdaysMask == 0) {
      setState(() => _errorText = 'Select at least one weekday.');
      return;
    }

    final repo = ref.read(timetableRepositoryProvider);
    await repo.saveEvent(
      id: widget.existing?.id,
      title: title,
      subjectId: _subjectId,
      location: _locationController.text,
      isRecurring: _isRecurring,
      weekdaysMask: _weekdaysMask,
      specificDate: DateFormat('yyyy-MM-dd').format(_specificDate),
      startMinutes: startM,
      endMinutes: endM,
      reminderEnabled: _reminderEnabled,
      existingCreatedAt: widget.existing?.createdAt,
    );

    await _resyncNotifications();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    await ref.read(timetableRepositoryProvider).deleteEvent(widget.existing!.id);
    await _resyncNotifications();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _resyncNotifications() async {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEditing ? 'Edit event' : 'Add event', style: t.titleLarge),
                      if (isEditing && _isRecurring)
                        Text(
                          'Updates recurring series',
                          style: t.bodyMedium?.copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (isEditing)
                  IconButton(
                    tooltip: 'Delete event',
                    onPressed: _delete,
                    icon: Icon(PhosphorIconsRegular.trash, color: c.danger),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('event_title_field'),
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Class or event title'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('event_location_field'),
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Room or location',
                hintText: 'e.g., Room B204',
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
                  child: ChoiceChip(
                    label: const Center(child: Text('Weekly class')),
                    selected: _isRecurring,
                    onSelected: (_) => setState(() => _isRecurring = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('One-off event')),
                    selected: !_isRecurring,
                    onSelected: (_) => setState(() => _isRecurring = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isRecurring)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (idx) {
                  final bit = 1 << idx;
                  final selected = (_weekdaysMask & bit) != 0;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _weekdaysMask = selected
                            ? (_weekdaysMask & ~bit)
                            : (_weekdaysMask | bit);
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? c.primary : c.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _dayLetters[idx],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? c.onPrimary : c.inkSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              )
            else
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(PhosphorIconsRegular.calendarBlank, size: 18),
                label: Text(DateFormat('EEEE, MMM d, y').format(_specificDate)),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: true),
                    icon: const Icon(PhosphorIconsRegular.clock, size: 18),
                    label: Text(formatMinutesWithPeriod(_toMinutes(_startTime))),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('–'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: false),
                    icon: const Icon(PhosphorIconsRegular.clock, size: 18),
                    label: Text(formatMinutesWithPeriod(_toMinutes(_endTime))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Class reminder'),
              subtitle: const Text('Notify before class starts'),
              value: _reminderEnabled,
              activeThumbColor: c.mint,
              onChanged: (v) => setState(() => _reminderEnabled = v),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 4),
              Text(
                _errorText!,
                style: t.bodyMedium?.copyWith(color: c.danger),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
