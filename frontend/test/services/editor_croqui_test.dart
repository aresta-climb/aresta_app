// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Suíte de testes do EditorDeCroqui.
/// Testa lógica de modos (oficial, editor, experimental), resolução híbrida de conexão e caminhos.
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/constants/network_constants.dart';

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
      expect(editor.activeBaseUrl, NetworkConstants.officialServerUrl);
    });

    test('deve retornar a URL do editor quando configurada', () {
      editor.isExperimentalMode.value = true;
      editor.editorUrl.value = 'http://meuservidor.local:8080';
      expect(editor.activeBaseUrl, 'http://meuservidor.local:8080');
    });

    test(
      'deve retornar a URL ghost aresta-zip no modo experimental com URL',
      () {
        editor.isExperimentalMode.value = true;
        editor.editorUrl.value = 'aresta-zip:///data/repo.croqui';
        expect(editor.activeBaseUrl, 'aresta-zip:///data/repo.croqui');
      },
    );

    test('deve normalizar URLs sem scheme adicionando https://', () {
      editor.isExperimentalMode.value = true;
      editor.editorUrl.value = 'aresta-climb.github.io/aresta_serving';
      expect(
        editor.activeBaseUrl,
        'https://aresta-climb.github.io/aresta_serving',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Normalização e Extração de Código de Sessão
  // ---------------------------------------------------------------------------

  group('Normalização e Extração de Código', () {
    test('deve normalizar códigos de 8 caracteres em minúsculas sem hifens', () {
      expect(EditorDeCroqui.normalizarCodigo('K9X2-P83A'), 'k9x2p83a');
      expect(EditorDeCroqui.normalizarCodigo('  k9x2-p83a  '), 'k9x2p83a');
      expect(EditorDeCroqui.normalizarCodigo('k9x2 p83a'), 'k9x2p83a');
      expect(EditorDeCroqui.normalizarCodigo('k9x2p83a'), 'k9x2p83a');
      expect(EditorDeCroqui.normalizarCodigo('ABCDEFGH'), 'abcdefgh');
      expect(EditorDeCroqui.normalizarCodigo('abcd-efgh'), 'abcdefgh');
    });

    test('deve formatar código adicionando hífen no meio', () {
      expect(EditorDeCroqui.formatarCodigo('k9x2p83a'), 'k9x2-p83a');
      expect(EditorDeCroqui.formatarCodigo('K9X2P83A'), 'k9x2-p83a');
      expect(EditorDeCroqui.formatarCodigo('k9x2-p83a'), 'k9x2-p83a');
      expect(EditorDeCroqui.formatarCodigo('abcdefgh'), 'abcd-efgh');
      expect(EditorDeCroqui.formatarCodigo('curto'), 'curto');
    });

    test('deve extrair código de URL canônica previa.arestaclimb.com (com e sem hífen)', () {
      // Formato contínuo: abcdefgh
      expect(
        EditorDeCroqui.extrairCodigoPrevia('https://previa.arestaclimb.com/k9x2p83a'),
        'k9x2p83a',
      );
      expect(
        EditorDeCroqui.extrairCodigoPrevia('https://previa.arestaclimb.com/abcdefgh'),
        'abcdefgh',
      );

      // Formato com hífen: abcd-efgh
      expect(
        EditorDeCroqui.extrairCodigoPrevia('https://previa.arestaclimb.com/k9x2-p83a'),
        'k9x2p83a',
      );
      expect(
        EditorDeCroqui.extrairCodigoPrevia('https://previa.arestaclimb.com/abcd-efgh'),
        'abcdefgh',
      );

      // Sem https://
      expect(
        EditorDeCroqui.extrairCodigoPrevia('previa.arestaclimb.com/k9x2-p83a'),
        'k9x2p83a',
      );
      expect(
        EditorDeCroqui.extrairCodigoPrevia('previa.arestaclimb.com/abcdefgh'),
        'abcdefgh',
      );
      expect(
        EditorDeCroqui.extrairCodigoPrevia('previa.arestaclimb.com/abcd-efgh'),
        'abcdefgh',
      );

      // Scheme customizado aresta://
      expect(
        EditorDeCroqui.extrairCodigoPrevia('aresta://previa/k9x2p83a'),
        'k9x2p83a',
      );
      expect(
        EditorDeCroqui.extrairCodigoPrevia('aresta://previa/k9x2-p83a'),
        'k9x2p83a',
      );
      expect(
        EditorDeCroqui.extrairCodigoPrevia('aresta://previa/abcdefgh'),
        'abcdefgh',
      );
      expect(
        EditorDeCroqui.extrairCodigoPrevia('aresta://previa/abcd-efgh'),
        'abcdefgh',
      );

      // Código digitado diretamente
      expect(EditorDeCroqui.extrairCodigoPrevia('k9x2-p83a'), 'k9x2p83a');
      expect(EditorDeCroqui.extrairCodigoPrevia('k9x2p83a'), 'k9x2p83a');
      expect(EditorDeCroqui.extrairCodigoPrevia('abcd-efgh'), 'abcdefgh');
      expect(EditorDeCroqui.extrairCodigoPrevia('abcdefgh'), 'abcdefgh');
      expect(EditorDeCroqui.extrairCodigoPrevia('  ABCD-EFGH  '), 'abcdefgh');

      // URLs inválidas / não relacionadas
      expect(EditorDeCroqui.extrairCodigoPrevia('http://192.168.1.50:8421'), isNull);
      expect(EditorDeCroqui.extrairCodigoPrevia('https://outrodominio.com/k9x2p83a'), isNull);
      expect(EditorDeCroqui.extrairCodigoPrevia(''), isNull);
      expect(EditorDeCroqui.extrairCodigoPrevia('curto'), isNull);
      expect(EditorDeCroqui.extrairCodigoPrevia('codigo-muito-longo-invalido'), isNull);
      expect(EditorDeCroqui.extrairCodigoPrevia('k9x2!p83a'), isNull);
    });

    test('deve gerar URL canônica de prévia com hífen por padrão e sem hífen opcionalmente', () {
      expect(
        EditorDeCroqui.urlPreviaParaCodigo('k9x2p83a'),
        'https://previa.arestaclimb.com/k9x2-p83a',
      );
      expect(
        EditorDeCroqui.urlPreviaParaCodigo('k9x2-p83a'),
        'https://previa.arestaclimb.com/k9x2-p83a',
      );
      expect(
        EditorDeCroqui.urlPreviaParaCodigo('abcdefgh'),
        'https://previa.arestaclimb.com/abcd-efgh',
      );
      expect(
        EditorDeCroqui.urlPreviaParaCodigo('abcdefgh', comHifen: false),
        'https://previa.arestaclimb.com/abcdefgh',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Resolução Híbrida de Conexão (Smart LAN-First)
  // ---------------------------------------------------------------------------

  group('Resolução Híbrida (Smart LAN-First)', () {
    test('deve resolver para LAN local quando o handshake local responder 200', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/info')) {
          return http.Response(
            jsonEncode({
              'status': 'conectado',
              'local_url': 'http://192.168.1.50:8421',
            }),
            200,
          );
        }
        if (request.url.host == '192.168.1.50' && request.url.path == '/handshake') {
          return http.Response(jsonEncode({'status': 'conectado'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final urlResolvida = await editor.resolverUrlHibrida(
        'k9x2-p83a',
        client: mockClient,
      );

      expect(urlResolvida, 'http://192.168.1.50:8421');
    });

    test('deve fazer fallback para Cloudflare Relay quando a LAN falhar ou der timeout', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/info')) {
          return http.Response(
            jsonEncode({
              'status': 'conectado',
              'local_url': 'http://192.168.1.50:8421',
            }),
            200,
          );
        }
        if (request.url.host == '192.168.1.50') {
          throw Exception('Timeout / Rede inalcançável');
        }
        return http.Response('Not Found', 404);
      });

      final urlResolvida = await editor.resolverUrlHibrida(
        'k9x2-p83a',
        client: mockClient,
      );

      expect(urlResolvida, 'https://previa.arestaclimb.com/k9x2-p83a');
    });

    test('deve retornar URL direta quando não for código de prévia', () async {
      final urlResolvida = await editor.resolverUrlHibrida('http://192.168.1.100:9000');
      expect(urlResolvida, 'http://192.168.1.100:9000');
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
      editor.isDevModeEnabled.value = true;
      expect(editor.isDevModeEnabled.value, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // WebSocket Live Reload Eventos
  // ---------------------------------------------------------------------------

  group('WebSocket Live Reload', () {
    test('LiveReloadEvent deve armazenar setorId e timestamp corretamente', () {
      final now = DateTime.now();
      final evento = LiveReloadEvent(setorId: 'setor_123', timestamp: now);
      expect(evento.setorId, 'setor_123');
      expect(evento.timestamp, now);
    });

    test('eventoLiveReload notificador deve disparar quando novo evento for emitido', () {
      LiveReloadEvent? recebido;
      editor.eventoLiveReload.addListener(() {
        recebido = editor.eventoLiveReload.value;
      });

      final now = DateTime.now();
      editor.eventoLiveReload.value = LiveReloadEvent(
        setorId: 'br_mg_ferros_setor1',
        timestamp: now,
      );

      expect(recebido, isNotNull);
      expect(recebido!.setorId, 'br_mg_ferros_setor1');
      expect(recebido!.timestamp, now);
    });

    test('iniciarEscutaLiveReload e encerrarEscutaLiveReload devem lidar com URLs invalidas e fechar conexao sem excecao', () {
      expect(() => editor.iniciarEscutaLiveReload('https://url-invalida-sem-codigo.com'), returnsNormally);
      expect(() => editor.iniciarEscutaLiveReload('https://previa.arestaclimb.com/k9x2-p83a'), returnsNormally);
      expect(() => editor.encerrarEscutaLiveReload(), returnsNormally);
    });

    test('dispararPulsoRecarregamento deve incrementar notificadorGatilhoRecarregamento', () {
      expect(editor.notificadorGatilhoRecarregamento.value, 0);
      editor.dispararPulsoRecarregamento();
      expect(editor.notificadorGatilhoRecarregamento.value, 1);
    });
  });
}
