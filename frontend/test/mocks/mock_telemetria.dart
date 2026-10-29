// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:frontend/services/firebase/classificador_dispositivo.dart';
import 'package:frontend/services/firebase/telemetria.dart';

class MockTelemetryService implements TelemetryService {
  @override
  FirebaseAnalytics? debugAnalytics;

  final List<String> recordedEvents = [];
  final Map<String, Map<String, dynamic>> recordedParams = {};

  void clear() {
    recordedEvents.clear();
    recordedParams.clear();
  }

  @override
  Future<void> initialize({
    bool? isDebugMode,
    FirebaseAnalytics? analyticsInstance,
  }) async {}

  @override
  Future<void> logAcaoExplorar(String idCroqui, String acao) async {
    recordedEvents.add('acao_explorar');
    recordedParams['acao_explorar'] = {'id_croqui': idCroqui, 'acao': acao};
  }

  @override
  Future<String?> getAppInstanceId() async {
    return 'mock_app_instance_id';
  }

  @override
  Future<void> logAtualizarCroqui(
    String idCroqui,
    String versao,
    String timestampAtualizacao,
  ) async {
    recordedEvents.add('atualizar_croqui');
    recordedParams['atualizar_croqui'] = {
      'id_croqui': idCroqui,
      'versao': versao,
      'timestamp_atualizacao': timestampAtualizacao,
    };
  }

  @override
  Future<void> logAcaoCroqui(
    String idCroqui,
    String acao, {
    String? origem,
    String? modoAcesso,
    bool? primeiraVisita,
    int? duracaoMs,
  }) async {
    recordedEvents.add('acao_croqui');
    final params = <String, dynamic>{'id_croqui': idCroqui, 'acao': acao};
    if (origem != null) {
      params['origem'] = origem;
    }
    if (modoAcesso != null) {
      params['modo_acesso'] = modoAcesso;
    }
    if (primeiraVisita != null) {
      params['primeira_visita'] = primeiraVisita ? 'true' : 'false';
    }
    if (duracaoMs != null) {
      params['duracao_ms'] = duracaoMs;
    }
    recordedParams['acao_croqui'] = params;
  }

  @override
  Future<void> logAbrirSetor(
    String idCroqui,
    String nomeSetor, {
    String? modoAcesso,
    int? duracaoMs,
  }) async {
    recordedEvents.add('abrir_setor');
    final params = <String, dynamic>{
      'id_croqui': idCroqui,
      'nome_setor': nomeSetor,
    };
    if (modoAcesso != null) {
      params['modo_acesso'] = modoAcesso;
    }
    if (duracaoMs != null) {
      params['duracao_ms'] = duracaoMs;
    }
    recordedParams['abrir_setor'] = params;
  }

  @override
  Future<void> logAbrirGrupo(
    String idCroqui,
    String nomeGrupo, {
    String? modoAcesso,
    int? duracaoMs,
  }) async {
    recordedEvents.add('abrir_grupo');
    final params = <String, dynamic>{
      'id_croqui': idCroqui,
      'nome_grupo': nomeGrupo,
    };
    if (modoAcesso != null) {
      params['modo_acesso'] = modoAcesso;
    }
    if (duracaoMs != null) {
      params['duracao_ms'] = duracaoMs;
    }
    recordedParams['abrir_grupo'] = params;
  }

  @override
  Future<void> logAbrirMapa(
    String idCroqui,
    String nomeSetor, {
    String? modoAcesso,
    String? origemImagem,
    int? duracaoMs,
  }) async {
    recordedEvents.add('abrir_mapa');
    final params = <String, dynamic>{
      'id_croqui': idCroqui,
      'nome_setor': nomeSetor,
    };
    if (modoAcesso != null) {
      params['modo_acesso'] = modoAcesso;
    }
    if (origemImagem != null) {
      params['origem_imagem'] = origemImagem;
    }
    if (duracaoMs != null) {
      params['duracao_ms'] = duracaoMs;
    }
    recordedParams['abrir_mapa'] = params;
  }

