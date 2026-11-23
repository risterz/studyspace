import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/app/theme/studyspace_theme.dart';
import 'package:studyspace/app/theme/subject_styles.dart';

double _contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final bright = l1 > l2 ? l1 : l2;
  final dark = l1 > l2 ? l2 : l1;
  return (bright + 0.05) / (dark + 0.05);
}

void main() {
  test('Light and Dark palettes match spec tokens and meet WCAG AA 4.5:1', () {
    expect(StudySpaceColors.light.canvas, const Color(0xFFFAF9F6));
    expect(StudySpaceColors.dark.canvas, const Color(0xFF0F1420));

    for (final c in [StudySpaceColors.light, StudySpaceColors.dark]) {
      expect(_contrastRatio(c.inkPrimary, c.canvas), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.inkSecondary, c.canvas), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.inkPrimary, c.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.inkSecondary, c.surface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
    }
  });

  test('buildStudySpaceTheme attaches StudySpaceColors and maps all subject styles', () {
    final light = buildStudySpaceTheme(Brightness.light);
    final dark = buildStudySpaceTheme(Brightness.dark);
    expect(light.extension<StudySpaceColors>(), isNotNull);
    expect(dark.extension<StudySpaceColors>(), isNotNull);
    for (final k in SubjectColorKey.values) {
      expect(subjectTint(k, StudySpaceColors.light), isA<Color>());
      expect(subjectAccent(k, StudySpaceColors.dark), isA<Color>());
    }
    for (final i in SubjectIconKey.values) {
      expect(subjectIconData(i), isA<IconData>());
    }
  });
}
