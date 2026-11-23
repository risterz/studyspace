import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/app/theme/subject_styles.dart';
import 'package:studyspace/core/db/app_database.dart';

class SubjectBadge extends StatelessWidget {
  const SubjectBadge({
    super.key,
    required this.subject,
    this.size = 44,
    this.iconSize = 22,
    this.isCircle = false,
    this.overrideBackground,
  });

  final Subject? subject;
  final double size;
  final double iconSize;
  final bool isCircle;
  final Color? overrideBackground;

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    final colorKey = subject == null ? null : parseSubjectColorKey(subject!.colorKey);
    final iconKey = subject == null ? null : parseSubjectIconKey(subject!.iconKey);

    final bg = overrideBackground ??
        (colorKey == null ? c.surfaceVariant : subjectTint(colorKey, c));
    final fg = colorKey == null ? c.inkSecondary : subjectAccent(colorKey, c);
    final icon = iconKey == null
        ? PhosphorIconsRegular.graduationCap
        : subjectIconData(iconKey);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: fg),
    );
  }
}
