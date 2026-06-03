import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/theme/theme_controller.dart';

void main() {
  setUp(() {
    // Inicializa as preferências compartilhadas vazias para cada teste
    SharedPreferences.setMockInitialValues({});
    
    // Reseta o singleton manualmente para os testes garantindo que
    // comecem limpos sempre.
    ThemeController().themeMode.value = ThemeMode.dark;
  });

  test('Initial theme mode is ThemeMode.dark', () {
    final controller = ThemeController();
    expect(controller.themeMode.value, ThemeMode.dark);
  });

  test('setThemeMode updates the ValueNotifier and SharedPreferences', () async {
    final controller = ThemeController();
    
    // Troca para o modo claro
    await controller.setThemeMode(ThemeMode.light);
    
    // Verifica a propriedade ValueNotifier
    expect(controller.themeMode.value, ThemeMode.light);
    
    // Verifica se salvou corretamente na memória cache (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('theme_mode'), ThemeMode.light.index);
  });

  test('loadTheme restores the theme from SharedPreferences', () async {
    // Simula como se o usuário já tivesse escolhido o tema claro anteriormente
    SharedPreferences.setMockInitialValues({'theme_mode': ThemeMode.light.index});
    
    final controller = ThemeController();
    
    // Dispara a função loadTheme (que roda ao iniciar o app)
    await controller.loadTheme();
    
    // O valor deve ter sido carregado e atualizado
    expect(controller.themeMode.value, ThemeMode.light);
  });
}