  @override
  Future<void> logAcaoEscalada(
    String idCroqui,
    String nomeSetor,
    String nomeEscalada,
    String acao,
    String origem, {
    String? modoAcesso,
    int? duracaoMs,
  }) async {
    recordedEvents.add('acao_escalada');
    final params = <String, dynamic>{
      'id_croqui': idCroqui,
      'nome_setor': nomeSetor,
      'nome_escalada': nomeEscalada,
      'acao': acao,
      'origem': origem,
    };
    if (modoAcesso != null) {
      params['modo_acesso'] = modoAcesso;
    }
    if (duracaoMs != null) {
      params['duracao_ms'] = duracaoMs;
    }
    recordedParams['acao_escalada'] = params;
  }

  @override
  Future<void> logNavegarAba(String acao) async {
    recordedEvents.add('navegar_aba');
    recordedParams['navegar_aba'] = {'acao': acao};
  }

  @override
  Future<void> logBuscaCroquis(String query, int numeroResultados) async {
    recordedEvents.add('busca_croquis');
    recordedParams['busca_croquis'] = {
      'query': query,
      'numero_resultados': numeroResultados,
    };
  }

  @override
  Future<void> logBuscaEscaladas(
    String query,
    int numeroResultados,
    String idCroqui,
  ) async {
    recordedEvents.add('busca_escaladas');
    recordedParams['busca_escaladas'] = {
      'query': query,
      'numero_resultados': numeroResultados,
      'id_croqui': idCroqui,
    };
  }

  @override
  Future<void> logSincronizarApp({required String acao}) async {
    recordedEvents.add('sincronizar_app');
    recordedParams['sincronizar_app'] = {'acao': acao};
  }

  @override
  Future<void> logResultadoSincronizacao(String status) async {
    recordedEvents.add('resultado_sincronizacao');
    recordedParams['resultado_sincronizacao'] = {'acao': status};
  }

  @override
  Future<void> logNavegacaoHierarquica(String idCroqui, String destino) async {
    recordedEvents.add('navegacao_hierarquica_mapa');
    recordedParams['navegacao_hierarquica_mapa'] = {
      'id_croqui': idCroqui,
      'acao': destino,
    };
  }

  @override
  Future<void> logLinkExterno(String url, String origem, {String? detalhe}) async {
    recordedEvents.add('link_externo');
    recordedParams['link_externo'] = {
      'acao': 'abrir_link_externo',
      'url': url,
      'origem': origem,
      'detalhe': detalhe ?? url,
    };
  }

  @override
  Future<void> logAcaoIndiceEscaladas(
    String idCroqui,
    String acao, {
    required String modalidade,
    String? detalhe,
  }) async {
    recordedEvents.add('acao_indice_escaladas');
    final origemModalidade = modalidade.toLowerCase().startsWith('indice_')
        ? modalidade.toLowerCase()
        : 'indice_${modalidade.toLowerCase()}';
    final params = <String, dynamic>{
      'id_croqui': idCroqui,
      'acao': acao,
      'origem': origemModalidade,
    };
    if (detalhe != null) {
      params['detalhe'] = detalhe;
    }
    recordedParams['acao_indice_escaladas'] = params;
  }

  @override
  Future<void> logDeepLinkAberto({
    required String idCroqui,
    required String destino,
    required bool sucesso,
    String? tipoStart,
    String? origemLink,
    bool? abrirMapa,
    String? motivoErro,
    String? modoAcesso,
    int? duracaoMs,
    Map<String, String>? parametrosUtm,
  }) async {
    recordedEvents.add('deep_link_aberto');
    final params = <String, dynamic>{
      'id_croqui': idCroqui,
      'acao': destino,
      'destino': destino,
      'sucesso': sucesso ? 'true' : 'false',
    };
    if (tipoStart != null) {
      params['tipo_start'] = tipoStart;
      params['origem'] = tipoStart;
    }
    if (origemLink != null) {
      params['origem_link'] = origemLink;
    }
    if (abrirMapa != null) {
      params['abrir_mapa'] = abrirMapa ? 'true' : 'false';
    }
    if (motivoErro != null) {
      params['motivo_erro'] = motivoErro;
    }
    if (modoAcesso != null) {
      params['modo_acesso'] = modoAcesso;
    }
    if (duracaoMs != null) {
      params['duracao_ms'] = duracaoMs;
    }
    if (parametrosUtm != null) {
      params.addAll(parametrosUtm);
    }
    recordedParams['deep_link_aberto'] = params;
  }

