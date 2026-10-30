// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/classificador_dispositivo.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/feedback/gravador_breadcrumbs.dart';
import '../../mocks/mock_app_logger.dart';

/// Fake determinístico de [FirebaseAnalytics] para testes de fronteira sem rede.
class FakeFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  final List<String> recordedEvents = [];
  final Map<String, Map<String, dynamic>> recordedParams = {};
  bool? coletaHabilitada;
  bool lancarErroNoLogEvent = false;
  bool lancarErroNoAppInstanceId = false;
  bool lancarErroAoConfigurar = false;

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    if (lancarErroAoConfigurar) {
      throw Exception('Erro ao configurar analytics');
    }
    coletaHabilitada = enabled;
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
    List<AnalyticsEventItem>? items,
  }) async {
    if (lancarErroNoLogEvent) {
      throw Exception('Falha simulada no logEvent');
    }
    recordedEvents.add(name);
    if (parameters != null) {
      recordedParams[name] = Map<String, dynamic>.from(parameters);
    }
  }

  @override
  Future<String?> get appInstanceId async {
    if (lancarErroNoAppInstanceId) {
      throw Exception('Falha simulada no appInstanceId');
    }
    return 'fake_app_instance_id';
  }
}

void main() {
  group('TelemetryService Eventos de Negócio', () {
    late FakeFirebaseAnalytics fakeAnalytics;

    setUp(() {
      TelemetryService.resetForTesting();
      GravadorBreadcrumbs.resetForTesting();
      fakeAnalytics = FakeFirebaseAnalytics();
      TelemetryService.instance.debugAnalytics = fakeAnalytics;
    });

    test('logAcaoExplorar', () async {
      await TelemetryService.instance.logAcaoExplorar('crag1', 'baixar');
      expect(fakeAnalytics.recordedEvents, contains('acao_explorar'));
      expect(
        fakeAnalytics.recordedParams['acao_explorar']!['id_croqui'],
        'crag1',
      );
      expect(fakeAnalytics.recordedParams['acao_explorar']!['acao'], 'baixar');
    });

    test('logAcaoFeedback registra evento básico e parâmetros enriquecidos', () async {
      await TelemetryService.instance.logAcaoFeedback(
        'abrir_feedback',
        origem: 'app_bar',
        temCroqui: true,
        idCroqui: 'br_mg_pedra_grande',
      );
      expect(fakeAnalytics.recordedEvents, contains('acao_feedback'));
      expect(fakeAnalytics.recordedParams['acao_feedback']!['acao'], 'abrir_feedback');
      expect(fakeAnalytics.recordedParams['acao_feedback']!['origem'], 'app_bar');
      expect(fakeAnalytics.recordedParams['acao_feedback']!['tem_croqui'], 'true');
      expect(fakeAnalytics.recordedParams['acao_feedback']!['id_croqui'], 'br_mg_pedra_grande');

      await TelemetryService.instance.logAcaoFeedback(
        'enviar_feedback',
        tipoFeedback: 'croqui',
        idCroqui: 'br_mg_pedra_grande',
        qtdCaracteres: 42,
      );
      expect(fakeAnalytics.recordedParams['acao_feedback']!['acao'], 'enviar_feedback');
      expect(fakeAnalytics.recordedParams['acao_feedback']!['tipo_feedback'], 'croqui');
      expect(fakeAnalytics.recordedParams['acao_feedback']!['qtd_caracteres'], 42);

      await TelemetryService.instance.logAcaoFeedback(
        'despacho_feedback',
        status: 'sucesso',
        dispatcher: 'connectivity_plus',
        erro: 'erro_teste',
      );
      expect(fakeAnalytics.recordedParams['acao_feedback']!['acao'], 'despacho_feedback');
      expect(fakeAnalytics.recordedParams['acao_feedback']!['status'], 'sucesso');
      expect(fakeAnalytics.recordedParams['acao_feedback']!['dispatcher'], 'connectivity_plus');
      expect(fakeAnalytics.recordedParams['acao_feedback']!['erro'], 'erro_teste');
    });

    test('getAppInstanceId retorna valor do fake', () async {
      final appInstanceId = await TelemetryService.instance.getAppInstanceId();
      expect(appInstanceId, 'fake_app_instance_id');
    });

    test('logAtualizarCroqui', () async {
      await TelemetryService.instance.logAtualizarCroqui(
        'crag1',
        'sha123',
        '2026-06-04T10:00:00.000Z',
      );
      expect(fakeAnalytics.recordedEvents, contains('atualizar_croqui'));
      expect(
        fakeAnalytics.recordedParams['atualizar_croqui']!['id_croqui'],
        'crag1',
      );
      expect(
        fakeAnalytics.recordedParams['atualizar_croqui']!['versao'],
        'sha123',
      );
      expect(
        fakeAnalytics
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
      expect(fakeAnalytics.recordedEvents, contains('acao_croqui'));
      expect(
        fakeAnalytics.recordedParams['acao_croqui']!['acao'],
        'abrir_croqui',
      );
      expect(
        fakeAnalytics.recordedParams['acao_croqui']!['origem'],
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
      expect(fakeAnalytics.recordedEvents, contains('acao_croqui'));
      expect(
        fakeAnalytics.recordedParams['acao_croqui']!['modo_acesso'],
        'offline',
      );
      expect(
        fakeAnalytics.recordedParams['acao_croqui']!['primeira_visita'],
        'true',
      );
    });

    test('logAcaoCroqui com modoAcesso e primeiraVisita false', () async {
      await TelemetryService.instance.logAcaoCroqui(
        'crag1',
        'abrir_croqui',
        origem: 'home',
        modoAcesso: 'memoria',
        primeiraVisita: false,
        duracaoMs: 120,
      );
      expect(fakeAnalytics.recordedEvents, contains('acao_croqui'));
      expect(
        fakeAnalytics.recordedParams['acao_croqui']!['modo_acesso'],
        'memoria',
      );
      expect(
        fakeAnalytics.recordedParams['acao_croqui']!['primeira_visita'],
        'false',
      );
      expect(
        fakeAnalytics.recordedParams['acao_croqui']!['duracao_ms'],
        120,
      );
    });

    test('logAbrirSetor', () async {
      await TelemetryService.instance.logAbrirSetor(
        'crag1',
        'Setor Central',
        modoAcesso: 'offline',
        duracaoMs: 250,
      );
      expect(fakeAnalytics.recordedEvents, contains('abrir_setor'));
      expect(
        fakeAnalytics.recordedParams['abrir_setor']!['id_croqui'],
        'crag1',
      );
      expect(
        fakeAnalytics.recordedParams['abrir_setor']!['nome_setor'],
        'Setor Central',
      );
      expect(
        fakeAnalytics.recordedParams['abrir_setor']!['modo_acesso'],
        'offline',
      );
      expect(
        fakeAnalytics.recordedParams['abrir_setor']!['duracao_ms'],
        250,
      );
    });

    test('logAbrirGrupo', () async {
      await TelemetryService.instance.logAbrirGrupo(
        'crag1',
        'Bloco Principal',
        modoAcesso: 'online',
        duracaoMs: 180,
      );
      expect(fakeAnalytics.recordedEvents, contains('abrir_grupo'));
      expect(
        fakeAnalytics.recordedParams['abrir_grupo']!['id_croqui'],
        'crag1',
      );
      expect(
        fakeAnalytics.recordedParams['abrir_grupo']!['nome_grupo'],
        'Bloco Principal',
      );
      expect(
        fakeAnalytics.recordedParams['abrir_grupo']!['modo_acesso'],
        'online',
      );
      expect(
        fakeAnalytics.recordedParams['abrir_grupo']!['duracao_ms'],
        180,
      );
    });

    test('logAbrirMapa', () async {
      await TelemetryService.instance.logAbrirMapa(
        'crag1',
        'Setor Central',
        modoAcesso: 'temp_cache',
        origemImagem: 'cache',
        duracaoMs: 310,
      );
      expect(fakeAnalytics.recordedEvents, contains('abrir_mapa'));
      expect(
        fakeAnalytics.recordedParams['abrir_mapa']!['id_croqui'],
        'crag1',
      );
      expect(
        fakeAnalytics.recordedParams['abrir_mapa']!['nome_setor'],
        'Setor Central',
      );
      expect(
        fakeAnalytics.recordedParams['abrir_mapa']!['modo_acesso'],
        'temp_cache',
      );
      expect(
        fakeAnalytics.recordedParams['abrir_mapa']!['origem_imagem'],
        'cache',
      );
      expect(
        fakeAnalytics.recordedParams['abrir_mapa']!['duracao_ms'],
        310,
      );
    });

    test('logAcaoEscalada', () async {
      await TelemetryService.instance.logAcaoEscalada(
        'crag1',
        'Setor Central',
        'Fissura',
        'ver_mapa',
        'detalhe',
        modoAcesso: 'offline',
        duracaoMs: 95,
      );
      expect(fakeAnalytics.recordedEvents, contains('acao_escalada'));
      expect(
        fakeAnalytics.recordedParams['acao_escalada']!['id_croqui'],
        'crag1',
      );
      expect(
        fakeAnalytics.recordedParams['acao_escalada']!['nome_setor'],
        'Setor Central',
      );
      expect(
        fakeAnalytics.recordedParams['acao_escalada']!['nome_escalada'],
        'Fissura',
      );
      expect(
        fakeAnalytics.recordedParams['acao_escalada']!['acao'],
        'ver_mapa',
      );
      expect(
        fakeAnalytics.recordedParams['acao_escalada']!['origem'],
        'detalhe',
      );
      expect(
        fakeAnalytics.recordedParams['acao_escalada']!['modo_acesso'],
        'offline',
      );
      expect(
        fakeAnalytics.recordedParams['acao_escalada']!['duracao_ms'],
        95,
      );
    });

    test('logAcaoIndiceEscaladas com filtro e detalhe', () async {
      await TelemetryService.instance.logAcaoIndiceEscaladas(
        'crag1',
        'filtrar_grau',
        modalidade: 'Esportiva',
        detalhe: '5º a 8ºb',
      );
      expect(fakeAnalytics.recordedEvents, contains('acao_indice_escaladas'));
      expect(
        fakeAnalytics.recordedParams['acao_indice_escaladas']!['id_croqui'],
        'crag1',
      );
      expect(
        fakeAnalytics.recordedParams['acao_indice_escaladas']!['acao'],
        'filtrar_grau',
      );
      expect(
        fakeAnalytics.recordedParams['acao_indice_escaladas']!['origem'],
        'indice_esportiva',
      );
      expect(
        fakeAnalytics.recordedParams['acao_indice_escaladas']!['detalhe'],
        '5º a 8ºb',
      );

      // Modalidade já prefixada com indice_
      await TelemetryService.instance.logAcaoIndiceEscaladas(
        'crag1',
        'trocar_aba',
        modalidade: 'indice_boulder',
      );
      expect(
        fakeAnalytics.recordedParams['acao_indice_escaladas']!['origem'],
        'indice_boulder',
      );
    });

    test('logDeepLinkAberto com sucesso e parâmetros UTM', () async {
      await TelemetryService.instance.logDeepLinkAberto(
        idCroqui: 'br_mg_igarape_pedra_grande',
        destino: 'setor',
        sucesso: true,
        tipoStart: 'cold_start',
        origemLink: 'qrcode',
        abrirMapa: true,
        modoAcesso: 'offline',
        duracaoMs: 450,
        parametrosUtm: {'utm_source': 'placa_parque'},
      );
      expect(fakeAnalytics.recordedEvents, contains('deep_link_aberto'));
      final params = fakeAnalytics.recordedParams['deep_link_aberto']!;
      expect(params['id_croqui'], 'br_mg_igarape_pedra_grande');
      expect(params['destino'], 'setor');
      expect(params['sucesso'], 'true');
      expect(params['tipo_start'], 'cold_start');
      expect(params['origem_link'], 'qrcode');
      expect(params['abrir_mapa'], 'true');
      expect(params['modo_acesso'], 'offline');
      expect(params['duracao_ms'], 450);
      expect(params['utm_source'], 'placa_parque');
    });

    test('logDeepLinkAberto com falha e motivoErro', () async {
      await TelemetryService.instance.logDeepLinkAberto(
        idCroqui: 'br_mg_igarape_pedra_grande',
        destino: 'via',
        sucesso: false,
        motivoErro: 'sem_conexao',
      );
      expect(fakeAnalytics.recordedEvents, contains('deep_link_aberto'));
      final params = fakeAnalytics.recordedParams['deep_link_aberto']!;
      expect(params['id_croqui'], 'br_mg_igarape_pedra_grande');
      expect(params['sucesso'], 'false');
      expect(params['motivo_erro'], 'sem_conexao');
    });

    test('logAcaoBetaAberto para abrir modal e clique em canal', () async {
      await TelemetryService.instance.logAcaoBetaAberto(
        'abrir_modal',
        origem: 'home',
      );
      expect(fakeAnalytics.recordedEvents, contains('acao_beta_aberto'));
      var params = fakeAnalytics.recordedParams['acao_beta_aberto']!;
      expect(params['acao'], 'abrir_modal');
      expect(params['origem'], 'home');

      await TelemetryService.instance.logAcaoBetaAberto(
        'clique_canal',
        canal: 'whatsapp',
        detalhe: 'https://chat.whatsapp.com/teste',
      );
      params = fakeAnalytics.recordedParams['acao_beta_aberto']!;
      expect(params['acao'], 'clique_canal');
      expect(params['canal'], 'whatsapp');
      expect(params['detalhe'], 'https://chat.whatsapp.com/teste');
    });

    test('logApoioPix ao copiar chave pix', () async {
      await TelemetryService.instance.logApoioPix('br_mg_igarape_pedra_grande');
      expect(fakeAnalytics.recordedEvents, contains('apoio_pico'));
      final params = fakeAnalytics.recordedParams['apoio_pico']!;
      expect(params['id_croqui'], 'br_mg_igarape_pedra_grande');
      expect(params['acao'], 'copiar_pix');
    });

    test('logAcaoGuardiaoSaida para decisões no modal de saída', () async {
      await TelemetryService.instance.logAcaoGuardiaoSaida(
        'br_mg_igarape_pedra_grande',
        'confirmar_saida',
      );
      expect(fakeAnalytics.recordedEvents, contains('guardiao_saida'));
      final params = fakeAnalytics.recordedParams['guardiao_saida']!;
      expect(params['id_croqui'], 'br_mg_igarape_pedra_grande');
      expect(params['acao'], 'confirmar_saida');
    });

    test('logSalvarOfflineBanner para ação no banner online', () async {
      await TelemetryService.instance.logSalvarOfflineBanner(
        'br_mg_igarape_pedra_grande',
      );
      expect(fakeAnalytics.recordedEvents, contains('banner_modo_online'));
      final params = fakeAnalytics.recordedParams['banner_modo_online']!;
      expect(params['id_croqui'], 'br_mg_igarape_pedra_grande');
      expect(params['acao'], 'banner_salvar_offline');
    });

    test('logNavegacaoPicoHub para navegação nos cards centrais', () async {
      await TelemetryService.instance.logNavegacaoPicoHub(
        'br_mg_igarape_pedra_grande',
        'setores',
      );
      expect(fakeAnalytics.recordedEvents, contains('navegacao_pico_hub'));
      final params = fakeAnalytics.recordedParams['navegacao_pico_hub']!;
      expect(params['id_croqui'], 'br_mg_igarape_pedra_grande');
      expect(params['acao'], 'setores');
    });

    test('logAlterarOrdenacao em setores ou vias', () async {
      await TelemetryService.instance.logAlterarOrdenacao('setor', 'grau');
      expect(fakeAnalytics.recordedEvents, contains('alterar_ordenacao'));
      final params = fakeAnalytics.recordedParams['alterar_ordenacao']!;
      expect(params['acao'], 'alterar_ordenacao');
      expect(params['origem'], 'setor');
      expect(params['detalhe'], 'grau');
    });

    test('logAcaoConfiguracoes', () async {
      await TelemetryService.instance.logAcaoConfiguracoes('limpar_cache');
      expect(fakeAnalytics.recordedEvents, contains('acao_configuracoes'));
      expect(fakeAnalytics.recordedParams['acao_configuracoes']!['acao'], 'limpar_cache');
    });

    test('logLinkExterno com detalhe opcional', () async {
      await TelemetryService.instance.logLinkExterno(
        'https://instagram.com/aresta',
        'comunidade',
        detalhe: 'https://instagram.com/aresta',
      );
      expect(fakeAnalytics.recordedEvents, contains('link_externo'));
      final params = fakeAnalytics.recordedParams['link_externo']!;
      expect(params['url'], 'https://instagram.com/aresta');
      expect(params['origem'], 'comunidade');
      expect(params['detalhe'], 'https://instagram.com/aresta');

      await TelemetryService.instance.logLinkExterno(
        'https://aresta.app',
        'home',
      );
      expect(fakeAnalytics.recordedParams['link_externo']!['detalhe'], 'https://aresta.app');
    });

    test('logCompartilharEntidade registra página e mapa', () async {
      await TelemetryService.instance.logCompartilharEntidade(
        idCroqui: 'br_mg_igarape_pedra_grande',
        tipoEntidade: 'setor',
        uid: 'hv7YWgTBQGyWOX',
        abrirMapa: false,
      );
      expect(fakeAnalytics.recordedEvents, contains('compartilhar_entidade'));
      var params = fakeAnalytics.recordedParams['compartilhar_entidade']!;
      expect(params['id_croqui'], 'br_mg_igarape_pedra_grande');
      expect(params['tipo_entidade'], 'setor');
      expect(params['uid'], 'hv7YWgTBQGyWOX');
      expect(params['abrir_mapa'], 'false');
      expect(params['origem'], 'pagina_detalhe');

      await TelemetryService.instance.logCompartilharEntidade(
        idCroqui: 'br_mg_igarape_pedra_grande',
        tipoEntidade: 'via',
        uid: 'x8siJek3FiG3aB',
        abrirMapa: true,
      );
      params = fakeAnalytics.recordedParams['compartilhar_entidade']!;
      expect(params['abrir_mapa'], 'true');
      expect(params['origem'], 'mapa_interativo');
    });

    test('logBuscaCroquis e logBuscaEscaladas', () async {
      await TelemetryService.instance.logBuscaCroquis('pedra', 5);
      expect(fakeAnalytics.recordedEvents, contains('busca_croquis'));
      expect(fakeAnalytics.recordedParams['busca_croquis']!['query'], 'pedra');
      expect(fakeAnalytics.recordedParams['busca_croquis']!['numero_resultados'], 5);

      await TelemetryService.instance.logBuscaEscaladas('via_teste', 2, 'crag1');
      expect(fakeAnalytics.recordedEvents, contains('busca_escaladas'));
      expect(fakeAnalytics.recordedParams['busca_escaladas']!['query'], 'via_teste');
      expect(fakeAnalytics.recordedParams['busca_escaladas']!['numero_resultados'], 2);
      expect(fakeAnalytics.recordedParams['busca_escaladas']!['id_croqui'], 'crag1');
    });

    test('logResultadoSincronizacao e logNavegacaoHierarquica', () async {
      await TelemetryService.instance.logResultadoSincronizacao('sucesso');
      expect(fakeAnalytics.recordedEvents, contains('resultado_sincronizacao'));
      expect(fakeAnalytics.recordedParams['resultado_sincronizacao']!['acao'], 'sucesso');

      await TelemetryService.instance.logNavegacaoHierarquica('crag1', 'grupo_a');
      expect(fakeAnalytics.recordedEvents, contains('navegacao_hierarquica_mapa'));
      expect(fakeAnalytics.recordedParams['navegacao_hierarquica_mapa']!['id_croqui'], 'crag1');
      expect(fakeAnalytics.recordedParams['navegacao_hierarquica_mapa']!['acao'], 'grupo_a');
    });

    test('logDatabaseMigrationScreenOpened e logDatabaseMigrationTryAgain', () async {
      await TelemetryService.instance.logDatabaseMigrationScreenOpened();
      expect(fakeAnalytics.recordedEvents, contains('migracao_db'));
      expect(fakeAnalytics.recordedParams['migracao_db']!['acao'], 'aberta_tela_migracao');

      await TelemetryService.instance.logDatabaseMigrationTryAgain();
      expect(fakeAnalytics.recordedParams['migracao_db']!['acao'], 'tentar_novamente_clicado_tela_migracao');
    });

    test('logAppVersion avisos e bloqueios', () async {
      await TelemetryService.instance.logAppVersionHardBlock();
      expect(fakeAnalytics.recordedEvents, contains('migracao_db'));
      expect(fakeAnalytics.recordedParams['migracao_db']!['acao'], 'tela_hard_block_mostrada');

      await TelemetryService.instance.logAppVersionSoftBlock();
      expect(fakeAnalytics.recordedParams['migracao_db']!['acao'], 'banner_soft_block_mostrado');

      await TelemetryService.instance.logAppVersionRecommendedUpdate();
      expect(fakeAnalytics.recordedParams['migracao_db']!['acao'], 'banner_versao_recomendada_mostrado');
    });

    test('logEvento genérico', () async {
      await TelemetryService.instance.logEvento('evento_custom', parametros: {'chave': 'valor'});
      expect(fakeAnalytics.recordedEvents, contains('evento_custom'));
      expect(fakeAnalytics.recordedParams['evento_custom']!['chave'], 'valor');
    });
  });

  group('TelemetryService Real Instance Tests', () {
    test(
      'Should not throw exception when logging events before Firebase is initialized',
      () async {
        TelemetryService.resetForTesting();
        try {
          await TelemetryService.instance.logSincronizarApp(acao: 'automatica');
        } catch (e) {
          fail('Should not throw uncaught exception: $e');
        }
      },
    );

    test(
      'Should logError when _logEvent fails',
      () async {
        TelemetryService.resetForTesting();
        final fake = FakeFirebaseAnalytics()..lancarErroNoLogEvent = true;
        TelemetryService.instance.debugAnalytics = fake;
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
        final fake = FakeFirebaseAnalytics()..lancarErroNoAppInstanceId = true;
        TelemetryService.instance.debugAnalytics = fake;
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        final id = await TelemetryService.instance.getAppInstanceId();

        expect(id, isNull);
        expect(
          mockLogger.recordedErrors.first['contextMessage'],
          '⚠️ [Telemetry] Erro ao obter appInstanceId',
        );
      },
    );

    test(
      'initialize desativa coleta analítica em modo debug',
      () async {
        TelemetryService.resetForTesting();
        final fake = FakeFirebaseAnalytics();

        await TelemetryService.instance.initialize(
          isDebugMode: true,
          analyticsInstance: fake,
        );

        expect(fake.coletaHabilitada, isFalse);
      },
    );

    test(
      'initialize captura erro ao desativar coleta analítica e registra logError',
      () async {
        TelemetryService.resetForTesting();
        final fake = FakeFirebaseAnalytics()..lancarErroAoConfigurar = true;
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        await TelemetryService.instance.initialize(
          isDebugMode: true,
          analyticsInstance: fake,
        );

        expect(mockLogger.recordedErrors, isNotEmpty);
        expect(
          mockLogger.recordedErrors.first['contextMessage'],
          '⚠️ [Telemetry] Erro ao desativar coleta do Firebase Analytics',
        );
      },
    );

    test(
      'Deve alimentar o GravadorBreadcrumbs automaticamente em _logEvent',
      () async {
        TelemetryService.resetForTesting();
        GravadorBreadcrumbs.resetForTesting();
        final fake = FakeFirebaseAnalytics();
        TelemetryService.instance.debugAnalytics = fake;
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        await TelemetryService.instance.logNavegarAba('explorar');

        final breadcrumbs = GravadorBreadcrumbs.instance.obterBreadcrumbs();
        expect(breadcrumbs, isNotEmpty);
        expect(breadcrumbs.last['evento'], 'navegar_aba');
        expect(breadcrumbs.last['parametros'], {'acao': 'explorar'});
      },
    );

    test(
      'logPerformanceAberturaApp, logPerformanceSyncIndex e parâmetros opcionais duracaoMs/modoAcesso/origemImagem são registrados nos breadcrumbs',
      () async {
        TelemetryService.resetForTesting();
        GravadorBreadcrumbs.resetForTesting();
        final fake = FakeFirebaseAnalytics();
        TelemetryService.instance.debugAnalytics = fake;
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        await TelemetryService.instance.logPerformanceAberturaApp(
          tipoStart: 'cold_start',
          destino: 'home',
          duracaoMs: 390,
        );
        expect(
          GravadorBreadcrumbs.instance.obterBreadcrumbs().last['parametros'],
          containsPair('duracao_ms', 390),
        );

        await TelemetryService.instance.logPerformanceSyncIndex(
          fase: 'fase1_indice_catalogo',
          duracaoMs: 115,
          statusHttp: '304',
          origem: 'auto',
          modo: 'oficial',
          teveAtualizacao: true,
          qtdPicosAtualizados: 3,
          qtdThumbs: 12,
        );
        expect(
          GravadorBreadcrumbs.instance.obterBreadcrumbs().last['parametros'],
          containsPair('status_http', '304'),
        );

        await TelemetryService.instance.logAbrirMapa(
          'pico_1',
          'Setor 1',
          modoAcesso: 'offline',
          origemImagem: 'downloads',
          duracaoMs: 55,
        );
        final paramsMapa =
            GravadorBreadcrumbs.instance.obterBreadcrumbs().last['parametros']
                as Map<String, dynamic>;
        expect(paramsMapa['modo_acesso'], 'offline');
        expect(paramsMapa['origem_imagem'], 'downloads');
        expect(paramsMapa['duracao_ms'], 55);
      },
    );

    test(
      'logFluidezSessaoTela e eventos de performance incluem tier_dispositivo e ram_gb automaticamente',
      () async {
        TelemetryService.resetForTesting();
        GravadorBreadcrumbs.resetForTesting();
        final fake = FakeFirebaseAnalytics();
        TelemetryService.instance.debugAnalytics = fake;
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;
        ClassificadorDispositivo.instancia.classificar(ramTotalMb: 12288);

        await TelemetryService.instance.logFluidezSessaoTela(
          tela: 'mapa_interativo',
          idCroqui: 'pico_1',
          duracaoMs: 1200,
          totalFrames: 60,
          framesJank: 2,
          taxaJankPct: 3,
          p95UiMs: 10,
          p95RasterMs: 12,
        );

        final ultimo = GravadorBreadcrumbs.instance.obterBreadcrumbs().last;
        expect(ultimo['evento'], 'fluidez_sessao_tela');
        final params = ultimo['parametros'] as Map<String, dynamic>;
        expect(params['tela'], 'mapa_interativo');
        expect(params['id_croqui'], 'pico_1');
        expect(params['duracao_ms'], 1200);
        expect(params['total_frames'], 60);
        expect(params['frames_jank'], 2);
        expect(params['taxa_jank_pct'], 3);
        expect(params['p95_ui_ms'], 10);
        expect(params['p95_raster_ms'], 12);
        expect(params['tier_dispositivo'], 'alto');
        expect(params['ram_gb'], '12');
      },
    );
  });

  group('TelemetryService - Guarda Defensiva AppLogger.firebaseInicializado', () {
    late MockAppLogger mockLogger;

    setUp(() {
      TelemetryService.resetForTesting();
      TelemetryService.instance.debugAnalytics = null;
      mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;
    });

    tearDown(() {
      AppLogger.resetForTesting();
    });

    test(
      'quando Firebase não estiver inicializado e debugAnalytics for nulo, initialize degrada com logAviso sem lançar [core/no-app] nem chamar logError',
      () async {
        expect(AppLogger.firebaseInicializado, isFalse);

        await expectLater(
          TelemetryService.instance.initialize(isDebugMode: true),
          completes,
        );

        expect(mockLogger.recordedErrors, isEmpty);
        expect(mockLogger.recordedWarnings, isNotEmpty);
        expect(
          mockLogger.recordedWarnings.first,
          contains('Firebase não inicializado'),
        );
      },
    );

    test(
      'quando Firebase não estiver inicializado e debugAnalytics for nulo, _logEvent registra breadcrumbs e log local sem lançar [core/no-app] nem chamar logError',
      () async {
        expect(AppLogger.firebaseInicializado, isFalse);
        GravadorBreadcrumbs.resetForTesting();

        await expectLater(
          TelemetryService.instance.logSincronizarApp(acao: 'manual'),
          completes,
        );

        expect(mockLogger.recordedErrors, isEmpty);
        expect(GravadorBreadcrumbs.instance.obterBreadcrumbs(), isNotEmpty);
        expect(
          GravadorBreadcrumbs.instance.obterBreadcrumbs().last['evento'],
          'sincronizar_app',
        );
      },
    );

    test(
      'quando Firebase não estiver inicializado e debugAnalytics for nulo, getAppInstanceId retorna null sem lançar [core/no-app] nem chamar logError',
      () async {
        expect(AppLogger.firebaseInicializado, isFalse);

        final id = await TelemetryService.instance.getAppInstanceId();

        expect(id, isNull);
        expect(mockLogger.recordedErrors, isEmpty);
      },
    );
  });
}
