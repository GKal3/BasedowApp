import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../../models/eye_boxes.dart';

/// Il volto è stato rilevato ma non è frontale.
class FaceNotFrontalException implements Exception {
  const FaceNotFrontalException();
}

abstract class EyeDetector {
  /// Rileva gli occhi sulla foto scattata. Null se non c'è esattamente un
  /// volto o gli occhi non sono rilevati.
  ///
  /// [mirrored] = true se la foto è a specchio (come in un selfie): in quel
  /// caso l'occhio destro del paziente (OD) sta a DESTRA nell'immagine.
  Future<EyeBoxes?> detect(String photoPath, {bool mirrored = false});
  void dispose();
}

class MlKitEyeDetector implements EyeDetector {
  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  /// Lato lungo massimo dell'immagine data a ML Kit. La foto salvata resta
  /// a piena risoluzione.
  static const _maxDetectSide = 1600;

  @override
  Future<EyeBoxes?> detect(String photoPath, {bool mirrored = false}) async {
    // 1. Applica l'orientamento EXIF ai pixel e sovrascrive il file, così
    //    foto, rilevatore e visualizzazione usano lo stesso spazio.
    final bytes = await File(photoPath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      debugPrint('EyeDetector: immagine non decodificabile');
      return null;
    }
    final fixed = img.bakeOrientation(decoded);
    await File(photoPath).writeAsBytes(img.encodeJpg(fixed, quality: 92));
    final w = fixed.width, h = fixed.height;

    // 2. Copia ridotta per il rilevamento (ML Kit lavora meglio così).
    var detectPath = photoPath;
    var dw = w, dh = h;
    final longSide = max(w, h);
    if (longSide > _maxDetectSide) {
      final scale = _maxDetectSide / longSide;
      dw = (w * scale).round();
      dh = (h * scale).round();
      final small = img.copyResize(
        fixed,
        width: dw,
        height: dh,
        interpolation: img.Interpolation.average,
      );
      detectPath = '$photoPath.detect.jpg';
      await File(detectPath).writeAsBytes(img.encodeJpg(small, quality: 90));
    }
    debugPrint('EyeDetector: foto ${w}x$h, rilevamento su ${dw}x$dh');

    // 3. Rilevamento.
    List<Face> faces;
    try {
      faces = await _detector.processImage(InputImage.fromFilePath(detectPath));
    } finally {
      if (detectPath != photoPath) {
        try {
          await File(detectPath).delete();
        } catch (_) {}
      }
    }
    if (faces.length != 1) {
      debugPrint('EyeDetector: volti trovati = ${faces.length}');
      return null;
    }
    final face = faces.first;

    // 4. Controllo di sicurezza: il viso deve essere frontale.
    final lm = face.landmarks;
    final le = lm[FaceLandmarkType.leftEye]?.position;
    final re = lm[FaceLandmarkType.rightEye]?.position;
    final nb = lm[FaceLandmarkType.noseBase]?.position;
    if (le == null || re == null || nb == null) {
      debugPrint('EyeDetector: landmark mancanti');
      return null;
    }
    final ex = (re.x - le.x).toDouble();
    final ey = (re.y - le.y).toDouble();
    final iod = sqrt(ex * ex + ey * ey);
    if (iod < 1) {
      debugPrint('EyeDetector: distanza occhi nulla');
      return null;
    }
    final mx = (le.x + re.x) / 2;
    final my = (le.y + re.y) / 2;
    final noseOff = (((nb.x - mx) * ex + (nb.y - my) * ey) / iod).abs() / iod;
    final yaw = (face.headEulerAngleY ?? 0).abs();
    final roll = (face.headEulerAngleZ ?? 0).abs();
    debugPrint('EyeDetector: yaw ${yaw.toStringAsFixed(1)} '
        'roll ${roll.toStringAsFixed(1)} naso ${noseOff.toStringAsFixed(3)}');
    if (yaw > 6 || roll > 10 || noseOff > 0.08) {
      throw const FaceNotFrontalException();
    }

    // 5. Contorni degli occhi.
    final a = face.contours[FaceContourType.leftEye]?.points;
    final b = face.contours[FaceContourType.rightEye]?.points;
    if (a == null || b == null || a.isEmpty || b.isEmpty) {
      debugPrint('EyeDetector: contorni degli occhi mancanti');
      return null;
    }

    // 6. OD/OS dalla posizione nell'immagine.
    //    Foto "vera" (fotocamera posteriore): l'occhio destro del paziente
    //    sta a SINISTRA nell'immagine. Foto a specchio: è il contrario.
    final aCx = a.map((p) => p.x).reduce((x, y) => x + y) / a.length;
    final bCx = b.map((p) => p.x).reduce((x, y) => x + y) / b.length;
    final leftInImage = aCx < bCx ? a : b;
    final rightInImage = aCx < bCx ? b : a;

    final odPoints = mirrored ? rightInImage : leftInImage;
    final osPoints = mirrored ? leftInImage : rightInImage;

    // I box sono frazioni (0..1): valgono anche per la foto a piena
    // risoluzione.
    return EyeBoxes(
      od: _box(odPoints, dw, dh),
      os: _box(osPoints, dw, dh),
      imageWidth: w,
      imageHeight: h,
    );
  }

  /// Box dai punti del contorno, con margine e proporzioni fisse (2:1)
  /// così tutti gli ingrandimenti hanno la stessa forma.
  EyeBox _box(List<Point<int>> pts, int w, int h) {
    final minX = pts.map((p) => p.x).reduce(min).toDouble();
    final maxX = pts.map((p) => p.x).reduce(max).toDouble();
    final minY = pts.map((p) => p.y).reduce(min).toDouble();
    final maxY = pts.map((p) => p.y).reduce(max).toDouble();

    final cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
    var bw = (maxX - minX) * 1.6; // margine attorno all'occhio
    if (bw > w) bw = w.toDouble();
    var bh = bw / 2;
    if (bh > h) {
      bh = h.toDouble();
      bw = bh * 2;
    }

    final left = (cx - bw / 2).clamp(0, w - bw).toDouble();
    final top = (cy - bh / 2).clamp(0, h - bh).toDouble();
    return EyeBox(left / w, top / h, bw / w, bh / h);
  }

  @override
  void dispose() => _detector.close();
}