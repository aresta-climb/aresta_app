// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../services/dataset_repository.dart';
import '../../services/http/sync_service.dart';
import 'card_croqui_view_model.dart';
import '../common_functions.dart';

/// Modelo de apresentação para a tela [MeusCroquisPage] (MVVM).
///
/// Observa as atualizações do [DatasetRepository] e expõe a lista de croquis
/// offline já transformados no modelo passivo [CardCroquiViewModel], mantendo a UI
/// livre de regras de negócio e acoplamento com Protobuf.
class MeusCroquisViewModel extends ChangeNotifier {
  /// Repositório de dados locais e catálogo de croquis.
  final DatasetRepository datasetRepo;

  /// Serviço de sincronização e download de dados.
  final SyncService syncService;

  MeusCroquisViewModel({
    required this.datasetRepo,
    required this.syncService,
  }) {
    datasetRepo.activeDataset.addListener(_aoAtualizarDataset);
  }

  void _aoAtualizarDataset() {
    notifyListeners();
  }

  @override
  void dispose() {
    datasetRepo.activeDataset.removeListener(_aoAtualizarDataset);
    super.dispose();
  }

  /// Retorna a lista de croquis salvos offline mapeados como [CardCroquiViewModel].
  List<CardCroquiViewModel> get croquisSalvos {
    final dataset = datasetRepo.activeDataset.value;
    final croquis = dataset?.croquisBaixados ?? [];
    return croquis.map(mapearCroquiParaCard).toList();
  }

  /// Indica se não há nenhum croqui salvo offline.
  bool get estaVazio => croquisSalvos.isEmpty;

  /// Dispara a rotina de sincronização manual dos croquis salvos.
  Future<void> sincronizarManual(BuildContext context) async {
    await handleManualSync(context, datasetRepo, syncService);
  }
}
