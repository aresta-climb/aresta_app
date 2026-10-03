// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';
import 'pico_proximo_view_model.dart';
import '../../services/repositorio_dataset.dart';
import '../../services/http/sync_service.dart';
import '../../services/http/servico_download_segundo_plano.dart';
import '../../services/dataset/modelos/metadados_indice.dart';
import '../function_library/biblioteca_funcoes_comuns.dart';
import '../function_library/funcoes_home.dart';

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
    if (dataset == null) return false;
    return dataset.croquisBaixados.any((c) => c.id == picoId) ||
        dataset.picosBaixados.any((p) => p.id == picoId);
  }

  /// Retorna os picos mais próximos ao usuário formatados como [PicoProximoViewModel].
  List<PicoProximoViewModel> get picosProximos {
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return const [];

    final availablePicos = dataset.metadadosDisponiveis.isNotEmpty
        ? dataset.metadadosDisponiveis
        : (dataset.picosDisponiveis.isNotEmpty
            ? dataset.picosDisponiveis
            : dataset.availablePicos);
    if (availablePicos.isEmpty) return const [];

    if (_userLat == null || _userLon == null) {
      return const [];
    }

    final proximos = calcularPicosMaisProximos(
      userLat: _userLat!,
      userLon: _userLon!,
      picosDisponiveis: availablePicos,
    );

    return proximos.map((item) {
      final pico = item.pico;
      if (pico is MetadadosIndice) {
        return PicoProximoViewModel.deMetadados(
          metadados: pico,
          distanciaKm: item.distanciaKm,
          estaBaixado: estaBaixado(pico.id),
        );
      }
      final String id = item.id;
      final String nome = item.nome;
      final String local = pico is ResumoPico
          ? pico.local
          : (pico is Map ? (pico['local']?.toString() ?? '') : '');
      final String thumb = pico is ResumoPico
          ? pico.thumbnailUrl
          : (pico is Map ? (pico['thumbnailUrl']?.toString() ?? '') : '');

      return PicoProximoViewModel.deValores(
        id: id,
        nome: nome,
        localizacao: local,
        caminhoMiniatura: thumb,
        distanciaKm: item.distanciaKm,
        estaBaixado: estaBaixado(id),
      );
    }).toList();
  }

  /// Dispara a sincronização manual dos dados com o servidor remoto.
  Future<void> sincronizarManual(BuildContext context) async {
    await handleManualSync(context, datasetRepo, syncService);
  }

  /// Aciona o download dos dados de um pico específico em segundo plano.
  Future<bool> baixarPico(String picoId) async {
    final indice = datasetRepo.indiceData.value;
    if (indice != null) {
      final resumos = indice.croquis.where((r) => r.id == picoId).toList();
      if (resumos.isNotEmpty) {
        final servicoDownload = ServicoDownloadSegundoPlano(syncService: syncService);
        return await servicoDownload.executarDownload(resumos.first);
      }
    }
    final resumoFallback = ResumoCroqui()
      ..id = picoId
      ..nome = picoId;
    return await syncService.downloadCrag(resumoFallback);
  }

  /// Abre a tela de detalhes de um pico a partir do seu identificador único.
  Future<void> abrirPico(BuildContext context, String picoId) async {
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return;

    dynamic pico;
    if (dataset.metadadosDisponiveis.any((m) => m.id == picoId)) {
      pico = dataset.metadadosDisponiveis.firstWhere((m) => m.id == picoId);
    } else if (dataset.picosDisponiveis.any((p) => p.id == picoId)) {
      pico = dataset.picosDisponiveis.firstWhere((p) => p.id == picoId);
    } else if (dataset.availablePicos.any((p) => (p is Map ? p['id'] : p.id) == picoId)) {
      pico = dataset.availablePicos.firstWhere((p) => (p is Map ? p['id'] : p.id) == picoId);
    } else {
      pico = ResumoCroqui(id: picoId);
    }

    await handlePicoSelection(context, datasetRepo, pico, source: 'home');
  }
}
