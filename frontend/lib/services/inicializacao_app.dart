// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:frontend/application_managers/migracao/migracao_background_orchestrator.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/http/sync_service.dart';

/// Configura os parâmetros de gestão de memória e teto LRU do Flutter para
/// garantir conformidade com os novos requisitos técnicos do Google Play (Android Vitals).
///
/// Define o tamanho máximo de bytes em memória RAM para o [PaintingBinding.instance.imageCache]
/// como [tamanhoMaximoBytes] (por padrão 100 MB). Isso preserva os últimos 5-6 croquis em alta
/// resolução para consulta instantânea na rocha, mantendo o consumo em segundo plano bem
/// abaixo do limite de 200 MB da Google Play.
void configurarGestaoMemoria({int tamanhoMaximoBytes = 100 * 1024 * 1024}) {
  PaintingBinding.instance.imageCache.maximumSizeBytes = tamanhoMaximoBytes;
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
}) async {
  // Cancela com segurança qualquer migração em segundo plano ativa (Foreground Takeover)
  await MigracaoBackgroundOrchestrator.cancelarMigracaoSegundoPlano(
    workmanager: workmanager,
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
}) {
  editor.eventoLiveReload.addListener(() async {
    final evento = editor.eventoLiveReload.value;
    if (evento != null) {
      AppLogger.instance.logInfo(
        '⚡ [LiveReload] Evento push recebido no Flutter! (Setor/ID: ${evento.setorId}). Disparando sync...',
      );
      await syncService.syncIndex();

      // Recarrega sob demanda croquis que estejam abertos em sessão online
      final servicoOnline = servicoCroquiOnline ??
          ServicoCroquiOnline(sessaoOnline: datasetRepo.gerenciadorSessaoOnline);
      final croquisOnlineIds =
          datasetRepo.gerenciadorSessaoOnline.croquisEmMemoria.keys.toList();
      for (final picoId in croquisOnlineIds) {
        final picosDisponiveis =
            datasetRepo.activeDataset.value?.picosDisponiveis ?? [];
        final picoItem = picosDisponiveis.firstWhere(
          (p) => p.id == picoId,
          orElse: () => const ResumoPico(id: '', nome: '', local: ''),
        );
        final url = picoItem.url;
        if (url.isNotEmpty) {
          await servicoOnline.recarregarCroquiOnline(url, picoId: picoId);
          datasetRepo.notificarAtualizacaoSessaoOnline(picoId);
        }
      }

      // Purgação cirúrgica do cache inativo do Flutter sem descartar texturas ativas da GPU
      final cache = imageCache ?? PaintingBinding.instance.imageCache;
      cache.clear();

      AppLogger.instance.logInfo(
        '⚡ [LiveReload] Sincronização automática concluída!',
      );
    }
  });
}
