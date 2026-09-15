// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/http/servico_croqui_online.dart';
import 'package:frontend/services/dataset/sessao_online/gerenciador_sessao_online.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../../mocks/mock_app_logger.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getTemporaryPath() async => tempPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
}

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
    test('carregarCroquiRemoto baixa, desserializa e registra na sessão online e salva no temp_cache com hash', () async {
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
        'https://servidor.com/croquis/pico_online/compilado.binarypb?v=hash123',
        picoId: 'pico_online',
        checksumSha256: 'hash123',
      );

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Pedra do Elefante'));
      expect(sessaoOnline.obterCroquiOnline('pico_online'), isNotNull);
      expect(sessaoOnline.obterEtag('pico_online'), equals('"v1-hash"'));

      final arquivoCache = File('${tempDir.path}/pico_online/compilado.binarypb.hash123');
      expect(await arquivoCache.exists(), isTrue);
    });

    test('carregarCroquiRemoto reutiliza arquivo já existente no temp_cache sem fazer requisição HTTP', () async {
      final croquiMock = Croqui(id: 'pico_cached', nome: 'Pico do Cache');
      final bytes = croquiMock.writeToBuffer();

      final cacheDir = Directory('${tempDir.path}/pico_cached')..createSync(recursive: true);
      final arquivoCache = File('${cacheDir.path}/compilado.binarypb.hash999');
      await arquivoCache.writeAsBytes(bytes);

      final resultado = await servico.carregarCroquiRemoto(
        'https://servidor.com/pico_cached/compilado.binarypb?v=hash999',
        picoId: 'pico_cached',
        checksumSha256: 'hash999',
      );

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Pico do Cache'));
      expect(sessaoOnline.obterCroquiOnline('pico_cached'), isNotNull);

      // Garante que NENHUMA chamada HTTP foi feita ao client
      verifyNever(() => mockClient.get(any(), headers: any(named: 'headers')));
    });

    test('carregarCroquiRemoto expurga versões anteriores do compilado.binarypb no temp_cache', () async {
      final cacheDir = Directory('${tempDir.path}/pico_expurgo')..createSync(recursive: true);
      final arquivoAntigo = File('${cacheDir.path}/compilado.binarypb.hash_antigo');
      await arquivoAntigo.writeAsBytes([1, 2, 3]);

      final arquivoLegado = File('${cacheDir.path}/pico_expurgo.binarypb');
      await arquivoLegado.writeAsBytes([4, 5, 6]);

      expect(await arquivoAntigo.exists(), isTrue);
      expect(await arquivoLegado.exists(), isTrue);

      final croquiNovo = Croqui(id: 'pico_expurgo', nome: 'Pico Novo');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response.bytes(croquiNovo.writeToBuffer(), 200));

      final resultado = await servico.carregarCroquiRemoto(
        'https://servidor.com/pico_expurgo/compilado.binarypb?v=hash_novo',
        picoId: 'pico_expurgo',
        checksumSha256: 'hash_novo',
      );

      expect(resultado, isNotNull);

      final arquivoNovo = File('${cacheDir.path}/compilado.binarypb.hash_novo');
      expect(await arquivoNovo.exists(), isTrue);
      expect(await arquivoAntigo.exists(), isFalse, reason: 'Versão antiga deve ser expurgada');
      expect(await arquivoLegado.exists(), isFalse, reason: 'Arquivo legado deve ser expurgado');
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

    test('carregarCroquiRemoto trata exceções de rede (ex: SocketException) retornando null', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(const SocketException('Falha de conexão com o servidor'));

      final resultado = await servico.carregarCroquiRemoto(
        'https://servidor.com/croquis/pico_offline.binarypb',
        picoId: 'pico_offline',
      );

      expect(resultado, isNull);
      expect(sessaoOnline.obterCroquiOnline('pico_offline'), isNull);
    });

    test('verificarAtualizacaoEtag trata exceções de rede retornando false', () async {
      sessaoOnline.registrarCroquiOnline(
        'pico_1',
        Croqui(id: 'pico_1'),
        etag: '"etag_atual"',
      );

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenThrow(const HttpException('Conexão abortada'));

      final houveAtualizacao = await servico.verificarAtualizacaoEtag(
        'pico_1',
        'https://servidor.com/pico_1.binarypb',
      );

      expect(houveAtualizacao, isFalse);
    });

    test('iniciarPollingEtag gerencia timers e cancelarPolling encerra polling específico', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 304));

      servico.iniciarPollingEtag(
        'pico_1',
        'https://servidor.com/pico_1.binarypb',
        intervalo: const Duration(milliseconds: 100),
      );

      // Inicia polling para um segundo pico
      servico.iniciarPollingEtag(
        'pico_2',
        'https://servidor.com/pico_2.binarypb',
        intervalo: const Duration(milliseconds: 100),
      );

      // Cancela o polling de pico_1
      servico.cancelarPolling('pico_1');

      // Cancelar de pico inexistente não gera erro
      expect(() => servico.cancelarPolling('pico_inexistente'), returnsNormally);

      // Dispose cancela todos os timers restantes
      servico.dispose();
    });

    test('iniciarPollingEtag não agenda timer se o pico já estiver baixado', () async {
      final servicoComCheck = ServicoCroquiOnline(
        client: mockClient,
        sessaoOnline: sessaoOnline,
        caminhoCacheVolatil: tempDir.path,
        verificarPicoBaixado: (id) => id == 'pico_baixado',
      );

      servicoComCheck.iniciarPollingEtag(
        'pico_baixado',
        'https://servidor.com/pico_baixado.binarypb',
      );

      expect(servicoComCheck.isPollingAtivo('pico_baixado'), isFalse);
      verifyNever(() => mockClient.get(any(), headers: any(named: 'headers')));
      servicoComCheck.dispose();
    });

    test('verificarAtualizacaoEtag cancela polling e não faz requisição HTTP se o pico estiver baixado', () async {
      bool baixado = false;
      final servicoComCheck = ServicoCroquiOnline(
        client: mockClient,
        sessaoOnline: sessaoOnline,
        caminhoCacheVolatil: tempDir.path,
        verificarPicoBaixado: (id) => baixado,
      );

      sessaoOnline.registrarCroquiOnline('pico_1', Croqui(id: 'pico_1'), etag: 'etag1');
      servicoComCheck.iniciarPollingEtag(
        'pico_1',
        'https://servidor.com/pico_1.binarypb',
      );
      expect(servicoComCheck.isPollingAtivo('pico_1'), isTrue);

      // Simula que o download acabou de ser concluído
      baixado = true;

      final resultado = await servicoComCheck.verificarAtualizacaoEtag(
        'pico_1',
        'https://servidor.com/pico_1.binarypb',
      );

      expect(resultado, isFalse);
      expect(servicoComCheck.isPollingAtivo('pico_1'), isFalse);
      verifyNever(() => mockClient.get(any(), headers: any(named: 'headers')));
      servicoComCheck.dispose();
    });

    test('verificarAtualizacaoEtag cancela polling e não faz requisição HTTP se a sessão online foi encerrada', () async {
      servico.iniciarPollingEtag(
        'pico_sem_sessao',
        'https://servidor.com/pico_sem_sessao.binarypb',
      );
      expect(servico.isPollingAtivo('pico_sem_sessao'), isTrue);

      // A sessão online não possui o pico registrado (ou foi removida)
      expect(sessaoOnline.obterCroquiOnline('pico_sem_sessao'), isNull);

      final resultado = await servico.verificarAtualizacaoEtag(
        'pico_sem_sessao',
        'https://servidor.com/pico_sem_sessao.binarypb',
      );

      expect(resultado, isFalse);
      expect(servico.isPollingAtivo('pico_sem_sessao'), isFalse);
      verifyNever(() => mockClient.get(any(), headers: any(named: 'headers')));
    });

    test('verificarAtualizacaoEtag com 200 processa bytes, atualiza sessão online e grava em cache volátil', () async {
      sessaoOnline.registrarCroquiOnline(
        'pico_1',
        Croqui(id: 'pico_1', nome: 'Pedra Velha'),
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
      // Deve ter atualizado o croqui diretamente em memória
      expect(sessaoOnline.obterCroquiOnline('pico_1')?.nome, equals('Pedra Nova'));
      expect(sessaoOnline.obterEtag('pico_1'), equals('"etag_novo"'));

      // Deve ter salvo cópia no cache volátil
      final arquivoCache = File('${tempDir.path}/pico_1/compilado.binarypb');
      expect(await arquivoCache.exists(), isTrue);
      expect(await arquivoCache.readAsBytes(), equals(croquiAtualizado.writeToBuffer()));
    });

    test('recarregarCroquiOnline baixa com bypass de cache (?t=) e atualiza sessão online', () async {
      sessaoOnline.registrarCroquiOnline(
        'pico_1',
        Croqui(id: 'pico_1', nome: 'Pedra Antes'),
        etag: '"etag_1"',
      );

      final croquiRecarregado = Croqui(id: 'pico_1', nome: 'Pedra Recarregada');
      when(() => mockClient.get(
            any(that: predicate<Uri>((uri) => uri.queryParameters.containsKey('t'))),
          )).thenAnswer(
        (_) async => http.Response.bytes(
          croquiRecarregado.writeToBuffer(),
          200,
          headers: {'etag': '"etag_2"'},
        ),
      );

      final resultado = await servico.recarregarCroquiOnline(
        'https://servidor.com/croquis/pico_1.binarypb',
        picoId: 'pico_1',
      );

      expect(resultado, isNotNull);
      expect(resultado?.nome, equals('Pedra Recarregada'));
      expect(sessaoOnline.obterCroquiOnline('pico_1')?.nome, equals('Pedra Recarregada'));
      expect(sessaoOnline.obterEtag('pico_1'), equals('"etag_2"'));

      final arquivoCache = File('${tempDir.path}/pico_1/compilado.binarypb');
      expect(await arquivoCache.exists(), isTrue);
      expect(await arquivoCache.readAsBytes(), equals(croquiRecarregado.writeToBuffer()));
    });

    test('usa getTemporaryDirectory quando caminhoCacheVolatil for nulo', () async {
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
      final servicoPadrao = ServicoCroquiOnline(
        client: mockClient,
        sessaoOnline: sessaoOnline,
      );

      final croquiMock = Croqui(id: 'pico_default', nome: 'Pedra Default');
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response.bytes(croquiMock.writeToBuffer(), 200),
      );

      final res = await servicoPadrao.carregarCroquiRemoto(
        'https://servidor.com/croqui.binarypb',
        picoId: 'pico_default',
      );
      expect(res, isNotNull);
      expect(res?.nome, equals('Pedra Default'));
      servicoPadrao.dispose();
    });

    test('recarregarCroquiOnline retorna null se ocorrer exceção ao processar URL', () async {
      final resultado = await servico.recarregarCroquiOnline(
        '::url-invalida::',
        picoId: 'pico_invalido',
      );
      expect(resultado, isNull);
    });

    test('verificarAtualizacaoEtag com 200 e bytes corrompidos trata exceção e retorna true', () async {
      sessaoOnline.registrarCroquiOnline('pico_corrompido', Croqui(id: 'pico_corrompido'), etag: '"etag_1"');
      when(() => mockClient.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response.bytes(Uint8List.fromList([255, 255, 255]), 200, headers: {'etag': '"etag_2"'}),
      );

      final resultado = await servico.verificarAtualizacaoEtag(
        'pico_corrompido',
        'https://servidor.com/croqui.binarypb',
      );

      expect(resultado, isTrue);
      expect(sessaoOnline.atualizacoesPendentes.value['pico_corrompido'], equals('"etag_2"'));
    });

    test('iniciarPollingEtag com callback aoAtualizar executa verificação no timer periódico', () async {
      sessaoOnline.registrarCroquiOnline('pico_timer', Croqui(id: 'pico_timer', nome: 'Pedra Timer'), etag: '"etag_1"');
      final novoCroqui = Croqui(id: 'pico_timer', nome: 'Pedra Timer Nova');

      when(() => mockClient.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response.bytes(novoCroqui.writeToBuffer(), 200, headers: {'etag': '"etag_2"'}),
      );

      bool callbackChamado = false;
      servico.iniciarPollingEtag(
        'pico_timer',
        'https://servidor.com/croqui.binarypb',
        intervalo: const Duration(milliseconds: 20),
        aoAtualizar: (id, croqui) {
          callbackChamado = true;
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(callbackChamado, isTrue);
      servico.cancelarPolling('pico_timer');
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('instanciação padrão usa http.Client() padrão', () {
      final s = ServicoCroquiOnline(sessaoOnline: sessaoOnline);
      expect(s, isNotNull);
      s.dispose();
    });

    test('_salvarEmCacheVolatil trata exceção ao falhar gravação em disco e registra via logError', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      final arquivoFalso = File('${tempDir.path}/bloqueio');
      await arquivoFalso.writeAsString('bloqueado');

      final servicoComErroCache = ServicoCroquiOnline(
        client: mockClient,
        sessaoOnline: sessaoOnline,
        caminhoCacheVolatil: arquivoFalso.path,
      );

      final croquiMock = Croqui(id: 'pico_erro_cache', nome: 'Pedra Erro Cache');
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response.bytes(croquiMock.writeToBuffer(), 200),
      );

      final res = await servicoComErroCache.carregarCroquiRemoto(
        'https://servidor.com/croqui.binarypb',
        picoId: 'sub_bloqueio',
      );
      expect(res, isNotNull);

      expect(mockLogger.recordedErrors, isNotEmpty);
      final recorded = mockLogger.recordedErrors.firstWhere(
        (e) => e['contextMessage'].contains('[ServicoCroquiOnline] Falha ao gravar cache volátil'),
      );
      expect(recorded['stackTrace'], isNotNull);

      servicoComErroCache.dispose();
    });
  });
}

