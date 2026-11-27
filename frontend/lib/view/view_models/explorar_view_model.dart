// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/modelos/modelos_clima_pico.dart';
import '../../data/modelos/modelos_rede_viaria_aresta.dart';
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
  List<PicoRelevoReferencia>? _cacheReferenciasRelevoCatalogo;
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
    _servicoClima.addListener(_aoAtualizarClima);
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
    _cacheReferenciasRelevoCatalogo = null;
    if (_servicoClima.inicializado && !_descartado) {
      unawaited(
        _servicoClima.sincronizarSeNecessario(
          idsPicosCatalogo: _idsPicosComCoordenada,
        ),
      );
    }
    _notificarSeAtivo();
  }

  void _aoAtualizarClima() {
    _cacheReferenciasRelevoCatalogo = null;
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
    _servicoClima.removeListener(_aoAtualizarClima);
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

  void definirApenasSalvosOffline(bool valor) {
    _apenasSalvosOffline = valor;
    notifyListeners();
  }

  /// Limpa todas as modalidades, faixas de grau, raio e recorte offline, restaurando a ordenação padrão.
  void limparTodosFiltros() {
    _limparFiltrosInterno();
    _ordem = OrdemOrdenacaoPico.proximidade;
    notifyListeners();
  }

  void _limparFiltrosInterno() {
    _modalidadesAtivas.clear();
    _minGrauVia = null;
    _maxGrauVia = null;
    _minGrauBoulder = null;
    _maxGrauBoulder = null;
    _raioMaximoKm = null;
    _apenasSalvosOffline = false;
  }

  /// Altitude máxima do maciço em metros obtida externamente (NASA SRTM/NASADEM 30m).
  int? obterAltitudePico(String picoId) =>
      _servicoClima.obterAltitudePico(picoId);

  /// Cota altimétrica completa (`base` e `pico`) para escalonamento 3D no terreno detalhado.
  CotaAltimetricaPico? obterCotaAltimetricaPico(String picoId) =>
      _servicoClima.obterCotaAltimetrica(picoId);

  /// Estado vigente de umidade superficial na janela conservadora de 4 dias (`Seco` quando sem chuva próxima).
  EstadoUmidadePico obterUmidadePico(String picoId) =>
      _servicoClima.obterUmidadePico(picoId);

  /// Indica se o botão opcional de bolhas de chuva/fogo na seção `Mapa` está ligado (inicia sempre desligado).
  bool get radarClimaMapaAtivo => _radarClimaMapaAtivo;

  /// Liga ou desliga a visualização opcional das bolhas de chuva e incêndio sobre o mapa.
  void definirRadarClimaMapaAtivo(bool ativo) {
    if (_radarClimaMapaAtivo == ativo) return;
    _radarClimaMapaAtivo = ativo;
    notifyListeners();
  }

  /// Bolhas regionais de chuva visíveis no mapa (exibidas somente quando [radarClimaMapaAtivo] está ativo).
  List<BolhaAtivaRenderizavel> get bolhasChuvaAtivas =>
      _radarClimaMapaAtivo ? _servicoClima.bolhasAtivas : const [];

  /// Zonas regionais de incêndio florestal visíveis no mapa (exibidas somente quando [radarClimaMapaAtivo] está ativo).
  List<BolhaIncendioAtivaRenderizavel> get bolhasIncendioAtivas =>
      _radarClimaMapaAtivo ? _servicoClima.bolhasIncendioAtivas : const [];

  void atualizarLocalizacaoUsuario(double lat, double lon) {
    _userLat = lat;
    _userLon = lon;
    _cacheProximidadePorId = null;
    notifyListeners();
  }

  Map<String, PicoProximo> _obterProximidadePorId(
    List<MetadadosIndice> todosPicos,
  ) {
    final existente = _cacheProximidadePorId;
    if (existente != null) return existente;
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

  /// Limpa busca e filtros, define ordenação por proximidade e solicita rolagem até o 7º pico.
  void focarSetimoPicoProximo() {
    _timerDebounce?.cancel();
    _termoBusca = '';
    _limparFiltrosInterno();
    _ordem = OrdemOrdenacaoPico.proximidade;
    notifyListeners();
    _solicitacaoScrollSetimoPico.value++;
  }

  bool get carregando => datasetRepo.activeDataset.value == null;

  bool get modoEditorAtivo {
    final config = datasetRepo.editorDeCroqui;
    return config.editorUrl.value != null || config.isExperimentalMode.value;
  }

  bool estaBaixado(String picoId) {
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return false;
    return dataset.croquisBaixados.any((c) => c.id == picoId);
  }

  /// Lista de picos filtrados por busca, modalidade, faixa de grau, alcance e offline, ordenados pelo critério ativo.
  List<MetadadosIndice> get picosFiltrados {
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return [];

    final todosPicos = dataset.metadadosDisponiveis;
    final proximidadePorId = localizacaoUsuarioAtiva != null
        ? _obterProximidadePorId(todosPicos)
        : const <String, PicoProximo>{};

    final filtrados = FiltradorCatalogoExplorar.filtrarPorBuscaDifusa(
      todosPicos,
      _termoBusca,
    ).where((m) {
      if (!FiltradorCatalogoExplorar.atendeModalidades(m, _modalidadesAtivas)) {
        return false;
      }
      if (!FiltradorCatalogoExplorar.atendeFaixasGrau(
        metadados: m,
        perfisGrauPorPico: _perfisGrauPorPico,
        minGrauVia: _minGrauVia,
        maxGrauVia: _maxGrauVia,
        minGrauBoulder: _minGrauBoulder,
        maxGrauBoulder: _maxGrauBoulder,
      )) {
        return false;
      }
      if (_apenasSalvosOffline && !estaBaixado(m.id)) return false;
      if (_raioMaximoKm != null && proximidadePorId.isNotEmpty) {
        final prox = proximidadePorId[m.id];
        if (prox == null || prox.distanciaKm > _raioMaximoKm!) return false;
      }
      return true;
    }).toList();

    return FiltradorCatalogoExplorar.ordenarPicosFiltrados(
      itens: filtrados,
      ordem: _ordem,
      proximidadePorId: proximidadePorId,
    );
  }

  /// Projeta os picos filtrados em marcadores visuais imutáveis para renderização na superfície do globo.
  List<MarcadorPicoGlobo> get marcadoresGlobo => [
        for (final m in picosFiltrados)
          if (m.latitude != null && m.longitude != null)
            construirMarcadorGloboPico(
              id: m.id,
              nome: m.nome,
              caminhoRelativo: m.caminhoRelativo,
              latitude: m.latitude!,
              longitude: m.longitude!,
              cota: obterCotaAltimetricaPico(m.id),
              umidade: _radarClimaMapaAtivo
                  ? obterUmidadePico(m.id)
                  : const EstadoUmidadePico.seco(),
            ),
      ];

  /// Referências topográficas e viárias imutáveis de todo o catálogo ativo (invariantes a busca e filtros).
  List<PicoRelevoReferencia> get referenciasRelevoCatalogo {
    final existente = _cacheReferenciasRelevoCatalogo;
    if (existente != null) return existente;
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return const [];
    final construidas = List<PicoRelevoReferencia>.unmodifiable([
      for (final m in dataset.metadadosDisponiveis)
        if (m.id.isNotEmpty && m.latitude != null && m.longitude != null)
          construirMarcadorGloboPico(
            id: m.id,
            nome: m.nome,
            caminhoRelativo: m.caminhoRelativo,
            latitude: m.latitude!,
            longitude: m.longitude!,
            cota: obterCotaAltimetricaPico(m.id),
            umidade: const EstadoUmidadePico.seco(),
          ).paraReferenciaRelevo(),
    ]);
    _cacheReferenciasRelevoCatalogo = construidas;
    return construidas;
  }

  /// Calcula o destino geográfico e o nível de detalhe alvo para voar até um pico selecionado na gaveta.
  ({
    double latitude,
    double longitude,
    double? altitudeBaseMetros,
    double destinoLod,
  })? calcularDestinoVooPico(String picoId, {required double lodAtual}) {
    for (final m in picosFiltrados) {
      if (m.id != picoId) continue;
      if (m.latitude == null || m.longitude == null) return null;
      return (
        latitude: m.latitude!,
        longitude: m.longitude!,
        altitudeBaseMetros:
            obterCotaAltimetricaPico(picoId)?.altitudeBaseMetros.toDouble(),
        destinoLod: lodAtual >= 2.25 ? 3.65 : math.max(2.35, lodAtual),
      );
    }
    return null;
  }

  /// Cartões de apresentação prontos para exibição na gaveta deslizante com badges de distância/viagem.
  List<CardCroquiViewModel> get picosCards {
    final dataset = datasetRepo.activeDataset.value;
    final filtrados = picosFiltrados;
    final proximidadePorId =
        (localizacaoUsuarioAtiva != null && dataset != null && filtrados.isNotEmpty)
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

  void alterarTermoBusca(String novoTermo) {
    _termoBusca = novoTermo;
    notifyListeners();

    _timerDebounce?.cancel();
    _timerDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_termoBusca.isNotEmpty && !_descartado) {
        final t = telemetria ?? TelemetryService.instance;
        t.logBuscaCroquis(_termoBusca, picosFiltrados.length);
      }
    });
  }

  void alterarOrdem(OrdemOrdenacaoPico novaOrdem) {
    if (_ordem == novaOrdem) return;
    _ordem = novaOrdem;
    final t = telemetria ?? TelemetryService.instance;
    t.logAlterarOrdenacao('browse', novaOrdem.name);
    notifyListeners();
  }

  /// Normaliza um alvo de download (`CardCroquiViewModel`, `Map` ou `String`) em par `(id, nome)`.
  ({String id, String nome}) resolverAlvoDownload(Object? crag) =>
      resolverAlvoDownloadExplorar(crag);

  Future<bool> baixarPico(MetadadosIndice pico) async {
    final indice = datasetRepo.indiceData.value;
    if (indice == null) return false;
    final resumos = indice.croquis.where((r) => r.id == pico.id);
    final resumo = resumos.isNotEmpty
        ? resumos.first
        : (pico.caminhoRelativo.isNotEmpty ? pico : null);
    if (resumo == null) return false;
    return ServicoDownloadSegundoPlano(syncService: syncService)
        .executarDownload(resumo);
  }

  Future<bool> baixarPicoPorId(String picoId) async {
    final indice = datasetRepo.indiceData.value;
    if (indice == null) return false;
    final resumos = indice.croquis.where((r) => r.id == picoId);
    if (resumos.isEmpty) return false;
    return ServicoDownloadSegundoPlano(syncService: syncService)
        .executarDownload(resumos.first);
  }

  Future<void> abrirPico(BuildContext context, String picoId) async {
    if (datasetRepo.activeDataset.value == null) return;
    await handlePicoSelection(context, datasetRepo, picoId, source: 'explorar');
  }

  void trocarServing(BuildContext context) {
    mostrarDialogConexao(
      context,
      datasetRepo,
      titulo: tr(ChaveTexto.explorarTrocarServing),
    );
  }

  Future<void> sincronizarServing(BuildContext context) async {
    await handleSyncServing(context, datasetRepo, syncService);
    await _servicoClima.sincronizarSeNecessario(
      forcar: true,
      idsPicosCatalogo: _idsPicosComCoordenada,
    );
  }
}
