/// Un requisito della password con il suo controllo.
class PasswordRule {
  const PasswordRule(this.label, this.test);
  final String label;
  final bool Function(String) test;
}

final passwordRules = <PasswordRule>[
  PasswordRule('Almeno 8 caratteri', (p) => p.length >= 8),
  PasswordRule(
    'Una lettera maiuscola',
    (p) => RegExp(r'\p{Lu}', unicode: true).hasMatch(p),
  ),
  PasswordRule(
    'Una lettera minuscola',
    (p) => RegExp(r'\p{Ll}', unicode: true).hasMatch(p),
  ),
  PasswordRule('Un numero', (p) => RegExp(r'\p{N}', unicode: true).hasMatch(p)),
  PasswordRule(
    'Un carattere speciale (es. ! ? # @ €)',
    (p) => RegExp(r'[^\p{L}\p{N}\s]', unicode: true).hasMatch(p),
  ),
];

bool isPasswordValid(String p) => passwordRules.every((r) => r.test(p));