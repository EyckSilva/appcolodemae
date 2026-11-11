import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colodemae_flutter/services/auth_service.dart';
import 'package:colodemae_flutter/services/user_service.dart';
import 'package:colodemae_flutter/services/account_settings_service.dart';
import 'package:colodemae_flutter/models/baby.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _User user;
  late _Auth auth;
  late _Firestore db;
  late UserService users;

  setUp(() {
    user = _User();
    auth = _Auth(user);
    db = _Firestore();
    users = UserService(auth: auth, firestore: db);
  });

  test('Missing profile uses UID and server timestamps; repeats preserve data',
      () async {
    await users.criarPerfil(usuario: user, nome: ' Ana Silva ');
    final profile = db.documents['usuarios/mother-1']!;
    expect(profile['nome'], 'Ana Silva');
    expect(profile['email'], user.email);
    expect(profile['criadoEm'], isA<FieldValue>());
    expect(profile['atualizadoEm'], isA<FieldValue>());
    final created = Timestamp(1000, 0);
    db.documents['usuarios/mother-1'] = {
      ...profile,
      'criadoEm': created,
      'nome': 'Nome preservado',
      'campoLegado': 'preservado',
    };
    final before =
        Map<String, dynamic>.from(db.documents['usuarios/mother-1']!);
    await users.criarPerfil(usuario: user, nome: 'Outro nome');
    expect(db.documents['usuarios/mother-1'], before);
    expect(db.writes, 1);
  });

  test('Legacy account without display name gets a recoverable profile',
      () async {
    await users.criarPerfil(usuario: user, nome: ' ');
    expect((await users.buscarPerfilAtual())?['nome'], 'Mamãe');
  });

  test('Profile reads and writes reject another UID or no session', () async {
    await expectLater(users.buscarPerfil('another-uid'), throwsStateError);
    auth.user = null;
    await expectLater(
        users.criarPerfil(usuario: user, nome: 'Ana'), throwsStateError);
    expect(() => users.buscarPerfilAtual(), throwsStateError);
    expect(db.writes, 0);
  });

  test(
      'Firestore failure never turns successful registration into account failure',
      () async {
    final profiles = _Profiles()..fail = true;
    final service = AuthService(auth: auth, userService: profiles);
    final credential = await service.cadastrar(
        nome: 'Ana', email: user.email!, senha: 'senha123');
    expect(credential.user, same(user));
    expect(auth.creates, 1);
    expect(auth.currentUser, same(user));
    expect(service.falhaPerfil.value?.uid, user.uid);
    profiles.fail = false;
    expect(await service.sincronizarPerfil(), isTrue);
    expect(auth.creates, 1);
    expect(profiles.calls, 2);
    expect(profiles.lastName, 'Ana');
    expect(service.falhaPerfil.value, isNull);
  });

  test('Authentication failure does not attempt a profile write', () async {
    auth.failure = FirebaseAuthException(code: 'email-already-in-use');
    final profiles = _Profiles();
    final service = AuthService(auth: auth, userService: profiles);
    await expectLater(
      service.cadastrar(nome: 'Ana', email: user.email!, senha: 'senha123'),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(profiles.calls, 0);
    expect(service.falhaPerfil.value, isNull);
  });

  test(
      'Restored session and login recover profiles without recreating accounts',
      () async {
    final service = AuthService(auth: auth, userService: users);
    expect(await service.usuarioLogado.first, same(user));
    await service.sincronizarPerfil();
    final original =
        Map<String, dynamic>.from(db.documents['usuarios/mother-1']!);
    await service.entrar(email: user.email!, senha: 'senha123');
    expect(db.documents['usuarios/mother-1'], original);
    expect(auth.creates, 0);
    expect(await service.consultarPerfilAtual(), original);
  });

  test('Simultaneous recovery attempts share the same pending write', () async {
    final profiles = _Profiles()..pending = Completer<void>();
    final service = AuthService(auth: auth, userService: profiles);
    final first = service.sincronizarPerfil();
    final second = service.sincronizarPerfil();
    expect(identical(first, second), isTrue);
    expect(profiles.calls, 1);
    profiles.pending!.complete();
    expect(await first, isTrue);
    expect(await second, isTrue);
  });

  test(
      'Baby writes reuse existing IDs and preserve unrelated fields and creation timestamp',
      () async {
    final service = AccountSettingsService(auth: auth, firestore: db);
    final created = Timestamp(1000, 0);
    db.documents['usuarios/mother-1/bebes/original'] = {
      'nome': 'Bia',
      'nascimento': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'criadoEm': created,
      'campoLegado': 'keep',
    };
    final id = await service.salvarBebe(
        user.uid, Baby(name: 'Beatriz', birthDate: DateTime(2026, 2, 1)));
    expect(id, 'original');
    final data = db.documents['usuarios/mother-1/bebes/original']!;
    expect(data['nome'], 'Beatriz');
    expect(data['criadoEm'], created);
    expect(data['campoLegado'], 'keep');
    expect(data['atualizadoEm'], isA<FieldValue>());
    expect((await service.bebes(user.uid).first).single.baby.birthDate,
        DateTime(2026, 2, 1));
    expect(db.documents.length, 1);
  });

  test('Notification patch preserves the other switch and all existing data',
      () async {
    final service = AccountSettingsService(auth: auth, firestore: db);
    final created = Timestamp(1000, 0);
    db.documents['usuarios/mother-1/preferencias/notificacoes'] = {
      'lembretesEducativos': true,
      'desafio15Dias': false,
      'criadoEm': created,
      'campoLegado': 'keep',
    };
    await service.salvarPreferencia(user.uid, 'lembretesEducativos', false);
    final prefs = await service.preferencias(user.uid).first;
    expect(prefs?['lembretesEducativos'], false);
    expect(prefs?['desafio15Dias'], false);
    expect(prefs?['criadoEm'], created);
    expect(prefs?['campoLegado'], 'keep');
    expect(prefs?['atualizadoEm'], isA<FieldValue>());
  });

  test(
      'Missing baby and preferences use stable documents and server timestamps',
      () async {
    final service = AccountSettingsService(auth: auth, firestore: db);
    final id = await service.salvarBebe(
        user.uid, Baby(name: 'Bia', birthDate: DateTime(2026, 1, 1)));
    expect(id, 'principal');
    expect(db.documents['usuarios/mother-1/bebes/principal']?['criadoEm'],
        isA<FieldValue>());
    await service.salvarPreferencia(user.uid, 'desafio15Dias', false);
    expect(
        db.documents['usuarios/mother-1/preferencias/notificacoes']
            ?['lembretesEducativos'],
        true);
    expect(
        db.documents['usuarios/mother-1/preferencias/notificacoes']
            ?['criadoEm'],
        isA<FieldValue>());
  });

  test('Settings service rejects another account and invalid baby data',
      () async {
    final service = AccountSettingsService(auth: auth, firestore: db);
    expect(() => service.bebes('another-user'), throwsStateError);
    expect(() => service.preferencias('another-user'), throwsStateError);
    await expectLater(
        service.salvarPreferencia('another-user', 'lembretesEducativos', false),
        throwsStateError);
    await expectLater(
        service.salvarBebe(user.uid, Baby(name: '', birthDate: DateTime.now())),
        throwsArgumentError);
    expect(db.writes, 0);
  });
}

