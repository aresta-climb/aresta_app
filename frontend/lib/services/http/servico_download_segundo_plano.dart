// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';
import '../firebase/app_logger.dart';
import '../notificacoes/gerenciador_notificacao_download.dart';
import 'sync_service.dart';

/// Serviço responsável por orquestrar downloads de croquis completos para o armazenamento local,
/// permitindo execução resiliente em segundo plano e notificação contínua de progresso na bandeja do SO.
class ServicoDownloadSegundoPlano {
  final SyncService syncService;
  final GerenciadorNotificacaoDownload gerenciadorNotificacao;

  ServicoDownloadSegundoPlano({
    required this.syncService,
    GerenciadorNotificacaoDownload? gerenciadorNotificacao,
  }) : gerenciadorNotificacao =
            gerenciadorNotificacao ?? GerenciadorNotificacaoDownload.instancia;

  /// Executa o download de um croqui específico utilizando o [SyncService] e atualizando as notificações nativas.
  ///
  /// Retorna `true` se o download e a verificação atômica de arquivos forem bem sucedidos.
  Future<bool> executarDownload(ResumoCroqui resumo) async {
    final picoId = resumo.id;
    final nomePico = resumo.nome.isNotEmpty ? resumo.nome : picoId;

    void atualizarNotificacaoProgresso() {
      final progresso = syncService.downloadingCrags.value[picoId];
      if (progresso != null) {
        gerenciadorNotificacao.atualizarProgresso(picoId, nomePico, progresso);
      }
    }

    try {
      debugPrint(
        '[ServicoDownloadSegundoPlano] Iniciando download do croqui $picoId ($nomePico)...',
      );

      await gerenciadorNotificacao.solicitarPermissoes();

      syncService.downloadingCrags.addListener(atualizarNotificacaoProgresso);

      final sucesso = await syncService.downloadCrag(resumo);

      if (sucesso) {
        await gerenciadorNotificacao.notificarConclusao(picoId, nomePico);
      } else {
        debugPrint(
          '🛑 [ServicoDownloadSegundoPlano] Falha no download do croqui $picoId ($nomePico). Verifique logs anteriores do SyncService/SyncIsolate.',
        );
        AppLogger.instance.logFalhaSyncOuDownload(
          'Falha no download do croqui $picoId ($nomePico) em segundo plano',
        );
        await gerenciadorNotificacao.notificarFalha(picoId, nomePico);
      }

      debugPrint(
        '[ServicoDownloadSegundoPlano] Download de $picoId finalizado com status: $sucesso',
      );
      return sucesso;
    } catch (e, stack) {
      debugPrint(
        '🛑 [ServicoDownloadSegundoPlano] Exceção ao executar download do croqui $picoId: $e',
      );
      AppLogger.instance.logFalhaSyncOuDownload(
        'Exceção ao baixar croqui $picoId ($nomePico) em segundo plano',
        error: e,
        stackTrace: stack,
      );
      await gerenciadorNotificacao.notificarFalha(
        picoId,
        nomePico,
        'Erro inesperado ao baixar croqui.',
      );
      return false;
    } finally {
      syncService.downloadingCrags.removeListener(atualizarNotificacaoProgresso);
    }
  }
}
