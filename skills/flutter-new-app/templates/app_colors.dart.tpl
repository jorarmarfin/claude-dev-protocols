import 'package:flutter/material.dart';

/// Paleta derivada del logo ({{LOGO_FILE}}) via extract_colors.py.
/// brand = {{BRAND_HEX}} | light = {{LIGHT_HEX}} | dark = {{DARK_HEX}}
abstract final class AppColors {
  static const brand = Color(0x{{BRAND_HEX_ARGB}});
  static const brandLight = Color(0x{{LIGHT_HEX_ARGB}});
  static const brandDark = Color(0x{{DARK_HEX_ARGB}});

  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFA726);
  static const error = Color(0xFFE53935);
}
