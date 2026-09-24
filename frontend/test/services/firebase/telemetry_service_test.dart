// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../../mocks/mock_app_logger.dart';
import '../../mocks/mock_telemetry_service.dart';

void main() {
  group('TelemetryService Mock Tests', () {
    late MockTelemetryService mockTelemetry;

    setUp(() {
      mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;
    });

    test('logAcaoExplorar', () async {
      await TelemetryService.instance.logAcaoExplorar('crag1', 'baixar');
      expect(mockTelemetry.recordedEvents, contains('acao_explorar'));
      expect(
        mockTelemetry.recordedParams['acao_explorar']!['id_croqui'],
        'crag1',
      );
      expect(mockTelemetry.recordedParams['acao_explorar']!['acao'], 'baixar');
    });

    test('getAppInstanceId retorna valor mockado', () async {
      final appInstanceId = await TelemetryService.instance.getAppInstanceId();
      expect(appInstanceId, 'mock_app_instance_id');
    });

    test('logAtualizarCroqui', () async {
      await TelemetryService.instance.logAtualizarCroqui(
        'crag1',
        'sha123',
        '2026-06-04T10:00:00.000Z',
      );
      expect(mockTelemetry.recordedEvents, contains('atualizar_croqui'));
      expect(
        mockTelemetry.recordedParams['atualizar_croqui']!['id_croqui'],
        'crag1',
      );
      expect(
        mockTelemetry.recordedParams['atualizar_croqui']!['versao'],
        'sha123',
      );
      expect(
        mockTelemetry
            .recordedParams['atualizar_croqui']!['timestamp_atualizacao'],
        '2026-06-04T10:00:00.000Z',
      );
    });

    test('logAcaoCroqui com origem', () async {
      await TelemetryService.instance.logAcaoCroqui(
        'crag1',
        'abrir_croqui',
        origem: 'explorar',
      );
      expect(mockTelemetry.recordedEvents, contains('acao_croqui'));
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['acao'],
        'abrir_croqui',
      );
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['origem'],
        'explorar',
      );
    });

    test('logAcaoCroqui com modoAcesso e primeiraVisita true', () async {
      await TelemetryService.instance.logAcaoCroqui(
        'crag1',
        'abrir_croqui',
        origem: 'home',
        modoAcesso: 'offline',
        primeiraVisita: true,
      );
      expect(mockTelemetry.recordedEvents, contains('acao_croqui'));
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['modo_acesso'],
        'offline',
      );
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['primeira_visita'],
        'true',
      );
    });

    test('logAcaoCroqui com modoAcesso e primeiraVisita false', () async {
      await TelemetryService.instance.logAcaoCroqui(
        'crag2',
        'abrir_croqui',
        origem: 'meus_croquis',
        modoAcesso: 'online',
        primeiraVisita: false,
      );
      expect(mockTelemetry.recordedEvents, contains('acao_croqui'));
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['modo_acesso'],
        'online',
      );
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['primeira_visita'],
        'false',
      );
    });

    test('logAbrirSetor', () async {
      await TelemetryService.instance.logAbrirSetor('crag1', 'Setor 1');
      expect(mockTelemetry.recordedEvents, contains('abrir_setor'));
    });

    test('logAbrirGrupo', () async {
      await TelemetryService.instance.logAbrirGrupo('crag1', 'Grupo 1');
      expect(mockTelemetry.recordedEvents, contains('abrir_grupo'));
    });

    test('logAbrirMapa', () async {
      await TelemetryService.instance.logAbrirMapa('crag1', 'Grupo 1');
      expect(mockTelemetry.recordedEvents, contains('abrir_mapa'));
    });

    test('logAcaoEscalada', () async {
      await TelemetryService.instance.logAcaoEscalada(
        'crag1',
        'Setor 1',
        'Via 1',
        'abrir_detalhes',
        'mapa',
      );
      expect(mockTelemetry.recordedEvents, contains('acao_escalada'));
      expect(
        mockTelemetry.recordedParams['acao_escalada']!['nome_escalada'],
        'Via 1',
      );
      expect(
        mockTelemetry.recordedParams['acao_escalada']!['acao'],
        'abrir_detalhes',
      );
      expect(mockTelemetry.recordedParams['acao_escalada']!['origem'], 'mapa');
    });

    test('logAcaoIndiceEscaladas com filtro e detalhe', () async {
      await TelemetryService.instance.logAcaoIndiceEscaladas(
        'crag_pedra',
        'filtrar_grau',
        modalidade: 'Esportiva',
        detalhe: '5º a 8ºb',
      );
      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      final params = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'filtrar_grau');
      expect(params['origem'], 'indice_esportiva');
      expect(params['detalhe'], '5º a 8ºb');
    });

    test('logDeepLinkAberto com sucesso e parâmetros UTM', () async {
      await TelemetryService.instance.logDeepLinkAberto(
        idCroqui: 'crag_pedra',
        destino: 'via',
        sucesso: true,
        tipoStart: 'cold_start',
        parametrosUtm: {
          'utm_source': 'placa_pedra',
          'utm_medium': 'qrcode',
        },
      );
      expect(mockTelemetry.recordedEvents, contains('deep_link_aberto'));
      final params = mockTelemetry.recordedParams['deep_link_aberto']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'via');
      expect(params['destino'], 'via');
      expect(params['sucesso'], 'true');
      expect(params['tipo_start'], 'cold_start');
      expect(params['origem'], 'cold_start');
      expect(params['utm_source'], 'placa_pedra');
      expect(params['utm_medium'], 'qrcode');
    });

    test('logDeepLinkAberto com falha e motivoErro', () async {
      await TelemetryService.instance.logDeepLinkAberto(
        idCroqui: 'crag_desconhecido',
        destino: 'pico',
        sucesso: false,
        tipoStart: 'warm_start',
        motivoErro: 'sem_conexao',
      );
      expect(mockTelemetry.recordedEvents, contains('deep_link_aberto'));
      final params = mockTelemetry.recordedParams['deep_link_aberto']!;
      expect(params['id_croqui'], 'crag_desconhecido');
      expect(params['sucesso'], 'false');
      expect(params['motivo_erro'], 'sem_conexao');
    });

    test('logAcaoBetaAberto para abrir modal e clique em canal', () async {
      await TelemetryService.instance.logAcaoBetaAberto(
        'abrir_modal_beta',
        origem: 'home_header',
      );
      expect(mockTelemetry.recordedEvents, contains('acao_beta_aberto'));
      var params = mockTelemetry.recordedParams['acao_beta_aberto']!;
      expect(params['acao'], 'abrir_modal_beta');
      expect(params['origem'], 'home_header');

      await TelemetryService.instance.logAcaoBetaAberto(
        'clique_instagram',
        canal: 'instagram',
      );
      params = mockTelemetry.recordedParams['acao_beta_aberto']!;
      expect(params['acao'], 'clique_instagram');
      expect(params['origem'], 'modal_beta');
      expect(params['detalhe'], 'instagram');
    });

    test('logApoioPix ao copiar chave pix', () async {
      await TelemetryService.instance.logApoioPix('crag_pedra');
      expect(mockTelemetry.recordedEvents, contains('apoio_pico'));
      final params = mockTelemetry.recordedParams['apoio_pico']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'copiar_pix');
      expect(params['origem'], 'apoie_pico');
    });

    test('logAcaoGuardiaoSaida para decisões no modal de saída', () async {
      await TelemetryService.instance.logAcaoGuardiaoSaida(
        'crag_pedra',
        'guardiao_salvar_offline',
      );
      expect(mockTelemetry.recordedEvents, contains('guardiao_saida'));
      final params = mockTelemetry.recordedParams['guardiao_saida']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'guardiao_salvar_offline');
      expect(params['modo_acesso'], 'online');
    });

    test('logSalvarOfflineBanner para ação no banner online', () async {
      await TelemetryService.instance.logSalvarOfflineBanner('crag_pedra');
      expect(mockTelemetry.recordedEvents, contains('banner_modo_online'));
      final params = mockTelemetry.recordedParams['banner_modo_online']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'banner_salvar_offline');
      expect(params['origem'], 'banner_online');
      expect(params['modo_acesso'], 'online');
    });

    test('logNavegacaoPicoHub para navegação nos cards centrais', () async {
      await TelemetryService.instance.logNavegacaoPicoHub(
        'crag_pedra',
        'abrir_indice_escaladas',
      );
      expect(mockTelemetry.recordedEvents, contains('navegacao_pico_hub'));
      final params = mockTelemetry.recordedParams['navegacao_pico_hub']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'abrir_indice_escaladas');
      expect(params['origem'], 'pico_hub');
    });

    test('logAlterarOrdenacao em setores ou vias', () async {
      await TelemetryService.instance.logAlterarOrdenacao('setor', 'grau');
      expect(mockTelemetry.recordedEvents, contains('alterar_ordenacao'));
      final params = mockTelemetry.recordedParams['alterar_ordenacao']!;
      expect(params['acao'], 'alterar_ordenacao');
      expect(params['origem'], 'setor');
      expect(params['detalhe'], 'grau');
    });

    test('logLinkExterno com detalhe opcional', () async {
      await TelemetryService.instance.logLinkExterno(
        'https://instagram.com/aresta',
        'comunidade',
        detalhe: 'https://instagram.com/aresta',
      );
      expect(mockTelemetry.recordedEvents, contains('link_externo'));
      final params = mockTelemetry.recordedParams['link_externo']!;
      expect(params['url'], 'https://instagram.com/aresta');
      expect(params['origem'], 'comunidade');
      expect(params['detalhe'], 'https://instagram.com/aresta');
    });
  });

  group('TelemetryService Real Instance Tests', () {
    test(
      'Should not throw exception when logging events before Firebase is initialized',
      () async {
        // Reseta para a instância real (que chamaria FirebaseAnalytics internamente)
        TelemetryService.resetForTesting();

        try {
          // Isso normalmente quebraria se Firebase.initializeApp() não tiver terminado,
          // mas o nosso try-catch interno na _logEvent deve absorver graciosamente.
          await TelemetryService.instance.logSincronizarApp(acao: 'automatica');
          // Passou sem quebrar = sucesso
        } catch (e) {
          fail('Should not throw uncaught exception: $e');
        }
      },
    );

    test(
      'Should logError when _logEvent fails',
      () async {
        TelemetryService.resetForTesting();
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        await TelemetryService.instance.logSincronizarApp(acao: 'automatica');

        expect(mockLogger.recordedErrors, isNotEmpty);
        expect(
          mockLogger.recordedErrors.first['contextMessage'],
          '⚠️ [Telemetry] Erro ao enviar evento (Firebase pronto?)',
        );
      },
    );

    test(
      'Should logError and return null when getAppInstanceId fails',
      () async {
        TelemetryService.resetForTesting();
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        final id = await TelemetryService.instance.getAppInstanceId();

        expect(id, isNull);
        expect(mockLogger.recordedErrors, isNotEmpty);
        expect(
          mockLogger.recordedErrors.first['contextMessage'],
          '⚠️ [Telemetry] Erro ao obter appInstanceId',
        );
      },
    );
  });
}
