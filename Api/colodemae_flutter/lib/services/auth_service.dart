import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'user_service.dart';

/// A autenticação já teve sucesso; somente a sincronização do perfil falhou.
class ProfileSyncFailure {
  const ProfileSyncFailure({required this.uid, required this.cause});

  final String uid;
  final Object cause;
}

class AuthService {
  AuthService({FirebaseAuth? auth, UserService? userService})
      : _providedAuth = auth,
        _providedUsers = userService;

  final FirebaseAuth? _providedAuth;
  final UserService? _providedUsers;
  FirebaseAuth get _auth => _providedAuth ?? FirebaseAuth.instance;
  late final UserService _users = _providedUsers ?? UserService(auth: _auth);
  final _profileFailure = ValueNotifier<ProfileSyncFailure?>(null);
  ValueListenable<ProfileSyncFailure?> get falhaPerfil => _profileFailure;
  final Map<String, Future<bool>> _syncs = {};
  final Map<String, String> _pendingNames = {};
  bool _registering = false;

  // Cadastrar uma nova mãe
  Future<UserCredential> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    if (_registering) throw StateError('Já existe um cadastro em andamento.');
    _registering = true;
    try {
      // Somente erros desta chamada representam falha na criação da conta.
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      final usuario = credential.user;
      if (usuario != null) {
        await sincronizarPerfil(usuario: usuario, nome: nome);
      } else {
        _profileFailure.value = ProfileSyncFailure(
          uid: _auth.currentUser?.uid ?? '',
          cause: StateError('O usuário criado ainda não está disponível.'),
        );
      }
      return credential;
    } finally {
      _registering = false;
    }
  }

  // Fazer login
  Future<UserCredential> entrar({
    required String email,
    required String senha,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
    await sincronizarPerfil(usuario: credential.user);
    return credential;
  }

  /// Pode ser repetido sem recriar a conta ou substituir um perfil existente.
  /// Retorna false para falhas do perfil, mantendo a sessão autenticada.
  Future<bool> sincronizarPerfil({User? usuario, String? nome}) {
    final atual = usuario ?? _auth.currentUser;
    if (atual == null || _auth.currentUser?.uid != atual.uid) {
      return Future.value(false);
    }
    if (nome != null) _pendingNames[atual.uid] = nome.trim();
    final ongoing = _syncs[atual.uid];
    if (ongoing != null) return ongoing;
    late final Future<bool> task;
    task = _sincronizar(atual).whenComplete(() {
      if (identical(_syncs[atual.uid], task)) _syncs.remove(atual.uid);
    });
    _syncs[atual.uid] = task;
    return task;
  }

  Future<bool> _sincronizar(User usuario) async {
    try {
      final nome = _pendingNames[usuario.uid];
      if (nome != null) await usuario.updateDisplayName(nome);
      await _users.criarPerfil(
        usuario: usuario,
        nome: nome ?? usuario.displayName ?? '',
      );
      if (_auth.currentUser?.uid == usuario.uid) {
        _pendingNames.remove(usuario.uid);
        _profileFailure.value = null;
      }
      return true;
    } catch (error) {
      if (_auth.currentUser?.uid == usuario.uid) {
        _profileFailure.value =
            ProfileSyncFailure(uid: usuario.uid, cause: error);
      }
      return false;
    }
  }

  Future<Map<String, dynamic>?> consultarPerfilAtual() =>
      _users.buscarPerfilAtual();

  // Sair da conta
  Future<void> sair() async {
    await _auth.signOut();
    _pendingNames.clear();
    _profileFailure.value = null;
  }

  // Recuperar senha
  Future<void> recuperarSenha(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // Verificar estado da autenticação
  Stream<User?> get usuarioLogado => _auth.authStateChanges().map((usuario) {
        if (usuario == null) {
          _profileFailure.value = null;
          _pendingNames.clear();
        } else if (!_registering) {
          // Recupera perfis ausentes inclusive ao restaurar uma sessão antiga.
          unawaited(sincronizarPerfil(usuario: usuario));
        }
        return usuario;
      });
}
