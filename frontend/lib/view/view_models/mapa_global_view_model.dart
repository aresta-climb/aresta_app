// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';
import 'mapa_pico_view_model.dart';
import 'card_croqui_view_model.dart';
import '../../services/repositorio_dataset.dart';
import '../../services/http/sync_service.dart';
import '../../services/http/servico_download_segundo_plano.dart';
import '../function_library/funcoes_home.dart';

/// Modelo de apresentação e gerenciador de estado para a tela [MapaGlobalPage] (MVVM).
///
/// Encapsula a conversão de metadados do índice para [MapaPicoViewModel], gerenciamento de downloads,
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
  ///
  /// Suporta resolução polimórfica a partir de [MapaPicoViewModel], [CardCroquiViewModel],
  /// identificadores em [String] ou mapas legados. Se a lista injetada em [picosIniciais]
  /// não produzir marcadores válidos com coordenadas, recorre automaticamente ao catálogo
  /// completo em [ConjuntoDadosCroqui.metadadosDisponiveis] para evitar tela vazia.
  List<MapaPicoViewModel> get picosNoMapa {
    final dataset = datasetRepo.activeDataset.value;
    final baseUrl = datasetRepo.editorDeCroqui.activeBaseUrl;

    if (picosIniciais != null && picosIniciais!.isNotEmpty) {
      final picosProcessados = picosIniciais!
          .map((item) {
            if (item is MapaPicoViewModel) return item;
            if (item is Map) {
              return MapaPicoViewModel.deMapa(Map<String, dynamic>.from(item));
            }
            if (item is ResumoCroqui) {
              return MapaPicoViewModel.deMetadados(
                metadados: item,
                estaBaixado: estaBaixado(item.id),
                baseUrl: baseUrl,
              );
            }

            // Identifica o id a partir de CardCroquiViewModel ou String
            final String? picoId;
            if (item is CardCroquiViewModel) {
              picoId = item.id;
            } else if (item is String) {
              picoId = item;
            } else {
              picoId = null;
            }

            if (picoId != null && dataset != null) {
              final metas = dataset.metadadosDisponiveis.where((m) => m.id == picoId);
              if (metas.isNotEmpty) {
                return MapaPicoViewModel.deMetadados(
                  metadados: metas.first,
                  estaBaixado: estaBaixado(picoId),
                  baseUrl: baseUrl,
                );
              }
            }

            return null;
          })
          .whereType<MapaPicoViewModel>()
          .where((dto) => dto.temCoordenadasValidas)
          .toList();

      if (picosProcessados.isNotEmpty) {
        return picosProcessados;
      }
      // Fallback: se nenhum pico inicial possui coordenadas válidas,
      // carrega todo o catálogo para evitar mapa em branco.
    }

    if (dataset == null) return const [];

    return dataset.metadadosDisponiveis
        .map((m) => MapaPicoViewModel.deMetadados(
              metadados: m,
              estaBaixado: estaBaixado(m.id),
              baseUrl: baseUrl,
            ))
        .where((dto) => dto.temCoordenadasValidas)
        .toList();
  }

  /// Aciona o download dos dados binários de um pico pelo seu identificador único.
  Future<bool> baixarPico(String picoId) async {
    final indice = datasetRepo.indiceData.value;
    if (indice == null) return false;

    final resumos = indice.croquis.where((r) => r.id == picoId).toList();
    if (resumos.isEmpty) return false;

    final servicoDownload = ServicoDownloadSegundoPlano(syncService: syncService);
    return await servicoDownload.executarDownload(resumos.first);
  }

  /// Abre a página de detalhes de um pico selecionado a partir do mapa.
  Future<void> abrirPico(BuildContext context, String picoId) async {
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return;

    final meta = dataset.metadadosDisponiveis.firstWhere(
      (m) => m.id == picoId,
      orElse: () => ResumoCroqui(id: picoId),
    );

    await handlePicoSelection(context, datasetRepo, meta, source: 'mapa');
  }
}
