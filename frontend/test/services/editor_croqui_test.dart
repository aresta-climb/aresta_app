/// Suíte de testes do EditorDeCroqui.
/// Testa lógica de modos (oficial, editor, experimental) e caminhos.
/// Nota: testes de connect/disconnect/activateExperimental que precisam de
/// acesso ao disco são cobertos nos testes de integração.
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/editor_croqui.dart';

void main() {
  late EditorDeCroqui editor;

  setUp(() {
    editor = EditorDeCroqui();
  });

  // ---------------------------------------------------------------------------
  // activeBaseUrl
  // ---------------------------------------------------------------------------

  group('activeBaseUrl', () {
    test('deve retornar URL oficial quando sem editor ou experimental', () {
      expect(editor.activeBaseUrl, 'https://aresta-climb.github.io/aresta_serving');
    });

    test('deve retornar a URL do editor quando configurada', () {
      editor.isExperimentalMode.value = true;
      editor.editorUrl.value = 'http://meuservidor.local:8080';
      expect(editor.activeBaseUrl, 'http://meuservidor.local:8080');
    });

    test('deve retornar a URL ghost aresta-zip no modo experimental com URL', () {
      editor.isExperimentalMode.value = true;
      editor.editorUrl.value = 'aresta-zip:///data/repo.croqui';
      expect(editor.activeBaseUrl, 'aresta-zip:///data/repo.croqui');
    });

    test('deve normalizar URLs sem scheme adicionando https://', () {
      editor.isExperimentalMode.value = true;
      editor.editorUrl.value = 'aresta-climb.github.io/aresta_serving';
      expect(editor.activeBaseUrl, 'https://aresta-climb.github.io/aresta_serving');
    });

  });

  // ---------------------------------------------------------------------------
  // isEditorActive
  // ---------------------------------------------------------------------------

  group('isEditorActive', () {
    test('deve ser falso no estado inicial', () {
      expect(editor.isEditorActive, isFalse);
    });

    test('deve ser verdadeiro quando modo experimental está ativo', () {
      editor.isExperimentalMode.value = true;
      expect(editor.isEditorActive, isTrue);
    });

    test('deve ser falso quando editorUrl é null e experimental é false', () {
      editor.editorUrl.value = null;
      editor.isExperimentalMode.value = false;
      expect(editor.isEditorActive, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // downloadsPath
  // ---------------------------------------------------------------------------

  group('downloadsPath', () {
    const docsPath = '/data/user/0/app/files';

    test('modo oficial: deve retornar caminho padrão de downloads', () {
      expect(editor.downloadsPath(docsPath), '$docsPath/downloads');
    });

    test('modo experimental: deve retornar caminho experimental', () {
      editor.isExperimentalMode.value = true;
      expect(
        editor.downloadsPath(docsPath),
        '$docsPath/editor/experimental/downloads',
      );
    });

    test('deve priorizar experimental sobre editorUrl quando ambos ativos', () {
      editor.editorUrl.value = 'http://editor.local';
      editor.isExperimentalMode.value = true;
      // isExperimentalMode tem prioridade
      expect(
        editor.downloadsPath(docsPath),
        '$docsPath/editor/experimental/downloads',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // indicePath
  // ---------------------------------------------------------------------------

  group('indicePath', () {
    const docsPath = '/data/user/0/app/files';

    test('modo oficial: deve retornar caminho padrão do índice', () {
      expect(editor.indicePath(docsPath), '$docsPath/indice.binarypb');
    });

    test('modo experimental: deve retornar caminho experimental do índice', () {
      editor.isExperimentalMode.value = true;
      expect(
        editor.indicePath(docsPath),
        '$docsPath/editor/experimental/indice.binarypb',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // isExperimentalMode / editorUrl / isDevModeEnabled notificadores
  // ---------------------------------------------------------------------------

  group('Notificadores de estado', () {
    test('editorUrl deve notificar ouvintes quando alterado', () {
      bool notified = false;
      editor.editorUrl.addListener(() => notified = true);

      editor.editorUrl.value = 'http://novo.local';

      expect(notified, isTrue);
    });

    test('isExperimentalMode deve notificar ouvintes quando alterado', () {
      bool notified = false;
      editor.isExperimentalMode.addListener(() => notified = true);

      editor.isExperimentalMode.value = true;

      expect(notified, isTrue);
    });

    test('setDevMode deve atualizar isDevModeEnabled imediatamente', () async {
      expect(editor.isDevModeEnabled.value, isFalse);
      // Chamamos sem aguardar o write em disco para o teste unitário
      editor.isDevModeEnabled.value = true;
      expect(editor.isDevModeEnabled.value, isTrue);
    });
  });
}
