import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Campo di testo con etichetta sopra, come `.field` del prototipo.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.textInputAction,
    this.inputFormatters,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.t(12.5, w: FontWeight.w800)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: obscureText ? 1 : maxLines,
            minLines: minLines,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            style: AppText.t(15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.t(15, c: AppColors.muted2),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.all(14),
              suffixIcon: suffixIcon,
              border: _border(AppColors.cardBorder),
              enabledBorder: _border(AppColors.cardBorder),
              focusedBorder: _border(AppColors.sky300),
            ),
          ),
        ],
      ),
    );
  }
}
