import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';

enum SubjectColorKey {
  periwinkle,
  mint,
  lilac,
  amber,
  coral,
  sky,
}

enum SubjectIconKey {
  flask,
  function,
  pencil,
  book,
  code,
  globe,
  atom,
  music,
}

SubjectColorKey parseSubjectColorKey(String? raw) {
  return SubjectColorKey.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => SubjectColorKey.periwinkle,
  );
}

SubjectIconKey parseSubjectIconKey(String? raw) {
  return SubjectIconKey.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => SubjectIconKey.book,
  );
}

Color subjectTint(SubjectColorKey key, StudySpaceColors colors) {
  return switch (key) {
    SubjectColorKey.periwinkle => colors.primarySoft,
    SubjectColorKey.mint => colors.mintSoft,
    SubjectColorKey.lilac => colors.lilacSoft,
    SubjectColorKey.amber => colors.amberSoft,
    SubjectColorKey.coral => colors.coralSoft,
    SubjectColorKey.sky => colors.skySoft,
  };
}

Color subjectAccent(SubjectColorKey key, StudySpaceColors colors) {
  return switch (key) {
    SubjectColorKey.periwinkle => colors.primary,
    SubjectColorKey.mint => colors.mint,
    SubjectColorKey.lilac => colors.lilac,
    SubjectColorKey.amber => colors.amber,
    SubjectColorKey.coral => colors.coral,
    SubjectColorKey.sky => colors.sky,
  };
}

IconData subjectIconData(SubjectIconKey key, {bool filled = false}) {
  if (filled) {
    return switch (key) {
      SubjectIconKey.flask => PhosphorIconsFill.flask,
      SubjectIconKey.function => PhosphorIconsFill.function,
      SubjectIconKey.pencil => PhosphorIconsFill.pencilSimple,
      SubjectIconKey.book => PhosphorIconsFill.bookOpen,
      SubjectIconKey.code => PhosphorIconsFill.code,
      SubjectIconKey.globe => PhosphorIconsFill.globeHemisphereWest,
      SubjectIconKey.atom => PhosphorIconsFill.atom,
      SubjectIconKey.music => PhosphorIconsFill.musicNotes,
    };
  }
  return switch (key) {
    SubjectIconKey.flask => PhosphorIconsRegular.flask,
    SubjectIconKey.function => PhosphorIconsRegular.function,
    SubjectIconKey.pencil => PhosphorIconsRegular.pencilSimple,
    SubjectIconKey.book => PhosphorIconsRegular.bookOpen,
    SubjectIconKey.code => PhosphorIconsRegular.code,
    SubjectIconKey.globe => PhosphorIconsRegular.globeHemisphereWest,
    SubjectIconKey.atom => PhosphorIconsRegular.atom,
    SubjectIconKey.music => PhosphorIconsRegular.musicNotes,
  };
}
