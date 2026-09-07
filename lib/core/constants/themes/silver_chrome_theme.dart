import 'package:flutter/material.dart';

import 'app_theme_data.dart';
import 'app_theme_id.dart';

/// Apple Green — locked to the preview. Internal id silverChrome (compat).
const AppThemeData silverChromeTheme = AppThemeData(
  id: AppThemeId.silverChrome,
  label: 'Apple Green',
  accent: Color(0xFF8FDB5A),
  accentLight: Color(0xFFB6F08A),
  accentDark: Color(0xFF4CA818),
  screenGradient: [
    Color(0xFF0B1610),
    Color(0xFF0B1610),
    Color(0xFF0B1610),
  ],
  background: Color(0xFF0B1610),
  surface: Color(0xFF1C3324),
  textPrimary: Color(0xFFEEF8EC),
  textSecondary: Color(0xFF8EAE8A),
);
