import '../models/app_user.dart';
import '../shared/formatters.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Contratto di autenticazione. Oggi c'è solo l'implementazione in memoria;
/// quando sceglierai il backend basterà scriverne un'altra (es. Supabase)
/// senza toccare le schermate.
abstract class AuthRepository {
  // Utente della sessione salvata, null se non c'è.
  AppUser? get currentUser;
  
  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String nome,
    required String cognome,
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class _Account {
  _Account(this.user, this.password);
  final AppUser user;
  final String password;
}

/// SOLO PER SVILUPPO UI: gli utenti vivono in RAM e le password non sono
/// protette. Va sostituita con un'autenticazione vera.
class InMemoryAuthRepository implements AuthRepository {
  @override
  AppUser? get currentUser => null;
  
  final List<_Account> _accounts = [
    // Account demo per provare l'app senza registrarsi. Da rimuovere.
    _Account(
      const AppUser(
        id: 'demo',
        nome: 'Demo',
        cognome: 'Medico',
        email: 'demo@ospedale.it',
      ),
      'demo123',
    ),
  ];

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final e = email.trim().toLowerCase();
    for (final a in _accounts) {
      if (a.user.email == e && a.password == password) return a.user;
    }
    throw AuthException('Credenziali non valide. Riprova.');
  }

  @override
  Future<AppUser> signUp({
    required String nome,
    required String cognome,
    required String email,
    required String password,
  }) async {
    final e = email.trim().toLowerCase();
    if (_accounts.any((a) => a.user.email == e)) {
      throw AuthException('Esiste già un account con questa email.');
    }
    final user = AppUser(
      id: 'u_${newId()}',
      nome: nome.trim(),
      cognome: cognome.trim(),
      email: e,
    );
    _accounts.add(_Account(user, password));
    return user;
  }

  @override
  Future<void> signOut() async {}
}