  @override
  Future<void> logPerformanceAberturaApp({
    required String tipoStart,
    required String destino,
    required int duracaoMs,
  }) async {
    recordedEvents.add('performance_abertura_app');
    recordedParams['performance_abertura_app'] = {
      'tipo_start': tipoStart,
      'destino': destino,
      'acao': destino,
      'origem': tipoStart,
      'duracao_ms': duracaoMs,
    };
  }

  @override
  Future<void> logPerformanceSyncIndex({
    required String fase,
    required int duracaoMs,
    String? statusHttp,
    String? origem,
    String? modo,
    bool? teveAtualizacao,
    int? qtdPicosAtualizados,
    int? qtdThumbs,
  }) async {
    recordedEvents.add('performance_sync_index');
    final params = <String, dynamic>{
      'fase': fase,
      'acao': fase,
      'duracao_ms': duracaoMs,
    };
    if (statusHttp != null) {
      params['status_http'] = statusHttp;
    }
    if (origem != null) {
      params['origem'] = origem;
    }
    if (modo != null) {
      params['modo'] = modo;
    }
    if (teveAtualizacao != null) {
      params['teve_atualizacao'] = teveAtualizacao ? 'true' : 'false';
    }
    if (qtdPicosAtualizados != null) {
      params['qtd_picos_atualizados'] = qtdPicosAtualizados;
    }
    if (qtdThumbs != null) {
      params['qtd_thumbs'] = qtdThumbs;
    }
    recordedParams['performance_sync_index'] = params;
  }

  @override
  Future<void> logAcaoBetaAberto(
    String acao, {
    String? origem,
    String? canal,
    String? detalhe,
  }) async {
    recordedEvents.add('acao_beta_aberto');
    final params = <String, dynamic>{
      'acao': acao,
      'origem': origem ?? 'modal_beta',
    };
    if (canal != null) {
      params['canal'] = canal;
    }
    final infoDetalhe = detalhe ?? canal;
    if (infoDetalhe != null) {
      params['detalhe'] = infoDetalhe;
    }
    recordedParams['acao_beta_aberto'] = params;
  }

  @override
  Future<void> logApoioPix(String idCroqui) async {
    recordedEvents.add('apoio_pico');
    recordedParams['apoio_pico'] = {
      'id_croqui': idCroqui,
      'acao': 'copiar_pix',
      'origem': 'apoie_pico',
    };
  }

  @override
  Future<void> logAcaoGuardiaoSaida(String idCroqui, String acao) async {
    recordedEvents.add('guardiao_saida');
    recordedParams['guardiao_saida'] = {
      'id_croqui': idCroqui,
      'acao': acao,
      'origem': 'guardiao_saida',
      'modo_acesso': 'online',
    };
  }

  @override
  Future<void> logSalvarOfflineBanner(String idCroqui) async {
    recordedEvents.add('banner_modo_online');
    recordedParams['banner_modo_online'] = {
      'id_croqui': idCroqui,
      'acao': 'banner_salvar_offline',
      'origem': 'banner_online',
      'modo_acesso': 'online',
    };
  }

  @override
  Future<void> logNavegacaoPicoHub(String idCroqui, String secao) async {
    recordedEvents.add('navegacao_pico_hub');
    recordedParams['navegacao_pico_hub'] = {
      'id_croqui': idCroqui,
      'acao': secao,
      'origem': 'pico_hub',
    };
  }

  @override
  Future<void> logAlterarOrdenacao(String contexto, String modo) async {
    recordedEvents.add('alterar_ordenacao');
    recordedParams['alterar_ordenacao'] = {
      'acao': 'alterar_ordenacao',
      'origem': contexto,
      'detalhe': modo,
    };
  }

