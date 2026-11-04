import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../models/article.dart';

/// Trio de cores (fundo suave, destaque, tom médio) associado a cada categoria de conteúdo.
class CategoryColors {
  const CategoryColors({required this.soft, required this.accent, required this.mid});

  final Color soft;
  final Color accent;
  final Color mid;
}

CategoryColors categoryColors(AppPalette palette, ArticleCategory category) {
  switch (category) {
    case ArticleCategory.pega:
      return CategoryColors(soft: palette.roseSoft, accent: palette.rose, mid: palette.roseMid);
    case ArticleCategory.ordenha:
    case ArticleCategory.sono:
      return CategoryColors(soft: palette.lilacSoft, accent: palette.lilac, mid: palette.lilacMid);
    case ArticleCategory.amamentacao:
      // No modo noturno o pêssego vira marrom e destoa das outras categorias,
      // então Amamentação segue o lilás como as demais.
      if (palette.bg.computeLuminance() < 0.5) {
        return CategoryColors(soft: palette.lilacSoft, accent: palette.lilac, mid: palette.lilacMid);
      }
      return CategoryColors(soft: palette.peachSoft, accent: palette.peach, mid: palette.peachMid);
  }
}
