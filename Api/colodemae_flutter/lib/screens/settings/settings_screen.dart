import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_palette.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/app_toggle.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/settings_row.dart';
import '../../services/baby_controller.dart';
import '../../services/theme_controller.dart';
import '../../services/auth_service.dart';
import '../../services/settings_controller.dart';
import '../../models/baby.dart';
import 'privacy_policy_screen.dart';
import 'widgets/baby_edit_form.dart';

/// Configurações do app: perfil do bebê, aparência, notificações e privacidade (RF12).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _editingBaby = false;
  bool _savingBaby = false;
  bool _signingOut = false;

  Future<void> _editBaby() async {
    try {
      await context.read<BabyController>().ensureLoaded();
      if (mounted) setState(() => _editingBaby = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Não foi possível carregar as informações do bebê. Tente novamente.'),
      ));
    }
  }

  Future<void> _saveBaby(Baby baby) async {
    if (_savingBaby) return;
    _savingBaby = true;
    try {
      await context.read<BabyController>().update(baby);
      if (mounted) setState(() => _editingBaby = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Não foi possível salvar as informações do bebê. Tente novamente.'),
      ));
    } finally {
      _savingBaby = false;
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      await context.read<SettingsController>().setPreference(key, value);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Não foi possível salvar sua preferência. Tente novamente.'),
      ));
    }
  }

  Future<void> _logout() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await context.read<AuthService>().sair();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível sair. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final babyController = context.watch<BabyController>();
    final themeController = context.watch<ThemeController>();
    final baby = babyController.baby;
    final user = context.watch<User?>();
    final settings = context.watch<SettingsController>();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'PERFIL',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: palette.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Configurações',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: palette.textPrimary),
          ),
          const SizedBox(height: 20),
          if (user != null) ...[
            SectionCard(
              icon:
                  Icon(LucideIcons.user, size: 18, color: palette.textPrimary),
              title: 'Minha conta',
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                          settings.profile?['nome'] as String? ??
                              user.displayName ??
                              'Minha conta',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                          settings.profile?['email'] as String? ??
                              user.email ??
                              '',
                          style: TextStyle(color: palette.textSecondary)),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _signingOut ? null : _logout,
                        icon: const Icon(LucideIcons.logOut, size: 18),
                        label:
                            Text(_signingOut ? 'Saindo...' : 'Sair da conta'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SectionCard(
            icon: Icon(LucideIcons.baby, size: 18, color: palette.textPrimary),
            title: 'Meu bebê',
            children: [
              if (_editingBaby)
                BabyEditForm(
                  baby: baby,
                  onCancel: () => setState(() => _editingBaby = false),
                  onSave: _saveBaby,
                )
              else ...[
                SettingsRow(
                  label: 'Nome',
                  trailing: Text(
                    baby?.name ?? '—',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: palette.textPrimary),
                  ),
                ),
                SettingsRow(
                  label: 'Nascimento',
                  trailing: Text(
                    baby == null ? '—' : formatDateBr(baby.birthDate),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary),
                  ),
                ),
                SettingsRow(
                  label: 'Idade',
                  isLast: true,
                  trailing: Text(
                    baby == null ? '—' : '${baby.daysSinceBirth} dias',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _editBaby,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: const Text('Editar informações'),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            icon: Icon(LucideIcons.moon, size: 18, color: palette.textPrimary),
            title: 'Aparência',
            children: [
              SettingsRow(
                label: 'Modo noturno',
                description: 'Confortável para mamadas de madrugada',
                isLast: true,
                trailing: AppToggle(
                  value: themeController.isDark,
                  onChanged: (_) => themeController.toggleDark(),
                  accentColor: palette.lilac,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            icon: Icon(LucideIcons.bell, size: 18, color: palette.textPrimary),
            title: 'Notificações',
            children: [
              SettingsRow(
                label: 'Lembretes educativos',
                description: 'Dicas diárias sobre amamentação',
                trailing: AppToggle(
                  value: settings.educationalReminders,
                  onChanged: (v) => _savePreference('lembretesEducativos', v),
                ),
              ),
              SettingsRow(
                label: 'Desafio dos 15 dias',
                description: 'Apoio especial na fase mais delicada',
                isLast: true,
                trailing: AppToggle(
                  value: settings.fifteenDayChallenge,
                  onChanged: (v) => _savePreference('desafio15Dias', v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            icon:
                Icon(LucideIcons.shield, size: 18, color: palette.textPrimary),
            title: 'Privacidade',
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sua privacidade importa',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: palette.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    for (final item in const [
                      'Dados de saúde nunca coletados sem consentimento explícito',
                      'Localização protegida e nunca armazenada nos servidores',
                      'Informações estatísticas são sempre completamente anônimas',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                  color: palette.textPrimary,
                                  shape: BoxShape.circle),
                              child: Icon(LucideIcons.check,
                                  size: 12, color: palette.surface),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48)),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(LucideIcons.arrowRight, size: 18),
                        label: const Text('Ler política de privacidade'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border, width: 1),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.wifi, size: 18, color: palette.textPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sincronização via Wi-Fi',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary),
                      ),
                      Text(
                        'Economiza dados móveis automaticamente',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
                const _StatusPill(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(999)),
      child: const Text('Ativo',
          style: TextStyle(
              color: Color(0xFF388E3C),
              fontSize: 12,
              fontWeight: FontWeight.w800)),
    );
  }
}
