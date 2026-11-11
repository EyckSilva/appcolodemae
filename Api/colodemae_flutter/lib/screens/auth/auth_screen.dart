import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_theme.dart';
import '../../core/painters/splash_illustration.dart';
import '../../core/widgets/circle_back_button.dart';
import '../../services/auth_service.dart';

enum _AuthPage { login, register, recovery }

/// Formulários de cadastro, login e recuperação de senha via Firebase.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  _AuthPage _page = _AuthPage.login;
  bool _busy = false;
  bool _sent = false;
  String? _error;
  String? _recoveryMessage;

  bool get _isLogin => _page == _AuthPage.login;
  bool get _isRegister => _page == _AuthPage.register;
  bool get _isRecovery => _page == _AuthPage.recovery;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _navigate(_AuthPage page) {
    FocusScope.of(context).unfocus();
    _formKey.currentState?.reset();
    setState(() {
      _page = page;
      _error = null;
      _sent = false;
      _password.clear();
      _confirmation.clear();
    });
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_isRegister) {
        await _authService.cadastrar(
          nome: _name.text,
          email: _email.text,
          senha: _password.text,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso!'),
          ),
        );

        // O Firebase já autentica após o cadastro.
      } else if (_isLogin) {
        await _authService.entrar(
          email: _email.text,
          senha: _password.text,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login realizado com sucesso!'),
          ),
        );

        // O gerenciamento de sessão será integrado
        // à navegação principal na próxima etapa.
      } else if (_isRecovery) {
        await _authService.recuperarSenha(_email.text);

        if (!mounted) return;

        setState(() {
          _sent = true;
          _recoveryMessage = 'Se houver uma conta associada a este e-mail, '
              'você receberá instruções para recuperar sua senha.';
        });
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = switch (error.code) {
          'email-already-in-use' => 'Este e-mail já está cadastrado.',
          'weak-password' => 'Escolha uma senha mais forte.',
          'invalid-email' => 'Informe um e-mail válido.',
          'invalid-credential' => 'E-mail ou senha incorretos.',
          'wrong-password' => 'E-mail ou senha incorretos.',
          'user-not-found' => 'E-mail ou senha incorretos.',
          'network-request-failed' => 'Verifique sua conexão com a internet.',
          'too-many-requests' =>
            'Muitas tentativas. Tente novamente mais tarde.',
          'operation-not-allowed' =>
            'Esta forma de autenticação não está habilitada.',
          _ => 'Não foi possível concluir a operação.',
        };
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Ocorreu um erro inesperado. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe seu e-mail.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final title = _isLogin
        ? 'Que bom ter você aqui!'
        : _isRegister
            ? 'Crie sua conta'
            : _sent
                ? 'Confira seu e-mail'
                : 'Esqueceu sua senha?';
    final subtitle = _isLogin
        ? 'Faça login para continuar acessando sua conta'
        : _isRegister
            ? 'Um espaço de acolhimento para você e seu bebê.'
            : _sent
                ? 'Vamos ajudar você a voltar para o seu colo de apoio.'
                : 'Tudo bem, acontece. Informe seu e-mail para recuperar o acesso.';

    return PopScope(
      canPop: _isLogin,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_busy) _navigate(_AuthPage.login);
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.peachSoft, palette.lilacSoft, palette.roseSoft],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      const SplashIllustration(size: 88),
                      const SizedBox(height: 12),
                      Text('Colo de Mãe',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: palette.textPrimary)),
                      Text('apoio, amor e amamentação',
                          style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w700,
                              color: palette.textMuted)),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: palette.border, width: 1.5),
                        ),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!_isLogin) ...[
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: CircleBackButton(
                                          onPressed: _busy
                                              ? () {}
                                              : () =>
                                                  _navigate(_AuthPage.login))),
                                  const SizedBox(height: 20),
                                ],
                                Text(title,
                                    textAlign: _isLogin
                                        ? TextAlign.center
                                        : TextAlign.start,
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: palette.textPrimary)),
                                const SizedBox(height: 8),
                                Text(subtitle,
                                    textAlign: _isLogin
                                        ? TextAlign.center
                                        : TextAlign.start,
                                    style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: palette.textSecondary)),
                                const SizedBox(height: 24),
                                if (_sent) ...[
                                  const Icon(LucideIcons.mailCheck,
                                      size: 48, color: AppPalette.button),
                                  const SizedBox(height: 16),
                                  Text(_recoveryMessage!,
                                      style: TextStyle(
                                          height: 1.5,
                                          color: palette.textSecondary)),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                      onPressed: () =>
                                          _navigate(_AuthPage.login),
                                      child: const Text('Voltar para o login')),
                                  TextButton(
                                      onPressed: () =>
                                          setState(() => _sent = false),
                                      child: const Text('Tentar outro e-mail')),
                                ] else ...[
                                  if (_isRegister) ...[
                                    _AuthField(
                                      key: const ValueKey('name'),
                                      controller: _name,
                                      label: 'Seu nome',
                                      icon: LucideIcons.user,
                                      autofillHints: const [AutofillHints.name],
                                      validator: (value) => (value
                                                      ?.trim()
                                                      .length ??
                                                  0) <
                                              2
                                          ? 'Informe seu nome com pelo menos 2 caracteres.'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  _AuthField(
                                    key: const ValueKey('email'),
                                    controller: _email,
                                    label: 'E-mail',
                                    icon: LucideIcons.mail,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    validator: _validateEmail,
                                    onSubmitted:
                                        _isRecovery ? (_) => _submit() : null,
                                  ),
                                  if (!_isRecovery) ...[
                                    const SizedBox(height: 16),
                                    _AuthField(
                                      key: ValueKey('password-$_page'),
                                      controller: _password,
                                      label: 'Senha',
                                      icon: LucideIcons.lockKeyhole,
                                      password: true,
                                      autofillHints: [
                                        _isRegister
                                            ? AutofillHints.newPassword
                                            : AutofillHints.password
                                      ],
                                      helperText: _isRegister
                                          ? 'Use pelo menos 6 caracteres.'
                                          : null,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Informe sua senha.';
                                        }
                                        if (_isRegister && value.length < 6) {
                                          return 'A senha deve ter pelo menos 6 caracteres.';
                                        }
                                        return null;
                                      },
                                      onSubmitted:
                                          _isLogin ? (_) => _submit() : null,
                                    ),
                                  ],
                                  if (_isRegister) ...[
                                    const SizedBox(height: 16),
                                    _AuthField(
                                      key: const ValueKey('confirmation'),
                                      controller: _confirmation,
                                      label: 'Confirmar senha',
                                      icon: LucideIcons.lockKeyhole,
                                      password: true,
                                      autofillHints: const [
                                        AutofillHints.newPassword
                                      ],
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                              ? 'Confirme sua senha.'
                                              : value != _password.text
                                                  ? 'As senhas não coincidem.'
                                                  : null,
                                      onSubmitted: (_) => _submit(),
                                    ),
                                  ],
                                  if (_isLogin)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                          onPressed: _busy
                                              ? null
                                              : () =>
                                                  _navigate(_AuthPage.recovery),
                                          child: const Text(
                                              'Esqueci minha senha')),
                                    )
                                  else
                                    const SizedBox(height: 24),
                                  if (_error != null) ...[
                                    Semantics(
                                        liveRegion: true,
                                        child: Text(_error!,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error,
                                                fontSize: 13))),
                                    const SizedBox(height: 16),
                                  ],
                                  ElevatedButton.icon(
                                    onPressed: _busy ? null : _submit,
                                    icon: _busy
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : Icon(
                                            _isLogin
                                                ? LucideIcons.logIn
                                                : _isRegister
                                                    ? LucideIcons.userPlus
                                                    : LucideIcons.mail,
                                            size: 18),
                                    label: Text(_busy
                                        ? 'Aguarde...'
                                        : _isLogin
                                            ? 'Entrar'
                                            : _isRegister
                                                ? 'Criar minha conta'
                                                : 'Enviar instruções'),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_isLogin || _isRegister) ...[
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 4,
                                      children: [
                                        Text(
                                            _isLogin
                                                ? 'Ainda não tem uma conta?'
                                                : 'Já tem uma conta?',
                                            style: TextStyle(
                                                color: palette.textSecondary,
                                                fontSize: 13)),
                                        TextButton(
                                          onPressed: _busy
                                              ? null
                                              : () => _navigate(_isLogin
                                                  ? _AuthPage.register
                                                  : _AuthPage.login),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppPalette.button,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            minimumSize: const Size(0, 44),
                                            textStyle: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900),
                                          ),
                                          child: Text(_isLogin
                                              ? 'Cadastre-se'
                                              : 'Entrar'),
                                        ),
                                      ],
                                    ),
                                  ] else
                                    TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _navigate(_AuthPage.login),
                                        child:
                                            const Text('Voltar para o login')),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatefulWidget {
  const _AuthField(
      {super.key,
      required this.controller,
      required this.label,
      required this.icon,
      required this.validator,
      this.password = false,
      this.keyboardType,
      this.autofillHints,
      this.helperText,
      this.onSubmitted});

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final bool password;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final String? helperText;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: widget.password && _obscure,
      keyboardType: widget.keyboardType,
      autofillHints: widget.autofillHints,
      autocorrect:
          !widget.password && widget.keyboardType != TextInputType.emailAddress,
      enableSuggestions: !widget.password,
      textCapitalization:
          widget.autofillHints?.contains(AutofillHints.name) ?? false
              ? TextCapitalization.words
              : TextCapitalization.none,
      textInputAction: widget.onSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: widget.onSubmitted,
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: context.palette.textPrimary),
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        errorMaxLines: 3,
        prefixIcon:
            Icon(widget.icon, size: 18, color: context.palette.textMuted),
        suffixIcon: widget.password
            ? IconButton(
                tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 18, color: context.palette.textMuted),
              )
            : null,
      ),
    );
  }
}
