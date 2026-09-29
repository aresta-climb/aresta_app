// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/theme/temas.dart';

void main() {
  group('Temas da Aplicação (construirTemaClaro e construirTemaEscuro)', () {
    test('construirTemaClaro constrói tema claro com propriedades esperadas', () {
      final tema = construirTemaClaro();

      expect(tema.brightness, Brightness.light);
      expect(tema.useMaterial3, isTrue);
      expect(tema.textTheme.bodyMedium?.fontFamily, 'Montserrat');
      expect(tema.colorScheme.primary, AppColors.light.beastHide);
      expect(tema.scaffoldBackgroundColor, AppColors.light.slateStone);
      expect(tema.extensions.containsKey(AppColors), isTrue);

      final coresExtension = tema.extension<AppColors>();
      expect(coresExtension, isNotNull);
      expect(coresExtension, AppColors.light);

      // Validação de temas de botões para evitar crashes no Material 3
      expect(tema.iconButtonTheme.style, isNotNull);
      expect(tema.menuButtonTheme.style, isNotNull);
      expect(tema.popupMenuTheme.color, AppColors.light.slateStone);
    });

    test('construirTemaEscuro constrói tema escuro com propriedades esperadas', () {
      final tema = construirTemaEscuro();

      expect(tema.brightness, Brightness.dark);
      expect(tema.useMaterial3, isTrue);
      expect(tema.textTheme.bodyMedium?.fontFamily, 'Montserrat');
      expect(tema.colorScheme.primary, AppColors.dark.beastHide);
      expect(tema.scaffoldBackgroundColor, AppColors.dark.deepBasalt);
      expect(tema.extensions.containsKey(AppColors), isTrue);

      final coresExtension = tema.extension<AppColors>();
      expect(coresExtension, isNotNull);
      expect(coresExtension, AppColors.dark);

      // Validação de temas de botões para evitar crashes no Material 3
      expect(tema.iconButtonTheme.style, isNotNull);
      expect(tema.menuButtonTheme.style, isNotNull);
      expect(tema.popupMenuTheme.color, AppColors.dark.deepBasalt);
    });
  });
}
