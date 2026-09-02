// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/http/servico_croqui_online.dart';
import 'package:frontend/services/dataset/sessao_online/gerenciador_sessao_online.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late GerenciadorSessaoOnline sessaoOnline;
  late ServicoCroquiOnline servico;
  late Directory tempDir;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://exemplo.com'));
  });

  setUp(() async {
    mockClient = MockHttpClient();
    sessaoOnline = GerenciadorSessaoOnline();
    tempDir = await Directory.systemTemp.createTemp('online_test_');
    servico = ServicoCroquiOnline(
      client: mockClient,
      sessaoOnline: sessaoOnline,
      caminhoCacheVolatil: tempDir.path,
    );
  });

  tearDown(() async {
    servico.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ServicoCroquiOnline', () {
    test('carregarCroquiRemoto baixa, desserializa e registra na sessão online', () async {
      final croquiMock = Croqui(id: 'pico_online', nome: 'Pedra do Elefante');
      final bytes = croquiMock.writeToBuffer();

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer(
        (_) async => http.Response.bytes(
          bytes,
          200,
          headers: {'etag': '"v1-hash"'},
        ),
      );

      final resultado = await servico.carregarCroquiRemoto(
        'https://servidor.com/croquis/pico_online.binarypb',
        picoId: 'pico_online',
      );

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Pedra do Elefante'));
      expect(sessaoOnline.obterCroquiOnline('pico_online'), isNotNull);
      expect(sessaoOnline.obterEtag('pico_online'), equals('"v1-hash"'));

      final arquivoCache = File('${tempDir.path}/pico_online/pico_online.binarypb');
      expect(await arquivoCache.exists(), isTrue);
    });

    test('carregarCroquiRemoto retorna null em caso de erro HTTP 404', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      final resultado = await servico.carregarCroquiRemoto(
        'https://servidor.com/croquis/pico_404.binarypb',
        picoId: 'pico_404',
      );

      expect(resultado, isNull);
      expect(sessaoOnline.obterCroquiOnline('pico_404'), isNull);
    });

    test('verificarAtualizacaoEtag com 304 não gera atualização pendente', () async {
      sessaoOnline.registrarCroquiOnline(
        'pico_1',
        Croqui(id: 'pico_1'),
        etag: '"etag_atual"',
      );

      when(() => mockClient.get(
            any(),
            headers: {'If-None-Match': '"etag_atual"'},
          )).thenAnswer((_) async => http.Response('', 304));

      final houveAtualizacao = await servico.verificarAtualizacaoEtag(
        'pico_1',
        'https://servidor.com/pico_1.binarypb',
      );

      expect(houveAtualizacao, isFalse);
      expect(sessaoOnline.atualizacoesPendentes.value.containsKey('pico_1'), isFalse);
    });

    test('verificarAtualizacaoEtag com 200 registra atualização pendente', () async {
      sessaoOnline.registrarCroquiOnline(
        'pico_1',
        Croqui(id: 'pico_1'),
        etag: '"etag_antigo"',
      );

      final croquiAtualizado = Croqui(id: 'pico_1', nome: 'Pedra Nova');
      when(() => mockClient.get(
            any(),
            headers: {'If-None-Match': '"etag_antigo"'},
          )).thenAnswer(
        (_) async => http.Response.bytes(
          croquiAtualizado.writeToBuffer(),
          200,
          headers: {'etag': '"etag_novo"'},
        ),
      );

      final houveAtualizacao = await servico.verificarAtualizacaoEtag(
        'pico_1',
        'https://servidor.com/pico_1.binarypb',
      );

      expect(houveAtualizacao, isTrue);
      expect(sessaoOnline.atualizacoesPendentes.value['pico_1'], equals('"etag_novo"'));
    });
  });
}
