import 'evaluation.dart';

class Patient {
  const Patient({
    required this.id,
    required this.nome,
    required this.cognome,
    this.dataNascita,
    this.note = '',
    this.evaluations = const [],
  });

  final String id;
  final String nome;
  final String cognome;
  final DateTime? dataNascita;
  final String note;
  final List<Evaluation> evaluations;

  String get fullName => '$nome $cognome';

  String get initials {
    final a = nome.isNotEmpty ? nome[0] : '';
    final b = cognome.isNotEmpty ? cognome[0] : '';
    return (a + b).toUpperCase();
  }

  int? get age {
    final b = dataNascita;
    if (b == null) return null;
    final n = DateTime.now();
    var a = n.year - b.year;
    if (n.month < b.month || (n.month == b.month && n.day < b.day)) a--;
    return a;
  }

  Patient copyWith({
    String? nome,
    String? cognome,
    DateTime? dataNascita,
    String? note,
    List<Evaluation>? evaluations,
  }) {
    return Patient(
      id: id,
      nome: nome ?? this.nome,
      cognome: cognome ?? this.cognome,
      dataNascita: dataNascita ?? this.dataNascita,
      note: note ?? this.note,
      evaluations: evaluations ?? this.evaluations,
    );
  }

  factory Patient.fromMap(Map<String, dynamic> m) {
    final evals = ((m['evaluations'] as List?) ?? const [])
        .map((e) => Evaluation.fromMap(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final birth = m['data_nascita'] as String?;

    return Patient(
      id: m['id'] as String,
      nome: m['nome'] as String,
      cognome: m['cognome'] as String,
      dataNascita: birth == null ? null : DateTime.parse(birth),
      note: (m['note'] as String?) ?? '',
      evaluations: evals,
    );
  }
}
