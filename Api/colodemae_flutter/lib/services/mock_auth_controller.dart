import 'package:flutter/foundation.dart';

class MockUser {
  const MockUser({required this.name, required this.email});

  final String name;
  final String email;
}

/// Demonstração local: contas e sessão existem apenas enquanto o app está aberto.
/// Nunca persiste senhas ou envia mensagens de e-mail.
class MockAuthController extends ChangeNotifier {
  static const demoEmail = 'mamae@colodemae.com';
  static const demoPassword = 'Colo123!';

  final Map<String, ({MockUser user, String password})> _accounts = {
    demoEmail: (
      user: const MockUser(name: 'Mariana', email: demoEmail),
      password: demoPassword,
    ),
  };

  MockUser? _user;
  MockUser? get user => _user;

  String? login(String email, String password) {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      return 'E-mail ou senha incorretos. Confira seus dados e tente novamente.';
    }
    _user = account.user;
    notifyListeners();
    return null;
  }

  String? register(String name, String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    if (_accounts.containsKey(normalizedEmail)) {
      return 'Este e-mail já está cadastrado. Entre na sua conta.';
    }
    final user = MockUser(name: name.trim(), email: normalizedEmail);
    _accounts[normalizedEmail] = (user: user, password: password);
    _user = user;
    notifyListeners();
    return null;
  }

  /// Retorno neutro inclusive para endereços não cadastrados.
  String requestPasswordRecovery(String email) =>
      'Se houver uma conta para ${email.trim()}, você receberá as instruções para recuperar sua senha.';

  void logout() {
    _user = null;
    notifyListeners();
  }
}
