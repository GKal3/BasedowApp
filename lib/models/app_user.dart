class AppUser {
  const AppUser({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.email,
  });

  final String id;
  final String nome;
  final String cognome;
  final String email;

  String get fullName => '$nome $cognome';
}
