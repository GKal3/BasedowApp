import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Mostra una foto locale; se manca o non si apre, un segnaposto.
/// Sul web il percorso è un URL `blob:` del browser, sui telefoni un file.
class AppPhoto extends StatelessWidget {
  const AppPhoto({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.cacheWidth = 1200,
  });

  final String? path;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;

  /// Larghezza massima (in pixel) a cui decodificare l'immagine, per
  /// risparmiare memoria. Per gli ingrandimenti degli occhi serve un valore
  /// alto, altrimenti vengono sgranati.
  final int? cacheWidth;

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.photoPlaceholder,
        alignment: Alignment.center,
        child: const Icon(Icons.person_outline, size: 40, color: AppColors.muted2),
      );

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p == null || p.isEmpty) return _placeholder();

    Widget onError(BuildContext context, Object error, StackTrace? stack) =>
        _placeholder();

    if (kIsWeb) {
      return Image.network(
        p,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: onError,
      );
    }
    return Image.file(
      File(p),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      errorBuilder: onError,
    );
  }
}