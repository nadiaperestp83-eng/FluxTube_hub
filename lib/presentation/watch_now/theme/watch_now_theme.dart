import 'package:flutter/material.dart';

/// Constantes visuais isoladas — fáceis de trocar por um ThemeExtension
/// do teu app depois, sem mexer nos widgets.
class WatchNowColors {
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F5F7);
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF6E6E73);
  static const accent = Color(0xFF0A84FF);
  static const chipSelectedBg = Color(0xFF1C1C1E);
  static const chipUnselectedBg = Color(0xFFEFEFF1);
}

class WatchNowRadius {
  static const card = 20.0;
  static const chip = 999.0;
  static const badge = 8.0;
}

class WatchNowTextStyles {
  static const title = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: WatchNowColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const sectionHeader = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: WatchNowColors.textPrimary,
  );

  static const seeAll = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: WatchNowColors.accent,
  );

  static const cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const cardSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );

  static const videoTileTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: WatchNowColors.textPrimary,
  );
}
