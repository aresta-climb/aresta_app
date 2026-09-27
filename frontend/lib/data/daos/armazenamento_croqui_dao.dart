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
