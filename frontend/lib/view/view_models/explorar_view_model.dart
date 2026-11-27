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

  Iterable<String> get _idsPicosComCoordenada {
    final lista = datasetRepo.activeDataset.value?.metadadosDisponiveis;
    if (lista == null) return const [];
    return lista
        .where((m) => m.id.isNotEmpty && m.latitude != null && m.longitude != null)
        .map((m) => m.id);
  }

  Future<void> _inicializarDadosAuxiliares() async {
    await _hidratarLocalizacaoCache();
    if (_descartado) return;
    await recarregarPerfisGrauCatalogo();
    if (_descartado) return;
    await _servicoClima.inicializar();
    if (_descartado) return;
    await _servicoClima.sincronizarSeNecessario(
      idsPicosCatalogo: _idsPicosComCoordenada,
    );
  }

  Future<void> _hidratarLocalizacaoCache() async {
    if (_userLat != null && _userLon != null) return;
    final cache = await _localizadorGps.lerCoordenadaCache();
    if (cache != null && !_descartado && _userLat == null) {
      atualizarLocalizacaoUsuario(cache.latitude, cache.longitude);
    }
  }

  /// Indica se há uma consulta ativa de GPS em andamento pelo botão Minha Localização.
  bool get buscandoLocalizacao => _buscandoLocalizacao;

  /// Consulta o GPS real do dispositivo via [LocalizadorGpsUsuario] e atualiza a posição ativa.
  Future<ResultadoLocalizacaoGps> obterLocalizacaoTempoReal() async {
    _buscandoLocalizacao = true;
    _notificarSeAtivo();
    try {
      final res = await _localizadorGps.obterPosicaoAtual(
        coordenadaFallback: localizacaoUsuarioAtiva,
      );
      final coord = res.coordenada;
      if (coord != null && !_descartado) {
        atualizarLocalizacaoUsuario(coord.latitude, coord.longitude);
      }
      return res;
    } finally {
      _buscandoLocalizacao = false;
      _notificarSeAtivo();
    }
  }

  void _aoMudarCatalogo() => unawaited(recarregarPerfisGrauCatalogo());

  void _aoAtualizarDataset() {
    _cacheProximidadePorId = null;
    if (_servicoClima.inicializado && !_descartado) {
      unawaited(
        _servicoClima.sincronizarSeNecessario(
          idsPicosCatalogo: _idsPicosComCoordenada,
        ),
      );
    }
    _notificarSeAtivo();
  }

  void _notificarSeAtivo() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _timerDebounce?.cancel();
    _solicitacaoScrollSetimoPico.dispose();
    _solicitacaoAutoScrollPicoSelecionado.dispose();
    datasetRepo.activeDataset.removeListener(_aoAtualizarDataset);
    datasetRepo.calculadoraDistanciaEstrada.removeListener(_aoAtualizarDataset);
    datasetRepo.editorDeCroqui.isExperimentalMode
        .removeListener(_aoAtualizarDataset);
    datasetRepo.editorDeCroqui.editorUrl.removeListener(_aoAtualizarDataset);
    datasetRepo.repositorioCatalogo.versaoNotificador
        .removeListener(_aoMudarCatalogo);
    ControladorIdiomaApp.instancia.notificadorIdioma
        .removeListener(_notificarSeAtivo);
    _servicoClima.removeListener(_notificarSeAtivo);
    super.dispose();
  }

  /// Recarrega os perfis de graduação agregados a partir do `catalogo.db` local.
  Future<void> recarregarPerfisGrauCatalogo() async {
    final carregados =
        await datasetRepo.repositorioCatalogo.carregarPerfisGrauPorCroqui();
    if (_descartado) return;
    _perfisGrauPorPico = carregados;
    notifyListeners();
  }

  ValueListenable<Map<String, double>> get downloadingCrags =>
      syncService.downloadingCrags;

  ValueListenable<int> get solicitacaoScrollSetimoPico =>
      _solicitacaoScrollSetimoPico;

  /// Notificador incrementado quando um toque no mapa exige auto-scroll animado na lista da gaveta.
  ValueListenable<int> get solicitacaoAutoScrollPicoSelecionado =>
      _solicitacaoAutoScrollPicoSelecionado;

  String? get picoSelecionadoId => _picoSelecionadoId;
  double? get latitudeUsuario => _userLat;
  double? get longitudeUsuario => _userLon;

  /// Coordenada geográfica consolidada do usuário quando latitude e longitude estão disponíveis.
  ({double latitude, double longitude})? get localizacaoUsuarioAtiva =>
      (_userLat != null && _userLon != null)
          ? (latitude: _userLat!, longitude: _userLon!)
          : null;

  String get termoBusca => _termoBusca;
  OrdemOrdenacaoPico get ordem => _ordem;
  Set<ModalidadeExploracaoPico> get modalidadesAtivas =>
      Set<ModalidadeExploracaoPico>.unmodifiable(_modalidadesAtivas);
  int? get minGrauVia => _minGrauVia;
  int? get maxGrauVia => _maxGrauVia;
  int? get minGrauBoulder => _minGrauBoulder;
  int? get maxGrauBoulder => _maxGrauBoulder;
  double? get raioMaximoKm => _raioMaximoKm;
  bool get apenasSalvosOffline => _apenasSalvosOffline;

  bool get temFiltroGrauVia => _minGrauVia != null || _maxGrauVia != null;
  bool get temFiltroGrauBoulder =>
      _minGrauBoulder != null || _maxGrauBoulder != null;

  /// Quantidade de critérios de filtragem/ordenação não-padrão ativos para exibição de badge.
  int get totalFiltrosAtivos {
    var total = 0;
    if (_modalidadesAtivas.isNotEmpty) total++;
    if (temFiltroGrauVia) total++;
    if (temFiltroGrauBoulder) total++;
    if (_raioMaximoKm != null) total++;
    if (_apenasSalvosOffline) total++;
    if (_ordem != OrdemOrdenacaoPico.proximidade) total++;
    return total;
  }

  /// Seleciona um pico sincronizando mapa e gaveta; dispara auto-scroll quando [origemMapa] é verdadeiro.
  void selecionarPico(String? picoId, {bool origemMapa = false}) {
    _picoSelecionadoId = picoId;
    notifyListeners();
    if (origemMapa && picoId != null) {
      _solicitacaoAutoScrollPicoSelecionado.value++;
    }
  }

  void alternarModalidade(ModalidadeExploracaoPico modalidade) {
    if (!_modalidadesAtivas.remove(modalidade)) {
      _modalidadesAtivas.add(modalidade);
    }
    notifyListeners();
  }

  void definirModalidades(Set<ModalidadeExploracaoPico> novas) {
    _modalidadesAtivas
      ..clear()
      ..addAll(novas);
    notifyListeners();
  }

  void definirFaixaGrauVia(int? minValor, int? maxValor) {
    _minGrauVia = minValor;
    _maxGrauVia = maxValor;
    notifyListeners();
  }

  void definirFaixaGrauBoulder(int? minValor, int? maxValor) {
    _minGrauBoulder = minValor;
    _maxGrauBoulder = maxValor;
    notifyListeners();
  }

  void definirRaioMaximoKm(double? km) {
    _raioMaximoKm = km;
    notifyListeners();
  }

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
