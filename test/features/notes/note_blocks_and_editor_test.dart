import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyspace/app/theme/studyspace_theme.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/db/sample_seeder.dart';
import 'package:studyspace/features/notes/note_blocks.dart';
import 'package:studyspace/features/notes/note_editor_screen.dart';
import 'package:studyspace/features/notes/notes_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('parseMarkdownToBlocks and serializeBlocksToMarkdown round-trip cleanly and handle malformed lines', () {
    const md = '# Phospholipid Bilayer\n'
        'Hydrophilic heads face outward.\n'
        '- Selective permeability\n'
        '- [ ] Review pump\n'
        '- [x] Diagram osmosis';

    final blocks = parseMarkdownToBlocks(md);
    expect(blocks.length, 5);
    expect(blocks[0].type, NoteBlockType.heading);
    expect(blocks[0].text, 'Phospholipid Bilayer');
    expect(blocks[1].type, NoteBlockType.paragraph);
    expect(blocks[2].type, NoteBlockType.bullet);
    expect(blocks[3].type, NoteBlockType.checklist);
    expect(blocks[3].checked, isFalse);
    expect(blocks[4].type, NoteBlockType.checklist);
    expect(blocks[4].checked, isTrue);

    expect(serializeBlocksToMarkdown(blocks), md);

    // Review Focus #4: empty + malformed markdown never crashes or loses text
    final emptyBlocks = parseMarkdownToBlocks('');
    expect(emptyBlocks.length, 1);
    expect(emptyBlocks.first.type, NoteBlockType.paragraph);

    final weird = parseMarkdownToBlocks('  - [X] Uppercase Done\n### Deep Heading');
    expect(weird[0].type, NoteBlockType.checklist);
    expect(weird[0].checked, isTrue);
    expect(weird[0].text, 'Uppercase Done');
    expect(weird[1].type, NoteBlockType.heading);
    expect(weird[1].text, 'Deep Heading');
  });

  test('searchNotes matches case-insensitively across title, body, and subject name', () {
    final now = DateTime(2026, 11, 23);
    final bio = Subject(
      id: 'bio',
      name: 'Biology',
      colorKey: 'mint',
      iconKey: 'flask',
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );
    final notes = [
      Note(
        id: 'n1',
        subjectId: 'bio',
        title: 'Cell membrane review',
        body: 'Phospholipid bilayer notes',
        isPinned: false,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
      Note(
        id: 'n2',
        subjectId: null,
        title: 'Week 8 formulas',
        body: 'Integration by parts',
        isPinned: false,
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      ),
    ];

    expect(searchNotes(notes, {'bio': bio}, 'BIOLOGY').map((n) => n.id), ['n1']);
    expect(searchNotes(notes, {'bio': bio}, 'integration').map((n) => n.id), ['n2']);
    expect(searchNotes(notes, {'bio': bio}, 'membrane').map((n) => n.id), ['n1']);
  });

  testWidgets(
    'NoteEditorScreen toggles live checklist block and persists updated markdown to Drift DB',
    timeout: const Timeout(Duration(seconds: 20)),
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await seedSampleSemester(db, displayName: 'Maya', referenceNow: DateTime(2026, 11, 23, 9, 30));
      final seeded = await db.getAllNotes();
      final membraneNote = seeded.firstWhere((n) => n.title == 'Cell membrane review');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: buildStudySpaceTheme(Brightness.light),
            home: NoteEditorScreen(noteId: membraneNote.id),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Cell membrane review'), findsOneWidget);
      final uncheckedBox = find.byKey(const Key('checklist_toggle_5'));
      expect(uncheckedBox, findsOneWidget);

      await tester.tap(uncheckedBox);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final updated = await db.getNoteById(membraneNote.id);
      expect(updated!.body, contains('- [x] Review sodium-potassium pump stoichiometry'));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await db.close();
    },
  );

  testWidgets(
    'NoteEditorScreen deleting a note keeps it deleted after pop (no resurrection)',
    timeout: const Timeout(Duration(seconds: 20)),
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await seedSampleSemester(db, displayName: 'Maya', referenceNow: DateTime(2026, 11, 23, 9, 30));
      final seeded = await db.getAllNotes();
      final target = seeded.firstWhere((n) => n.title == 'Cell membrane review');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: buildStudySpaceTheme(Brightness.light),
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NoteEditorScreen(noteId: target.id),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Cell membrane review'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete note'));
      await tester.pumpAndSettle();

      final afterDelete = await db.getNoteById(target.id);
      expect(afterDelete, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      await db.close();
    },
  );
}
