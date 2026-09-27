// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import '../../data/dtos/card_croqui_dto.dart';
import '../../services/dataset/modelos/metadados_indice.dart';
import '../../services/dataset_repository.dart';
import '../../services/http/sync_service.dart';
import '../../services/http/servico_download_segundo_plano.dart';
import '../../services/firebase/telemetry_service.dart';
import '../common_functions.dart';
import '../home_functions.dart';
import '../settings_functions.dart';

/// Critério de ordenação da listagem de picos na exploração.
enum OrdemOrdenacaoPico {
  /// Ordem padrão recebida do catálogo.
  padrao,

  /// Ordem alfabética pelo nome do pico (A-Z).
  alfabetico,

  /// Ordem decrescente por quantidade total de vias escaladas.
  escaladas,
}

/// Modelo de apresentação e gerenciador de estado para a tela [BrowsePage] (MVVM).
///
/// Encapsula a lógica de pesquisa difusa (fuzzy search), debounce de digitação,
/// ordenação de picos e acionamento de downloads em segundo plano, mantendo
/// a árvore de widgets passiva (Dumb UI).
class BrowseViewModel extends ChangeNotifier {
  /// Repositório de dados com catálogo e croquis locais.
  final DatasetRepository datasetRepo;

  /// Serviço de sincronização e download de arquivos binários.
  final SyncService syncService;

  /// Serviço de telemetria opcional para testes ou injeção.
  final TelemetryService? telemetria;

  String _termoBusca = '';
  OrdemOrdenacaoPico _ordem = OrdemOrdenacaoPico.padrao;
  Timer? _timerDebounce;

  BrowseViewModel({
    required this.datasetRepo,
    required this.syncService,
    this.telemetria,
  }) {
    datasetRepo.activeDataset.addListener(_aoAtualizarDataset);
    datasetRepo.editorDeCroqui.isExperimentalMode.addListener(_aoAtualizarDataset);
    datasetRepo.editorDeCroqui.editorUrl.addListener(_aoAtualizarDataset);
  }

  void _aoAtualizarDataset() => notifyListeners();

  @override
  void dispose() {
    _timerDebounce?.cancel();
    datasetRepo.activeDataset.removeListener(_aoAtualizarDataset);
    datasetRepo.editorDeCroqui.isExperimentalMode.removeListener(_aoAtualizarDataset);
    datasetRepo.editorDeCroqui.editorUrl.removeListener(_aoAtualizarDataset);
    super.dispose();
  }

  /// Monitoramento reativo do mapa de downloads em andamento.
  ValueListenable<Map<String, double>> get downloadingCrags =>
      syncService.downloadingCrags;

  /// Termo de pesquisa atualmente ativo na barra de busca.
  String get termoBusca => _termoBusca;

  /// Critério de ordenação selecionado pelo usuário.
  OrdemOrdenacaoPico get ordem => _ordem;

  /// Indica se o catálogo ainda está carregando ou se o repositório é nulo.
  bool get carregando => datasetRepo.activeDataset.value == null;

  /// Indica se ferramentas ou opções do editor/experimental estão habilitadas.
  bool get modoEditorAtivo {
    final config = datasetRepo.editorDeCroqui;
    return config.editorUrl.value != null || config.isExperimentalMode.value;
  }

  /// Verifica se um pico específico já foi baixado para uso offline.
  bool estaBaixado(String picoId) {
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return false;
    return dataset.croquisBaixados.any((c) => c.id == picoId);
  }

