import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/circle_back_button.dart';

class _PolicySection {
  const _PolicySection({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

const List<_PolicySection> _sections = [
  _PolicySection(
    icon: LucideIcons.heart,
    title: 'Dados sobre você e seu bebê',
    body: 'O nome e a data de nascimento do seu bebê, seus favoritos e sua preferência de tema ficam salvos '
        'somente neste dispositivo. Não enviamos essas informações para nenhum servidor — se você desinstalar '
        'o app ou trocar de aparelho, esses dados não são transferidos automaticamente.',
  ),
  _PolicySection(
    icon: LucideIcons.mapPin,
    title: 'Localização',
    body: 'Sua localização só é acessada quando você toca em "Usar minha localização" na aba BLH, e apenas para '
        'calcular a distância até os Bancos de Leite Humano exibidos naquele momento. Ela não é armazenada, '
        'registrada em nenhum histórico, nem compartilhada com terceiros.',
  ),
  _PolicySection(
    icon: LucideIcons.shield,
    title: 'Dados de saúde',
    body: 'Informações sensíveis, como dados de saúde sua ou do seu bebê, nunca são coletadas sem consentimento '
        'explícito e nunca são usadas para fins diferentes daqueles apresentados dentro do próprio aplicativo.',
  ),
  _PolicySection(
    icon: LucideIcons.users,
    title: 'Compartilhamento com terceiros',
    body: 'O Colo de Mãe não vende, aluga nem compartilha seus dados pessoais com terceiros para fins '
        'publicitários. Ao tocar em "Iniciar Rota" ou "Ligar", o app abre o app de mapas ou o discador do seu '
        'próprio celular — nesse momento, o uso desses serviços externos segue as políticas de privacidade deles.',
  ),
  _PolicySection(
    icon: LucideIcons.chartBar,
    title: 'Estatísticas',
    body: 'Quando existirem, estatísticas de uso do aplicativo são sempre tratadas de forma agregada e anônima, '
        'sem identificar você individualmente.',
  ),
  _PolicySection(
    icon: LucideIcons.mail,
    title: 'Dúvidas',
    body: 'Se tiver qualquer dúvida sobre como seus dados são tratados, procure a equipe responsável pelo app '
        'através dos canais de contato disponíveis na loja de aplicativos.',
  ),
];

/// Tela de política de privacidade, acessível pelas Configurações.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                CircleBackButton(onPressed: () => Navigator.of(context).maybePop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Política de Privacidade',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: palette.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'A sua privacidade e a do seu bebê importam para nós. Este resumo explica, em linguagem simples, '
              'como o Colo de Mãe trata as informações usadas dentro do aplicativo.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.textMuted, height: 1.5),
            ),
            const SizedBox(height: 20),
            for (final section in _sections) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: palette.border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(section.icon, size: 18, color: palette.textPrimary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            section.title,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: palette.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.body,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
