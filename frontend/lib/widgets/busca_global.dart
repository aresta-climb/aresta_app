// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../aresta_api/proto/generated/indice.pb.dart';
import '../main.dart';
import '../navigation/arvore_navegacao.dart';
import '../navigation/localizador_destino_uid.dart';
import '../services/firebase/registro_primeira_visita.dart';
import '../services/repositorio_dataset.dart';
import '../theme/cores_app.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/function_library/funcoes_home.dart';
import '../view/function_library/via_functions.dart';

/// Item unificado exibido na lista de resultados da Busca Global.
class GlobalSearchResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Object? originalItem;
  final bool isDownloaded;
  final bool isPico;
  final String categoriaFiltro;

  GlobalSearchResult({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.originalItem,
    this.isDownloaded = true,
    this.isPico = false,
    this.categoriaFiltro = 'Todos',
  });
}

/// Barra e tela de Busca Global alimentada pelo catálogo SQLite (`catalogo.db`)
/// mesclado com o estado em memória e offline do repositório.
class GlobalSearch extends StatefulWidget {
  final DatasetRepository datasetRepo;
  final List<ResumoPico> downloadedPicos;
  final bool autoFocus;
  final TreeNavigationController? treeController;

  const GlobalSearch({
    super.key,
    required this.datasetRepo,
    required this.downloadedPicos,
    this.autoFocus = true,
    this.treeController,
  });

  @override
  State<GlobalSearch> createState() => _GlobalSearchState();
}

class _GlobalSearchState extends State<GlobalSearch> {
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _hasLoadedData = false;
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  Timer? _debounceTimer;

  List<GlobalSearchResult> _allData = [];
  List<GlobalSearchResult> _filteredResults = [];

