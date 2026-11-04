import 'package:flutter/material.dart';

/// Paleta de cores da identidade visual do Colo de Mãe.
///
/// Modelada como [ThemeExtension] para que o modo claro e o modo escuro
/// definam tons próprios (não uma simples inversão) e qualquer widget
/// acesse as cores via `Theme.of(context).extension<AppPalette>()!`.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.bgSecondary,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.border2,
    required this.peach,
    required this.peachSoft,
    required this.peachMid,
    required this.lilac,
    required this.lilacSoft,
    required this.lilacMid,
    required this.rose,
    required this.roseSoft,
    required this.roseMid,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
  });

  final Color bg;
  final Color bgSecondary;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color border2;

  final Color peach;
  final Color peachSoft;
  final Color peachMid;
  final Color lilac;
  final Color lilacSoft;
  final Color lilacMid;
  final Color rose;
  final Color roseSoft;
  final Color roseMid;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;

  /// Cor de cabelo das ilustrações — fixa nos dois temas, como no protótipo original.
  static const Color illustrationHair = Color(0xFF8B4A8B);

  /// Rosa padrão de todos os botões do app — o mesmo nos modos claro e escuro.
  static const Color button = Color(0xFFD97AAC);

  static const AppPalette light = AppPalette(
    bg: Color(0xFFFFF8F5),
    bgSecondary: Color(0xFFFEF3F9),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFDF5FF),
    border: Color(0xFFF0DDED),
    border2: Color(0xFFE8D4F0),
    peach: Color(0xFFF5B89A),
    peachSoft: Color(0xFFFDEEE7),
    peachMid: Color(0xFFF8D4C0),
    lilac: Color(0xFFC2A4E8),
    lilacSoft: Color(0xFFF0E8FC),
    lilacMid: Color(0xFFD8C4F4),
    rose: Color(0xFFD97AAC),
    roseSoft: Color(0xFFFCEEF5),
    roseMid: Color(0xFFEDBED8),
    textPrimary: Color(0xFF3A2240),
    textSecondary: Color(0xFF6B5073),
    textMuted: Color(0xFF9B8AA8),
    textFaint: Color(0xFFC0B0CC),
  );

  static const AppPalette dark = AppPalette(
    bg: Color(0xFF160F22),
    bgSecondary: Color(0xFF1C1430),
    surface: Color(0xFF231840),
    surface2: Color(0xFF2A1E4A),
    border: Color(0xFF3A2858),
    border2: Color(0xFF4A3868),
    peach: Color(0xFFC8714A),
    peachSoft: Color(0xFF251510),
    peachMid: Color(0xFF3A2018),
    lilac: Color(0xFF9464B8),
    lilacSoft: Color(0xFF1E1638),
    lilacMid: Color(0xFF2E2050),
    rose: Color(0xFF9464B8),
    roseSoft: Color(0xFF1A1230),
    roseMid: Color(0xFF2A1C48),
    textPrimary: Color(0xFFF0E4FC),
    textSecondary: Color(0xFFC4AED8),
    textMuted: Color(0xFF8878A0),
    textFaint: Color(0xFF584870),
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? bgSecondary,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? border2,
    Color? peach,
    Color? peachSoft,
    Color? peachMid,
    Color? lilac,
    Color? lilacSoft,
    Color? lilacMid,
    Color? rose,
    Color? roseSoft,
    Color? roseMid,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textFaint,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      border2: border2 ?? this.border2,
      peach: peach ?? this.peach,
      peachSoft: peachSoft ?? this.peachSoft,
      peachMid: peachMid ?? this.peachMid,
      lilac: lilac ?? this.lilac,
      lilacSoft: lilacSoft ?? this.lilacSoft,
      lilacMid: lilacMid ?? this.lilacMid,
      rose: rose ?? this.rose,
      roseSoft: roseSoft ?? this.roseSoft,
      roseMid: roseMid ?? this.roseMid,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      border2: Color.lerp(border2, other.border2, t)!,
      peach: Color.lerp(peach, other.peach, t)!,
      peachSoft: Color.lerp(peachSoft, other.peachSoft, t)!,
      peachMid: Color.lerp(peachMid, other.peachMid, t)!,
      lilac: Color.lerp(lilac, other.lilac, t)!,
      lilacSoft: Color.lerp(lilacSoft, other.lilacSoft, t)!,
      lilacMid: Color.lerp(lilacMid, other.lilacMid, t)!,
      rose: Color.lerp(rose, other.rose, t)!,
      roseSoft: Color.lerp(roseSoft, other.roseSoft, t)!,
      roseMid: Color.lerp(roseMid, other.roseMid, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
