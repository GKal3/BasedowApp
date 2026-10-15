/* CONFIGURAZIONE DEI COLORI - PALETTE DELL'APP */

import 'package:flutter/material.dart';

/// Palette presa dalle variabili CSS del prototipo HTML.
class AppColors {
  AppColors._();

  static const sky50 = Color(0xFFDBF4FF);
  static const sky300 = Color(0xFF8ECAE6);
  static const navy = Color(0xFF023047);
  static const amber = Color(0xFFFFB701);
  static const orange = Color(0xFFFC8500);
  static const white = Color(0xFFFFFFFF);
  static const card = Color(0xFFEEF6FA);
  static const danger = Color(0xFFD9534F);
  static const photoPlaceholder = Color(0xFFE3EAEE);
  static const cameraBg = Color(0xFF0A1620);

  // Navy con trasparenza (valori alpha espliciti, niente withOpacity).
  static const muted = Color(0x99023047); // 60%
  static const muted2 = Color(0x66023047); // 40%
  static const divider = Color(0x8C023047); // 55%
  static const track = Color(0x24023047); // 14%
  static const cardBorder = Color(0x14023047); // 8%
  static const shadow = Color(0x29023047); // 16%

  // Sfondi usati nel riepilogo e nelle card valutazione.
  static const warningBg = Color(0xFFFFF6E1);
  static const warningBorder = Color(0x66FFB701);
  static const evalCardTop = Color(0xFFE7F5FF);
  static const evalCardBottom = Color(0xFFD9ECF9);
}

class AppRadius {
  AppRadius._();
  static const double card = 18;
  static const double small = 12;
}

class AppShadows {
  AppShadows._();
  static const button = [
    BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 10)),
  ];
}