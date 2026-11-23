import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/app/theme/subject_styles.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

Future<void> showSubjectEditorSheet(
  BuildContext context, {
  Subject? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => SubjectEditorSheet(existing: existing),
  );
}

class SubjectEditorSheet extends ConsumerStatefulWidget {
  const SubjectEditorSheet({super.key, this.existing});

  final Subject? existing;

  @override
  ConsumerState<SubjectEditorSheet> createState() => _SubjectEditorSheetState();
}

class _SubjectEditorSheetState extends ConsumerState<SubjectEditorSheet> {
  late final TextEditingController _nameController;
  late SubjectColorKey _colorKey;
  late SubjectIconKey _iconKey;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _colorKey = parseSubjectColorKey(widget.existing?.colorKey);
    _iconKey = parseSubjectIconKey(widget.existing?.iconKey);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a subject name.');
      return;
    }
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    await db.upsertSubject(
      SubjectsCompanion(
        id: Value(widget.existing?.id ?? _uuid.v4()),
        name: Value(name),
        colorKey: Value(_colorKey.name),
        iconKey: Value(_iconKey.name),
        sortOrder: Value(widget.existing?.sortOrder ?? 10),
        createdAt: Value(widget.existing?.createdAt ?? now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete subject?'),
        content: Text(
          'Removing "${widget.existing!.name}" will unlink it from any classes, assignments, exams, and notes without deleting those items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(appDatabaseProvider)
        .softDeleteSubjectAndUnlink(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'Edit subject' : 'New subject',
                    style: t.titleLarge,
                  ),
                ),
                if (isEditing)
                  IconButton(
                    tooltip: 'Delete subject',
                    onPressed: _delete,
                    icon: Icon(PhosphorIconsRegular.trash, color: c.danger),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Subject name'),
            ),
            const SizedBox(height: 16),
            Text('Color', style: t.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: SubjectColorKey.values.map((key) {
                final selected = key == _colorKey;
                return InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _colorKey = key),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: subjectTint(key, c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? subjectAccent(key, c) : c.border,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: selected
                        ? Icon(PhosphorIconsBold.check,
                            size: 18, color: subjectAccent(key, c))
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Icon', style: t.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: SubjectIconKey.values.map((key) {
                final selected = key == _iconKey;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _iconKey = key),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? subjectTint(_colorKey, c) : c.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? subjectAccent(_colorKey, c) : c.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      subjectIconData(key),
                      size: 20,
                      color: selected ? subjectAccent(_colorKey, c) : c.inkSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: t.bodyMedium?.copyWith(color: c.danger)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save subject'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
