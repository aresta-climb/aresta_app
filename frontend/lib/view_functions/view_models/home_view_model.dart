// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';
import '../../data/dtos/pico_proximo_dto.dart';
import '../../services/dataset_repository.dart';
import '../../services/http/sync_service.dart';
import '../../services/http/servico_download_segundo_plano.dart';
import '../../services/dataset/modelos/metadados_indice.dart';
import '../../widgets/nearby_crags_carousel.dart';
import '../common_functions.dart';
import '../home_functions.dart';

/// Modelo de apresentação e gerenciador de estado para a tela [HomePage] (MVVM).
///
/// Encapsula o cálculo geodésico de picos próximos ao usuário, monitoramento de downloads,
/// sincronização manual e acionamento de navegação para detalhes do croqui, mantendo a interface (Dumb UI)
/// completamente livre de referências diretas a repositórios e serviços de rede.
class HomeViewModel extends ChangeNotifier {
  /// Repositório central de dados de escalada.
  final DatasetRepository datasetRepo;

  /// Serviço de sincronização e download de arquivos binários.
  final SyncService syncService;

  double? _userLat;
  double? _userLon;

  HomeViewModel({
    required this.datasetRepo,
    required this.syncService,
  }) {
    datasetRepo.activeDataset.addListener(_aoAtualizarDataset);
    datasetRepo.homeResetTrigger.addListener(_aoAtualizarDataset);
  }

  void _aoAtualizarDataset() => notifyListeners();

  @override
  void dispose() {
    datasetRepo.activeDataset.removeListener(_aoAtualizarDataset);
    datasetRepo.homeResetTrigger.removeListener(_aoAtualizarDataset);
    super.dispose();
  }

  /// Indica se os dados do catálogo ainda estão sendo inicializados.
  bool get carregando => datasetRepo.activeDataset.value == null;

  /// Monitoramento reativo do progresso percentual dos picos atualmente em download.
  ValueListenable<Map<String, double>> get downloadingCrags =>
      syncService.downloadingCrags;

  /// Atualiza a coordenada geográfica do usuário para cálculo de distâncias.
  void atualizarLocalizacaoUsuario(double lat, double lon) {
    _userLat = lat;
    _userLon = lon;
    notifyListeners();
  }

  /// Verifica se um pico específico já foi baixado para o armazenamento local.
  bool estaBaixado(String picoId) {
    final dataset = datasetRepo.activeDataset.value;
