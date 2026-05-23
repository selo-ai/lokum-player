import 'package:flutter/material.dart';

class AppColors {
  // Deep dark background palette
  static const Color background = Color(0xFF0A0E1A); // Very dark navy
  static const Color surface = Color(0xFF141A2E);    // Dark blue-grey
  static const Color surfaceLight = Color(0xFF1F2942); // Lighter blue-grey
  
  // High contrast accent colors
  static const Color primary = Color(0xFF00E5FF);     // Neon cyan
  static const Color secondary = Color(0xFFFF3D00);   // Neon orange/red
  static const Color accent = Color(0xFF7C4DFF);      // Neon purple/violet
  
  // Status Colors
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
  static const Color error = Color(0xFFFF1744);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A99AD);
  static const Color textMuted = Color(0xFF5E6D82);
  
  // Glassmorphic border & shadow colors
  static const Color borderLight = Color(0x33FFFFFF);
  static const Color borderDark = Color(0x1AFFFFFF);
  static const Color shadow = Color(0x1F000000);
  
  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFF05070D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient cardGradient = LinearGradient(
    colors: [Color(0x26141A2E), Color(0x0D141A2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
