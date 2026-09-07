// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import '../../../aresta_api/proto/generated/croqui.pb.dart';
import '../../firebase/app_logger.dart';

/// Gerencia as operações de entrada/saída de arquivos no armazenamento permanente (`/downloads`).
class GerenciadorArquivosLocais {
  /// Carrega e desserializa o [Croqui] completo a partir do diretório de downloads local.
  Future<Croqui?> carregarCroqui(String downloadsPath, String picoId) async {
    try {
      final file = File('$downloadsPath/$picoId/$picoId.binarypb');
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return Croqui.fromBuffer(bytes);
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao carregar croqui local $picoId em $downloadsPath',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  /// Verifica se o croqui do [picoId] está presente no diretório de downloads.
  Future<bool> verificarPicoBaixado(String downloadsPath, String picoId) async {
    final file = File('$downloadsPath/$picoId/$picoId.binarypb');
    return file.exists();
  }

  /// Exclui a pasta do pico do armazenamento local.
  Future<bool> excluirPico(String downloadsPath, String picoId) async {
    try {
      final dir = Directory('$downloadsPath/$picoId');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        AppLogger.instance.logInfo(
          '[GerenciadorArquivosLocais] Pasta do pico $picoId deletada com sucesso.',
        );
        return true;
      } else {
        AppLogger.instance.logInfo(
          '[GerenciadorArquivosLocais] Pasta não encontrada para deleção: ${dir.path}',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao excluir pasta do pico $picoId',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return false;
  }
}
