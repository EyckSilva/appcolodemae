import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_palette.dart';
import '../../models/article.dart';
import '../../services/favorites_controller.dart';
import 'widgets/article_guide_sheet.dart';
import 'widgets/category_section.dart';

const List<ArticleCategory> kCategoryOrder = [
  ArticleCategory.pega,
  ArticleCategory.ordenha,
  ArticleCategory.amamentacao,
  ArticleCategory.sono,
];

/// Biblioteca de conteúdos sobre amamentação, organizada por categoria (RF06).
class ContentScreen extends StatelessWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final favorites = context.watch<FavoritesController>();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'BIBLIOTECA',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: palette.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Vamos cuidar dessa fase juntos',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: palette.textPrimary),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < kCategoryOrder.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            CategorySection(
              category: kCategoryOrder[i],
              articles: articles.where((a) => a.category == kCategoryOrder[i]).toList(),
              isFavorite: favorites.isFavorite,
              onToggleFavorite: favorites.toggle,
              onOpenArticle: (article) => showArticleGuide(context, article),
            ),
          ],
        ],
      ),
    );
  }
}
