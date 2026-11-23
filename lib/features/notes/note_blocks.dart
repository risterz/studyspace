import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum NoteBlockType { heading, paragraph, bullet, checklist }

class NoteBlock {
  NoteBlock({
    String? id,
    required this.type,
    required this.text,
    this.checked = false,
  }) : id = id ?? _uuid.v4();

  final String id;
  final NoteBlockType type;
  final String text;
  final bool checked;

  NoteBlock copyWith({
    NoteBlockType? type,
    String? text,
    bool? checked,
  }) {
    return NoteBlock(
      id: id,
      type: type ?? this.type,
      text: text ?? this.text,
      checked: checked ?? this.checked,
    );
  }
}

final _checklistRe = RegExp(r'^\s*-\s+\[([ xX])\]\s?(.*)$');
final _bulletRe = RegExp(r'^\s*[-*]\s+(.*)$');
final _headingRe = RegExp(r'^\s*#{1,6}\s+(.*)$');

List<NoteBlock> parseMarkdownToBlocks(String markdown) {
  if (markdown.trim().isEmpty) {
    return [NoteBlock(type: NoteBlockType.paragraph, text: '')];
  }

  final lines = markdown.replaceAll('\r\n', '\n').split('\n');
  final blocks = <NoteBlock>[];

  for (final line in lines) {
    final checkMatch = _checklistRe.firstMatch(line);
    if (checkMatch != null) {
      final isChecked = checkMatch.group(1)!.toLowerCase() == 'x';
      blocks.add(
        NoteBlock(
          type: NoteBlockType.checklist,
          text: checkMatch.group(2) ?? '',
          checked: isChecked,
        ),
      );
      continue;
    }

    final headingMatch = _headingRe.firstMatch(line);
    if (headingMatch != null) {
      blocks.add(
        NoteBlock(
          type: NoteBlockType.heading,
          text: headingMatch.group(1) ?? '',
        ),
      );
      continue;
    }

    final bulletMatch = _bulletRe.firstMatch(line);
    if (bulletMatch != null) {
      blocks.add(
        NoteBlock(
          type: NoteBlockType.bullet,
          text: bulletMatch.group(1) ?? '',
        ),
      );
      continue;
    }

    blocks.add(NoteBlock(type: NoteBlockType.paragraph, text: line));
  }

  return blocks.isEmpty
      ? [NoteBlock(type: NoteBlockType.paragraph, text: '')]
      : blocks;
}

String serializeBlocksToMarkdown(List<NoteBlock> blocks) {
  return blocks.map((b) {
    return switch (b.type) {
      NoteBlockType.heading => '# ${b.text}',
      NoteBlockType.paragraph => b.text,
      NoteBlockType.bullet => '- ${b.text}',
      NoteBlockType.checklist => '- [${b.checked ? 'x' : ' '}] ${b.text}',
    };
  }).join('\n');
}
