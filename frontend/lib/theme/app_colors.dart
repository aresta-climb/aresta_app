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

  // Novas cores
  final Color deepBasalt;
  final Color dryMoss;
  final Color ashGrey;
  final Color chalkWhite;
  final Color slateBlue;
  final Color clayDust;
  final Color rustIron;
  final Color darkPine;
  final Color fernGreen;
  final Color graniteEdge;
  final Color caveShadow;

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
    this.deepBasalt = const Color(0xFF161616),
    this.dryMoss = const Color(0xFF7B8B6F),
    this.ashGrey = const Color(0xFF8E959D),
    this.chalkWhite = const Color(0xFFF4F3ED),
    this.slateBlue = const Color(0xFF1B2430),
    this.clayDust = const Color(0xFFFCECE6),
    this.rustIron = const Color(0xFFE27D60),
    this.darkPine = const Color(0xFF2C332A),
    this.fernGreen = const Color(0xFF7B8B6F),
    this.graniteEdge = const Color(0xFF2A2A2A),
    this.caveShadow = const Color(0xFF1F1F1F),
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
    Color? deepBasalt,
    Color? dryMoss,
    Color? ashGrey,
    Color? chalkWhite,
    Color? slateBlue,
    Color? clayDust,
    Color? rustIron,
    Color? darkPine,
    Color? fernGreen,
    Color? graniteEdge,
    Color? caveShadow,
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
      deepBasalt: deepBasalt ?? this.deepBasalt,
      dryMoss: dryMoss ?? this.dryMoss,
      ashGrey: ashGrey ?? this.ashGrey,
      chalkWhite: chalkWhite ?? this.chalkWhite,
      slateBlue: slateBlue ?? this.slateBlue,
      clayDust: clayDust ?? this.clayDust,
      rustIron: rustIron ?? this.rustIron,
      darkPine: darkPine ?? this.darkPine,
      fernGreen: fernGreen ?? this.fernGreen,
      graniteEdge: graniteEdge ?? this.graniteEdge,
      caveShadow: caveShadow ?? this.caveShadow,
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
      deepBasalt: Color.lerp(deepBasalt, other.deepBasalt, t)!,
      dryMoss: Color.lerp(dryMoss, other.dryMoss, t)!,
      ashGrey: Color.lerp(ashGrey, other.ashGrey, t)!,
      chalkWhite: Color.lerp(chalkWhite, other.chalkWhite, t)!,
      slateBlue: Color.lerp(slateBlue, other.slateBlue, t)!,
      clayDust: Color.lerp(clayDust, other.clayDust, t)!,
      rustIron: Color.lerp(rustIron, other.rustIron, t)!,
      darkPine: Color.lerp(darkPine, other.darkPine, t)!,
      fernGreen: Color.lerp(fernGreen, other.fernGreen, t)!,
      graniteEdge: Color.lerp(graniteEdge, other.graniteEdge, t)!,
      caveShadow: Color.lerp(caveShadow, other.caveShadow, t)!,
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
    
    // Novas cores da home
    deepBasalt: Color(0xFF161616),
    dryMoss: Color(0xFF7B8B6F),
    ashGrey: Color(0xFF8E959D),
    chalkWhite: Color(0xFFF4F3ED),
    slateBlue: Color(0xFF1B2430),
    clayDust: Color(0xFFFCECE6),
    rustIron: Color(0xFFE27D60),
    darkPine: Color(0xFF2C332A),
    fernGreen: Color(0xFF7B8B6F),
    graniteEdge: Color(0xFF2A2A2A),
    caveShadow: Color(0xFF1F1F1F),
  );

  // Nova Paleta Clara
  static const AppColors light = AppColors(
    nobleBlack: Color(0xFFEBE8E0),
    beastHide: Color(0xFFD68C3E),
    fishBone: Color(0xFF2A2E33),
    leatherWork: Color(0xFF996642),
    obsidianBrown: Color(0xFFFFFFFF),
    slateStone: Color(0xFFE8E3DA),
    mossRock: Color(0xFF6D854C),
    clayEarth: Color(0xFFA85542),
    weatheredIron: Color(0xFF999999),
  );

  // Cor fixa da logomarca (Laranja/Coral Vibrante)
  static const Color brandColor = Color(0xFFE25844);
}

// Extensão auxiliar no BuildContext para acessar as cores rapidamente
extension AppColorsExtension on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
