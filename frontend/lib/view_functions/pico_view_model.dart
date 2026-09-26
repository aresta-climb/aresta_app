// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../services/dataset_repository.dart';
import '../utils/pico_categorization.dart';

/// Modelo de apresentação e gerenciador de estado para a tela [PicoDetailsPage] (MVVM).
///
/// Encapsula a formatação estatística do pico (setores, modalidades, contagem de vias),
/// o ciclo de vida do polling de atualizações online (ETag), a interceptação de saída
/// para picos não salvos offline e operações de download/exclusão.
class PicoViewModel extends ChangeNotifier {
  /// Dados do pico obtidos a partir do croqui.
  final Pico pico;

  /// Objeto completo do croqui.
  final Croqui croqui;

  /// Identificador único do pico/crag.
  final String cragId;

  /// Repositório de dados com dataset ativo e gerenciamento de armazenamento.
  final DatasetRepository datasetRepo;

  final ServicoCroquiOnline _servicoCroquiOnline;
  final PicoCategorizedData _categorias;
  bool _isInitiallyDownloaded;

  PicoViewModel({
    required this.pico,
    required this.croqui,
    required this.cragId,
    required this.datasetRepo,
    ServicoCroquiOnline? servicoCroquiOnline,
  })  : _categorias = PicoCategorizedData(croqui),
        _servicoCroquiOnline = servicoCroquiOnline ??
            ServicoCroquiOnline(
              sessaoOnline: datasetRepo.gerenciadorSessaoOnline,
              verificarPicoBaixado: (id) => datasetRepo.isPicoDownloaded(id),
            ),
        _isInitiallyDownloaded = datasetRepo.isPicoDownloaded(cragId) {
    datasetRepo.activeDataset.addListener(_verificarStatusDownload);
  }

  void _verificarStatusDownload() {
    final baixado = datasetRepo.isPicoDownloaded(cragId);
    if (baixado) {
      _servicoCroquiOnline.cancelarPolling(cragId);
      if (!_isInitiallyDownloaded) {
        _isInitiallyDownloaded = true;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    datasetRepo.activeDataset.removeListener(_verificarStatusDownload);
    _servicoCroquiOnline.cancelarPolling(cragId);
    _servicoCroquiOnline.dispose();
    super.dispose();
  }
}
