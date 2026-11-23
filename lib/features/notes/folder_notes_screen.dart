import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/app/widgets/pastel_card.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/features/notes/notes_providers.dart';
import 'package:studyspace/features/notes/notes_repository.dart';

class FolderNotesScreen extends ConsumerWidget {
  const FolderNotesScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;
    final subjects = ref.watch(subjectsByIdProvider);
    final subject = subjects[subjectId];
    final allNotes = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
    final folderNotes = allNotes.where((n) => n.subjectId == subjectId).toList();
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(subject?.name ?? 'Subject notes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => context.push('/notes/new?subjectId=$subjectId'),
              icon: const Icon(PhosphorIconsBold.plus, size: 16),
              label: const Text('New note'),
            ),
          ),
        ],
      ),
      body: folderNotes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsRegular.noteBlank,
                        size: 40, color: c.inkSecondary),
                    const SizedBox(height: 10),
                    Text('No notes in this folder yet', style: t.titleMedium),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () =>
                          context.push('/notes/new?subjectId=$subjectId'),
                      icon: const Icon(PhosphorIconsBold.plus, size: 16),
                      label: const Text('Create note'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              itemCount: folderNotes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final note = folderNotes[index];
                return PastelCard(
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
                            Text(
                              note.title,
                              style: t.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatRelativeEdited(note.updatedAt, now),
                              style: t.bodyMedium?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(PhosphorIconsRegular.caretRight,
                          size: 18, color: c.inkSecondary),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
