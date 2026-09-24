// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

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
    test(
      'activateExperimental ativa isExperimentalMode e configura a URL sem expiração temporizada',
      () async {
        final editor = EditorDeCroqui();

        await editor.activateExperimental(url: 'https://test.local');

        expect(editor.isExperimentalMode.value, isTrue);
        expect(editor.editorUrl.value, 'https://test.local');

        // Desconecta manualmente
        await editor.disconnect();
        expect(editor.isExperimentalMode.value, isFalse);
        expect(editor.editorUrl.value, 'https://test.local');
      },
    );

    test(
      'loadFromDisk executa Nuke compulsório se isExperimental estiver salvo no boot (Sessão Volátil)',
      () async {
        final editor = EditorDeCroqui();
        await editor.activateExperimental(url: 'https://test.local');
        expect(editor.isExperimentalMode.value, isTrue);

        // Simula reinicialização do aplicativo
        final novoEditor = EditorDeCroqui();
        await novoEditor.loadFromDisk();

        // No boot, o modo experimental deve ser resetado com segurança
        expect(novoEditor.isExperimentalMode.value, isFalse);
        expect(novoEditor.editorUrl.value, isNull);
      },
    );

    test(
      'disconnect desliga isExperimentalMode mas mantém a URL configurada',
      () async {
        final editor = EditorDeCroqui();
        await editor.activateExperimental(url: 'https://test.local');
        expect(editor.isExperimentalMode.value, isTrue);
        expect(editor.editorUrl.value, 'https://test.local');

        await editor.disconnect();
        expect(editor.isExperimentalMode.value, isFalse);
        expect(editor.editorUrl.value, 'https://test.local'); // URL preservada
      },
    );

    test(
      'nukeExperimentalData limpa totalmente o estado e configurações',
      () async {
        final editor = EditorDeCroqui();
        await editor.activateExperimental(url: 'someUrl');
        expect(editor.isExperimentalMode.value, isTrue);
        expect(editor.editorUrl.value, isNotNull);

        await editor.nukeExperimentalData();

        expect(editor.isExperimentalMode.value, isFalse);
        expect(editor.editorUrl.value, isNull);
      },
    );

    test(
      'activateExperimental adiciona http:// se a URL não tiver esquema',
      () async {
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
      },
    );
  });
}
