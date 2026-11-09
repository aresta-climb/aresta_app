// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'card_croqui_view_model.dart';
import '../../services/dataset/modelos/metadados_indice.dart';
import '../../services/repositorio_dataset.dart';
import '../../services/http/sync_service.dart';
import '../../services/http/servico_download_segundo_plano.dart';
import '../../services/firebase/telemetria.dart';
import '../function_library/biblioteca_funcoes_comuns.dart';
import '../function_library/funcoes_home.dart';
import '../function_library/funcoes_configuracoes.dart';
import '../../widgets/carrossel_picos_proximos.dart';

/// Critério de ordenação da listagem de picos na exploração.
enum OrdemOrdenacaoPico {
  /// Ordem crescente pela distância geodésica até o usuário (padrão).
  proximidade,

  /// Ordem alfabética pelo nome do pico (A-Z).
  alfabetico,

  /// Ordem decrescente por quantidade total de vias escaladas.
  escaladas,
}

/// Modelo de apresentação e gerenciador de estado para a tela [BrowsePage] (MVVM).
///
/// Encapsula a lógica de pesquisa difusa (fuzzy search), debounce de digitação,
/// ordenação de picos (incluindo cálculo geodésico compartilhado com a Home) e acionamento
/// de downloads em segundo plano, mantendo a árvore de widgets passiva (Dumb UI).
class BrowseViewModel extends ChangeNotifier {
  /// Repositório de dados com catálogo e croquis locais.
  final DatasetRepository datasetRepo;

  /// Serviço de sincronização e download de arquivos binários.
  final SyncService syncService;

  /// Serviço de telemetria opcional para testes ou injeção.
  final TelemetryService? telemetria;

  String _termoBusca = '';
  OrdemOrdenacaoPico _ordem = OrdemOrdenacaoPico.proximidade;
  double? _userLat;
  double? _userLon;
  Map<String, PicoProximo>? _cacheProximidadePorId;
  final ValueNotifier<int> _solicitacaoScrollSetimoPico = ValueNotifier<int>(0);
  Timer? _timerDebounce;

  BrowseViewModel({
    required this.datasetRepo,
    required this.syncService,
    this.telemetria,
  }) {
    datasetRepo.activeDataset.addListener(_aoAtualizarDataset);
    datasetRepo.calculadoraDistanciaEstrada.addListener(_aoAtualizarDataset);
    datasetRepo.editorDeCroqui.isExperimentalMode.addListener(_aoAtualizarDataset);
    datasetRepo.editorDeCroqui.editorUrl.addListener(_aoAtualizarDataset);
  }

  void _aoAtualizarDataset() {
    _cacheProximidadePorId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timerDebounce?.cancel();
    _solicitacaoScrollSetimoPico.dispose();
    datasetRepo.activeDataset.removeListener(_aoAtualizarDataset);
    datasetRepo.calculadoraDistanciaEstrada.removeListener(_aoAtualizarDataset);
    datasetRepo.editorDeCroqui.isExperimentalMode.removeListener(_aoAtualizarDataset);
    datasetRepo.editorDeCroqui.editorUrl.removeListener(_aoAtualizarDataset);
    super.dispose();
  }

  /// Monitoramento reativo do mapa de downloads em andamento.
  ValueListenable<Map<String, double>> get downloadingCrags =>
      syncService.downloadingCrags;

  /// Notificador reativo incrementado quando a tela deve rolar até o 7º pico mais próximo.
  ValueListenable<int> get solicitacaoScrollSetimoPico =>
      _solicitacaoScrollSetimoPico;

  /// Latitude atual do usuário, se já resolvida.
  double? get latitudeUsuario => _userLat;

  /// Longitude atual do usuário, se já resolvida.
  double? get longitudeUsuario => _userLon;

  /// Termo de pesquisa atualmente ativo na barra de busca.
  String get termoBusca => _termoBusca;

  /// Critério de ordenação selecionado pelo usuário.
  OrdemOrdenacaoPico get ordem => _ordem;