  final List<String> _filters = const [
    'Todos',
    'Picos',
    'Setores',
    'Esportivas',
    'Móveis',
    'Boulders',
    'Highlines',
  ];

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.autoFocus) {
      _isExpanded = true;
      _loadAllData();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(GlobalSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.downloadedPicos != oldWidget.downloadedPicos) {
      _hasLoadedData = false;
      if (_isExpanded && !_isLoading) {
        _loadAllData();
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fecharModalSePossivel() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _toggleExpand() {
    if (Navigator.of(context).canPop() && _isExpanded) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        if (!_hasLoadedData && !_isLoading) {
          _loadAllData();
        }
        _searchFocusNode.requestFocus();
      } else {
        _searchFocusNode.unfocus();
        _searchQuery = '';
        _searchController.clear();
        _filteredResults.clear();
      }
    });
  }

  GlobalSearchResult _criarResultadoPorUid({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDownloaded,
    required bool isPico,
    required String categoriaFiltro,
    required Object originalItem,
    required String uid,
    required String idSlug,
    required bool ehEscalada,
  }) {
    return GlobalSearchResult(
      title: title,
      subtitle: subtitle,
      icon: icon,
      isDownloaded: isDownloaded,
      isPico: isPico,
      categoriaFiltro: categoriaFiltro,
      originalItem: originalItem,
      onTap: () => _abrirDestinoPorUid(
        uid: uid,
        idSlug: idSlug,
        titulo: title,
        isDownloaded: isDownloaded,
        ehEscalada: ehEscalada,
      ),
    );
  }

  GlobalSearchResult _criarResultadoResumoPico(
    ResumoPico crag, {
    required bool isDownloaded,
  }) {
    final partes = [
      'Pico',
      if (crag.local.isNotEmpty) crag.local,
      isDownloaded ? 'Salvo offline' : 'Catálogo',
    ];
    return GlobalSearchResult(
      title: crag.nome,
      subtitle: partes.join(' • '),
      icon: isDownloaded ? Icons.landscape : Icons.travel_explore,
      isDownloaded: isDownloaded,
      isPico: true,
      categoriaFiltro: 'Picos',
      originalItem: crag,
      onTap: () {
        _fecharModalSePossivel();
        handlePicoSelection(
          context,
          widget.datasetRepo,
          crag,
          source: 'busca_global',
        );
      },
    );
  }

  Future<void> _abrirDestinoPorUid({
    required String uid,
    required String idSlug,
    required String titulo,
    required bool isDownloaded,
    required bool ehEscalada,
  }) async {
    if (ehEscalada) {
      TelemetryService.instance.logAcaoEscalada(
        idSlug,
        'global',
        titulo,
        'abrir_detalhes',
        'busca_global',
      );
    } else {
      final primeiraVisita = await RegistroPrimeiraVisita.instancia
          .registrarEVerificarPrimeiraVisita(idSlug);
      TelemetryService.instance.logAcaoCroqui(
        idSlug,
        'abrir_croqui',
        origem: 'busca_global',
        modoAcesso: isDownloaded ? 'offline' : 'online',
        primeiraVisita: primeiraVisita,
      );
    }

    final localizador = LocalizadorDestinoUid(datasetRepo: widget.datasetRepo);
    final resultado = await localizador.localizar(uid);
    if (!mounted || resultado == null) return;

    _fecharModalSePossivel();
    final controlador =
        widget.treeController ?? TreeNavigationWrapper.currentTreeController;
    controlador?.navigateTo(resultado.noNavegacao);
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    final List<GlobalSearchResult> aggregatedData = [];
    final Set<String> processedCragIds = {};
    final Set<String> idsBaixados = widget.downloadedPicos
        .map((p) => p.id)
        .where((id) => id.isNotEmpty)
        .toSet();
    final Set<String> idsIndice =
        (widget.datasetRepo.indiceData.value?.croquis ?? const <ResumoCroqui>[])
            .map((c) => c.id)
            .where((id) => id.isNotEmpty)
            .toSet();
    final Set<String> idsPermitidos = <String>{
      ...idsIndice,
      ...idsBaixados,
      ...(widget.datasetRepo.activeDataset.value?.availablePicos ??
              const <ResumoPico>[])
          .map((p) => p.id)
          .where((id) => id.isNotEmpty),
      ...widget.datasetRepo.gerenciadorSessaoOnline.croquisEmMemoria.keys,
    };
    final bool restringirAoIndice = idsIndice.isNotEmpty;

    try {
      // 1. Dados do catálogo SQLite (catalogo.db)
      final croquisCatalogo =
          await widget.datasetRepo.repositorioCatalogo.listarCroquis();
      final entidadesCatalogo = await widget.datasetRepo.repositorioCatalogo
          .listarEntidadesDetalhadas();

      for (final croquiCat in croquisCatalogo) {
        if (restringirAoIndice && !idsPermitidos.contains(croquiCat.idSlug)) {
          continue;
        }
        processedCragIds.add(croquiCat.idSlug);
        final baixado = idsBaixados.contains(croquiCat.idSlug);
        final partesLocal = [
          if ((croquiCat.cidade ?? '').isNotEmpty) croquiCat.cidade!,
          if ((croquiCat.estado ?? '').isNotEmpty) croquiCat.estado!,
        ];
        final localStr = partesLocal.join(', ');
        final subtitulo = baixado
            ? (localStr.isNotEmpty
                  ? 'Pico • $localStr • Salvo offline'
                  : 'Pico • Salvo offline')
            : (localStr.isNotEmpty ? 'Pico • $localStr' : 'Pico');

        aggregatedData.add(
          _criarResultadoPorUid(
            title: croquiCat.nome,
            subtitle: subtitulo,
            icon: baixado ? Icons.landscape : Icons.travel_explore,
            isDownloaded: baixado,
            isPico: true,
            categoriaFiltro: 'Picos',
            originalItem: croquiCat,
            uid: croquiCat.croquiUid,
            idSlug: croquiCat.idSlug,
            ehEscalada: false,
          ),
        );
      }

      for (final ent in entidadesCatalogo) {
        if (restringirAoIndice && !idsPermitidos.contains(ent.idSlug)) {
          continue;
        }
        final baixado = idsBaixados.contains(ent.idSlug);
        if (ent.tipo == 'grupo') {
          aggregatedData.add(
            _criarResultadoPorUid(
              title: ent.nome,
              subtitle: 'Grupo • ${ent.picoNome}',
              icon: Icons.terrain,
              isDownloaded: baixado,
              isPico: false,
              categoriaFiltro: 'Setores',
              originalItem: ent,
              uid: ent.uid,
              idSlug: ent.idSlug,
              ehEscalada: false,
            ),
          );
        } else if (ent.tipo == 'setor') {
          final temGrupo =
              ent.grupoNome != null && ent.grupoNome!.trim().isNotEmpty;
          final subtitulo = temGrupo
              ? 'Setor (Grupo: ${ent.grupoNome}) • ${ent.picoNome}'
              : 'Setor • ${ent.picoNome}';
          aggregatedData.add(
            _criarResultadoPorUid(
              title: ent.nome,
              subtitle: subtitulo,
              icon: Icons.terrain,
              isDownloaded: baixado,
              isPico: false,
              categoriaFiltro: 'Setores',
              originalItem: ent,
              uid: ent.uid,
              idSlug: ent.idSlug,
              ehEscalada: false,
            ),
          );
        } else if (ent.tipo == 'escalada') {
          _adicionarEscaladaCatalogo(aggregatedData, ent, baixado);
        }
      }

      // 2. Croquis baixados que ainda não constam no catalogo.db
      for (final cragData in widget.downloadedPicos) {
        final cragIdStr = cragData.id;
        if (cragIdStr.isEmpty || processedCragIds.contains(cragIdStr)) {
          continue;
        }
        processedCragIds.add(cragIdStr);
        aggregatedData.add(
          _criarResultadoResumoPico(cragData, isDownloaded: true),
        );
      }

      // 3. Croquis da sessão online em memória não presentes no catalogo.db
      for (final entry in widget
          .datasetRepo
          .gerenciadorSessaoOnline
          .croquisEmMemoria
          .entries) {
        final cragId = entry.key;
        final croqui = entry.value;
        if (processedCragIds.contains(cragId) || croqui.picos.isEmpty) {
          continue;
        }
        processedCragIds.add(cragId);
        _adicionarCroquiProtobuf(
          aggregatedData,
          croqui,
          cragId,
          isDownloaded: idsBaixados.contains(cragId),
        );
      }

      // 4. Croquis disponíveis no índice que ainda não constam no catalogo.db
      final availablePicos =
          widget.datasetRepo.activeDataset.value?.availablePicos ?? const [];
      for (final crag in availablePicos) {
        final cragId = crag.id;
        if (cragId.isEmpty || processedCragIds.contains(cragId)) {
          continue;
        }
        processedCragIds.add(cragId);
        aggregatedData.add(
          _criarResultadoResumoPico(crag, isDownloaded: false),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _allData = aggregatedData;
          _isLoading = false;
          _hasLoadedData = true;
        });
        _applyFilters();
      }
    }
  }

  void _adicionarEscaladaCatalogo(
    List<GlobalSearchResult> lista,
    ItemCatalogoBusca ent,
    bool baixado,
  ) {
    String rotuloTipo = 'Esportiva';
    String categoriaFiltro = 'Esportivas';
    IconData icon = Icons.trending_up;

    switch (ent.escaladaTipo) {
      case 'tradicional':
        rotuloTipo = 'Móvel';
        categoriaFiltro = 'Móveis';
        break;
      case 'boulder':
        rotuloTipo = 'Boulder';
        categoriaFiltro = 'Boulders';
        icon = Icons.landscape;
        break;
      case 'highline':
        rotuloTipo = 'Highline';
        categoriaFiltro = 'Highlines';
        icon = Icons.straighten;
        break;
      case 'multienfiada':
        rotuloTipo = 'Multienfiada';
        categoriaFiltro = 'Outros';
        break;
      default:
        break;
    }

    final grauBruto = (ent.escaladaGrau ?? '').trim();
    String grauFormatado = '';
    if (grauBruto.isNotEmpty) {
      grauFormatado =
          (grauBruto.startsWith('V') || grauBruto.endsWith('m'))
          ? grauBruto
          : formatGradeString(grauBruto);
    }
    final grauDisplay = grauFormatado.isNotEmpty ? ' | $grauFormatado' : '';
    final partesContexto = [
      if ((ent.setorNome ?? '').isNotEmpty) ent.setorNome!,
      ent.picoNome,
    ];

    lista.add(
      _criarResultadoPorUid(
        title: ent.nome,
        subtitle: '$rotuloTipo$grauDisplay • ${partesContexto.join(' • ')}',
        icon: icon,
        isDownloaded: baixado,
        isPico: false,
        categoriaFiltro: categoriaFiltro,
        originalItem: ent,
        uid: ent.uid,
        idSlug: ent.idSlug,
        ehEscalada: true,
      ),
    );
  }

  void _adicionarCroquiProtobuf(
    List<GlobalSearchResult> aggregatedData,
    Croqui croqui,
    String cragId, {
    required bool isDownloaded,
  }) {
    final pico = croqui.picos.first;
    final picoNome = pico.nome;
    final picoLocal = pico.estado;
    final picoSubtitle = picoLocal.isNotEmpty ? 'Pico • $picoLocal' : 'Pico';

    aggregatedData.add(
      _criarResultadoPorUid(
        title: picoNome,
        subtitle: picoSubtitle,
        icon: Icons.landscape,
        isDownloaded: isDownloaded,
        isPico: true,
        categoriaFiltro: 'Picos',
        originalItem: pico,
        uid: croqui.uid,
        idSlug: cragId,
        ehEscalada: false,
      ),
    );

    for (final sg in pico.setoresOuGrupos) {
      if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
        _adicionarSetorProtobuf(
          aggregatedData,
          sg.setor.conteudo,
          cragId: cragId,
          picoNome: picoNome,
          grupoNome: null,
          isDownloaded: isDownloaded,
        );
      } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo &&
          sg.grupo.hasConteudo()) {
        final grupo = sg.grupo.conteudo;
        for (final arqSetor in grupo.setores) {
          if (arqSetor.hasConteudo()) {
            _adicionarSetorProtobuf(
              aggregatedData,
              arqSetor.conteudo,
              cragId: cragId,
              picoNome: picoNome,
              grupoNome: grupo.nome,
              isDownloaded: isDownloaded,
            );
          }
        }
      }
    }
  }

  void _adicionarSetorProtobuf(
    List<GlobalSearchResult> aggregatedData,
    Setor setor, {
    required String cragId,
    required String picoNome,
    required String? grupoNome,
    required bool isDownloaded,
  }) {
    final subtitulo = (grupoNome != null && grupoNome.isNotEmpty)
        ? 'Setor (Grupo: $grupoNome) • $picoNome'
        : 'Setor • $picoNome';

    aggregatedData.add(
      _criarResultadoPorUid(
        title: setor.nome,
        subtitle: subtitulo,
        icon: Icons.terrain,
        isDownloaded: isDownloaded,
        isPico: false,
        categoriaFiltro: 'Setores',
        originalItem: setor,
        uid: setor.uid,
        idSlug: cragId,
        ehEscalada: false,
      ),
    );

    for (final escalada in setor.escaladas) {
      _adicionarEscaladaProtobuf(
        aggregatedData,
        escalada,
        cragId: cragId,
        picoNome: picoNome,
        setorNome: setor.nome,
        isDownloaded: isDownloaded,
      );
    }
  }

  void _adicionarEscaladaProtobuf(
    List<GlobalSearchResult> list,
    Escalada escalada, {
    required String cragId,
    required String picoNome,
    required String setorNome,
    required bool isDownloaded,
  }) {
    final escaladaNome = getEscaladaNome(escalada);
    String tipoStr = getModalidadeEscalada(escalada);
    String categoriaFiltro = 'Esportivas';
    IconData icon = Icons.trending_up;

    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaMovel:
        categoriaFiltro = 'Móveis';
        break;
      case Escalada_Tipo.boulder:
        icon = Icons.landscape;
        categoriaFiltro = 'Boulders';
        break;
      case Escalada_Tipo.highline:
        icon = Icons.straighten;
        categoriaFiltro = 'Highlines';
        break;
      case Escalada_Tipo.notSet:
        tipoStr = 'Outro';
        categoriaFiltro = 'Outros';
        break;
      default:
        break;
    }

    final grauStr = getGrauString(escalada);
    final grauDisplay = grauStr.isNotEmpty ? ' | $grauStr' : '';

    list.add(
      _criarResultadoPorUid(
        title: escaladaNome,
        subtitle: '$tipoStr$grauDisplay • $setorNome • $picoNome',
        icon: icon,
        isDownloaded: isDownloaded,
        isPico: false,
        categoriaFiltro: categoriaFiltro,
        originalItem: escalada,
        uid: escalada.uid,
        idSlug: cragId,
        ehEscalada: true,
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (_searchQuery.isNotEmpty) {
        TelemetryService.instance.logBuscaEscaladas(
          _searchQuery,
          _filteredResults.length,
          'global',
        );
      }
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredResults = [];
      });
      return;
    }

    final typeFilteredData = _allData.where((item) {
      if (_selectedFilter == 'Todos') return true;
      return item.categoriaFiltro == _selectedFilter;
    }).toList();

    final fuse = Fuzzy<GlobalSearchResult>(
      typeFilteredData,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'title',
            getter: (GlobalSearchResult i) => normalizeSearchString(i.title),
            weight: 1.0,
          ),
          WeightedKey(
            name: 'subtitle',
            getter: (GlobalSearchResult i) => normalizeSearchString(i.subtitle),
            weight: 0.5,
          ),
        ],
        threshold: 0.4,
      ),
    );

    final queryLower = normalizeSearchString(_searchQuery);
    final results = fuse.search(queryLower).toList();

    // Prioriza itens já baixados offline aplicando boost determinístico no score
    results.sort((a, b) {
      final scoreA = a.item.isDownloaded ? (a.score * 0.5) - 0.15 : a.score;
      final scoreB = b.item.isDownloaded ? (b.score * 0.5) - 0.15 : b.score;
      return scoreA.compareTo(scoreB);
    });

    setState(() {
      _filteredResults = results.map((r) => r.item).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final caveShadowColor = context.colors.caveShadow;
    final searchTextColor = context.colors.chalkWhite;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 50,
            decoration: BoxDecoration(
              color: caveShadowColor,
              border: Border.all(color: context.colors.graniteEdge),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.arrow_back : Icons.search,
                    color: searchTextColor,
                  ),
                  onPressed: _toggleExpand,
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    style: TextStyle(color: searchTextColor),
                    cursorColor: const Color(0xFFC04F34),
                    decoration: InputDecoration(
                      hintText: 'Buscar picos, setores ou vias...',
                      hintStyle: TextStyle(
                        color: searchTextColor.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                    ),
                    readOnly: false,
                    onTap: () {
                      if (!_isExpanded) _toggleExpand();
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: searchTextColor),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                PopupMenuButton<String>(
                  onSelected: _onFilterChanged,
                  color: caveShadowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: context.colors.graniteEdge),
                  ),
                  itemBuilder: (BuildContext context) {
                    return _filters.map((String filter) {
                      final isSelected = _selectedFilter == filter;
                      return PopupMenuItem<String>(
                        value: filter,
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFFC04F34)
                                : context.colors.chalkWhite,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: caveShadowColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.graniteEdge),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 16,
                          color: context.colors.ashGrey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Filtro: $_selectedFilter',
                          style: TextStyle(
                            color: context.colors.ashGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dica: pesquise por picos, setores, vias ou graus (ex: 7a, V4)',
                    style: TextStyle(
                      color: context.colors.ashGrey,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFC04F34),
                  ),
                ),
              )
            else if (_searchQuery.isNotEmpty && _filteredResults.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Nenhum resultado encontrado.',
                    style: TextStyle(color: context.colors.ashGrey),
                  ),
                ),
              )
            else if (_searchQuery.isNotEmpty && _filteredResults.isNotEmpty)
              Expanded(
                child: Material(
                  color: caveShadowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.colors.graniteEdge),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filteredResults.length,
                    separatorBuilder: (context, index) => Divider(
                      color: context.colors.graniteEdge.withValues(alpha: 0.5),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = _filteredResults[index];
                      return ListTile(
                        leading: Icon(
                          item.icon,
                          color: item.isDownloaded
                              ? context.colors.dryMoss
                              : const Color(0xFFC04F34),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: context.colors.chalkWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          item.subtitle,
                          style: TextStyle(
                            color: context.colors.ashGrey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: item.isDownloaded
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colors.dryMoss.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: context.colors.dryMoss,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Offline',
                                      style: TextStyle(
                                        color: context.colors.dryMoss,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Icon(
                                Icons.cloud_outlined,
                                size: 16,
                                color: context.colors.ashGrey,
                              ),
                        onTap: () {
                          TelemetryService.instance.logAcaoEscalada(
                            'global_search',
                            'global',
                            item.title,
                            'abrir_detalhes',
                            'busca_global',
                          );
                          item.onTap();
                        },
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
