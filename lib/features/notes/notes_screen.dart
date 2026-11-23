import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/app/theme/subject_styles.dart';
import 'package:studyspace/app/widgets/pastel_card.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/features/notes/notes_providers.dart';
import 'package:studyspace/features/notes/notes_repository.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchController = TextEditingController();
  bool _showAllFolders = false;
  bool _showAllRecent = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showMoveFolderSheet(
    BuildContext context,
    Note note,
    List<Subject> subjects,
  ) {
    final t = Theme.of(context).textTheme;
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Move to folder', style: t.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Unfiled'),
                onTap: () async {
                  await ref.read(notesRepositoryProvider).moveNote(note, null);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              ...subjects.map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.name),
                  onTap: () async {
                    await ref.read(notesRepositoryProvider).moveNote(note, s.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? const <Subject>[];
    final subjectsById = ref.watch(subjectsByIdProvider);
    final noteCounts = ref.watch(subjectNoteCountsProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);
    final searchQuery = ref.watch(notesSearchQueryProvider);
    final now = DateTime.now();

    final visibleFolders =
        _showAllFolders ? subjects : subjects.take(4).toList();
    final visibleNotes =
        (_showAllRecent || searchQuery.isNotEmpty)
            ? filteredNotes
            : filteredNotes.take(5).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            // Header: Notes + [+ New note] pill
            Row(
              children: [
                Expanded(child: Text('Notes', style: t.displaySmall)),
                Material(
                  color: c.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => context.push('/notes/new'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Icon(PhosphorIconsBold.plus, size: 15, color: c.primary),
                          const SizedBox(width: 6),
                          Text(
                            'New note',
                            style: t.labelLarge?.copyWith(color: c.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes',
                prefixIcon: Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 20,
                  color: c.inkSecondary,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          ref.read(notesSearchQueryProvider.notifier).state = '';
                        },
                        icon: Icon(PhosphorIconsRegular.x, size: 18, color: c.inkSecondary),
                      )
                    : null,
              ),
              onChanged: (v) =>
                  ref.read(notesSearchQueryProvider.notifier).state = v,
            ),
            const SizedBox(height: 22),
            // Subject folders 2x2 grid
            if (subjects.isNotEmpty && searchQuery.isEmpty) ...[
              Row(
                children: [
                  Expanded(child: Text('Subject folders', style: t.titleMedium)),
                  if (subjects.length > 4)
                    TextButton(
                      onPressed: () =>
                          setState(() => _showAllFolders = !_showAllFolders),
                      child: Text(
                        _showAllFolders ? 'Show less' : 'View all',
                        style: t.labelLarge?.copyWith(color: c.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleFolders.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                itemBuilder: (context, index) {
                  final s = visibleFolders[index];
                  final count = noteCounts[s.id] ?? 0;
                  final iconKey = parseSubjectIconKey(s.iconKey);
                  return PastelCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () => context.push('/notes/folder/${s.id}'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              PhosphorIconsFill.folderSimple,
                              size: 54,
                              color: c.primaryRing.withValues(alpha: 0.72),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Icon(
                                subjectIconData(iconKey),
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.name,
                          style: t.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count ${count == 1 ? 'note' : 'notes'}',
                          style: t.bodyMedium?.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
            ],
            // Recent notes section
            Row(
              children: [
                Expanded(
                  child: Text(
                    searchQuery.isEmpty ? 'Recent notes' : 'Matching notes',
                    style: t.titleMedium,
                  ),
                ),
                if (filteredNotes.length > 5 && searchQuery.isEmpty)
                  TextButton(
                    onPressed: () =>
                        setState(() => _showAllRecent = !_showAllRecent),
                    child: Text(
                      _showAllRecent ? 'Show less' : 'View all',
                      style: t.labelLarge?.copyWith(color: c.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (visibleNotes.isEmpty)
              PastelCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Column(
                  children: [
                    Icon(PhosphorIconsRegular.notePencil,
                        size: 36, color: c.inkSecondary),
                    const SizedBox(height: 10),
                    Text(
                      searchQuery.isEmpty ? 'No notes yet' : 'No matching notes',
                      style: t.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      searchQuery.isEmpty
                          ? 'Capture lecture summaries, formulas, and study checklists.'
                          : 'Try another keyword or clear your search.',
                      style: t.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...visibleNotes.map((note) {
                final subject = note.subjectId == null
                    ? null
                    : subjectsById[note.subjectId];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PastelCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    onTap: () => context.push('/notes/editor/${note.id}'),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c.mintSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            PhosphorIconsRegular.fileText,
                            color: c.mint,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (note.isPinned) ...[
                                    Icon(PhosphorIconsFill.pushPin,
                                        size: 13, color: c.primary),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      note.title,
                                      style: t.titleSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      subject?.name ?? 'General',
                                      style: t.bodyMedium?.copyWith(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    formatRelativeEdited(note.updatedAt, now),
                                    style: t.bodyMedium?.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(PhosphorIconsRegular.dotsThreeVertical,
                              color: c.inkSecondary),
                          onSelected: (action) async {
                            if (action == 'pin') {
                              await ref
                                  .read(notesRepositoryProvider)
                                  .togglePin(note);
                            } else if (action == 'move') {
                              await _showMoveFolderSheet(
                                  context, note, subjects);
                            } else if (action == 'delete') {
                              await ref
                                  .read(notesRepositoryProvider)
                                  .deleteNote(note.id);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'pin',
                              child: Text(note.isPinned ? 'Unpin' : 'Pin'),
                            ),
                            const PopupMenuItem(
                              value: 'move',
                              child: Text('Move folder'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
