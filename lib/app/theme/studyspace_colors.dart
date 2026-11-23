import 'package:flutter/material.dart';

@immutable
class StudySpaceColors extends ThemeExtension<StudySpaceColors> {
  const StudySpaceColors({
    required this.canvas,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.primary,
    required this.primaryRing,
    required this.onPrimary,
    required this.primarySoft,
    required this.mint,
    required this.mintSoft,
    required this.lilac,
    required this.lilacSoft,
    required this.amber,
    required this.amberSoft,
    required this.coral,
    required this.coralSoft,
    required this.sky,
    required this.skySoft,
    required this.danger,
    required this.warning,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color inkPrimary;
  final Color inkSecondary;
  final Color primary;
  final Color primaryRing;
  final Color onPrimary;
  final Color primarySoft;
  final Color mint;
  final Color mintSoft;
  final Color lilac;
  final Color lilacSoft;
  final Color amber;
  final Color amberSoft;
  final Color coral;
  final Color coralSoft;
  final Color sky;
  final Color skySoft;
  final Color danger;
  final Color warning;

  static const light = StudySpaceColors(
    canvas: Color(0xFFFAF9F6),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF3F4F8),
    border: Color(0xFFE7E9F0),
    inkPrimary: Color(0xFF16213E),
    inkSecondary: Color(0xFF556076),
    primary: Color(0xFF5668E2),
    primaryRing: Color(0xFF7484F4),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFE8ECFE),
    mint: Color(0xFF28A77E),
    mintSoft: Color(0xFFE4F7F0),
    lilac: Color(0xFF9B6CC7),
    lilacSoft: Color(0xFFF5EBF8),
    amber: Color(0xFFC97B1E),
    amberSoft: Color(0xFFFEF3E2),
    coral: Color(0xFFD14B62),
    coralSoft: Color(0xFFFDECEF),
    sky: Color(0xFF2D86C4),
    skySoft: Color(0xFFE7F4FC),
    danger: Color(0xFFD93E4F),
    warning: Color(0xFFD9822B),
  );

  static const dark = StudySpaceColors(
    canvas: Color(0xFF0F1420),
    surface: Color(0xFF171E2E),
    surfaceVariant: Color(0xFF212A3E),
    border: Color(0xFF2C364D),
    inkPrimary: Color(0xFFF1F5FF),
    inkSecondary: Color(0xFFA4B0C8),
    primary: Color(0xFF8C9BFF),
    primaryRing: Color(0xFF8C9BFF),
    onPrimary: Color(0xFF0C1222),
    primarySoft: Color(0xFF242D4C),
    mint: Color(0xFF4CD4A4),
    mintSoft: Color(0xFF1A342E),
    lilac: Color(0xFFC8A2F0),
    lilacSoft: Color(0xFF32243B),
    amber: Color(0xFFF6B76B),
    amberSoft: Color(0xFF3B2D1C),
    coral: Color(0xFFFF8598),
    coralSoft: Color(0xFF3E222A),
    sky: Color(0xFF73C2F7),
    skySoft: Color(0xFF1A3042),
    danger: Color(0xFFFF6B7A),
    warning: Color(0xFFF6AD55),
  );

  static StudySpaceColors of(BuildContext context) {
    final ext = Theme.of(context).extension<StudySpaceColors>();
    return ext ?? (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  StudySpaceColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? inkPrimary,
    Color? inkSecondary,
    Color? primary,
    Color? primaryRing,
    Color? onPrimary,
    Color? primarySoft,
    Color? mint,
    Color? mintSoft,
    Color? lilac,
    Color? lilacSoft,
    Color? amber,
    Color? amberSoft,
    Color? coral,
    Color? coralSoft,
    Color? sky,
    Color? skySoft,
    Color? danger,
    Color? warning,
  }) {
    return StudySpaceColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      inkPrimary: inkPrimary ?? this.inkPrimary,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      primary: primary ?? this.primary,
      primaryRing: primaryRing ?? this.primaryRing,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySoft: primarySoft ?? this.primarySoft,
      mint: mint ?? this.mint,
      mintSoft: mintSoft ?? this.mintSoft,
      lilac: lilac ?? this.lilac,
      lilacSoft: lilacSoft ?? this.lilacSoft,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
      coral: coral ?? this.coral,
      coralSoft: coralSoft ?? this.coralSoft,
      sky: sky ?? this.sky,
      skySoft: skySoft ?? this.skySoft,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
    );
  }

  @override
  StudySpaceColors lerp(ThemeExtension<StudySpaceColors>? other, double t) {
    if (other is! StudySpaceColors) return this;
    return StudySpaceColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      inkPrimary: Color.lerp(inkPrimary, other.inkPrimary, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryRing: Color.lerp(primaryRing, other.primaryRing, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      mintSoft: Color.lerp(mintSoft, other.mintSoft, t)!,
      lilac: Color.lerp(lilac, other.lilac, t)!,
      lilacSoft: Color.lerp(lilacSoft, other.lilacSoft, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberSoft: Color.lerp(amberSoft, other.amberSoft, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      coralSoft: Color.lerp(coralSoft, other.coralSoft, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      skySoft: Color.lerp(skySoft, other.skySoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
