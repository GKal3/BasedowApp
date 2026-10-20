import 'dart:ui';

/// Rettangolo normalizzato (0..1) rispetto all'immagine.
class EyeBox {
  const EyeBox(this.left, this.top, this.width, this.height);
  final double left, top, width, height;

  Map<String, dynamic> toMap() =>
      {'left': left, 'top': top, 'width': width, 'height': height};

  factory EyeBox.fromMap(Map<String, dynamic> m) => EyeBox(
        (m['left'] as num).toDouble(),
        (m['top'] as num).toDouble(),
        (m['width'] as num).toDouble(),
        (m['height'] as num).toDouble(),
      );

  Rect toRect(Size imageSize) => Rect.fromLTWH(
        left * imageSize.width,
        top * imageSize.height,
        width * imageSize.width,
        height * imageSize.height,
      );
}

class EyeBoxes {
  const EyeBoxes({
    required this.od,
    required this.os,
    required this.imageWidth,
    required this.imageHeight,
    this.source = 'mlkit',
  });

  final EyeBox od;
  final EyeBox os;
  final int imageWidth;
  final int imageHeight;
  final String source; // quale rilevatore li ha prodotti

  EyeBox of(bool isOd) => isOd ? od : os;

  Map<String, dynamic> toMap() => {
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
        'source': source,
        'od': od.toMap(),
        'os': os.toMap(),
      };

  factory EyeBoxes.fromMap(Map<String, dynamic> m) => EyeBoxes(
        imageWidth: m['imageWidth'] as int,
        imageHeight: m['imageHeight'] as int,
        source: (m['source'] as String?) ?? 'mlkit',
        od: EyeBox.fromMap(m['od'] as Map<String, dynamic>),
        os: EyeBox.fromMap(m['os'] as Map<String, dynamic>),
      );
}