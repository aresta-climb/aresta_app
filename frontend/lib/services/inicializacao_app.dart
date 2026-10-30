// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:frontend/application_managers/migracao/migracao_background_orchestrator.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/localizador_destino_uid.dart';
import 'package:frontend/navigation/servico_navegacao_deep_link.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/classificador_dispositivo.dart';
import 'package:frontend/services/http/sync_service.dart';

/// Configura os parâmetros de gestão de memória e teto LRU do Flutter para
/// garantir conformidade com os novos requisitos técnicos do Google Play (Android Vitals).
///
/// Quando [tamanhoMaximoBytes] não é informado explicitamente, classifica o porte de memória RAM
/// do aparelho via [ClassificadorDispositivo] e define o teto adaptativo do
/// [PaintingBinding.instance.imageCache] (50 MB para tier `'baixo'`, 100 MB para `'medio'`/fallback
/// e 150 MB para `'alto'`).
void configurarGestaoMemoria({
  int? tamanhoMaximoBytes,
  int? ramTotalMb,
  String? caminhoMeminfo,
}) {
  if (tamanhoMaximoBytes != null) {
    PaintingBinding.instance.imageCache.maximumSizeBytes = tamanhoMaximoBytes;
    return;
  }
  final perfil = ClassificadorDispositivo.instancia.classificar(
    ramTotalMb: ramTotalMb,
    caminhoMeminfo: caminhoMeminfo,
  );
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      perfil.limiteCacheImagensBytes;
}

/// Realiza a migração silenciosa das versões antigas dos termos legais aceitos pelo usuário.
///
/// Anteriormente, a aceitação dos termos era armazenada como um booleano (`accepted_terms`).
/// Com a introdução do controle versionado (`accepted_legal_version`), migramos usuários
/// preexistentes para a versão base (1) e removemos a chave obsoleta para evitar inconsistências.
/// Retorna o valor de `accepted_legal_version` (ou `null` se nunca aceito).
Future<int?> migrarTermosLegais(SharedPreferences prefs) async {
  int? acceptedLegalVersion = prefs.getInt('accepted_legal_version');
  final bool oldAcceptedTerms = prefs.getBool('accepted_terms') ?? false;

  if (oldAcceptedTerms && acceptedLegalVersion == null) {
    await prefs.setInt('accepted_legal_version', 1);
    acceptedLegalVersion = 1;
    await prefs.remove('accepted_terms');
  } else if (oldAcceptedTerms) {
    await prefs.remove('accepted_terms');
  }

  return acceptedLegalVersion;
}

