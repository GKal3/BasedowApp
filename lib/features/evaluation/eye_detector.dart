import 'dart:io';
import 'dart:math';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../../models/eye_boxes.dart';

abstract class EyeDetector {
  /// Null se non c'è esattamente un volto o gli occhi non sono rilevati.
  Future<EyeBoxes?> detect(String photoPath);
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

  @override
  Future<EyeBoxes?> detect(String photoPath) async {
    // 1. Applica l'orientamento EXIF ai pixel e sovrascrive il file, così
    //    foto, rilevatore e visualizzazione usano lo stesso spazio.
    final bytes = await File(photoPath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final fixed = img.bakeOrientation(decoded);
    await File(photoPath).writeAsBytes(img.encodeJpg(fixed, quality: 92));
    final w = fixed.width, h = fixed.height;

    // 2. Rilevamento.
    final faces =
        await _detector.processImage(InputImage.fromFilePath(photoPath));
    if (faces.length != 1) return null;
    final face = faces.first;

    final a = face.contours[FaceContourType.leftEye]?.points;
    final b = face.contours[FaceContourType.rightEye]?.points;
    if (a == null || b == null || a.isEmpty || b.isEmpty) return null;

    // 3. OD/OS dalla posizione: in una foto non specchiata scattata al
    //    paziente, il suo occhio destro (OD) sta a SINISTRA nell'immagine.
    final aCx = a.map((p) => p.x).reduce((x, y) => x + y) / a.length;
    final bCx = b.map((p) => p.x).reduce((x, y) => x + y) / b.length;
    final leftInImage = aCx < bCx ? a : b;
    final rightInImage = aCx < bCx ? b : a;

    return EyeBoxes(
      od: _box(leftInImage, w, h),
      os: _box(rightInImage, w, h),
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
    final bw = (maxX - minX) * 1.6; // margine attorno all'occhio
    final bh = bw / 2;

    final left = (cx - bw / 2).clamp(0, w - bw).toDouble();
    final top = (cy - bh / 2).clamp(0, h - bh).toDouble();
    return EyeBox(left / w, top / h, bw / w, bh / h);
  }

  @override
  void dispose() => _detector.close();
}