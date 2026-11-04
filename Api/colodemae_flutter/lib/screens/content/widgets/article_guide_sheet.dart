import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/category_colors.dart';
import '../../../core/widgets/favorite_icon.dart';
import '../../../models/article.dart';
import '../../../services/favorites_controller.dart';

/// Abre o artigo como um guia passo a passo em modal: um passo curto por tela,
/// para a mãe ler com calma, sem blocos longos de texto.
Future<void> showArticleGuide(BuildContext context, Article article) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ArticleGuideSheet(article: article),
  );
}

class _ArticleGuideSheet extends StatefulWidget {
  const _ArticleGuideSheet({required this.article});

  final Article article;

  @override
  State<_ArticleGuideSheet> createState() => _ArticleGuideSheetState();
}

class _ArticleGuideSheetState extends State<_ArticleGuideSheet> {
  final PageController _pageController = PageController();
  int _index = 0;

  bool get _isLast => _index == widget.article.steps.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop();
    } else {
      _goTo(_index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final article = widget.article;
    final colors = categoryColors(palette, article.category);
    final favorites = context.watch<FavoritesController>();
    final steps = article.steps;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.78,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: palette.border2, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: colors.soft, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(article.category.icon, size: 14, color: palette.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      article.category.label,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Favoritar',
                onPressed: () => favorites.toggle(article.id),
                icon: FavoriteIcon(active: favorites.isFavorite(article.id)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(LucideIcons.x, size: 22, color: palette.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            article.title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: palette.textPrimary, height: 1.25),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= _index ? AppPalette.button : palette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Passo ${_index + 1} de ${steps.length}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: palette.textMuted),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: steps.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _StepPage(step: steps[i], background: colors.mid),
            ),
          ),
          if (favorites.isFavorite(article.id) && _isLast) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.cloudDownload, size: 14, color: palette.textPrimary),
                const SizedBox(width: 6),
                Text(
                  'Salvo nos favoritos — disponível offline',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (_index > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _goTo(_index - 1),
                    icon: const Icon(LucideIcons.arrowLeft, size: 18),
                    label: const Text('Voltar'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _next,
                  iconAlignment: IconAlignment.end,
                  icon: Icon(_isLast ? LucideIcons.check : LucideIcons.arrowRight, size: 18),
                  label: Text(_isLast ? 'Entendi' : 'Próximo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({required this.step, required this.background});

  final ArticleStep step;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 260),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: background, shape: BoxShape.circle),
              child: Icon(step.icon, size: 42, color: palette.textPrimary),
            ),
            const SizedBox(height: 24),
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: palette.textPrimary),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                step.text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: palette.textSecondary, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
