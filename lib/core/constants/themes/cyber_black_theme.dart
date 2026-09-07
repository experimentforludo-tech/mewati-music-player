import 'package:flutter/material.dart';

import 'app_theme_data.dart';
import 'app_theme_id.dart';

/// Deep Black — locked. OLED #000000, accent #FF6600.
const AppThemeData cyberBlackTheme = AppThemeData(
  id: AppThemeId.cyberBlack,
  label: 'Deep Black',
  accent: Color(0xFFFF6600),
  accentLight: Color(0xFFFF944D),
  accentDark: Color(0xFFCC5200),
  screenGradient: [
    Color(0xFF000000),
    Color(0xFF000000),
    Color(0xFF000000),
  ],
  background: Color(0xFF000000),
  surface: Color(0xFF000000),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFB3B3B3),
);
