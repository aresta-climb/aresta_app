// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../../aresta_api/proto/generated/croqui.pb.dart';
import '../../../data/daos/armazenamento_croqui_dao.dart';

/// Gerencia as operações de entrada/saída de arquivos no armazenamento permanente (`/downloads`).
///
/// Delega as leituras físicas e manipulações de arquivo binário ao [ArmazenamentoCroquiDao].
class GerenciadorArquivosLocais {
  final ArmazenamentoCroquiDao _dao;

  /// Cria uma nova instância de [GerenciadorArquivosLocais], permitindo injeção de [ArmazenamentoCroquiDao].
  GerenciadorArquivosLocais({ArmazenamentoCroquiDao? dao})
      : _dao = dao ?? ArmazenamentoCroquiDao();

  /// Carrega e desserializa o [Croqui] completo a partir do diretório de downloads local.
  ///
  /// Prioriza o caminho canônico `compilado.binarypb`. Caso localize o arquivo legado `<picoId>.binarypb`,
  /// executa uma migração transparente (*lazy rename*) no mesmo diretório antes de desserializar.
  Future<Croqui?> carregarCroqui(String downloadsPath, String picoId) =>
      _dao.carregarCroqui(downloadsPath, picoId);

  /// Verifica se o croqui do [picoId] está presente no diretório de downloads (canônico ou legado).
  Future<bool> verificarPicoBaixado(String downloadsPath, String picoId) =>
      _dao.verificarPicoBaixado(downloadsPath, picoId);

  /// Exclui a pasta do pico do armazenamento local.
  Future<bool> excluirPico(String downloadsPath, String picoId) =>
      _dao.excluirPico(downloadsPath, picoId);
}
