import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  tearDown(() async {
    // Garante que o timer seja cancelado ao final de cada teste para não vazar
    final editor = EditorDeCroqui();
    await editor.nukeExperimentalData();
  });

  group('Experimental Mode Behavior', () {
    test('Timer do modo experimental continua rodando no background após disconnect', () async {
      final editor = EditorDeCroqui();

      // Inicia o modo experimental e o timer de 20 minutos
      await editor.activateExperimental(url: 'someUrl');
      
      // Aguarda o primeiro tick do timer
      await Future.delayed(const Duration(milliseconds: 1500));
      
      expect(editor.timeRemaining.value, isNotNull);
      final initialRemaining = editor.timeRemaining.value!;
      
      // Simula a desconexão (voltar pro modo oficial)
      await editor.disconnect();
      
      // Garante que desconectou
      expect(editor.isExperimentalMode.value, isFalse);
      
      // Aguarda mais um pouco para provar que o timer ainda está rodando no background
      await Future.delayed(const Duration(milliseconds: 2500));
      
      // O tempo restante deve ter diminuído
      final newRemaining = editor.timeRemaining.value!;
      expect(newRemaining, isNotNull);
      expect(newRemaining.inSeconds, lessThan(initialRemaining.inSeconds));
      
      // A interface deve continuar no modo oficial, sem o nuke prematuro
      expect(editor.isExperimentalMode.value, isFalse);
    });

    test('activateExperimental com forceResetTimer=false não zera o timer se já estiver ativo', () async {
      final editor = EditorDeCroqui();
      await editor.activateExperimental(url: 'someUrl');
      await Future.delayed(const Duration(milliseconds: 1500));
      final remaining1 = editor.timeRemaining.value!;
      
      // Ativa novamente sem forçar reset
      await editor.activateExperimental(url: 'otherUrl', forceResetTimer: false);
      final remaining2 = editor.timeRemaining.value!;
      
      // O timer não deve ter voltado para 20 minutos (1200 segundos), mas continuado a diminuir
      expect(remaining2.inSeconds, lessThanOrEqualTo(remaining1.inSeconds));
    });

    test('activateExperimental com forceResetTimer=true zera o timer', () async {
      final editor = EditorDeCroqui();
      await editor.activateExperimental(url: 'someUrl');
      await Future.delayed(const Duration(milliseconds: 1500));
      final remaining1 = editor.timeRemaining.value!;
      
      // Ativa novamente forçando reset
      await editor.activateExperimental(url: 'otherUrl', forceResetTimer: true);
      final remaining2 = editor.timeRemaining.value!;
      
      // O timer deve ter voltado para perto de 20 minutos (maior que o remaining1)
      expect(remaining2.inSeconds, greaterThan(remaining1.inSeconds));
    });

    test('disconnect desliga isExperimentalMode mas mantém a URL configurada', () async {
      final editor = EditorDeCroqui();
      await editor.activateExperimental(url: 'https://test.local');
      expect(editor.isExperimentalMode.value, isTrue);
      expect(editor.editorUrl.value, 'https://test.local');

      await editor.disconnect();
      expect(editor.isExperimentalMode.value, isFalse);
      expect(editor.editorUrl.value, 'https://test.local'); // URL preservada
    });

    test('nukeExperimentalData limpa totalmente o estado e configurações', () async {
      final editor = EditorDeCroqui();
      await editor.activateExperimental(url: 'someUrl');
      expect(editor.isExperimentalMode.value, isTrue);
      expect(editor.editorUrl.value, isNotNull);
      expect(editor.timeRemaining.value, isNotNull);

      await editor.nukeExperimentalData();
      
      expect(editor.isExperimentalMode.value, isFalse);
      expect(editor.editorUrl.value, isNull);
      expect(editor.timeRemaining.value, isNull);
    });

    test('activateExperimental adiciona http:// se a URL não tiver esquema', () async {
      final editor = EditorDeCroqui();
      
      // Sem esquema
      await editor.activateExperimental(url: '10.0.2.2:8156');
      expect(editor.editorUrl.value, 'http://10.0.2.2:8156');
      
      // Com http://
      await editor.activateExperimental(url: 'http://192.168.1.5:8000');
      expect(editor.editorUrl.value, 'http://192.168.1.5:8000');
      
      // Com https://
      await editor.activateExperimental(url: 'https://meuserver.com');
      expect(editor.editorUrl.value, 'https://meuserver.com');
    });
  });
}
