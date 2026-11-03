import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/app_user.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  sb.SupabaseClient get _c => sb.Supabase.instance.client;

  AppUser _toUser(sb.User u) => AppUser(
        id: u.id,
        nome: (u.userMetadata?['nome'] ?? '') as String,
        cognome: (u.userMetadata?['cognome'] ?? '') as String,
        email: u.email ?? '',
      );

  @override
  AppUser? get currentUser {
    final u = _c.auth.currentUser;
    return u == null ? null : _toUser(u);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _c.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return _toUser(res.user!);
    } on sb.AuthException {
      throw AuthException('Credenziali non valide. Riprova.');
    } catch (_) {
      throw AuthException('Errore di connessione. Riprova.');
    }
  }

  @override
  Future<AppUser> signUp({
    required String nome,
    required String cognome,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _c.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'nome': nome.trim(), 'cognome': cognome.trim()},
      );
      final u = res.user;

      // Email già registrata (conferma email attiva): Supabase non dà
      // errore ma restituisce un utente senza identità.
      if (u != null && (u.identities?.isEmpty ?? false)) {
        throw AuthException('Esiste già un account con questa email.');
      }

      if (u == null || res.session == null) {
        throw AuthException('Registrazione non riuscita. Controlla la tua email.');
      }
      return _toUser(u);
    } on sb.AuthException catch (e) {
      // Email già registrata (conferma email disattiva): errore esplicito.
      if (_isAlreadyRegistered(e)) {
        throw AuthException('Esiste già un account con questa email.');
      }
      throw AuthException(e.message);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException('Errore di connessione. Riprova.');
    }
  }

  bool _isAlreadyRegistered(sb.AuthException e) =>
      e.code == 'user_already_exists' ||
      e.code == 'email_exists' ||
      e.message.toLowerCase().contains('already registered');

  @override
  Future<void> signOut() => _c.auth.signOut();
}