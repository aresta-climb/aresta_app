// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../data/dtos/card_croqui_dto.dart';
import '../../navigation/navigation_functions.dart';
import '../../services/dataset_repository.dart';
import '../../services/firebase/registro_primeira_visita.dart';
import '../../services/firebase/telemetry_service.dart';
import '../../services/http/sync_service.dart';
import '../../theme/app_colors.dart';
import '../common_functions.dart';

/// Modelo de apresentação para a tela [MeusCroquisPage] (MVVM).
///
/// Observa as atualizações do [DatasetRepository] e expõe a lista de croquis
/// offline já transformados no modelo passivo [CardCroquiDTO], mantendo a UI
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

  /// Retorna a lista de croquis salvos offline mapeados como [CardCroquiDTO].
  List<CardCroquiDTO> get croquisSalvos {
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return const [];
    if (dataset.croquisBaixados.isNotEmpty) {
      return dataset.croquisBaixados.map(mapearCroquiParaCard).toList();
    }
    return dataset.picosBaixados.map((pico) {
      final stats = pico.estatisticas;
      final textoStats = stats != null
          ? '${stats.totalSetores} setores • ${stats.totalVias} escaladas'
          : '';
      return CardCroquiDTO(
        id: pico.id,
        titulo: pico.nome,
        localizacao: pico.local,
        textoEstatisticas: textoStats,
        caminhoMiniatura: pico.thumbnailUrl,
        salvoOffline: true,
      );
    }).toList();
  }

  /// Indica se não há nenhum croqui salvo offline.
  bool get estaVazio => croquisSalvos.isEmpty;

  /// Dispara a rotina de sincronização manual dos croquis salvos.
  Future<void> sincronizarManual(BuildContext context) async {
    await handleManualSync(context, datasetRepo, syncService);
  }
}
