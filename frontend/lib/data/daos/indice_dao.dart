// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import '../../aresta_api/proto/generated/indice.pb.dart';
import '../../services/firebase/app_logger.dart';

/// Data Access Object (DAO) responsável pela persistência e leitura direta da mensagem Protobuf [Indice].
///
/// Encapsula a leitura do arquivo `indice.binarypb` no armazenamento local e gravação de novos catálogos sincronizados.
class IndiceDao {
  /// Lê e desserializa o [Indice] a partir do caminho físico informado.
  Future<Indice?> carregarDoDisco(String caminhoArquivo) async {
    try {
      final arquivo = File(caminhoArquivo);
      if (await arquivo.exists()) {
        final bytes = await arquivo.readAsBytes();
        return Indice.fromBuffer(bytes);
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao carregar índice do disco em $caminhoArquivo',
        error: e,
        stackTrace: stackTrace,
