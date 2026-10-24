import 'dart:io' show Platform;
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Esito dell'analisi di un fotogramma: testo da mostrare e se il viso è
/// ben posizionato. I record hanno uguaglianza per valore, quindi un
/// `ValueNotifier<GuideResult>` si aggiorna solo quando qualcosa cambia.
typedef GuideResult = ({String message, bool aligned});

/// Guida in tempo reale: guarda i fotogrammi della fotocamera e dice se il
/// viso è dentro l'ovale, alla distanza giusta e di fronte.
///
/// Serve SOLO alla guida visiva. I box degli occhi da salvare si calcolano
/// sulla foto scattata (vedi `eye_detector.dart`).
class LiveFaceGuide {
  LiveFaceGuide()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.fast,
            minFaceSize: 0.2,
          ),
        );

  static const GuideResult idle = (message: 'Inquadra il viso', aligned: false);

  // ---- Parametri di taratura (modificali se la guida è troppo rigida/lasca) ----

  /// Proporzioni del riquadro della fotocamera (larghezza / altezza).
  static const _boxAspect = 3 / 4;

  /// Posizione verticale del centro dell'ovale, in frazione dell'altezza.
  static const _ovalCenterY = 0.44;

  /// Altezza dell'ovale in frazione dell'altezza del riquadro
  /// (larghezza 78% × proporzioni 319:384 dell'immagine della sagoma).
  static const _ovalHeight = 0.78 * (384 / 319) / (4 / 3);

  /// Altezza del volto rispetto all'ovale: sotto il minimo "Avvicinati",
  /// sopra il massimo "Allontanati".
  static const _minFaceRatio = 0.55;
  static const _maxFaceRatio = 0.95;

  /// Scostamento massimo del centro del volto dal centro dell'ovale
  /// (frazione della larghezza / dell'altezza del riquadro).
  static const _maxOffsetX = 0.10;
  static const _maxOffsetY = 0.10;

  /// Inclinazione massima della testa, in gradi.
  static const _maxAngle = 15.0;

  /// Fotogrammi consecutivi "buoni" prima di segnare il viso come allineato
  /// (evita lo sfarfallio).
  static const _framesNeeded = 3;

  /// Analizzo al massimo un fotogramma ogni tanto: basta e risparmia batteria.
  static const _minInterval = Duration(milliseconds: 120);

  final FaceDetector _detector;
  bool _busy = false;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  int _okFrames = 0;

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

      // ML Kit restituisce le coordinate sull'immagine già raddrizzata:
      // con rotazione di 90°/270° larghezza e altezza si scambiano.
      final quarterTurn = rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg;
      final upright = quarterTurn
          ? Size(image.height.toDouble(), image.width.toDouble())
          : Size(image.width.toDouble(), image.height.toDouble());

      return _evaluate(faces, upright);
    } catch (_) {
      return null;
    } finally {
      _busy = false;
    }
  }

  GuideResult _evaluate(List<Face> faces, Size upright) {
    if (faces.isEmpty) {
      _okFrames = 0;
      return idle;
    }
    if (faces.length > 1) {
      _okFrames = 0;
      return (message: 'Un solo volto nell’inquadratura', aligned: false);
    }

    final face = faces.first;
    final r = face.boundingBox;

    // L'anteprima riempie il riquadro 3:4 ritagliando (BoxFit.cover):
    // porto le coordinate dall'immagine al riquadro.
    final imgAspect = upright.width / upright.height;
    final cropY = imgAspect < _boxAspect; // immagine più stretta: taglia sopra/sotto
    final vis = cropY ? imgAspect / _boxAspect : _boxAspect / imgAspect;
    double mapX(double n) => cropY ? n : (n - (1 - vis) / 2) / vis;
    double mapY(double n) => cropY ? (n - (1 - vis) / 2) / vis : n;

    // Il controllo orizzontale è simmetrico rispetto al centro, quindi non
    // importa se il flusso della camera è a specchio o no.
    final cx = mapX(r.center.dx / upright.width);
    final cy = mapY(r.center.dy / upright.height);
    final faceH = (r.height / upright.height) * (cropY ? 1 / vis : 1);
    final ratio = faceH / _ovalHeight;

    String? problem;
    if (ratio < _minFaceRatio) {
      problem = 'Avvicinati';
    } else if (ratio > _maxFaceRatio) {
      problem = 'Allontanati';
    } else if ((cx - 0.5).abs() > _maxOffsetX ||
        (cy - _ovalCenterY).abs() > _maxOffsetY) {
      problem = 'Centra il viso nell’ovale';
    } else if ((face.headEulerAngleX ?? 0).abs() > _maxAngle ||
        (face.headEulerAngleY ?? 0).abs() > _maxAngle ||
        (face.headEulerAngleZ ?? 0).abs() > _maxAngle) {
      problem = 'Tieni la testa dritta';
    }

    if (problem != null) {
      _okFrames = 0;
      return (message: problem, aligned: false);
    }

    _okFrames++;
    if (_okFrames < _framesNeeded) {
      return (message: 'Tieni fermo…', aligned: false);
    }
    return (message: 'Perfetto, scatta ora', aligned: true);
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