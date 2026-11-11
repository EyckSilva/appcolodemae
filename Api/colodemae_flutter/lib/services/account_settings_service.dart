import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/baby.dart';

class SavedBaby {
  const SavedBaby(this.id, this.baby);
  final String id;
  final Baby baby;
}

/// Dados privados da sessão. Nenhuma leitura usa uma coleção de outra usuária.
class AccountSettingsService {
  AccountSettingsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _providedDb = firestore,
        _providedAuth = auth;

  final FirebaseFirestore? _providedDb;
  final FirebaseAuth? _providedAuth;
  FirebaseFirestore get _db => _providedDb ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _providedAuth ?? FirebaseAuth.instance;

  void _check(String uid) {
    if (_auth.currentUser?.uid != uid) {
      throw StateError('A sessão desta conta não está ativa.');
    }
  }

  DocumentReference<Map<String, dynamic>> _user(String uid) {
    _check(uid);
    return _db.collection('usuarios').doc(uid);
  }

  Stream<Map<String, dynamic>?> perfil(String uid) =>
      _user(uid).snapshots().map((doc) {
        _check(uid);
        final data = doc.data();
        if (data != null &&
            (data['nome'] is! String || data['email'] is! String)) {
          throw const FormatException('Perfil inválido.');
        }
        return data;
      });

  Stream<List<SavedBaby>> bebes(String uid) =>
      _user(uid).collection('bebes').snapshots().map((snapshot) {
        _check(uid);
        final docs = snapshot.docs.toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        return docs.map((doc) {
          final data = doc.data();
          final date = (data['nascimento'] as Timestamp).toDate().toUtc();
          return SavedBaby(
              doc.id,
              Baby(
                  name: data['nome'] as String,
                  birthDate: DateTime(date.year, date.month, date.day)));
        }).toList();
      });

  Stream<Map<String, dynamic>?> preferencias(String uid) => _user(uid)
          .collection('preferencias')
          .doc('notificacoes')
          .snapshots()
          .map((doc) {
        _check(uid);
        final data = doc.data();
        if (data != null &&
            (data['lembretesEducativos'] is! bool ||
                data['desafio15Dias'] is! bool)) {
          throw const FormatException('Preferências inválidas.');
        }
        return data;
      });

  Future<String> salvarBebe(String uid, Baby baby, {String? id}) async {
    final col = _user(uid).collection('bebes');
    final name = baby.name.trim();
    final birth = DateTime.utc(
        baby.birthDate.year, baby.birthDate.month, baby.birthDate.day);
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final earliest = DateTime.utc(now.year - 2, now.month, now.day);
    if (name.isEmpty ||
        name.length > 200 ||
        birth.isAfter(today) ||
        birth.isBefore(earliest)) {
      throw ArgumentError('Confira o nome e a data de nascimento do bebê.');
    }
    if (id == null) {
      // Reutiliza um bebê existente antes de criar o documento principal.
      final existing = (await col.get()).docs.toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      id = existing.isEmpty ? 'principal' : existing.first.id;
    }
    _check(uid);
    final doc = col.doc(id);
    await _db.runTransaction<void>((tx) async {
      final current = await tx.get(doc);
      _check(uid);
      final values = <String, dynamic>{
        'nome': name,
        'nascimento': Timestamp.fromDate(birth),
        'atualizadoEm': FieldValue.serverTimestamp(),
      };
      if (current.exists) {
        tx.update(doc, values);
      } else {
        tx.set(doc, {...values, 'criadoEm': FieldValue.serverTimestamp()});
      }
    });
    return id;
  }

  Future<void> salvarPreferencia(String uid, String campo, bool valor) async {
    if (!const ['lembretesEducativos', 'desafio15Dias'].contains(campo)) {
      throw ArgumentError('Preferência inválida.');
    }
    final doc = _user(uid).collection('preferencias').doc('notificacoes');
    await _db.runTransaction<void>((tx) async {
      final current = await tx.get(doc);
      _check(uid);
      final patch = {
        campo: valor,
        'atualizadoEm': FieldValue.serverTimestamp()
      };
      if (current.exists) {
        tx.update(doc, patch);
      } else {
        tx.set(doc, {
          'lembretesEducativos': true,
          'desafio15Dias': true,
          ...patch,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
