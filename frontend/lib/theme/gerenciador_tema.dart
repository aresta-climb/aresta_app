// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerenciador do estado global e persistência do tema selecionado pelo usuário.
class GerenciadorTema {
  static final GerenciadorTema _instance = GerenciadorTema._internal();
  factory GerenciadorTema() => _instance;
  GerenciadorTema._internal();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  /// Carrega a preferência de tema persistida no [SharedPreferences].
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode');
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < ThemeMode.values.length) {
      themeMode.value = ThemeMode.values[themeIndex];
    }
  }

  /// Define e persiste o novo [ThemeMode] no dispositivo.
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }
}

/// Alias de compatibilidade retroativa para [GerenciadorTema].
typedef ThemeController = GerenciadorTema;

