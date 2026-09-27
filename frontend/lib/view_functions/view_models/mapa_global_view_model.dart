// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';
import '../../data/dtos/mapa_pico_dto.dart';
import '../../services/dataset_repository.dart';
import '../../services/http/sync_service.dart';
import '../../services/http/servico_download_segundo_plano.dart';
import '../home_functions.dart';

/// Modelo de apresentação e gerenciador de estado para a tela [MapaGlobalPage] (MVVM).
///
/// Encapsula a conversão de metadados do índice para [MapaPicoDTO], gerenciamento de downloads,
/// verificação de status offline e navegação para picos, tornando o widget de mapa puramente passivo (Dumb UI).
class MapaGlobalViewModel extends ChangeNotifier {
  /// Repositório de dados com catálogo e croquis baixados.
  final DatasetRepository datasetRepo;

  /// Serviço de sincronização e download de arquivos binários.
  final SyncService syncService;

  /// Lista opcional de picos injetados inicialmente (ex: via nós de navegação ou testes).
  final List<dynamic>? picosIniciais;

  MapaGlobalViewModel({
    required this.datasetRepo,
    required this.syncService,
    this.picosIniciais,
  }) {
    datasetRepo.activeDataset.addListener(_aoAtualizarDataset);
  }

  void _aoAtualizarDataset() => notifyListeners();

  @override
  void dispose() {
    datasetRepo.activeDataset.removeListener(_aoAtualizarDataset);
    super.dispose();
  }

  /// Monitoramento reativo dos downloads em andamento.
  ValueListenable<Map<String, double>> get downloadingCrags =>
      syncService.downloadingCrags;

  /// Verifica se um pico específico já foi baixado para o armazenamento local.
  bool estaBaixado(String picoId) {
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return false;
    return dataset.croquisBaixados.any((c) => c.id == picoId);
  }

  /// Lista de picos catalogados válidos para plotagem geográfica no mapa mundial.
  List<MapaPicoDTO> get picosNoMapa {
    if (picosIniciais != null && picosIniciais!.isNotEmpty) {
      return picosIniciais!
          .map((item) {
            if (item is MapaPicoDTO) return item;
            if (item is Map) {
              return MapaPicoDTO.deMapa(Map<String, dynamic>.from(item));
            }
            if (item is ResumoCroqui) {
              return MapaPicoDTO.deMetadados(
                metadados: item,
                estaBaixado: estaBaixado(item.id),
              );
            }
            return null;
          })
          .whereType<MapaPicoDTO>()
          .where((dto) => dto.temCoordenadasValidas)
          .toList();
    }

    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return const [];

    final baseUrl = datasetRepo.editorDeCroqui.activeBaseUrl;
    return dataset.metadadosDisponiveis
        .map((m) => MapaPicoDTO.deMetadados(
              metadados: m,
              estaBaixado: estaBaixado(m.id),
              baseUrl: baseUrl,
            ))
