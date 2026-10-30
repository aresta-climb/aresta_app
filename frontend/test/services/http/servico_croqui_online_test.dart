// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:frontend/services/http/servico_croqui_online.dart';
import 'package:frontend/services/dataset/sessao_online/gerenciador_sessao_online.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/utils/construtor_caminho_trajeto.dart';
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
      client: ClienteHttpAresta.paraTestes(mockClient),
      sessaoOnline: sessaoOnline,
      caminhoCacheVolatil: tempDir.path,
    );
  });

  tearDown(() async {
    servico.dispose();
    verifyNever(() => mockClient.close());
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ServicoCroquiOnline', () {
    test('carregarCroquiRemoto calcula SHA-256 real em memória na chegada do HTTP, grava atomicamente no temp_cache e registra na sessão online mesmo se a URL tinha ?v=hash_antigo', () async {
      final croquiMock = Croqui(id: 'pico_online', nome: 'Pedra do Elefante');
      final bytes = croquiMock.writeToBuffer();
      final hashReal = sha256.convert(bytes).toString();

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
        'https://servidor.com/croquis/pico_online/compilado.binarypb?v=hash_antigo_despejado_pela_cdn',
        picoId: 'pico_online',
        checksumSha256: 'hash_antigo_despejado_pela_cdn',
      );

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Pedra do Elefante'));
      expect(sessaoOnline.obterCroquiOnline('pico_online'), isNotNull);
      expect(sessaoOnline.obterEtag('pico_online'), equals('"v1-hash"'));
      expect(sessaoOnline.obterChecksum('pico_online'), equals(hashReal));

      final arquivoCacheReal = File('${tempDir.path}/pico_online/compilado.binarypb.$hashReal');
      final arquivoTmp = File('${tempDir.path}/pico_online/compilado.binarypb.$hashReal.tmp');
      final arquivoHashAntigo = File('${tempDir.path}/pico_online/compilado.binarypb.hash_antigo_despejado_pela_cdn');
      expect(await arquivoCacheReal.exists(), isTrue);
      expect(await arquivoTmp.exists(), isFalse);
      expect(await arquivoHashAntigo.exists(), isFalse);
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

    test('carregarCroquiRemoto expurga versões anteriores do compilado.binarypb no temp_cache após gravação atômica', () async {
      final cacheDir = Directory('${tempDir.path}/pico_expurgo')..createSync(recursive: true);
      final arquivoAntigo = File('${cacheDir.path}/compilado.binarypb.hash_antigo');
      await arquivoAntigo.writeAsBytes([1, 2, 3]);

      final arquivoLegado = File('${cacheDir.path}/pico_expurgo.binarypb');
      await arquivoLegado.writeAsBytes([4, 5, 6]);

      expect(await arquivoAntigo.exists(), isTrue);
      expect(await arquivoLegado.exists(), isTrue);

      final croquiNovo = Croqui(id: 'pico_expurgo', nome: 'Pico Novo');
      final bytesNovo = croquiNovo.writeToBuffer();
      final hashRealNovo = sha256.convert(bytesNovo).toString();
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response.bytes(bytesNovo, 200));

      final resultado = await servico.carregarCroquiRemoto(
        'https://servidor.com/pico_expurgo/compilado.binarypb?v=$hashRealNovo',
        picoId: 'pico_expurgo',
        checksumSha256: hashRealNovo,
      );

      expect(resultado, isNotNull);

      final arquivoNovo = File('${cacheDir.path}/compilado.binarypb.$hashRealNovo');
      expect(await arquivoNovo.exists(), isTrue);
      expect(await arquivoAntigo.exists(), isFalse, reason: 'Versão antiga deve ser expurgada');
      expect(await arquivoLegado.exists(), isFalse, reason: 'Arquivo legado deve ser expurgado');
    });

    test('carregarCroquiRemoto usa versão anterior de compilado.binarypb.* no temp_cache como fallback de emergência quando a rede falha', () async {
      final cacheDir = Directory('${tempDir.path}/pico_fallback')..createSync(recursive: true);
      final croquiAnterior = Croqui(id: 'pico_fallback', nome: 'Pico Salva-Vidas');
      final arquivoAntigo = File('${cacheDir.path}/compilado.binarypb.hash_antigo_salvo');
      await arquivoAntigo.writeAsBytes(croquiAnterior.writeToBuffer());

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(const SocketException('Sem conexão na rocha'));

      final resultado = await servico.carregarCroquiRemoto(
        'https://servidor.com/pico_fallback/compilado.binarypb?v=hash_novo_indice',
        picoId: 'pico_fallback',
        checksumSha256: 'hash_novo_indice',
      );

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Pico Salva-Vidas'));
      expect(sessaoOnline.obterCroquiOnline('pico_fallback')?.nome, equals('Pico Salva-Vidas'));
      expect(sessaoOnline.obterChecksum('pico_fallback'), equals('hash_antigo_salvo'));
      expect(await arquivoAntigo.exists(), isTrue);
    });

    test('carregarCroquiRemoto ignora arquivos .tmp ou corrompidos no fallback offline do temp_cache e retorna null', () async {
      final cacheDir = Directory('${tempDir.path}/pico_fallback_corrompido')..createSync(recursive: true);
      await File('${cacheDir.path}/compilado.binarypb.hash1.tmp').writeAsBytes(
        Croqui(id: 'pico_fallback_corrompido', nome: 'Incompleto').writeToBuffer(),
      );
      await File('${cacheDir.path}/compilado.binarypb.hash_corrompido').writeAsBytes([255, 255, 255]);

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(const SocketException('Sem conexão na rocha'));

      final resultado = await servico.carregarCroquiRemoto(
        'https://servidor.com/pico_fallback_corrompido/compilado.binarypb?v=hash_novo',
        picoId: 'pico_fallback_corrompido',
        checksumSha256: 'hash_novo',
      );

      expect(resultado, isNull);
    });

    test('carregarCroquiRemoto recupera da rede quando o arquivo do hash esperado no temp_cache está corrompido e anexa ?v= quando ausente na URL', () async {
      expect(servico.sessaoOnline, same(sessaoOnline));
      expect(servico.caminhoCacheVolatil, equals(tempDir.path));
      expect(await servico.obterDiretorioCache(), equals(tempDir.path));

      final cacheDir = Directory('${tempDir.path}/pico_corrompido_cache')..createSync(recursive: true);
      final croquiValido = Croqui(id: 'pico_corrompido_cache', nome: 'Pico Recuperado');
      final bytesValidos = croquiValido.writeToBuffer();
      final hashEsperado = sha256.convert(bytesValidos).toString();

      await File('${cacheDir.path}/compilado.binarypb.$hashEsperado').writeAsBytes([255, 255, 255]);

      Uri? uriRequisitada;
      when(() => mockClient.get(any(), headers: any(named: 'headers'))).thenAnswer((inv) async {
        uriRequisitada = inv.positionalArguments.first as Uri;
        return http.Response.bytes(bytesValidos, 200);
      });

      final resultado = await servico.carregarCroquiRemoto(
        'https://servidor.com/pico_corrompido_cache/compilado.binarypb',
        picoId: 'pico_corrompido_cache',
        checksumSha256: hashEsperado,
      );

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Pico Recuperado'));
      expect(uriRequisitada?.queryParameters['v'], equals(hashEsperado));
    });

    test('carregarCroquiRemoto retorna null em caso de erro HTTP 404 sem retentar erro permanente', () async {
      var chamadas = 0;
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        chamadas++;
        return http.Response('Not Found', 404);
      });

      final resultado = await servico.carregarCroquiRemoto(
        'https://servidor.com/croquis/pico_404.binarypb',
        picoId: 'pico_404',
      );

      expect(resultado, isNull);
      expect(chamadas, equals(1), reason: 'HTTP 404 não é falha transitória e não deve retentar');
      expect(sessaoOnline.obterCroquiOnline('pico_404'), isNull);
    });

    test('carregarCroquiRemoto realiza 2 tentativas escalonadas e recupera quando a 1ª tentativa sofre timeout ou erro de socket Keep-Alive zumbi', () async {
      expect(
        ServicoCroquiOnline.padraoTimeoutsTentativas,
        equals(const [Duration(seconds: 4), Duration(seconds: 6)]),
      );
      expect(
        ServicoCroquiOnline.padraoIntervaloEntreTentativas,
        equals(const Duration(milliseconds: 350)),
      );

      final servicoComTimeoutsCurtos = ServicoCroquiOnline(
        client: ClienteHttpAresta.paraTestes(mockClient),
        sessaoOnline: sessaoOnline,
        caminhoCacheVolatil: tempDir.path,
        timeoutsTentativas: const [
          Duration(milliseconds: 30),
          Duration(milliseconds: 150),
        ],
        intervaloEntreTentativas: const Duration(milliseconds: 10),
      );

      final croquiValido = Croqui(id: 'pico_retry', nome: 'Pico Recuperado na 2a Tentativa');
      final bytesValidos = croquiValido.writeToBuffer();

      var tentativa = 0;
      when(() => mockClient.get(any(), headers: any(named: 'headers'))).thenAnswer((_) async {
        tentativa++;
        if (tentativa == 1) {
          // Simula buraco negro pós-TCP que estoura o timeout de 30ms da 1ª tentativa
          await Future<void>.delayed(const Duration(milliseconds: 80));
          return http.Response.bytes(bytesValidos, 200);
        }
        return http.Response.bytes(bytesValidos, 200);
      });

      final resultado = await servicoComTimeoutsCurtos.carregarCroquiRemoto(
        'https://servidor.com/pico_retry/compilado.binarypb?v=hash_retry',
        picoId: 'pico_retry',
        checksumSha256: 'hash_retry',
      );

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Pico Recuperado na 2a Tentativa'));
      expect(tentativa, equals(2));
    });

    test('carregarCroquiRemoto retenta na 2ª tentativa quando a 1ª tentativa retorna erro HTTP transitório (503)', () async {
      final servicoRapido = ServicoCroquiOnline(
        client: ClienteHttpAresta.paraTestes(mockClient),
        sessaoOnline: sessaoOnline,
        caminhoCacheVolatil: tempDir.path,
        intervaloEntreTentativas: const Duration(milliseconds: 5),
      );

      final croquiValido = Croqui(id: 'pico_503', nome: 'Pico Após 503');
      final bytesValidos = croquiValido.writeToBuffer();

      var tentativa = 0;
      when(() => mockClient.get(any(), headers: any(named: 'headers'))).thenAnswer((_) async {
        tentativa++;
        if (tentativa == 1) {
          return http.Response('Service Unavailable', 503);
        }
        return http.Response.bytes(bytesValidos, 200);
      });

      final resultado = await servicoRapido.carregarCroquiRemoto(
        'https://servidor.com/pico_503/compilado.binarypb?v=hash_503',
        picoId: 'pico_503',
        checksumSha256: 'hash_503',
      );

      expect(resultado, isNotNull);
      expect(resultado!.nome, equals('Pico Após 503'));
      expect(tentativa, equals(2));
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

    test('carregarCroquiRemoto trata exceções de rede (ex: SocketException) retornando null e registrando apenas logAviso', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(const SocketException('Falha de conexão com o servidor'));

      final resultado = await servico.carregarCroquiRemoto(
        'https://servidor.com/croquis/pico_offline.binarypb',
        picoId: 'pico_offline',
      );

      expect(resultado, isNull);
      expect(sessaoOnline.obterCroquiOnline('pico_offline'), isNull);
      expect(mockLogger.recordedErrors, isEmpty);
      expect(mockLogger.recordedWarnings, isNotEmpty);
    });

    test('carregarCroquiRemoto registra erro no Crashlytics em caso de HTTP 500/404 e apenas logAviso em HTTP 503 transitório', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Server error', 500));

      final resultado500 = await servico.carregarCroquiRemoto(
        'https://servidor.com/croquis/pico_500.binarypb',
        picoId: 'pico_500',
      );

      expect(resultado500, isNull);
      expect(mockLogger.recordedErrors, isNotEmpty);

      mockLogger.recordedErrors.clear();
      mockLogger.recordedWarnings.clear();

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Service Unavailable', 503));

      final resultado503 = await servico.carregarCroquiRemoto(
        'https://servidor.com/croquis/pico_503.binarypb',
        picoId: 'pico_503',
      );

      expect(resultado503, isNull);
      expect(mockLogger.recordedErrors, isEmpty);
      expect(mockLogger.recordedWarnings, isNotEmpty);
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
        client: ClienteHttpAresta.paraTestes(mockClient),
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
        client: ClienteHttpAresta.paraTestes(mockClient),
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

    test('verificarAtualizacaoEtag e timer de polling permanecem dormentes sem disparar HTTP quando WebSocket de Live Reload estiver conectado', () async {
      bool wsConectado = true;
      final servicoComWs = ServicoCroquiOnline(
        client: ClienteHttpAresta.paraTestes(mockClient),
        sessaoOnline: sessaoOnline,
        caminhoCacheVolatil: tempDir.path,
        verificarLiveReloadAtivo: () => wsConectado,
      );

      sessaoOnline.registrarCroquiOnline('pico_ws', Croqui(id: 'pico_ws'), etag: 'etag1');

      // 1. Com WebSocket conectado, verificarAtualizacaoEtag retorna false e não dispara HTTP
      final resultadoComWs = await servicoComWs.verificarAtualizacaoEtag(
        'pico_ws',
        'https://servidor.com/pico_ws.binarypb',
      );
      expect(resultadoComWs, isFalse);
      verifyNever(() => mockClient.get(any(), headers: any(named: 'headers')));

      // 2. Quando o WebSocket cai (wsConectado = false), o polling volta a executar normalmente
      wsConectado = false;
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 304));

      final resultadoSemWs = await servicoComWs.verificarAtualizacaoEtag(
        'pico_ws',
        'https://servidor.com/pico_ws.binarypb',
      );
      expect(resultadoSemWs, isFalse);
      verify(() => mockClient.get(any(), headers: any(named: 'headers'))).called(1);

      servicoComWs.dispose();
    });

    test('verificarAtualizacaoEtag com 200 processa bytes, atualiza sessão online e grava em cache volátil com hash real', () async {
      sessaoOnline.registrarCroquiOnline(
        'pico_1',
        Croqui(id: 'pico_1', nome: 'Pedra Velha'),
        etag: '"etag_antigo"',
      );

      final croquiAtualizado = Croqui(id: 'pico_1', nome: 'Pedra Nova');
      final bytesAtualizados = croquiAtualizado.writeToBuffer();
      final hashReal = sha256.convert(bytesAtualizados).toString();
      when(() => mockClient.get(
            any(),
            headers: {'If-None-Match': '"etag_antigo"'},
          )).thenAnswer(
        (_) async => http.Response.bytes(
          bytesAtualizados,
          200,
          headers: {'etag': '"etag_novo"'},
        ),
      );

      final houveAtualizacao = await servico.verificarAtualizacaoEtag(
        'pico_1',
        'https://servidor.com/pico_1.binarypb',
      );

      expect(houveAtualizacao, isTrue);
      // Deve ter atualizado o croqui diretamente em memória com o hash real
      expect(sessaoOnline.obterCroquiOnline('pico_1')?.nome, equals('Pedra Nova'));
      expect(sessaoOnline.obterEtag('pico_1'), equals('"etag_novo"'));
      expect(sessaoOnline.obterChecksum('pico_1'), equals(hashReal));

      // Deve ter salvo cópia no cache volátil com o hash real
      final arquivoCache = File('${tempDir.path}/pico_1/compilado.binarypb.$hashReal');
      expect(await arquivoCache.exists(), isTrue);
      expect(await arquivoCache.readAsBytes(), equals(bytesAtualizados));
    });

    test('recarregarCroquiOnline baixa com bypass de cache (?t=) e atualiza sessão online', () async {
      sessaoOnline.registrarCroquiOnline(
        'pico_1',
        Croqui(id: 'pico_1', nome: 'Pedra Antes'),
        etag: '"etag_1"',
      );

      final croquiRecarregado = Croqui(id: 'pico_1', nome: 'Pedra Recarregada');
      final bytesRecarregado = croquiRecarregado.writeToBuffer();
      final hashReal = sha256.convert(bytesRecarregado).toString();
      when(() => mockClient.get(
            any(that: predicate<Uri>((uri) => uri.queryParameters.containsKey('t'))),
          )).thenAnswer(
        (_) async => http.Response.bytes(
          bytesRecarregado,
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
      expect(sessaoOnline.obterChecksum('pico_1'), equals(hashReal));

      final arquivoCache = File('${tempDir.path}/pico_1/compilado.binarypb.$hashReal');
      expect(await arquivoCache.exists(), isTrue);
      expect(await arquivoCache.readAsBytes(), equals(bytesRecarregado));
    });

    test('usa getTemporaryDirectory quando caminhoCacheVolatil for nulo', () async {
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
      final servicoPadrao = ServicoCroquiOnline(
        client: ClienteHttpAresta.paraTestes(mockClient),
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
        client: ClienteHttpAresta.paraTestes(mockClient),
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

    test('verificarAtualizacaoEtag com SocketException registra logAviso e não dispara logError', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      sessaoOnline.registrarCroquiOnline('pico_offline', Croqui(id: 'pico_offline'), etag: '"etag_1"');
      when(() => mockClient.get(any(), headers: any(named: 'headers'))).thenThrow(
        const SocketException('Failed host lookup: serving.arestaclimb.com'),
      );

      final resultado = await servico.verificarAtualizacaoEtag(
        'pico_offline',
        'https://servidor.com/croqui.binarypb',
      );

      expect(resultado, isFalse);
      expect(mockLogger.recordedErrors, isEmpty);
      expect(mockLogger.recordedWarnings, isNotEmpty);
      expect(
        mockLogger.recordedWarnings.any((w) => w.contains('Verificação de ETag ignorada: sem conexão com a internet')),
        isTrue,
      );
    });

    test('verificarAtualizacaoEtag com erro inesperado registra logError', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;

      sessaoOnline.registrarCroquiOnline('pico_inesperado', Croqui(id: 'pico_inesperado'), etag: '"etag_1"');
      when(() => mockClient.get(any(), headers: any(named: 'headers'))).thenThrow(
        const FormatException('Malformed payload'),
      );

      final resultado = await servico.verificarAtualizacaoEtag(
        'pico_inesperado',
        'https://servidor.com/croqui.binarypb',
      );

      expect(resultado, isFalse);
      expect(mockLogger.recordedErrors, isNotEmpty);
    });

    test('verificarAtualizacaoEtag com 200 OK deve limpar o cache de caminhos em ConstrutorCaminhoTrajeto', () async {
      const picoId = 'pico_etag_200';
      sessaoOnline.registrarCroquiOnline(picoId, Croqui(id: picoId), etag: '"etag_velho"');

      const chaveLinha = 'mapa_teste#linha_etag';
      final path1 = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: chaveLinha,
        caminhoSvg: 'M 0 0 L 20 20',
        estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
      );

      final novoCroqui = Croqui(id: picoId)..picos.add(Pico()..nome = 'Versão Nova');
      when(() => mockClient.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response(
          String.fromCharCodes(novoCroqui.writeToBuffer()),
          200,
          headers: {'etag': '"etag_novo"'},
        ),
      );

      final resultado = await servico.verificarAtualizacaoEtag(
        picoId,
        'https://servidor.com/croqui.binarypb',
      );

      expect(resultado, isTrue);

      final path2 = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: chaveLinha,
        caminhoSvg: 'M 0 0 L 20 20',
        estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
      );
      expect(identical(path1, path2), isFalse);
    });
  });
}
