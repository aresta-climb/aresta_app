// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import '../services/dataset_repository.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/via_functions.dart';
import '../view_functions/home_functions.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../navigation/navigation_functions.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../theme/app_colors.dart';

class GlobalSearchResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Object? originalItem;
  final bool isDownloaded;
  final bool isPico;

  GlobalSearchResult({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.originalItem,
    this.isDownloaded = true,
    this.isPico = false,
  });
}

class GlobalSearch extends StatefulWidget {
  final DatasetRepository datasetRepo;
  final List<ResumoPico> downloadedPicos;
  final bool autoFocus;

  const GlobalSearch({
    super.key,
    required this.datasetRepo,
    required this.downloadedPicos,
    this.autoFocus = true,
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

  final List<String> _filters = [
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

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && !_hasLoadedData && !_isLoading) {
        _loadAllData();
      }
      if (_searchFocusNode.hasFocus && !_isExpanded) {
        setState(() {
          _isExpanded = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(GlobalSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    _repoChangeWatcher(oldWidget);
  }

  /// Observa se a lista de picos mudou (ex: mudança de modo ou fim de download) e invalida o cache.
  void _repoChangeWatcher(GlobalSearch oldWidget) {
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

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    final List<GlobalSearchResult> aggregatedData = [];
    final Set<String> processedCragIds = {};

    try {
      // 1. Croquis Baixados
      for (final cragData in widget.downloadedPicos) {
        final cragIdStr = cragData.id;
        if (cragIdStr.isEmpty) continue;
        processedCragIds.add(cragIdStr);

        final picoNome =
            cragData.nome.isNotEmpty ? cragData.nome : 'Sem Nome';
        final picoLocal = cragData.local;
        final picoSubtitle = picoLocal.isNotEmpty
            ? 'Pico • $picoLocal • Salvo offline'
            : 'Pico • Salvo offline';

        Croqui? croqui;
        try {
          croqui = await widget.datasetRepo.getCroqui(cragIdStr);
        } catch (_) {
          croqui = null;
        }

        if (croqui != null && croqui.picos.isNotEmpty) {
          final pico = croqui.picos.first;
          final finalNome = pico.nome.isNotEmpty ? pico.nome : picoNome;
          final finalLocal = picoLocal.isNotEmpty
              ? picoLocal
              : (pico.hasEstado() ? pico.estado : '');
          final finalSubtitle = finalLocal.isNotEmpty
              ? 'Pico • $finalLocal • Salvo offline'
              : 'Pico • Salvo offline';

          aggregatedData.add(
            GlobalSearchResult(
              title: finalNome,
              subtitle: finalSubtitle,
              icon: Icons.landscape,
              isDownloaded: true,
              isPico: true,
              originalItem: pico,
              onTap: () {
                TelemetryService.instance.logAcaoCroqui(
                  cragIdStr,
                  'abrir_croqui',
                  origem: 'busca_global',
                );
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                AppNav.toPico(
                  context,
                  pico: pico,
                  croqui: croqui,
                  cragId: cragIdStr,
                );
              },
            ),
          );

          _processPicoData(
            aggregatedData,
            pico,
            croqui,
            cragIdStr,
            finalNome,
            isDownloaded: true,
          );
        } else {
          // Pico salvo mas sem protobuf carregado no momento
          aggregatedData.add(
            GlobalSearchResult(
              title: picoNome,
              subtitle: picoSubtitle,
              icon: Icons.landscape,
              isDownloaded: true,
              isPico: true,
              originalItem: cragData,
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                handlePicoSelection(
                  context,
                  widget.datasetRepo,
                  cragData,
                  source: 'busca_global',
                );
              },
            ),
          );
        }
      }

      // 2. Croquis da Sessão Online em Memória
      for (final entry
          in widget.datasetRepo.gerenciadorSessaoOnline.croquisEmMemoria.entries) {
        final cragId = entry.key;
        if (processedCragIds.contains(cragId)) continue;
        processedCragIds.add(cragId);

        final croqui = entry.value;
        if (croqui.picos.isEmpty) continue;
        final pico = croqui.picos.first;
        final picoNome = pico.nome.isNotEmpty ? pico.nome : 'Sem Nome';
        final picoLocal = pico.hasEstado() ? pico.estado : '';
        final picoSubtitle = picoLocal.isNotEmpty
            ? 'Pico • $picoLocal'
            : 'Pico';

        aggregatedData.add(
          GlobalSearchResult(
            title: picoNome,
            subtitle: picoSubtitle,
            icon: Icons.landscape,
            isDownloaded: false,
            isPico: true,
            originalItem: pico,
            onTap: () {
              TelemetryService.instance.logAcaoCroqui(
                cragId,
                'abrir_croqui',
                origem: 'busca_global',
              );
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              AppNav.toPico(
                context,
                pico: pico,
                croqui: croqui,
                cragId: cragId,
              );
            },
          ),
        );

        _processPicoData(
          aggregatedData,
          pico,
          croqui,
          cragId,
          picoNome,
          isDownloaded: false,
        );
      }

      // 3. Croquis Disponíveis no Catálogo / Explorar
      final availablePicos =
          widget.datasetRepo.activeDataset.value?.availablePicos ?? const [];
      for (final crag in availablePicos) {
        final cragId = crag.id;
        if (cragId.isEmpty || processedCragIds.contains(cragId)) {
          continue;
        }
        processedCragIds.add(cragId);

        final cragNome = crag.nome.isNotEmpty ? crag.nome : 'Sem Nome';
        final cragLocal = crag.local;
        final cragSubtitle = cragLocal.isNotEmpty
            ? 'Pico • $cragLocal • Catálogo'
            : 'Pico • Catálogo';

        aggregatedData.add(
          GlobalSearchResult(
            title: cragNome,
            subtitle: cragSubtitle,
            icon: Icons.travel_explore,
            isDownloaded: false,
            isPico: true,
            originalItem: crag,
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              handlePicoSelection(
                context,
                widget.datasetRepo,
                crag,
                source: 'busca_global',
              );
            },
          ),
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

  void _processPicoData(
    List<GlobalSearchResult> aggregatedData,
    Pico pico,
    Croqui croqui,
    String cragId,
    String picoNome, {
    bool isDownloaded = true,
  }) {
    for (final sg in pico.setoresOuGrupos) {
      if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
        final setor = sg.setor.conteudo;

        aggregatedData.add(
          GlobalSearchResult(
            title: setor.nome,
            subtitle: 'Setor • $picoNome',
            icon: Icons.terrain,
            isDownloaded: isDownloaded,
            isPico: false,
            originalItem: setor,
            onTap: () {
              TelemetryService.instance.logAcaoCroqui(
                cragId,
                'abrir_croqui',
                origem: 'busca_global',
              );
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              AppNav.toPico(
                context,
                pico: pico,
                croqui: croqui,
                cragId: cragId,
              );
              AppNav.toSetor(
                context,
                setor: setor,
                pico: pico,
                croqui: croqui,
                cragId: cragId,
              );
            },
          ),
        );

        for (final escalada in setor.escaladas) {
          _addEscalada(
            aggregatedData,
            escalada,
            cragId,
            picoNome,
            pico,
            setor,
            croqui,
            isDownloaded: isDownloaded,
          );
        }
      } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo &&
          sg.grupo.hasConteudo()) {
        for (final s in sg.grupo.conteudo.setores) {
          if (s.hasConteudo()) {
            final setor = s.conteudo;

            aggregatedData.add(
              GlobalSearchResult(
                title: setor.nome,
                subtitle: 'Setor (Grupo: ${sg.grupo.conteudo.nome}) • $picoNome',
                icon: Icons.terrain,
                isDownloaded: isDownloaded,
                isPico: false,
                originalItem: setor,
                onTap: () {
                  TelemetryService.instance.logAcaoCroqui(
                    cragId,
                    'abrir_croqui',
                    origem: 'busca_global',
                  );
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  AppNav.toPico(
                    context,
                    pico: pico,
                    croqui: croqui,
                    cragId: cragId,
                  );
                  AppNav.toSetor(
                    context,
                    setor: setor,
                    pico: pico,
                    croqui: croqui,
                    cragId: cragId,
                  );
                },
              ),
            );

            for (final escalada in setor.escaladas) {
              _addEscalada(
                aggregatedData,
                escalada,
                cragId,
                picoNome,
                pico,
                setor,
                croqui,
                isDownloaded: isDownloaded,
              );
            }
          }
        }
      }
    }
  }

  void _addEscalada(
    List<GlobalSearchResult> list,
    Escalada escalada,
    String cragId,
    String picoNome,
    Pico pico,
    Setor setor,
    Croqui croqui, {
    bool isDownloaded = true,
  }) {
    String escaladaNome = getEscaladaNome(escalada);
    String tipoStr = getModalidadeEscalada(escalada);
    IconData icon = Icons.trending_up;

    switch (escalada.whichTipo()) {
      case Escalada_Tipo.boulder:
        icon = Icons.landscape;
        break;
      case Escalada_Tipo.highline:
        icon = Icons.straighten;
        break;
      case Escalada_Tipo.notSet:
        tipoStr = 'Outro';
        break;
      default:
        break;
    }

    final grauStr = getGrauString(escalada);
    final grauDisplay = grauStr.isNotEmpty ? ' | $grauStr' : '';

    list.add(
      GlobalSearchResult(
        title: escaladaNome,
        subtitle: '$tipoStr$grauDisplay • ${setor.nome} • $picoNome',
        icon: icon,
        isDownloaded: isDownloaded,
        isPico: false,
        originalItem: escalada,
        onTap: () {
          TelemetryService.instance.logAcaoEscalada(
            cragId,
            'global',
            escaladaNome,
            'abrir_detalhes',
            'busca_global',
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          AppNav.toPico(context, pico: pico, croqui: croqui, cragId: cragId);
          AppNav.toSetor(
            context,
            setor: setor,
            scrollToEscalada: escalada,
            pico: pico,
            croqui: croqui,
            cragId: cragId,
          );
          AppNav.toVia(
            context,
            escalada: escalada,
            setor: setor,
            pico: pico,
            croqui: croqui,
            cragId: cragId,
          );
        },
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
      if (_selectedFilter != 'Todos') {
        if (_selectedFilter == 'Picos') {
          return item.isPico;
        }
        if (_selectedFilter == 'Setores') {
          return item.originalItem is Setor;
        }

        final original = item.originalItem;
        if (original is Escalada) {
          if (_selectedFilter == 'Esportivas' &&
              original.whichTipo() != Escalada_Tipo.viaEsportiva) {
            return false;
          }
          if (_selectedFilter == 'Móveis' &&
              esc.whichTipo() != Escalada_Tipo.viaMovel) {
            return false;
          }
          if (_selectedFilter == 'Boulders' &&
              esc.whichTipo() != Escalada_Tipo.boulder) {
            return false;
          }
          if (_selectedFilter == 'Highlines' &&
              esc.whichTipo() != Escalada_Tipo.highline) {
            return false;
          }
        } else {
          return false;
        }
      }
      return true;
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
    final results = fuse.search(queryLower);

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
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFFC04F34),
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
                            ? Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: context.colors.dryMoss,
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
