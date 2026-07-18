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

  // Novas cores para a Home Page
  final Color homeBg;
  final Color textOlive;
  final Color textGrey;
  final Color cardOffWhite;
  final Color textDarkBlue;
  final Color tagBgOrange;
  final Color tagTextOrange;
  final Color cardOlive;
  final Color iconOlive;
  final Color borderGrey;
  final Color searchBg;

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
    this.homeBg = const Color(0xFF161616),
    this.textOlive = const Color(0xFF7B8B6F),
    this.textGrey = const Color(0xFF8E959D),
    this.cardOffWhite = const Color(0xFFF4F3ED),
    this.textDarkBlue = const Color(0xFF1B2430),
    this.tagBgOrange = const Color(0xFFFCECE6),
    this.tagTextOrange = const Color(0xFFE27D60),
    this.cardOlive = const Color(0xFF2C332A),
    this.iconOlive = const Color(0xFF7B8B6F),
    this.borderGrey = const Color(0xFF2A2A2A),
    this.searchBg = const Color(0xFF1F1F1F),
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
    Color? homeBg,
    Color? textOlive,
    Color? textGrey,
    Color? cardOffWhite,
    Color? textDarkBlue,
    Color? tagBgOrange,
    Color? tagTextOrange,
    Color? cardOlive,
    Color? iconOlive,
    Color? borderGrey,
    Color? searchBg,
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
      homeBg: homeBg ?? this.homeBg,
      textOlive: textOlive ?? this.textOlive,
      textGrey: textGrey ?? this.textGrey,
      cardOffWhite: cardOffWhite ?? this.cardOffWhite,
      textDarkBlue: textDarkBlue ?? this.textDarkBlue,
      tagBgOrange: tagBgOrange ?? this.tagBgOrange,
      tagTextOrange: tagTextOrange ?? this.tagTextOrange,
      cardOlive: cardOlive ?? this.cardOlive,
      iconOlive: iconOlive ?? this.iconOlive,
      borderGrey: borderGrey ?? this.borderGrey,
      searchBg: searchBg ?? this.searchBg,
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
      homeBg: Color.lerp(homeBg, other.homeBg, t)!,
      textOlive: Color.lerp(textOlive, other.textOlive, t)!,
      textGrey: Color.lerp(textGrey, other.textGrey, t)!,
      cardOffWhite: Color.lerp(cardOffWhite, other.cardOffWhite, t)!,
      textDarkBlue: Color.lerp(textDarkBlue, other.textDarkBlue, t)!,
      tagBgOrange: Color.lerp(tagBgOrange, other.tagBgOrange, t)!,
      tagTextOrange: Color.lerp(tagTextOrange, other.tagTextOrange, t)!,
      cardOlive: Color.lerp(cardOlive, other.cardOlive, t)!,
      iconOlive: Color.lerp(iconOlive, other.iconOlive, t)!,
      borderGrey: Color.lerp(borderGrey, other.borderGrey, t)!,
      searchBg: Color.lerp(searchBg, other.searchBg, t)!,
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
    homeBg: Color(0xFF161616),
    textOlive: Color(0xFF7B8B6F),
    textGrey: Color(0xFF8E959D),
    cardOffWhite: Color(0xFFF4F3ED),
    textDarkBlue: Color(0xFF1B2430),
    tagBgOrange: Color(0xFFFCECE6),
    tagTextOrange: Color(0xFFE27D60),
    cardOlive: Color(0xFF2C332A),
    iconOlive: Color(0xFF7B8B6F),
    borderGrey: Color(0xFF2A2A2A),
    searchBg: Color(0xFF1F1F1F),
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
