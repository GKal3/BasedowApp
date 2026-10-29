import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Esito dell'analisi di un fotogramma: testo da mostrare e se il viso è
/// ben posizionato. I record hanno uguaglianza per valore, quindi un
/// `ValueNotifier<GuideResult>` si aggiorna solo quando qualcosa cambia.
typedef GuideResult = ({String message, bool aligned});

/// Guida in tempo reale: verifica che gli occhi cadano nei due rettangoli
/// della sagoma, che la distanza sia quella prevista e che il viso sia
/// frontale (nessuna rotazione laterale, inclinazione o su/giù).
///
/// Tutte le misure sono relative al riquadro 3:4 dell'anteprima e alla
/// distanza tra gli occhi, mai in pixel o millimetri: il comportamento è lo
/// stesso su qualsiasi telefono, risoluzione o proporzione del sensore.
///
/// Serve SOLO alla guida visiva. I box degli occhi da salvare si calcolano
/// sulla foto scattata (vedi `eye_detector.dart`).
class LiveFaceGuide {
  LiveFaceGuide()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.accurate,
            enableLandmarks: true,
            minFaceSize: 0.2,
          ),
        );

  static const GuideResult idle = (message: 'Inquadra il viso', aligned: false);

  // ---- Geometria della sagoma ----
  // Deve coincidere con `_FaceMask` in camera_screen.dart e con l'immagine
  // assets/images/face_guide_mask.png. Se cambi la sagoma, cambia SOLO qui.

  /// Larghezza della sagoma / larghezza del riquadro.
  static const maskWidthFactor = 0.78;

  /// Larghezza / altezza dell'immagine della sagoma.
  static const maskAspect = 319 / 384;

  /// Alignment verticale della sagoma nel riquadro.
  static const maskAlignY = -0.12;

  /// Centro dei due rettangoli degli occhi DENTRO l'immagine della sagoma,
  /// in frazione della sua larghezza/altezza (0..1).
  static const _maskEyeLeftX = 0.275;
  static const _maskEyeRightX = 0.725;
  static const _maskEyeY = 0.438;

  /// Proporzioni del riquadro della fotocamera (larghezza / altezza).
  static const _boxAspect = 3 / 4;

  // ---- Valori derivati: dove devono cadere gli occhi nel riquadro ----
  static const _maskH = maskWidthFactor / maskAspect * _boxAspect;
  static const _maskTop = (1 - _maskH) * (1 + maskAlignY) / 2;

  /// Distanza tra i centri degli occhi / larghezza del riquadro (≈ 0.35).
  static const _targetIod = (_maskEyeRightX - _maskEyeLeftX) * maskWidthFactor;

  /// Punto medio degli occhi, in frazione di larghezza e altezza (≈ 0.50, 0.44).
  static const _targetX =
      0.5 + ((_maskEyeLeftX + _maskEyeRightX) / 2 - 0.5) * maskWidthFactor;
  static const _targetY = _maskTop + _maskEyeY * _maskH;

  // ---- Tolleranze (da tarare con debugInfo = true) ----

  /// Scarto ammesso sulla distanza, relativo al valore target (±5%).
  static const _iodTolerance = 0.05;

  /// Scostamento massimo del punto medio degli occhi dal target
  /// (frazione della larghezza / dell'altezza del riquadro).
  static const _maxOffsetX = 0.03;
  static const _maxOffsetY = 0.025;

  /// Rotazione laterale (yaw), in gradi.
  static const _maxYaw = 7.0;

  /// Spostamento del naso rispetto al centro degli occhi, in unità di
  /// distanza interoculare. Con il viso frontale è ≈ 0: controllo
  /// indipendente dall'angolo stimato da ML Kit.
  static const _maxNoseOffset = 0.07;

  /// Inclinazione laterale della testa (calcolata dalla linea degli occhi).
  static const _maxRoll = 5.0;

  /// Mento alzato/abbassato (pitch), in gradi.
  static const _maxPitch = 12.0;

  /// Dopo che il viso è allineato, le tolleranze si allargano di questo
  /// fattore finché non esce davvero (evita lo sfarfallio al limite).
  static const _holdFactor = 1.3;

  /// Fotogrammi consecutivi "buoni" prima di segnare il viso come allineato.
  static const _framesNeeded = 5;

  /// true = accanto al messaggio compaiono i valori misurati:
  /// d = distanza tra gli occhi (target ≈ 0.35), yaw, n = offset del naso,
  /// roll, x e y = punto medio degli occhi (target ≈ 0.50 e 0.44).
  /// Mettilo a false quando hai finito di tarare.
  static const debugInfo = true;

  /// Analizzo al massimo un fotogramma ogni tanto: basta e risparmia batteria.
  static const _minInterval = Duration(milliseconds: 120);

  final FaceDetector _detector;
  bool _busy = false;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  int _okFrames = 0;
  bool _wasAligned = false;

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// Ritorna null se il fotogramma viene saltato (troppo presto o già
  /// occupato) o se non è convertibile.
  Future<GuideResult?> analyze(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation orientation,
  ) async {
    if (_busy) return null;
    final now = DateTime.now();
    if (now.difference(_last) < _minInterval) return null;
    _last = now;
    _busy = true;
    try {
      final rotation = _rotation(camera, orientation);
      if (rotation == null) return null;
      final input = _toInputImage(image, rotation);
      if (input == null) return null;

      final faces = await _detector.processImage(input);

      // Dimensioni dell'immagine "in piedi" su cui ML Kit dà le coordinate.
      // Con rotazione di 90°/270° larghezza e altezza si scambiano SOLO se il
      // fotogramma arriva in orizzontale (Android). Su iPhone arriva già in
      // verticale.
      final quarterTurn = rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg;
      final swap = quarterTurn && image.width > image.height;
      final upright = swap
          ? Size(image.height.toDouble(), image.width.toDouble())
          : Size(image.width.toDouble(), image.height.toDouble());

      return _evaluate(faces, upright);
    } catch (_) {
      return null;
    } finally {
      _busy = false;
    }
  }

  void _reset() {
    _okFrames = 0;
    _wasAligned = false;
  }

  GuideResult _evaluate(List<Face> faces, Size upright) {
    if (faces.isEmpty) {
      _reset();
      return idle;
    }
    if (faces.length > 1) {
      _reset();
      return (message: 'Un solo volto nell’inquadratura', aligned: false);
    }

    final face = faces.first;
    final l = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final r = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;
    if (l == null || r == null || nose == null) {
      _reset();
      return idle;
    }

    // Occhio più a sinistra e più a destra NELL'IMMAGINE: non importa quale
    // sia il destro del paziente né se il flusso è a specchio.
    final a = l.x <= r.x ? l : r;
    final b = l.x <= r.x ? r : l;

    // Parte dell'immagine visibile nel riquadro 3:4 (l'anteprima riempie il
    // riquadro ritagliando, come BoxFit.cover). Lavoro in pixel
    // dell'immagine e poi normalizzo sul riquadro.
    final imgAspect = upright.width / upright.height;
    final cropY = imgAspect < _boxAspect; // immagine più stretta: taglia sopra/sotto
    final vis = cropY ? imgAspect / _boxAspect : _boxAspect / imgAspect;
    final boxW = upright.width * (cropY ? 1.0 : vis);
    final boxH = upright.height * (cropY ? vis : 1.0);
    final boxLeft = (upright.width - boxW) / 2;
    final boxTop = (upright.height - boxH) / 2;

    final dx = (b.x - a.x).toDouble();
    final dy = (b.y - a.y).toDouble();
    final iodPx = math.sqrt(dx * dx + dy * dy);
    if (iodPx < 1) {
      _reset();
      return idle;
    }

    final midPxX = (a.x + b.x) / 2;
    final midPxY = (a.y + b.y) / 2;

    final iod = iodPx / boxW; // distanza tra gli occhi / larghezza riquadro
    final midX = (midPxX - boxLeft) / boxW;
    final midY = (midPxY - boxTop) / boxH;

    // Inclinazione: angolo della linea degli occhi rispetto all'orizzontale.
    final roll = (math.atan2(dy, dx) * 180 / math.pi).abs();

    // Rotazione laterale: spostamento del naso lungo la linea degli occhi,
    // in unità di distanza interoculare. Proiettato sull'asse degli occhi,
    // quindi non si confonde con l'inclinazione della testa.
    final noseAlong =
        ((nose.x - midPxX) * dx + (nose.y - midPxY) * dy) / iodPx;
    final noseOff = noseAlong.abs() / iodPx;

    final yaw = (face.headEulerAngleY ?? 0).abs();
    final pitch = (face.headEulerAngleX ?? 0).abs();

    final dbg = debugInfo
        ? ' [d ${iod.toStringAsFixed(3)}  yaw ${yaw.toStringAsFixed(0)}'
            '  n ${noseOff.toStringAsFixed(2)}  roll ${roll.toStringAsFixed(0)}'
            '  x ${midX.toStringAsFixed(2)}  y ${midY.toStringAsFixed(2)}]'
        : '';

    final k = _wasAligned ? _holdFactor : 1.0;
    final iodTol = _targetIod * _iodTolerance * k;

    String? problem;
    if (iod < _targetIod - iodTol) {
      problem = 'Avvicinati';
    } else if (iod > _targetIod + iodTol) {
      problem = 'Allontanati';
    } else if ((midX - _targetX).abs() > _maxOffsetX * k ||
        (midY - _targetY).abs() > _maxOffsetY * k) {
      problem = 'Centra il viso nell’ovale';
    } else if (yaw > _maxYaw * k || noseOff > _maxNoseOffset * k) {
      problem = 'Guarda dritto, non ruotare il viso';
    } else if (roll > _maxRoll * k) {
      problem = 'Non inclinare la testa di lato';
    } else if (pitch > _maxPitch * k) {
      problem = 'Non alzare o abbassare il mento';
    }

    if (problem != null) {
      _reset();
      return (message: '$problem$dbg', aligned: false);
    }

    _okFrames++;
    if (_okFrames < _framesNeeded) {
      return (message: 'Tieni fermo…$dbg', aligned: false);
    }
    _wasAligned = true;
    return (message: 'Perfetto, scatta ora$dbg', aligned: true);
  }

  /// Rotazione da dichiarare a ML Kit (procedura ufficiale del plugin).
  InputImageRotation? _rotation(
    CameraDescription camera,
    DeviceOrientation orientation,
  ) {
    final sensor = camera.sensorOrientation;
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(sensor);
    }
    if (Platform.isAndroid) {
      final device = _orientations[orientation];
      if (device == null) return null;
      final compensated = camera.lensDirection == CameraLensDirection.front
          ? (sensor + device) % 360
          : (sensor - device + 360) % 360;
      return InputImageRotationValue.fromRawValue(compensated);
    }
    return null;
  }

  InputImage? _toInputImage(CameraImage image, InputImageRotation rotation) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    if (image.planes.length != 1) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void dispose() => _detector.close();
}