  /// Lista de picos filtrados pelo termo de busca e ordenados pelo critério ativo.
  List<MetadadosIndice> get picosFiltrados {
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return [];

    final todosPicos = dataset.metadadosDisponiveis;
    List<MetadadosIndice> resultado;

    if (_termoBusca.isEmpty) {
      resultado = todosPicos.toList();
    } else {
      final fuse = Fuzzy<MetadadosIndice>(
        todosPicos,
        options: FuzzyOptions(
          keys: [
            WeightedKey(
              name: 'nome',
              getter: (MetadadosIndice c) => normalizeSearchString(c.nome),
              weight: 1.0,
            ),
            WeightedKey(
              name: 'local',
              getter: (MetadadosIndice c) =>
                  normalizeSearchString(c.localizacaoFormatada),
              weight: 0.5,
            ),
          ],
          threshold: 0.4,
        ),
      );

      final queryNormalizada = normalizeSearchString(_termoBusca);
      resultado = fuse.search(queryNormalizada).map((r) => r.item).toList();
    }

    if (_ordem == OrdemOrdenacaoPico.alfabetico) {
      resultado.sort((a, b) => a.nome.compareTo(b.nome));
    } else if (_ordem == OrdemOrdenacaoPico.escaladas) {
      resultado.sort((a, b) {
        final viasA = a.precomputados.totalEscaladas;
        final viasB = b.precomputados.totalEscaladas;
        return viasB.compareTo(viasA);
      });
    }

    return resultado;
  }

  /// Lista dos picos filtrados mapeados diretamente para [CardCroquiDTO] (Dumb UI).
  List<CardCroquiDTO> get picosCards {
    return picosFiltrados.map((m) {
      return mapearMetadadosParaCard(
        m,
        salvoOffline: estaBaixado(m.id),
      );
    }).toList();
  }

  /// Atualiza o termo de busca, aciona a reconstrução da UI e agenda telemetria debounced.
  void alterarTermoBusca(String novoTermo) {
    _termoBusca = novoTermo;
    notifyListeners();

    _timerDebounce?.cancel();
    _timerDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_termoBusca.isNotEmpty) {
        final t = telemetria ?? TelemetryService.instance;
        t.logBuscaCroquis(_termoBusca, picosFiltrados.length);
      }
    });
  }

  /// Altera o critério de ordenação da lista e registra evento analítico.
  void alterarOrdem(OrdemOrdenacaoPico novaOrdem) {
    if (_ordem == novaOrdem) return;
    _ordem = novaOrdem;
    final t = telemetria ?? TelemetryService.instance;
    t.logAlterarOrdenacao('browse', novaOrdem.name);
    notifyListeners();
  }

  /// Aciona o download dos dados binários de um pico em segundo plano.
  Future<bool> baixarPico(MetadadosIndice pico) async {
    final indice = datasetRepo.indiceData.value;
    if (indice == null) return false;

    final resumos = indice.croquis.where((r) => r.id == pico.id).toList();
    final resumo = resumos.isNotEmpty
        ? resumos.first
        : (pico.caminhoRelativo.isNotEmpty ? pico : null);
    if (resumo == null) return false;

    final servicoDownload = ServicoDownloadSegundoPlano(syncService: syncService);
    return await servicoDownload.executarDownload(resumo);
  }

  /// Aciona o download dos dados de um pico pelo seu identificador único.
  Future<bool> baixarPicoPorId(String picoId) async {
    final indice = datasetRepo.indiceData.value;
    if (indice == null) return false;

    final resumos = indice.croquis.where((r) => r.id == picoId).toList();
    if (resumos.isEmpty) return false;

    final servicoDownload = ServicoDownloadSegundoPlano(syncService: syncService);
    return await servicoDownload.executarDownload(resumos.first);
  }

  /// Abre a página de detalhes de um pico selecionado.
  Future<void> abrirPico(BuildContext context, String picoId) async {
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return;

    final meta = dataset.metadadosDisponiveis.firstWhere(
      (m) => m.id == picoId,
      orElse: () => MetadadosIndice(id: picoId),
    );

    await handlePicoSelection(context, datasetRepo, meta, source: 'explorar');
  }

  /// Exibe diálogo para troca do servidor ativo (modo editor/experimental).
  void trocarServing(BuildContext context) {
    mostrarDialogConexao(
      context,
      datasetRepo,
      titulo: 'Trocar serving',
    );
  }

  /// Dispara a sincronização manual do serving ativo.
  Future<void> sincronizarServing(BuildContext context) async {
    await handleSyncServing(context, datasetRepo, syncService);
  }
}
