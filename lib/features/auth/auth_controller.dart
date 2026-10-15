/* GESTIONE DELLE AZIONI DI LOGIN - SIGN IN*/

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../data/providers.dart';
import '../../models/app_user.dart';

/// Stato = utente loggato (null se non loggato). Il router reagisce ai cambi
/// di questo stato e fa i redirect da solo.
class AuthController extends Notifier<AppUser?> {
  
  @override
  AppUser? build() => ref.read(authRepositoryProvider).currentUser;

  /// Ritorna un messaggio d'errore, oppure null se è andato tutto bene.
  Future<String?> signIn(String email, String password) async {
    try {
      state = await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signUp({
    required String nome,
    required String cognome,
    required String email,
    required String password,
  }) async {
    try {
      state = await ref.read(authRepositoryProvider).signUp(
            nome: nome,
            cognome: cognome,
            email: email,
            password: password,
          );
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = null;
  }
}

final authProvider =
    NotifierProvider<AuthController, AppUser?>(AuthController.new);