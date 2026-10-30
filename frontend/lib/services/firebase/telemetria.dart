// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../feedback/gravador_breadcrumbs.dart';
import 'app_logger.dart';
import 'classificador_dispositivo.dart';

/// Serviço responsável por disparar eventos de telemetria para o Firebase Analytics.
///
/// O uso deste serviço é fundamental para entender o engajamento dos usuários,
/// descobrir quais partes do aplicativo são mais acessadas, e quais croquis
/// recebem mais atenção. O Firebase agrega esses dados anonimamente.
///
/// ## Como adicionar novas telemetrias:
/// 1. Crie um novo método `Future<void> logNomeDaSuaAcao(...)` nesta classe.
/// 2. Defina os parâmetros necessários no mapa `params` que serão úteis para a análise.
/// 3. Chame o `_logEvent` passando o nome do evento e os parâmetros.
/// 4. Adicione um mock da nova função no `MockTelemetryService` e o verifique nos testes.
class TelemetryService {
  TelemetryService._privateConstructor();

  /// Instância singleton mutável (não const) para facilitar a injeção do mock nos testes.
  static TelemetryService instance = TelemetryService._privateConstructor();

  @visibleForTesting
  FirebaseAnalytics? debugAnalytics;

  FirebaseAnalytics? get _analytics =>
      debugAnalytics ??
      (AppLogger.firebaseInicializado ? FirebaseAnalytics.instance : null);

  @visibleForTesting
  static void resetForTesting() {
    instance = TelemetryService._privateConstructor();
  }

