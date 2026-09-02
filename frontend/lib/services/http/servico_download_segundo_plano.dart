// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';
import 'sync_service.dart';

/// Serviço responsável por orquestrar downloads de croquis completos para o armazenamento local,
/// permitindo execução resiliente em segundo plano e notificação contínua de progresso.
class ServicoDownloadSegundoPlano {
  final SyncService syncService;

  ServicoDownloadSegundoPlano({required this.syncService});

  /// Executa o download de um croqui específico utilizando o [SyncService].
  ///
  /// Retorna `true` se o download e a verificação atômica de arquivos forem bem sucedidos.
  Future<bool> executarDownload(ResumoCroqui resumo) async {
    try {
      debugPrint(
        '[ServicoDownloadSegundoPlano] Iniciando download do croqui ${resumo.id} (${resumo.nome})...',
      );
      final sucesso = await syncService.downloadCrag(resumo);
      debugPrint(
        '[ServicoDownloadSegundoPlano] Download de ${resumo.id} finalizado com status: $sucesso',
      );
      return sucesso;
    } catch (e) {
      debugPrint(
        '[ServicoDownloadSegundoPlano] Falha ao executar download do croqui ${resumo.id}: $e',
      );
      return false;
    }
  }
}
