import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  UserService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _providedDb = firestore,
        _providedAuth = auth;

  final FirebaseFirestore? _providedDb;
  final FirebaseAuth? _providedAuth;
  FirebaseFirestore get _db => _providedDb ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _providedAuth ?? FirebaseAuth.instance;

  User _proprietaria(String uid) {
    final atual = _auth.currentUser;
    if (atual == null || atual.uid != uid) {
      throw StateError('É necessário autenticar a proprietária do perfil.');
    }
    return atual;
  }

  /// Cria somente se estiver ausente. A transação evita sobrescritas em
  /// tentativas simultâneas e preserva integralmente documentos existentes.
  Future<void> criarPerfil({
    required User usuario,
    required String nome,
  }) async {
    _proprietaria(usuario.uid);
    final documento = _db.collection('usuarios').doc(usuario.uid);
    await _db.runTransaction<void>((transaction) async {
      final existente = await transaction.get(documento);
      if (existente.exists) return;
      _proprietaria(usuario.uid);
      final nomePerfil = nome.trim().isEmpty ? 'Mamãe' : nome.trim();
      transaction.set(documento, {
        'nome': nomePerfil,
        'email': usuario.email,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<Map<String, dynamic>?> buscarPerfil(String uid) async {
    _proprietaria(uid);
    final documento = await _db.collection('usuarios').doc(uid).get();
    _proprietaria(uid);
    return documento.data();
  }

  Future<Map<String, dynamic>?> buscarPerfilAtual() {
    final usuario = _auth.currentUser;
    if (usuario == null) {
      throw StateError('É necessário entrar na conta para consultar o perfil.');
    }
    return buscarPerfil(usuario.uid);
  }
}
