// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../services/firebase/app_logger.dart';

/// Data Access Object (DAO) responsável pela leitura e escrita direta de entidades Protobuf [Croqui] no disco local.
///
/// Encapsula a manipulação física dos arquivos binários (`compilado.binarypb`), renomeações transparentes de arquivos
/// legados e remoção de pastas de dados.
class ArmazenamentoCroquiDao {
  /// Carrega e desserializa a entidade [Croqui] diretamente dos bytes binários salvos no armazenamento local.
  Future<Croqui?> carregarCroqui(String downloadsPath, String picoId) async {
    try {
      final canonicalFile = File('$downloadsPath/$picoId/compilado.binarypb');
      if (await canonicalFile.exists()) {
        final bytes = await canonicalFile.readAsBytes();
        return Croqui.fromBuffer(bytes);
      }

      final legacyFile = File('$downloadsPath/$picoId/$picoId.binarypb');
      if (await legacyFile.exists()) {
        try {
          await legacyFile.rename(canonicalFile.path);
          final bytes = await canonicalFile.readAsBytes();
          return Croqui.fromBuffer(bytes);
        } catch (_) {
          final bytes = await legacyFile.readAsBytes();
          return Croqui.fromBuffer(bytes);
        }
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

  /// Verifica se o arquivo binário do [picoId] existe no diretório de downloads (formato canônico ou legado).
  Future<bool> verificarPicoBaixado(String downloadsPath, String picoId) async {
    final canonicalFile = File('$downloadsPath/$picoId/compilado.binarypb');
    if (await canonicalFile.exists()) return true;

    final legacyFile = File('$downloadsPath/$picoId/$picoId.binarypb');
    return legacyFile.exists();
  }

  /// Exclui o diretório e os arquivos locais associados ao [picoId].
  Future<bool> excluirPico(String downloadsPath, String picoId) async {
    try {
      final dir = Directory('$downloadsPath/$picoId');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        AppLogger.instance.logInfo(
          '[ArmazenamentoCroquiDao] Pasta do pico $picoId excluída com sucesso.',
        );
        return true;
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