  /// Inicializa e configura a coleta do Firebase Analytics.
  ///
  /// Fora do modo de produção oficial ([kModoDesenvolvimento], incluindo `--debug`, `--profile` e `RELEASE_LOCAL`),
  /// a coleta analítica do Firebase é desativada (`setAnalyticsCollectionEnabled(false)`)
  /// para não registrar tráfego falso de teste/profiling nem poluir os relatórios do Looker Studio/GA4.
  Future<void> initialize({
    bool? isDebugMode,
    FirebaseAnalytics? analyticsInstance,
  }) async {
    final isDebug = isDebugMode ?? kModoDesenvolvimento;
    final analytics = analyticsInstance ?? _analytics;
    if (analytics == null) {
      AppLogger.instance.logAviso(
        '📊 [Telemetry] Firebase não inicializado. Telemetria nativa desativada.',
      );
      return;
    }

    if (isDebug) {
      try {
        await analytics.setAnalyticsCollectionEnabled(false);
        AppLogger.instance.logInfo(
          '📊 [Telemetry] Modo debug detectado: coleta do Firebase Analytics desativada.',
        );
      } catch (e, stackTrace) {
        AppLogger.instance.logError(
          '⚠️ [Telemetry] Erro ao desativar coleta do Firebase Analytics',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Método interno de utilidade para printar no console local e despachar ao Firebase.
  Future<void> _logEvent(String name, [Map<String, Object>? parameters]) async {
    final Map<String, Object>? parametrosEnriquecidos;
    if (parameters != null && parameters.containsKey('duracao_ms')) {
      parametrosEnriquecidos = <String, Object>{
        'tier_dispositivo': ClassificadorDispositivo.instancia.tierDispositivo,
        'ram_gb': ClassificadorDispositivo.instancia.ramGb,
        ...parameters,
      };
    } else {
      parametrosEnriquecidos = parameters;
    }
    GravadorBreadcrumbs.instance.registrar(
      evento: name,
      parametros: parametrosEnriquecidos,
    );
    AppLogger.instance.logInfo(
      '📈 [Telemetry] Evento disparado: $name | Parâmetros: $parametrosEnriquecidos',
    );
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(
        name: name,
        parameters: parametrosEnriquecidos,
      );
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '⚠️ [Telemetry] Erro ao enviar evento (Firebase pronto?)',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Retorna o appInstanceId do Firebase Analytics (útil para associar feedbacks à sessão).
  Future<String?> getAppInstanceId() async {
    final analytics = _analytics;
    if (analytics == null) return null;
    try {
      return await analytics.appInstanceId;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        '⚠️ [Telemetry] Erro ao obter appInstanceId',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Registra ações relacionadas à aba Explorar (ex: expandir detalhes, baixar croqui).
  Future<void> logAcaoExplorar(String idCroqui, String acao) {
    return _logEvent('acao_explorar', {'id_croqui': idCroqui, 'acao': acao});
  }

  /// Registra quando um croqui já baixado é atualizado com uma nova versão (sha256).
  /// Agora também armazena o timestamp exato do update.
  Future<void> logAtualizarCroqui(
    String idCroqui,
    String versao,
    String timestampAtualizacao,
  ) {
    return _logEvent('atualizar_croqui', {
      'id_croqui': idCroqui,
      'versao': versao,
      'timestamp_atualizacao': timestampAtualizacao,
    });
  }

  /// Registra ações diversas feitas dentro da página do pico (e.g. abrir_croqui, buscar, deletar).
  ///
  /// - [idCroqui]: Identificador único do croqui.
  /// - [acao]: Ação realizada (ex: `'abrir_croqui'`, `'buscar'`).
  /// - [origem]: Origem de navegação (ex: `'home'`, `'explorar'`, `'meus_croquis'`).
  /// - [modoAcesso]: Modo de acesso do croqui (`'offline'`, `'online'`, `'memoria'`, `'temp_cache'` ou `'cdn_online'`).
  /// - [primeiraVisita]: Indica se é a primeira vez que o usuário abre este croqui específico no dispositivo.
  /// - [duracaoMs]: Duração em milissegundos até a interatividade da página.
  Future<void> logAcaoCroqui(
    String idCroqui,
    String acao, {
    String? origem,
    String? modoAcesso,
    bool? primeiraVisita,
    int? duracaoMs,
  }) {
    final params = <String, Object>{'id_croqui': idCroqui, 'acao': acao};
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
    return _logEvent('acao_croqui', params);
  }

  /// Registra quando um setor específico de um pico é aberto.
  Future<void> logAbrirSetor(
    String idCroqui,
    String nomeSetor, {
    String? modoAcesso,
    int? duracaoMs,
  }) {
    final params = <String, Object>{
      'id_croqui': idCroqui,
      'nome_setor': nomeSetor,
    };
    if (modoAcesso != null) {
      params['modo_acesso'] = modoAcesso;
    }
    if (duracaoMs != null) {
      params['duracao_ms'] = duracaoMs;
    }
    return _logEvent('abrir_setor', params);
  }

  /// Registra quando um grupo (sub-setores) específico é aberto.
  Future<void> logAbrirGrupo(
    String idCroqui,
    String nomeGrupo, {
    String? modoAcesso,
    int? duracaoMs,
  }) {
    final params = <String, Object>{
      'id_croqui': idCroqui,
      'nome_grupo': nomeGrupo,
    };
    if (modoAcesso != null) {
      params['modo_acesso'] = modoAcesso;
    }
    if (duracaoMs != null) {
      params['duracao_ms'] = duracaoMs;
    }
    return _logEvent('abrir_grupo', params);
  }

  /// Registra quando o mapa de um setor ou de um grupo é maximizado/visualizado.
  Future<void> logAbrirMapa(
    String idCroqui,
    String nomeSetor, {
    String? modoAcesso,
    String? origemImagem,
    int? duracaoMs,
  }) {
    final params = <String, Object>{
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
    return _logEvent('abrir_mapa', params);
  }

  /// Registra ações relacionadas a uma escalada/via (e.g., ver no mapa, abrir detalhes).
  Future<void> logAcaoEscalada(
    String idCroqui,
    String nomeSetor,
    String nomeEscalada,
    String acao,
    String origem, {
    String? modoAcesso,
    int? duracaoMs,
  }) {
    final params = <String, Object>{
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
    return _logEvent('acao_escalada', params);
  }

  /// Registra cliques na navegação principal inferior do app.
  Future<void> logNavegarAba(String acao) {
    return _logEvent('navegar_aba', {'acao': acao});
  }

  /// Registra buscas realizadas na aba explorar (croquis inteiros).
  Future<void> logBuscaCroquis(String query, int numeroResultados) {
    return _logEvent('busca_croquis', {
      'query': query,
      'numero_resultados': numeroResultados,
    });
  }

  /// Registra buscas globais dentro de um croqui buscando por vias.
  Future<void> logBuscaEscaladas(
    String query,
    int numeroResultados,
    String idCroqui,
  ) {
    return _logEvent('busca_escaladas', {
      'query': query,
      'numero_resultados': numeroResultados,
      'id_croqui': idCroqui,
    });
  }

  /// Registra os eventos de sincronização de dados local.
  Future<void> logSincronizarApp({required String acao}) {
    return _logEvent('sincronizar_app', {'acao': acao});
  }

  /// Registra o resultado final da sincronização de dados (sucesso, sem_atualizacoes, erro).
  Future<void> logResultadoSincronizacao(String status) {
    return _logEvent('resultado_sincronizacao', {'acao': status});
  }

  /// Registra a subida hierárquica no mapa interativo (ex: de Setor para Grupo).
  Future<void> logNavegacaoHierarquica(String idCroqui, String destino) {
    return _logEvent('navegacao_hierarquica_mapa', {
      'id_croqui': idCroqui,
      'acao': destino,
    });
  }

  /// Registra cliques em links de rotas de GPS e páginas web (ex: Termos de uso, redes sociais).
  Future<void> logLinkExterno(String url, String origem, {String? detalhe}) {
    return _logEvent('link_externo', {
      'acao': 'abrir_link_externo',
      'url': url,
      'origem': origem,
      'detalhe': detalhe ?? url,
    });
  }

  /// Registra ações analíticas ocorridas no Índice de Escaladas e seus filtros.
  ///
  /// - [idCroqui]: Identificador único do croqui/pico.
  /// - [acao]: Ação realizada (ex: `'filtrar_grau'`, `'filtrar_setor'`, `'filtrar_conquistador'`, `'filtrar_classicas'`, `'limpar_filtros'`, `'expandir_filtros'`, `'colapsar_filtros'`, `'trocar_aba'`).
  /// - [modalidade]: Modalidade da escalada (ex: `'Esportiva'`, `'Boulder'`, `'Móvel'`, etc.). É mapeada para a dimensão existente `origem` como `'indice_<modalidade>'`.
  /// - [detalhe]: Valor opcional livre (ex: `'5º a 8ºb'`, `'André Braga'`, `'true'`).
  Future<void> logAcaoIndiceEscaladas(
    String idCroqui,
    String acao, {
    required String modalidade,
    String? detalhe,
  }) {
    final origemModalidade = modalidade.toLowerCase().startsWith('indice_')
        ? modalidade.toLowerCase()
        : 'indice_${modalidade.toLowerCase()}';
    final params = <String, Object>{
      'id_croqui': idCroqui,
      'acao': acao,
      'origem': origemModalidade,
    };
    if (detalhe != null) {
      params['detalhe'] = detalhe;
    }
    return _logEvent('acao_indice_escaladas', params);
  }

  /// Registra abertura e resolução de Deep Links e QR Codes físicos.
  ///
  /// - [idCroqui]: Identificador único do croqui/pico.
  /// - [destino]: Destino do link (ex: `'pico'`, `'grupo'`, `'setor'`, `'via'`).
  /// - [sucesso]: Se a resolução e abertura foi bem-sucedida.
  /// - [tipoStart]: `'cold_start'` (app aberto do zero) ou `'warm_start'` (app já em memória).
  /// - [motivoErro]: Caso tenha falhado (ex: `'sem_conexao'`, `'pico_nao_encontrado'`).
  /// - [modoAcesso]: Camada de resolução (`'memoria'`, `'offline'`, `'temp_cache'`, `'cdn_online'`).
  /// - [duracaoMs]: Duração em milissegundos até a interatividade da página.
  /// - [parametrosUtm]: Parâmetros UTM extraídos da URL (`utm_source`, `utm_medium`, `utm_campaign`, etc.).
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
  }) {
    final params = <String, Object>{
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
    return _logEvent('deep_link_aberto', params);
  }

  /// Registra a performance de inicialização do aplicativo até a interatividade real (`HomePage`).
  Future<void> logPerformanceAberturaApp({
    required String tipoStart,
    required String destino,
    required int duracaoMs,
  }) {
    return _logEvent('performance_abertura_app', {
      'tipo_start': tipoStart,
      'destino': destino,
      'acao': destino,
      'origem': tipoStart,
      'duracao_ms': duracaoMs,
    });
  }

  /// Registra a performance de cada uma das fases da sincronização de catálogo e mídias (`syncIndex`).
  Future<void> logPerformanceSyncIndex({
    required String fase,
    required int duracaoMs,
    String? statusHttp,
    String? origem,
    String? modo,
    bool? teveAtualizacao,
    int? qtdPicosAtualizados,
    int? qtdThumbs,
  }) {
    final params = <String, Object>{
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
    return _logEvent('performance_sync_index', params);
  }

  /// Registra interações no modal informativo de Beta Aberto.
  ///
  /// - [acao]: Ação realizada (ex: `'abrir_modal_beta'`, `'clique_instagram'`, `'clique_whatsapp'`, `'clique_feedback'`).
  /// - [origem]: Origem do disparo (padrão `'modal_beta'`, ou `'home_header'`).
  /// - [canal]: Canal específico se aplicável (`'instagram'`, `'whatsapp'`).
  /// - [detalhe]: Informação complementar enviada à dimensão genérica.
  Future<void> logAcaoBetaAberto(
    String acao, {
    String? origem,
    String? canal,
    String? detalhe,
  }) {
    final params = <String, Object>{
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
    return _logEvent('acao_beta_aberto', params);
  }

  /// Registra quando o usuário copia a chave PIX de apoio ao pico.
  Future<void> logApoioPix(String idCroqui) {
    return _logEvent('apoio_pico', {
      'id_croqui': idCroqui,
      'acao': 'copiar_pix',
      'origem': 'apoie_pico',
    });
  }

  /// Registra ações do guardião de saída ao tentar sair de croqui online não salvo.
  ///
  /// - [idCroqui]: Identificador do croqui.
  /// - [acao]: Ação executada (`'exibir_modal'`, `'guardiao_salvar_offline'`, `'guardiao_sair_sem_salvar'`).
  Future<void> logAcaoGuardiaoSaida(String idCroqui, String acao) {
    return _logEvent('guardiao_saida', {
      'id_croqui': idCroqui,
      'acao': acao,
      'origem': 'guardiao_saida',
      'modo_acesso': 'online',
    });
  }

  /// Registra o clique no botão "Salvar Offline" do banner de modo online.
  Future<void> logSalvarOfflineBanner(String idCroqui) {
    return _logEvent('banner_modo_online', {
      'id_croqui': idCroqui,
      'acao': 'banner_salvar_offline',
      'origem': 'banner_online',
      'modo_acesso': 'online',
    });
  }

  /// Registra cliques de navegação nos cards centrais da página do pico (Hub).
  ///
  /// - [idCroqui]: Identificador do pico.
  /// - [secao]: Seção acessada (ex: `'abrir_setores_e_escaladas'`, `'abrir_setores'`, `'abrir_indice_escaladas'`, `'abrir_explorar_local'`, `'abrir_regras'`, `'abrir_comunidade'`, `'abrir_creditos'`).
  Future<void> logNavegacaoPicoHub(String idCroqui, String secao) {
    return _logEvent('navegacao_pico_hub', {
      'id_croqui': idCroqui,
      'acao': secao,
      'origem': 'pico_hub',
    });
  }

  /// Registra a alteração de critérios de ordenação de listas (ex: setores, vias).
  ///
  /// - [contexto]: Contexto da ordenação (`'setor'`, `'grupo'`, `'browse'`).
  /// - [modo]: Modo selecionado (`'grau'`, `'nome'`, `'padrao'`).
  Future<void> logAlterarOrdenacao(String contexto, String modo) {
    return _logEvent('alterar_ordenacao', {
      'acao': 'alterar_ordenacao',
      'origem': contexto,
      'detalhe': modo,
    });
  }

  /// Registra interações gerais nas telas de configuracao.
  Future<void> logAcaoConfiguracoes(String acao) {
    return _logEvent('acao_configuracoes', {'acao': acao});
  }

  /// Registra interações do sistema de In-App Feedback (abrir, enviar, cancelar, despacho).
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
  }) {
    final parametros = <String, Object>{'acao': acao};
    if (origem != null) parametros['origem'] = origem;
    if (tipoFeedback != null) parametros['tipo_feedback'] = tipoFeedback;
    if (idCroqui != null) parametros['id_croqui'] = idCroqui;
    if (temCroqui != null) parametros['tem_croqui'] = temCroqui.toString();
    if (qtdCaracteres != null) parametros['qtd_caracteres'] = qtdCaracteres;
    if (dispatcher != null) parametros['dispatcher'] = dispatcher;
    if (status != null) parametros['status'] = status;
    if (erro != null) parametros['erro'] = erro;
    return _logEvent('acao_feedback', parametros);
  }

  /// Registra a visualização da tela de atualização de banco de dados
  Future<void> logDatabaseMigrationScreenOpened() {
    return _logEvent('migracao_db', {'acao': 'aberta_tela_migracao'});
  }

  /// Registra cliques no botão de tentar novamente durante falhas de update
  Future<void> logDatabaseMigrationTryAgain() {
    return _logEvent('migracao_db', {
      'acao': 'tentar_novamente_clicado_tela_migracao',
    });
  }

  /// Registra quando o aplicativo é bloqueado devido à hardMinVersion
  Future<void> logAppVersionHardBlock() {
    return _logEvent('migracao_db', {'acao': 'tela_hard_block_mostrada'});
  }

  /// Registra quando o banner de atualização obrigatória é exibido (softMinVersion)
  Future<void> logAppVersionSoftBlock() {
    return _logEvent('migracao_db', {'acao': 'banner_soft_block_mostrado'});
  }

  /// Registra quando o banner de atualização recomendada é exibido
  Future<void> logAppVersionRecommendedUpdate() {
    return _logEvent('migracao_db', {
      'acao': 'banner_versao_recomendada_mostrado',
    });
  }

  /// Registra o compartilhamento nativo de um croqui, grupo, setor, via ou mapa.
  ///
  /// - [idCroqui]: Identificador do croqui/pico (ex: `'br_mg_igarape_pedra_grande'`).
  /// - [tipoEntidade]: Tipo da entidade compartilhada (`'pico'`, `'grupo'`, `'setor'`, `'via'`).
  /// - [uid]: Identificador universal (NanoID 14c) da entidade compartilhada.
  /// - [abrirMapa]: `true` quando compartilhado a partir do mapa interativo (`/sm/<uid>`), `false` quando da página (`/s/<uid>`).
  Future<void> logCompartilharEntidade({
    required String idCroqui,
    required String tipoEntidade,
    required String uid,
    bool abrirMapa = false,
  }) {
    return _logEvent('compartilhar_entidade', {
      'id_croqui': idCroqui,
      'tipo_entidade': tipoEntidade,
      'uid': uid,
      'abrir_mapa': abrirMapa ? 'true' : 'false',
      'origem': abrirMapa ? 'mapa_interativo' : 'pagina_detalhe',
    });
  }

  /// Registra a fluidez de quadros (UI e Raster P95 e taxa de jank) de uma sessão interativa.
  Future<void> logFluidezSessaoTela({
    required String tela,
    String? idCroqui,
    required int duracaoMs,
    required int totalFrames,
    required int framesJank,
    required int taxaJankPct,
    required int p95UiMs,
    required int p95RasterMs,
  }) {
    final params = <String, Object>{
      'tela': tela,
      'acao': tela,
      'duracao_ms': duracaoMs,
      'total_frames': totalFrames,
      'frames_jank': framesJank,
      'taxa_jank_pct': taxaJankPct,
      'p95_ui_ms': p95UiMs,
      'p95_raster_ms': p95RasterMs,
    };
    if (idCroqui != null) {
      params['id_croqui'] = idCroqui;
    }
    return _logEvent('fluidez_sessao_tela', params);
  }

  /// Dispara um evento de telemetria genérico com parâmetros customizados.
  Future<void> logEvento(String nome, {Map<String, Object>? parametros}) {
    return _logEvent(nome, parametros);
  }
}