/// Executa uma etapa assíncrona de pré-boot com limite de tempo ([timeout]) e
/// captura de falhas, evitando que a lentidão ou travamento de um plugin nativo
/// congele o aplicativo na splash screen nativa antes do `runApp`.
Future<void> executarEtapaPreBootComTimeout(
  String nomeEtapa,
  Future<void> Function() etapa, {
  Duration timeout = const Duration(seconds: 4),
}) async {
  try {
    await etapa().timeout(timeout);
  } catch (e, stackTrace) {
    AppLogger.instance.logAviso(
      '[InicializacaoApp] Etapa de pré-boot "$nomeEtapa" excedeu o tempo limite ou falhou: $e',
    );
    AppLogger.instance.logError(
      '[InicializacaoApp] Falha defensiva na etapa de pré-boot: $nomeEtapa',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

/// Inicializa os serviços de dados e sincronização no primeiro plano da aplicação.
///
/// Interrompe preventivamente qualquer migração em segundo plano em execução
/// (Foreground Takeover) para evitar conflitos de I/O de disco, inicializa o
/// [DatasetRepository] e verifica se a base local precisa de migração estrutural.
/// Caso não necessite, inicia a sincronização do índice em plano de fundo.
Future<bool> setupAppServices(
  DatasetRepository datasetRepo,
  SyncService syncService, {
  Workmanager? workmanager,
  Duration timeoutCancelamentoMigracao = const Duration(seconds: 2),
}) async {
  // Cancela com segurança qualquer migração em segundo plano ativa (Foreground Takeover)
  await MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano(
    workmanager: workmanager,
    timeoutCancelamento: timeoutCancelamentoMigracao,
  );

  await datasetRepo.init();

  final needsMigration = await syncService.checkNeedsMigration();
  if (!needsMigration) {
    // Roda em background sem bloquear o fluxo principal
    syncService.syncIndex();
  }
  return needsMigration;
}

/// Registra ouvintes para eventos de Live Reload emitidos pelo Editor Desktop via WebSocket.
///
/// Dispara a sincronização do índice, recarrega sob demanda croquis que estejam abertos
/// em sessão online e purga cirurgicamente o cache inativo de imagens da GPU sem
/// descartar texturas atualmente renderizadas na tela.
void registrarOuvintesLiveReload(
  EditorDeCroqui editor,
  DatasetRepository datasetRepo,
  SyncService syncService, {
  ServicoCroquiOnline? servicoCroquiOnline,
  ImageCache? imageCache,
  Duration debounceDuration = const Duration(milliseconds: 50),
}) {
  Timer? debounceTimer;
  editor.eventoLiveReload.addListener(() {
    final evento = editor.eventoLiveReload.value;
    if (evento != null) {
      debounceTimer?.cancel();
      debounceTimer = Timer(debounceDuration, () async {
        AppLogger.instance.logInfo(
          '⚡ [LiveReload] Evento push recebido no Flutter! (Setor/ID: ${evento.setorId}). Disparando sync...',
        );
        await syncService.syncIndex(auto: false, forceBypassCache: true);

        // Recarrega sob demanda croquis que estejam abertos em sessão online
        final servicoOnline = servicoCroquiOnline ??
            ServicoCroquiOnline(sessaoOnline: datasetRepo.gerenciadorSessaoOnline);
        final croquisOnlineIds =
            datasetRepo.gerenciadorSessaoOnline.croquisEmMemoria.keys.toList();
        for (final picoId in croquisOnlineIds) {
          final picosDisponiveis =
              datasetRepo.activeDataset.value?.picosDisponiveis ?? [];
          for (final picoItem in picosDisponiveis) {
            if (picoItem.id == picoId && picoItem.url.isNotEmpty) {
              await servicoOnline.recarregarCroquiOnline(
                picoItem.url,
                picoId: picoId,
              );
              datasetRepo.notificarAtualizacaoSessaoOnline(picoId);
              break;
            }
          }
        }

        // Purgação cirúrgica do cache inativo do Flutter sem descartar texturas ativas da GPU
        final cache = imageCache ?? PaintingBinding.instance.imageCache;
        cache.clear();

        AppLogger.instance.logInfo(
          '⚡ [LiveReload] Sincronização automática concluída!',
        );
      });
    }
  });
}

/// Resultado da resolução antecipada de Deep Link durante o *Cold Start* do aplicativo.
class ResultadoResolucaoColdStart {
  /// Controlador de navegação já posicionado no nó de destino (ou na [HomeNode] padrão).
  final TreeNavigationController treeController;

  /// URI inicial processada durante o *Cold Start*, para deduplicação em `GerenciadorDeepLinks`.
  final Uri? linkInicialProcessado;

  /// Mensagem de aviso gerada caso o link inicial aponte para um UID não encontrado.
  final String? mensagemAvisoInicial;

  /// Metadados da entidade/croqui quando o link inicial aponta para um croqui não baixado e sem conexão.
  final ItemCatalogoBusca? itemSemConexaoInicial;

  const ResultadoResolucaoColdStart({
    required this.treeController,
    this.linkInicialProcessado,
    this.mensagemAvisoInicial,
    this.itemSemConexaoInicial,
  });
}

/// Resolve antecipadamente o link inicial de *Cold Start* enquanto a splash screen está visível,
/// retornando o [TreeNavigationController] já posicionado no nó de destino para evitar
/// piscar a `HomePage` antes de navegar para o link.
///
/// Impõe um limite de tempo ([timeoutResolucao]) e captura exceções para garantir que a
/// splash reativa seja sempre encerrada com transição segura para a [HomeNode].
Future<ResultadoResolucaoColdStart> resolverDestinoInicialColdStart(
  DatasetRepository datasetRepo, {
  AppLinks? appLinks,
  SyncService? syncService,
  TreeNavigationController? treeController,
  Duration timeoutResolucao = const Duration(seconds: 8),
}) async {
  final controller = treeController ?? TreeNavigationController();

  try {
    return await () async {
      Uri? initialUri;

      try {
        initialUri = await (appLinks ?? AppLinks()).getInitialLink();
      } catch (e, st) {
        if (e is! MissingPluginException) {
          AppLogger.instance.logError(
            '[InicializacaoApp] Falha ao consultar getInitialLink no Cold Start',
            error: e,
            stackTrace: st,
          );
        }
      }

      if (initialUri == null) {
        return ResultadoResolucaoColdStart(treeController: controller);
      }

      String? mensagemAviso;
      ItemCatalogoBusca? itemSemConexao;
      final navigator = DeepLinkNavigatorService(
        datasetRepo: datasetRepo,
        treeController: controller,
        localizadorUid: LocalizadorDestinoUid(
          datasetRepo: datasetRepo,
          syncService: syncService,
        ),
        onMensagemAviso: (msg) => mensagemAviso = msg,
        onCroquiSemConexao: (item, _) => itemSemConexao = item,
      );

      await navigator.processarLink(initialUri, tipoStart: 'cold_start');

      return ResultadoResolucaoColdStart(
        treeController: controller,
        linkInicialProcessado: initialUri,
        mensagemAvisoInicial: mensagemAviso,
        itemSemConexaoInicial: itemSemConexao,
      );
    }().timeout(timeoutResolucao);
  } on TimeoutException {
    controller.goHome();
    AppLogger.instance.logAviso(
      '[InicializacaoApp] Tempo limite excedido ao resolver destino inicial no Cold Start ($timeoutResolucao). Abrindo na Home.',
    );
    return ResultadoResolucaoColdStart(treeController: controller);
  }
}
