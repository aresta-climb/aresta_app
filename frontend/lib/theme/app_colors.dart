import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color nobleBlack;
  final Color beastHide;
  final Color fishBone;
  final Color leatherWork;
  final Color obsidianBrown;
  final Color slateStone;
  final Color mossRock;
  final Color clayEarth;
  final Color weatheredIron;

  const AppColors({
    required this.nobleBlack,
    required this.beastHide,
    required this.fishBone,
    required this.leatherWork,
    required this.obsidianBrown,
    required this.slateStone,
    required this.mossRock,
    required this.clayEarth,
    required this.weatheredIron,
  });

  @override
  AppColors copyWith({
    Color? nobleBlack,
    Color? beastHide,
    Color? fishBone,
    Color? leatherWork,
    Color? obsidianBrown,
    Color? slateStone,
    Color? mossRock,
    Color? clayEarth,
    Color? weatheredIron,
  }) {
    return AppColors(
      nobleBlack: nobleBlack ?? this.nobleBlack,
      beastHide: beastHide ?? this.beastHide,
      fishBone: fishBone ?? this.fishBone,
      leatherWork: leatherWork ?? this.leatherWork,
      obsidianBrown: obsidianBrown ?? this.obsidianBrown,
      slateStone: slateStone ?? this.slateStone,
      mossRock: mossRock ?? this.mossRock,
      clayEarth: clayEarth ?? this.clayEarth,
      weatheredIron: weatheredIron ?? this.weatheredIron,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      nobleBlack: Color.lerp(nobleBlack, other.nobleBlack, t)!,
      beastHide: Color.lerp(beastHide, other.beastHide, t)!,
      fishBone: Color.lerp(fishBone, other.fishBone, t)!,
      leatherWork: Color.lerp(leatherWork, other.leatherWork, t)!,
      obsidianBrown: Color.lerp(obsidianBrown, other.obsidianBrown, t)!,
      slateStone: Color.lerp(slateStone, other.slateStone, t)!,
      mossRock: Color.lerp(mossRock, other.mossRock, t)!,
      clayEarth: Color.lerp(clayEarth, other.clayEarth, t)!,
      weatheredIron: Color.lerp(weatheredIron, other.weatheredIron, t)!,
    );
  }

  // Current Dark Palette
  static const AppColors dark = AppColors(
    nobleBlack: Color(0xFF1F2128),
    beastHide: Color(0xFFAE8F68),
    fishBone: Color(0xFFE4DAC5),
    leatherWork: Color(0xFF896449),
    obsidianBrown: Color(0xFF543E35),
    slateStone: Color(0xFF4A4E5A),
    mossRock: Color(0xFF5B614D),
    clayEarth: Color(0xFF7D4F43),
    weatheredIron: Color(0xFF3E4247),
  );

  // New Light Palette
  static const AppColors light = AppColors(
    nobleBlack: Color(0xFFEBE8E0), // Background: Soft warm beige, slightly darker
    beastHide: Color(0xFFD68C3E), // Primary accent: Natural amber
    fishBone: Color(0xFF2A2E33), // Text: Elegant dark slate
    leatherWork: Color(0xFF996642), // Secondary brown: Muted saddle
    obsidianBrown: Color(0xFFFFFFFF), // Cards/Panels: Pure white for elevation
    slateStone: Color(0xFFE8E3DA), // Secondary panels: Slightly darker beige
    mossRock: Color(0xFF6D854C), // Green accent: Natural moss
    clayEarth: Color(0xFFA85542), // Red accent: Muted terracotta
    weatheredIron: Color(0xFF999999), // Muted grey
  );
}

// Helper extension on BuildContext to quickly access colors
extension AppColorsExtension on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
