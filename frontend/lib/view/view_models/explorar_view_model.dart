// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/modelos/modelos_clima_pico.dart';
import '../../idioma/tradutor_app.dart';
import '../../services/clima/localizador_gps_usuario.dart';
import '../../services/clima/servico_clima_altimetria.dart';
import '../../services/dataset/modelos/metadados_indice.dart';
import '../../services/firebase/telemetria.dart';
import '../../services/http/servico_download_segundo_plano.dart';
import '../../services/http/sync_service.dart';
import '../../services/repositorio_dataset.dart';
import '../../widgets/carrossel_picos_proximos.dart';
import '../../widgets/explorar/componentes_marcador_globo.dart';
import '../function_library/biblioteca_funcoes_comuns.dart';
import '../function_library/funcoes_configuracoes.dart';
import '../function_library/funcoes_explorar.dart';
import '../function_library/funcoes_home.dart';
import 'card_croqui_view_model.dart';
import 'filtrador_catalogo_explorar.dart';

/// Critério de ordenação da listagem de picos na exploração.
enum OrdemOrdenacaoPico { proximidade, alfabetico, escaladas }

/// Modalidades disponíveis para filtragem rápida no catálogo e no globo da aba `Explorar`.
enum ModalidadeExploracaoPico {
  esportiva,
  boulder,
  movel,
  paredao,
  highline;

  /// Rótulo localizado exibido nas pílulas rápidas e no modal de filtros.
  String get rotulo => switch (this) {
        ModalidadeExploracaoPico.esportiva => tr(ChaveTexto.modEsportiva),
        ModalidadeExploracaoPico.boulder => tr(ChaveTexto.modBoulder),
        ModalidadeExploracaoPico.movel => tr(ChaveTexto.modMovelTrad),
        ModalidadeExploracaoPico.paredao => tr(ChaveTexto.modParedao),
        ModalidadeExploracaoPico.highline => tr(ChaveTexto.modHighline),
      };
}

/// Modelo de apresentação e gerenciador de estado para a aba unificada `Explorar` (MVVM).
///
/// Orquestra pesquisa difusa, filtros nacionais por faixa de graduação (`catalogo.db`),
/// tags de modalidade, raio de distância, estado contextual de chuva e incêndios,
/// altimetria externa e projeção declarativa dos marcadores e cards para a Dumb UI.
class BrowseViewModel extends ChangeNotifier {
  final DatasetRepository datasetRepo;
  final SyncService syncService;
  final TelemetryService? telemetria;
  final ServicoClimaAltimetria _servicoClima;
  final LocalizadorGpsUsuario _localizadorGps;

  String _termoBusca = '';
  OrdemOrdenacaoPico _ordem = OrdemOrdenacaoPico.proximidade;
  final Set<ModalidadeExploracaoPico> _modalidadesAtivas = {};
  int? _minGrauVia;
  int? _maxGrauVia;
  int? _minGrauBoulder;
  int? _maxGrauBoulder;
  double? _raioMaximoKm;
  bool _apenasSalvosOffline = false;
  bool _radarClimaMapaAtivo = false;

  String? _picoSelecionadoId;
  double? _userLat;
  double? _userLon;
  bool _buscandoLocalizacao = false;
  Map<String, PicoProximo>? _cacheProximidadePorId;
  Map<String, PerfilGrauPico> _perfisGrauPorPico = const {};

  final ValueNotifier<int> _solicitacaoScrollSetimoPico = ValueNotifier<int>(0);
  final ValueNotifier<int> _solicitacaoAutoScrollPicoSelecionado =
      ValueNotifier<int>(0);
  Timer? _timerDebounce;
  bool _descartado = false;

  BrowseViewModel({
    required this.datasetRepo,
    required this.syncService,
    this.telemetria,
    ServicoClimaAltimetria? servicoClima,
    LocalizadorGpsUsuario localizadorGps = const LocalizadorGpsUsuario(),
  })  : _servicoClima = servicoClima ?? ServicoClimaAltimetria.instancia,
        _localizadorGps = localizadorGps {
    datasetRepo.activeDataset.addListener(_aoAtualizarDataset);
    datasetRepo.calculadoraDistanciaEstrada.addListener(_aoAtualizarDataset);
    datasetRepo.editorDeCroqui.isExperimentalMode
        .addListener(_aoAtualizarDataset);
    datasetRepo.editorDeCroqui.editorUrl.addListener(_aoAtualizarDataset);
    datasetRepo.repositorioCatalogo.versaoNotificador
        .addListener(_aoMudarCatalogo);
    ControladorIdiomaApp.instancia.notificadorIdioma
        .addListener(_notificarSeAtivo);
    _servicoClima.addListener(_notificarSeAtivo);
    unawaited(_inicializarDadosAuxiliares());
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
