import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/category_colors.dart';
import '../../../core/widgets/favorite_icon.dart';
import '../../../core/widgets/pill.dart';
import '../../../models/article.dart';

/// Categoria da biblioteca em formato sanfona: o cabeçalho colorido abre e fecha
/// a lista de artigos (RF06).
class CategorySection extends StatefulWidget {
  const CategorySection({
    super.key,
    required this.category,
    required this.articles,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOpenArticle,
  });

  final ArticleCategory category;
  final List<Article> articles;
  final bool Function(String id) isFavorite;
  final void Function(String id) onToggleFavorite;
  final void Function(Article article) onOpenArticle;

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final colors = categoryColors(palette, widget.category);
    final count = widget.articles.length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.mid,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Icon(widget.category.icon, size: 22, color: palette.textPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.category.label,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: palette.textPrimary),
                    ),
                  ),
                  Pill(
                    label: '$count ${count == 1 ? 'artigo' : 'artigos'}',
                    color: Colors.white,
                    background: colors.accent,
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(LucideIcons.chevronDown, size: 20, color: palette.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Column(
                      children: [
                        for (var i = 0; i < count; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _ArticleTile(
                            article: widget.articles[i],
                            isFavorite: widget.isFavorite(widget.articles[i].id),
                            onToggleFavorite: () => widget.onToggleFavorite(widget.articles[i].id),
                            onOpen: () => widget.onOpenArticle(widget.articles[i]),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({
    required this.article,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOpen,
  });

  final Article article;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: palette.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.listChecks, size: 13, color: palette.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${article.steps.length} passos rápidos',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onToggleFavorite,
                icon: FavoriteIcon(active: isFavorite, size: 18),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: palette.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