class _User implements User {
  @override
  String get uid => 'mother-1';
  @override
  String? get email => 'ana@example.com';
  @override
  String? displayName;
  @override
  Future<void> updateDisplayName(String? value) async => displayName = value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements FirebaseAuth {
  _Auth(this.user);
  User? user;
  int creates = 0;
  FirebaseAuthException? failure;
  @override
  User? get currentUser => user;
  @override
  Stream<User?> authStateChanges() => Stream.value(user);
  @override
  Future<UserCredential> createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    creates++;
    if (failure != null) throw failure!;
    return _Credential(user);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword(
          {required String email, required String password}) async =>
      _Credential(user);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Credential implements UserCredential {
  _Credential(this.user);
  @override
  final User? user;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profiles extends UserService {
  bool fail = false;
  int calls = 0;
  String? lastName;
  Completer<void>? pending;
  @override
  Future<void> criarPerfil(
      {required User usuario, required String nome}) async {
    calls++;
    lastName = nome;
    if (fail) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    if (pending != null) await pending!.future;
  }
}

/// Test double for the SDK boundary; does not execute Firestore Rules.
class _Firestore implements FirebaseFirestore {
  final documents = <String, Map<String, dynamic>>{};
  int writes = 0;
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _Collection(this, collectionPath);
  @override
  Future<T> runTransaction<T>(TransactionHandler<T> transactionHandler,
          {Duration timeout = const Duration(seconds: 30),
          int maxAttempts = 5}) =>
      transactionHandler(_Transaction(this));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// The SDK's sealed types are replaced only at the unit-test boundary.
// ignore: subtype_of_sealed_class
class _Collection implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db, this.path);
  final _Firestore db;
  @override
  final String path;
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get(
          [GetOptions? options]) async =>
      _QuerySnapshot([
        for (final entry in db.documents.entries)
          if (entry.key.startsWith('$path/') &&
              entry.key.substring(path.length + 1).split('/').length == 1)
            _QueryDocument(entry.key.split('/').last, entry.value),
      ]);
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots(
          {bool includeMetadataChanges = false,
          ListenSource source = ListenSource.defaultSource}) =>
      Stream.fromFuture(get());
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Document(db, '${this.path}/$path');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Document implements DocumentReference<Map<String, dynamic>> {
  _Document(this.db, this.path);
  final _Firestore db;
  @override
  final String path;
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _Collection(db, '$path/$collectionPath');
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots(
          {bool includeMetadataChanges = false,
          ListenSource source = ListenSource.defaultSource}) =>
      Stream.fromFuture(get());
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
          [GetOptions? options]) async =>
      _Snapshot(db.documents[path]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Snapshot<T> implements DocumentSnapshot<T> {
  _Snapshot(this.value);
  final T? value;
  @override
  bool get exists => value != null;
  @override
  T? data() => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transaction implements Transaction {
  _Transaction(this.db);
  final _Firestore db;
  @override
  Transaction update(
      DocumentReference documentReference, Map<Object, Object?> data) {
    final current = db.documents[documentReference.path]!;
    for (final entry in data.entries) {
      current[entry.key as String] = entry.value;
    }
    db.writes++;
    return this;
  }

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
          DocumentReference<T> documentReference) async =>
      _Snapshot<T>(db.documents[documentReference.path] as T?);
  @override
  Transaction set<T>(DocumentReference<T> documentReference, T data,
      [SetOptions? options]) {
    db.documents[documentReference.path] =
        Map<String, dynamic>.from(data as Map);
    db.writes++;
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _QuerySnapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _QueryDocument extends _Snapshot<Map<String, dynamic>>
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _QueryDocument(this.id, Map<String, dynamic> data) : super(data);
  @override
  final String id;
  @override
  Map<String, dynamic> data() => value!;
}
