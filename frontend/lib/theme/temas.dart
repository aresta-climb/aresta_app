// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:frontend/theme/cores_app.dart';

/// Constrói o tema visual claro da aplicação Aresta Climb.
///
/// Define explicitamente estilos base para [IconButtonThemeData], [MenuButtonThemeData]
/// e [PopupMenuThemeData] garantindo que operações de fusão de estilo ([ButtonStyle.merge])
/// nunca recebam referências nulas durante mudanças de estado ou variações de tema no Material 3.
ThemeData construirTemaClaro() {
  final cores = AppColors.light;
  return ThemeData(
    fontFamily: 'Montserrat',
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: cores.beastHide,
      brightness: Brightness.light,
      primary: cores.beastHide,
    ),
    scaffoldBackgroundColor: cores.slateStone,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: cores.fishBone,
      selectionColor: cores.beastHide.withValues(alpha: 0.3),
      selectionHandleColor: cores.beastHide,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: cores.fishBone,
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: MenuItemButton.styleFrom(
        foregroundColor: cores.fishBone,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: cores.slateStone,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(
        fontFamily: 'Montserrat',
        color: cores.fishBone,
      ),
    ),
    extensions: const [AppColors.light],
  );
}

/// Constrói o tema visual escuro da aplicação Aresta Climb.
///
/// Define explicitamente estilos base para [IconButtonThemeData], [MenuButtonThemeData]
/// e [PopupMenuThemeData] garantindo que operações de fusão de estilo ([ButtonStyle.merge])
/// nunca recebam referências nulas durante mudanças de estado ou variações de tema no Material 3.
ThemeData construirTemaEscuro() {
  final cores = AppColors.dark;
  return ThemeData(
    fontFamily: 'Montserrat',
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: cores.beastHide,
      brightness: Brightness.dark,
      primary: cores.beastHide,
    ),
    scaffoldBackgroundColor: cores.deepBasalt,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: cores.fishBone,
      selectionColor: cores.beastHide.withValues(alpha: 0.3),
      selectionHandleColor: cores.beastHide,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: cores.fishBone,
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: MenuItemButton.styleFrom(
        foregroundColor: cores.fishBone,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: cores.deepBasalt,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(
        fontFamily: 'Montserrat',
        color: cores.fishBone,
      ),
    ),
    extensions: const [AppColors.dark],
  );
}
