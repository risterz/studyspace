import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/features/notes/note_blocks.dart';
import 'package:studyspace/features/notes/notes_providers.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.initialSubjectId,
  });

  final String? noteId;
  final String? initialSubjectId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final Map<String, TextEditingController> _blockControllers = {};
  final Map<String, FocusNode> _blockFocusNodes = {};

  String? _activeNoteId;
  String? _subjectId;
  bool _isPinned = false;
  DateTime? _createdAt;
  List<NoteBlock> _blocks = [NoteBlock(type: NoteBlockType.paragraph, text: '')];
  int _focusedIndex = 0;
  bool _loading = true;
  String _saveStatus = 'Saved';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _activeNoteId = widget.noteId;
    _subjectId = widget.initialSubjectId;
    _loadNote();
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      final existing =
          await ref.read(notesRepositoryProvider).getById(widget.noteId!);
      if (existing != null && mounted) {
        _titleController.text = existing.title;
        _subjectId = existing.subjectId;
        _isPinned = existing.isPinned;
        _createdAt = existing.createdAt;
        _blocks = parseMarkdownToBlocks(existing.body);
      }
    }
    _syncControllers();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _syncControllers() {
    final validIds = _blocks.map((b) => b.id).toSet();
    final staleIds =
        _blockControllers.keys.where((k) => !validIds.contains(k)).toList();
    for (final id in staleIds) {
      _blockControllers.remove(id)?.dispose();
      _blockFocusNodes.remove(id)?.dispose();
    }
    for (final b in _blocks) {
      _blockControllers.putIfAbsent(
        b.id,
        () => TextEditingController(text: b.text),
      );
      _blockFocusNodes.putIfAbsent(b.id, () => FocusNode());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    for (final c in _blockControllers.values) {
      c.dispose();
    }
    for (final f in _blockFocusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _scheduleSave({bool immediate = false}) {
    _debounce?.cancel();
    if (mounted && _saveStatus != 'Saving...') {
      setState(() => _saveStatus = 'Saving...');
    }
    if (immediate) {
      _persistNow();
    } else {
      _debounce = Timer(const Duration(milliseconds: 350), _persistNow);
    }
  }

  Future<void> _persistNow() async {
    final syncedBlocks = _blocks
        .map((b) => b.copyWith(text: _blockControllers[b.id]?.text ?? b.text))
        .toList();
    final body = serializeBlocksToMarkdown(syncedBlocks);
    final title = _titleController.text.trim();
    if (_activeNoteId == null && title.isEmpty && body.trim().isEmpty) {
      if (mounted) setState(() => _saveStatus = 'Draft');
      return;
    }

    final savedId = await ref.read(notesRepositoryProvider).saveNote(
          id: _activeNoteId,
          subjectId: _subjectId,
          title: title,
          body: body,
          isPinned: _isPinned,
          existingCreatedAt: _createdAt,
        );
    _activeNoteId = savedId;
    _createdAt ??= DateTime.now();
    if (mounted) {
      setState(() => _saveStatus = 'Saved');
    }
  }

  void _setBlockType(NoteBlockType type) {
    if (_blocks.isEmpty) {
      _blocks = [NoteBlock(type: type, text: '')];
      _focusedIndex = 0;
    } else {
      final idx = _focusedIndex.clamp(0, _blocks.length - 1);
      final current = _blocks[idx];
      final nextType =
          current.type == type ? NoteBlockType.paragraph : type;
      _blocks[idx] = current.copyWith(type: nextType, checked: false);
    }
    _syncControllers();
    setState(() {});
    _scheduleSave();
  }

  void _insertBlockAfter(int index, {NoteBlockType? type}) {
    final nextBlock = NoteBlock(
      type: type ?? NoteBlockType.paragraph,
      text: '',
    );
    setState(() {
      _blocks.insert(index + 1, nextBlock);
      _focusedIndex = index + 1;
      _syncControllers();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _blockFocusNodes[nextBlock.id]?.requestFocus();
    });
    _scheduleSave();
  }

  void _removeBlock(int index) {
    setState(() {
      if (_blocks.length == 1) {
        _blocks[0] = NoteBlock(type: NoteBlockType.paragraph, text: '');
        _blockControllers[_blocks[0].id]?.text = '';
      } else {
        _blocks.removeAt(index);
        _focusedIndex = (index - 1).clamp(0, _blocks.length - 1);
      }
      _syncControllers();
    });
    _scheduleSave();
  }

  int get _wordCount {
    final allText = [
      _titleController.text,
      ..._blocks.map((b) => _blockControllers[b.id]?.text ?? b.text),
    ].join(' ').trim();
    if (allText.isEmpty) return 0;
    return allText.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? const <Subject>[];

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _debounce?.cancel();
          _persistNow();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(PhosphorIconsRegular.arrowLeft),
            onPressed: () async {
              await _persistNow();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          title: Text(
            _saveStatus,
            style: t.labelMedium?.copyWith(color: c.inkSecondary),
          ),
          actions: [
            IconButton(
              tooltip: _isPinned ? 'Unpin note' : 'Pin note',
              onPressed: () {
                setState(() => _isPinned = !_isPinned);
                _scheduleSave(immediate: true);
              },
              icon: Icon(
                _isPinned ? PhosphorIconsFill.pushPin : PhosphorIconsRegular.pushPin,
                color: _isPinned ? c.primary : c.inkSecondary,
              ),
            ),
            if (_activeNoteId != null)
              IconButton(
                tooltip: 'Delete note',
                onPressed: () async {
                  await ref
                      .read(notesRepositoryProvider)
                      .deleteNote(_activeNoteId!);
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: Icon(PhosphorIconsRegular.trash, color: c.danger),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        // Subject folder chip selector
                        if (subjects.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: const Text('Unfiled'),
                                    selected: _subjectId == null,
                                    onSelected: (_) {
                                      setState(() => _subjectId = null);
                                      _scheduleSave(immediate: true);
                                    },
                                  ),
                                ),
                                ...subjects.map(
                                  (s) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(s.name),
                                      selected: _subjectId == s.id,
                                      onSelected: (_) {
                                        setState(() => _subjectId = s.id);
                                        _scheduleSave(immediate: true);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _titleController,
                          style: t.headlineMedium,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Note title',
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => _scheduleSave(),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(_blocks.length, (idx) {
                          final block = _blocks[idx];
                          final controller = _blockControllers[block.id]!;
                          final focusNode = _blockFocusNodes[block.id]!;
                          return _buildBlockRow(
                            context,
                            index: idx,
                            block: block,
                            controller: controller,
                            focusNode: focusNode,
                          );
                        }),
                      ],
                    ),
                  ),
                  // Bottom formatting toolbar
                  Container(
                    decoration: BoxDecoration(
                      color: c.surface,
                      border: Border(top: BorderSide(color: c.border)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            _ToolbarButton(
                              tooltip: 'Heading',
                              icon: PhosphorIconsRegular.textHOne,
                              active: _blocks.isNotEmpty &&
                                  _blocks[_focusedIndex.clamp(0, _blocks.length - 1)]
                                          .type ==
                                      NoteBlockType.heading,
                              onTap: () => _setBlockType(NoteBlockType.heading),
                            ),
                            _ToolbarButton(
                              tooltip: 'Bullet',
                              icon: PhosphorIconsRegular.listBullets,
                              active: _blocks.isNotEmpty &&
                                  _blocks[_focusedIndex.clamp(0, _blocks.length - 1)]
                                          .type ==
                                      NoteBlockType.bullet,
                              onTap: () => _setBlockType(NoteBlockType.bullet),
                            ),
                            _ToolbarButton(
                              tooltip: 'Checklist',
                              icon: PhosphorIconsRegular.checkSquare,
                              active: _blocks.isNotEmpty &&
                                  _blocks[_focusedIndex.clamp(0, _blocks.length - 1)]
                                          .type ==
                                      NoteBlockType.checklist,
                              onTap: () => _setBlockType(NoteBlockType.checklist),
                            ),
                            _ToolbarButton(
                              tooltip: 'Add block',
                              icon: PhosphorIconsRegular.plus,
                              active: false,
                              onTap: () => _insertBlockAfter(
                                _focusedIndex.clamp(0, _blocks.length - 1),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$_wordCount words',
                              style: t.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBlockRow(
    BuildContext context, {
    required int index,
    required NoteBlock block,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;

    final TextStyle? textStyle = switch (block.type) {
      NoteBlockType.heading => t.titleLarge,
      NoteBlockType.checklist => t.bodyLarge?.copyWith(
          decoration: block.checked ? TextDecoration.lineThrough : null,
          color: block.checked ? c.inkSecondary : c.inkPrimary,
        ),
      _ => t.bodyLarge,
    };

    return Padding(
      padding: EdgeInsets.only(
        top: block.type == NoteBlockType.heading ? 10 : 2,
        bottom: 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (block.type == NoteBlockType.checklist)
            InkWell(
              key: Key('checklist_toggle_$index'),
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _blocks[index] = block.copyWith(checked: !block.checked);
                });
                _scheduleSave(immediate: true);
              },
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: block.checked ? c.mint : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: block.checked ? c.mint : c.primaryRing,
                        width: 1.8,
                      ),
                    ),
                    child: block.checked
                        ? Icon(PhosphorIconsBold.check,
                            size: 14, color: c.onPrimary)
                        : null,
                  ),
                ),
              ),
            )
          else if (block.type == NoteBlockType.bullet)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 12),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) {
                if (hasFocus) setState(() => _focusedIndex = index);
              },
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                textInputAction: TextInputAction.next,
                style: textStyle,
                decoration: InputDecoration(
                  hintText: switch (block.type) {
                    NoteBlockType.heading => 'Section heading',
                    NoteBlockType.checklist => 'To-do item',
                    NoteBlockType.bullet => 'List item',
                    NoteBlockType.paragraph => 'Write a note...',
                  },
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (_) => _scheduleSave(),
                onSubmitted: (_) {
                  final nextType = block.type == NoteBlockType.checklist ||
                          block.type == NoteBlockType.bullet
                      ? block.type
                      : NoteBlockType.paragraph;
                  _insertBlockAfter(index, type: nextType);
                },
              ),
            ),
          ),
          if (_blocks.length > 1)
            IconButton(
              tooltip: 'Remove block',
              visualDensity: VisualDensity.compact,
              onPressed: () => _removeBlock(index),
              icon: Icon(PhosphorIconsRegular.x, size: 16, color: c.inkSecondary),
            ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active ? c.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: active ? c.primary : c.inkPrimary,
          ),
        ),
      ),
    );
  }
}
