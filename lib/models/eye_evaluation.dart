enum Eye { od, os }

extension EyeX on Eye {
  String get code => name; // 'od' | 'os'
  String get label => this == Eye.od ? 'Occhio destro' : 'Occhio sinistro';
  String get shortLabel => this == Eye.od ? 'OD' : 'OS';

  static Eye fromCode(String code) => code == 'os' ? Eye.os : Eye.od;
}

enum GradeField {
  iperemiaCongiuntivale,
  chemosiCongiuntivale,
  iperemiaPalpebrale,
  edemaPalpebrale,
}

const gradeLabels = ['Assente', 'Lieve', 'Moderata', 'Severa'];

/// Es. "2 · Moderata", oppure "—" se non valorizzato.
String formatGrade(int? v) => v == null ? '—' : '$v · ${gradeLabels[v]}';

String formatYesNo(bool? v) => v == null ? '—' : (v ? 'Sì' : 'No');

String formatMm(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)} mm';

/// Valutazione clinica di un singolo occhio.
class EyeEvaluation {
  const EyeEvaluation({
    this.iperemiaCongiuntivale,
    this.chemosiCongiuntivale,
    this.edemaCaruncola,
    this.iperemiaPalpebrale,
    this.edemaPalpebrale,
    this.mrd1,
    this.mrd2,
  });

  final int? iperemiaCongiuntivale;
  final int? chemosiCongiuntivale;
  final bool? edemaCaruncola;
  final int? iperemiaPalpebrale;
  final int? edemaPalpebrale;
  final double? mrd1;
  final double? mrd2;

  /// Ampiezza della rima palpebrale = MRD1 + MRD2.
  double? get rima => (mrd1 != null && mrd2 != null) ? mrd1! + mrd2! : null;

  bool get isComplete =>
      iperemiaCongiuntivale != null &&
      chemosiCongiuntivale != null &&
      edemaCaruncola != null &&
      iperemiaPalpebrale != null &&
      edemaPalpebrale != null &&
      mrd1 != null &&
      mrd2 != null;

  Map<String, dynamic> toMap() => {
        'iperemiaCongiuntivale': iperemiaCongiuntivale,
        'chemosiCongiuntivale': chemosiCongiuntivale,
        'edemaCaruncola': edemaCaruncola,
        'iperemiaPalpebrale': iperemiaPalpebrale,
        'edemaPalpebrale': edemaPalpebrale,
        'mrd1': mrd1,
        'mrd2': mrd2,
      };

  factory EyeEvaluation.fromMap(Map<String, dynamic> m) => EyeEvaluation(
        iperemiaCongiuntivale: m['iperemiaCongiuntivale'] as int?,
        chemosiCongiuntivale: m['chemosiCongiuntivale'] as int?,
        edemaCaruncola: m['edemaCaruncola'] as bool?,
        iperemiaPalpebrale: m['iperemiaPalpebrale'] as int?,
        edemaPalpebrale: m['edemaPalpebrale'] as int?,
        mrd1: (m['mrd1'] as num?)?.toDouble(),
        mrd2: (m['mrd2'] as num?)?.toDouble(),
      );

  int? grade(GradeField f) => switch (f) {
        GradeField.iperemiaCongiuntivale => iperemiaCongiuntivale,
        GradeField.chemosiCongiuntivale => chemosiCongiuntivale,
        GradeField.iperemiaPalpebrale => iperemiaPalpebrale,
        GradeField.edemaPalpebrale => edemaPalpebrale,
      };

  EyeEvaluation withGrade(GradeField f, int value) => EyeEvaluation(
        iperemiaCongiuntivale:
            f == GradeField.iperemiaCongiuntivale ? value : iperemiaCongiuntivale,
        chemosiCongiuntivale:
            f == GradeField.chemosiCongiuntivale ? value : chemosiCongiuntivale,
        edemaCaruncola: edemaCaruncola,
        iperemiaPalpebrale:
            f == GradeField.iperemiaPalpebrale ? value : iperemiaPalpebrale,
        edemaPalpebrale:
            f == GradeField.edemaPalpebrale ? value : edemaPalpebrale,
        mrd1: mrd1,
        mrd2: mrd2,
      );

  EyeEvaluation withEdemaCaruncola(bool value) => EyeEvaluation(
        iperemiaCongiuntivale: iperemiaCongiuntivale,
        chemosiCongiuntivale: chemosiCongiuntivale,
        edemaCaruncola: value,
        iperemiaPalpebrale: iperemiaPalpebrale,
        edemaPalpebrale: edemaPalpebrale,
        mrd1: mrd1,
        mrd2: mrd2,
      );

  /// Passare null per svuotare il campo.
  EyeEvaluation withMrd1(double? value) => EyeEvaluation(
        iperemiaCongiuntivale: iperemiaCongiuntivale,
        chemosiCongiuntivale: chemosiCongiuntivale,
        edemaCaruncola: edemaCaruncola,
        iperemiaPalpebrale: iperemiaPalpebrale,
        edemaPalpebrale: edemaPalpebrale,
        mrd1: value,
        mrd2: mrd2,
      );

  EyeEvaluation withMrd2(double? value) => EyeEvaluation(
        iperemiaCongiuntivale: iperemiaCongiuntivale,
        chemosiCongiuntivale: chemosiCongiuntivale,
        edemaCaruncola: edemaCaruncola,
        iperemiaPalpebrale: iperemiaPalpebrale,
        edemaPalpebrale: edemaPalpebrale,
        mrd1: mrd1,
        mrd2: value,
      );
}