  @override
  Future<void> logAcaoConfiguracoes(String acao) async {
    recordedEvents.add('acao_configuracoes');
    recordedParams['acao_configuracoes'] = {'acao': acao};
  }

  @override
  Future<void> logAcaoFeedback(
    String acao, {
    String? origem,
    String? tipoFeedback,
    String? idCroqui,
    bool? temCroqui,
    int? qtdCaracteres,
    String? dispatcher,
    String? status,
    String? erro,
  }) async {
    recordedEvents.add('acao_feedback');
    final params = <String, Object>{'acao': acao};
    if (origem != null) params['origem'] = origem;
    if (tipoFeedback != null) params['tipo_feedback'] = tipoFeedback;
    if (idCroqui != null) params['id_croqui'] = idCroqui;
    if (temCroqui != null) params['tem_croqui'] = temCroqui.toString();
    if (qtdCaracteres != null) params['qtd_caracteres'] = qtdCaracteres;
    if (dispatcher != null) params['dispatcher'] = dispatcher;
    if (status != null) params['status'] = status;
    if (erro != null) params['erro'] = erro;
    recordedParams['acao_feedback'] = params;
  }

  @override
  Future<void> logDatabaseMigrationScreenOpened() async {
    recordedEvents.add('migracao_db');
    recordedParams['migracao_db'] = {'acao': 'aberta_tela_migracao'};
  }

  @override
  Future<void> logDatabaseMigrationTryAgain() async {
    recordedEvents.add('migracao_db');
    recordedParams['migracao_db'] = {
      'acao': 'tentar_novamente_clicado_tela_migracao',
    };
  }

  @override
  Future<void> logAppVersionHardBlock() async {
    recordedEvents.add('migracao_db');
    recordedParams['migracao_db'] = {'acao': 'tela_hard_block_mostrada'};
  }

  @override
  Future<void> logAppVersionSoftBlock() async {
    recordedEvents.add('migracao_db');
    recordedParams['migracao_db'] = {'acao': 'banner_soft_block_mostrado'};
  }

  @override
  Future<void> logAppVersionRecommendedUpdate() async {
    recordedEvents.add('migracao_db');
    recordedParams['migracao_db'] = {
      'acao': 'banner_versao_recomendada_mostrado',
    };
  }

  @override
  Future<void> logCompartilharEntidade({
    required String idCroqui,
    required String tipoEntidade,
    required String uid,
    bool abrirMapa = false,
  }) async {
    recordedEvents.add('compartilhar_entidade');
    recordedParams['compartilhar_entidade'] = {
      'id_croqui': idCroqui,
      'tipo_entidade': tipoEntidade,
      'uid': uid,
      'abrir_mapa': abrirMapa ? 'true' : 'false',
      'origem': abrirMapa ? 'mapa_interativo' : 'pagina_detalhe',
    };
  }

  @override
  Future<void> logFluidezSessaoTela({
    required String tela,
    String? idCroqui,
    required int duracaoMs,
    required int totalFrames,
    required int framesJank,
    required int taxaJankPct,
    required int p95UiMs,
    required int p95RasterMs,
  }) async {
    recordedEvents.add('fluidez_sessao_tela');
    final params = <String, dynamic>{
      'tela': tela,
      'acao': tela,
      'duracao_ms': duracaoMs,
      'total_frames': totalFrames,
      'frames_jank': framesJank,
      'taxa_jank_pct': taxaJankPct,
      'p95_ui_ms': p95UiMs,
      'p95_raster_ms': p95RasterMs,
      'tier_dispositivo': ClassificadorDispositivo.instancia.tierDispositivo,
      'ram_gb': ClassificadorDispositivo.instancia.ramGb,
    };
    if (idCroqui != null) {
      params['id_croqui'] = idCroqui;
    }
    recordedParams['fluidez_sessao_tela'] = params;
  }

  @override
  Future<void> logEvento(String nome, {Map<String, Object>? parametros}) async {
    recordedEvents.add(nome);
    if (parametros != null) {
      recordedParams[nome] = parametros;
    }
  }
}

/// Alias em português para [MockTelemetryService].
typedef MockTelemetria = MockTelemetryService;