  /// Atualiza a coordenada geográfica do usuário para cálculo de distâncias e ordenação.
  void atualizarLocalizacaoUsuario(double lat, double lon) {
    _userLat = lat;
    _userLon = lon;
    _cacheProximidadePorId = null;
    notifyListeners();
  }

  Map<String, PicoProximo> _obterProximidadePorId(List<MetadadosIndice> todosPicos) {
    final existente = _cacheProximidadePorId;
    if (existente != null) {
      return existente;
    }
    final calculados = calcularPicosMaisProximos(
      userLat: _userLat!,
      userLon: _userLon!,
      picosDisponiveis: todosPicos,
      limite: null,
      calculadoraDistancia: datasetRepo.calculadoraDistanciaEstrada.value,
    );
    final mapa = <String, PicoProximo>{
      for (final item in calculados) item.id: item,
    };
    _cacheProximidadePorId = mapa;
    return mapa;
  }

  /// Limpa filtros de busca, define ordenação por proximidade e solicita rolagem até o 7º pico.
  void focarSetimoPicoProximo() {
    _timerDebounce?.cancel();
    _termoBusca = '';
    _ordem = OrdemOrdenacaoPico.proximidade;
    notifyListeners();
    _solicitacaoScrollSetimoPico.value++;
  }

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

    if (_ordem == OrdemOrdenacaoPico.proximidade) {
      if (_userLat != null && _userLon != null) {
        final proximidadePorId = _obterProximidadePorId(todosPicos);
        final comCoordenadas = resultado
            .where((m) => proximidadePorId.containsKey(m.id))
            .toList()
          ..sort(
            (a, b) => compararPicosPorProximidade(
              proximidadePorId[a.id]!,
              proximidadePorId[b.id]!,
            ),
          );
        final semCoordenadas = resultado
            .where((m) => !proximidadePorId.containsKey(m.id))
            .toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
        resultado = [...comCoordenadas, ...semCoordenadas];
      } else {
        resultado.sort((a, b) => a.nome.compareTo(b.nome));
      }
    } else if (_ordem == OrdemOrdenacaoPico.alfabetico) {
      resultado.sort((a, b) => a.nome.compareTo(b.nome));
    } else if (_ordem == OrdemOrdenacaoPico.escaladas) {
      resultado.sort((a, b) {
        final viasA = a.precomputados.totalEscaladas;
        final viasB = b.precomputados.totalEscaladas;
        final cmp = viasB.compareTo(viasA);
        return cmp != 0 ? cmp : a.nome.compareTo(b.nome);
      });
    }

    return resultado;
  }

  /// Lista dos picos filtrados mapeados diretamente para [CardCroquiViewModel] (Dumb UI).
  List<CardCroquiViewModel> get picosCards {
    final dataset = datasetRepo.activeDataset.value;
    final filtrados = picosFiltrados;
    final Map<String, PicoProximo> proximidadePorId = (_userLat != null &&
            _userLon != null &&
            dataset != null &&
            filtrados.isNotEmpty)
        ? _obterProximidadePorId(dataset.metadadosDisponiveis)
        : const <String, PicoProximo>{};

    return filtrados.map((m) {
      final prox = proximidadePorId[m.id];
      String textoDist = '';
      String? tooltipDist;
      if (prox != null) {
        if (prox.duracaoMinutos != null) {
          final estimativa = EstimativaViagemPico(
            distanciaMetros: prox.distanciaKm * 1000.0,
            duracaoMinutos: prox.duracaoMinutos,
          );
          textoDist = estimativa.formatarBadge();
          tooltipDist = estimativa.formatarTooltip();
        } else {
          textoDist = formatarDistanciaKm(prox.distanciaKm);
        }
      }
      return mapearMetadadosParaCard(
        m,
        salvoOffline: estaBaixado(m.id),
        textoDistancia: textoDist.isNotEmpty ? textoDist : null,
        tooltipDistancia: tooltipDist,
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
    if (datasetRepo.activeDataset.value == null) return;
    await handlePicoSelection(context, datasetRepo, picoId, source: 'explorar');
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
