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

  // Paleta Escura Atual
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

  // Nova Paleta Clara
  static const AppColors light = AppColors(
    nobleBlack: Color(0xFFEBE8E0), // Fundo: Bege quente, ligeiramente mais escuro
    beastHide: Color(0xFFD68C3E), // Destaque principal: Âmbar
    fishBone: Color(0xFF2A2E33), // Texto: Ardósia escura
    leatherWork: Color(0xFF996642), // Marrom secundário: Sela suave
    obsidianBrown: Color(0xFFFFFFFF), // Cartões/Painéis: Branco puro para elevação
    slateStone: Color(0xFFE8E3DA), // Painéis secundários: Bege ligeiramente mais escuro
    mossRock: Color(0xFF6D854C), // Destaque verde: Musgo
    clayEarth: Color(0xFFA85542), // Destaque vermelho: Terracota
    weatheredIron: Color(0xFF999999), // Cinza
  );

  // Cor fixa da logomarca (Laranja/Coral Vibrante)
  static const Color brandColor = Color(0xFFE25844);
}

// Extensão auxiliar no BuildContext para acessar as cores rapidamente
extension AppColorsExtension on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
