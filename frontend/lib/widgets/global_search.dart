import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import '../services/dataset_repository.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/via_functions.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../navigation/navigation_functions.dart';

class GlobalSearchResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final dynamic originalItem;

  GlobalSearchResult({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.originalItem,
  });
}

class GlobalSearch extends StatefulWidget {
  final DatasetRepository datasetRepo;
  final List<Map<String, dynamic>> downloadedPicos;

  const GlobalSearch({
    super.key,
    required this.datasetRepo,
    required this.downloadedPicos,
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

  List<GlobalSearchResult> _allData = [];
  List<GlobalSearchResult> _filteredResults = [];

  final List<String> _filters = [
    'Todos', 'Setores', 'Esportivas', 'Móveis', 'Boulders', 'Highlines'
  ];

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
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

    for (var cragData in widget.downloadedPicos) {
      final cragId = cragData['id'];
      if (cragId == null) continue;

      final croqui = await widget.datasetRepo.getCroqui(cragId);
      if (croqui == null || croqui.picos.isEmpty) continue;

      final pico = croqui.picos.first;
      final picoNome = pico.nome.isNotEmpty ? pico.nome : (cragData['nome'] ?? 'Sem Nome');

      for (final sg in pico.setoresOuGrupos) {
        if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
          final setor = sg.setor.conteudo;
          
          aggregatedData.add(GlobalSearchResult(
            title: setor.nome,
            subtitle: 'Setor • $picoNome',
            icon: Icons.terrain,
            originalItem: setor,
            onTap: () {
              AppNav.toPico(context, pico: pico, croqui: croqui, cragId: cragId);
              AppNav.toSetor(context, setor: setor, pico: pico, croqui: croqui, cragId: cragId);
            },
          ));

          for (final escalada in setor.escaladas) {
            _addEscalada(aggregatedData, escalada, cragId, picoNome, pico, setor, croqui);
          }

        } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
          for (final s in sg.grupo.conteudo.setores) {
            if (s.hasConteudo()) {
              final setor = s.conteudo;
              
              aggregatedData.add(GlobalSearchResult(
                title: setor.nome,
                subtitle: 'Setor (Grupo: ${sg.grupo.conteudo.nome}) • $picoNome',
                icon: Icons.terrain,
                originalItem: setor,
                onTap: () {
                  AppNav.toPico(context, pico: pico, croqui: croqui, cragId: cragId);
                  AppNav.toSetor(context, setor: setor, pico: pico, croqui: croqui, cragId: cragId);
                },
              ));

              for (final escalada in setor.escaladas) {
                _addEscalada(aggregatedData, escalada, cragId, picoNome, pico, setor, croqui);
              }
            }
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _allData = aggregatedData;
        _isLoading = false;
        _hasLoadedData = true;
      });
      _applyFilters();
    }
  }

  void _addEscalada(List<GlobalSearchResult> list, Escalada escalada, String cragId, String picoNome, Pico pico, Setor setor, Croqui croqui) {
    String escaladaNome = getEscaladaNome(escalada);
    String tipoStr = 'Via';
    IconData icon = Icons.trending_up;

    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        tipoStr = 'Esportiva';
        break;
      case Escalada_Tipo.viaMovel:
        tipoStr = 'Móvel';
        break;
      case Escalada_Tipo.boulder:
        tipoStr = 'Boulder';
        icon = Icons.landscape;
        break;
      case Escalada_Tipo.viaMultiplasEnfiadas:
        tipoStr = 'Multipitch';
        break;
      case Escalada_Tipo.highline:
        tipoStr = 'Highline';
        icon = Icons.straighten;
        break;
      default:
        tipoStr = 'Outro';
    }

    final grauStr = getGrauString(escalada);
    final grauDisplay = grauStr.isNotEmpty ? ' | $grauStr' : '';

    list.add(GlobalSearchResult(
      title: escaladaNome,
      subtitle: '$tipoStr$grauDisplay • ${setor.nome} • $picoNome',
      icon: icon,
      originalItem: escalada,
      onTap: () {
        AppNav.toPico(context, pico: pico, croqui: croqui, cragId: cragId);
        AppNav.toSetor(context, setor: setor, scrollToEscalada: escalada, pico: pico, croqui: croqui, cragId: cragId);
        AppNav.toVia(context, escalada: escalada, setor: setor, pico: pico, croqui: croqui, cragId: cragId);
      },
    ));
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
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
        if (_selectedFilter == 'Setores' && item.originalItem is! Setor) return false;
        
        if (item.originalItem is Escalada) {
          final esc = item.originalItem as Escalada;
          if (_selectedFilter == 'Esportivas' && esc.whichTipo() != Escalada_Tipo.viaEsportiva) return false;
          if (_selectedFilter == 'Móveis' && esc.whichTipo() != Escalada_Tipo.viaMovel) return false;
          if (_selectedFilter == 'Boulders' && esc.whichTipo() != Escalada_Tipo.boulder) return false;
          if (_selectedFilter == 'Highlines' && esc.whichTipo() != Escalada_Tipo.highline) return false;
        } else if (_selectedFilter != 'Setores') {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchBgColor = isDark ? fishBone : obsidianBrown;
    final searchTextColor = isDark ? nobleBlack : fishBone;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 50,
            decoration: BoxDecoration(
              color: searchBgColor,
              borderRadius: BorderRadius.circular(15),
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
                    cursorColor: searchTextColor,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar em seus guias baixados...',
                      hintStyle: TextStyle(color: searchTextColor.withValues(alpha: 0.6)),
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
                  color: nobleBlack,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (BuildContext context) {
                    return _filters.map((String filter) {
                      final isSelected = _selectedFilter == filter;
                      return PopupMenuItem<String>(
                        value: filter,
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? beastHide : fishBone,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: beastHide.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list, size: 16, color: fishBone),
                        const SizedBox(width: 8),
                        Text(
                          'Filtro: $_selectedFilter',
                          style: TextStyle(color: fishBone, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dica: você também pode pesquisar por dificuldade (ex: 7a, V4)',
                    style: TextStyle(
                      color: fishBone.withValues(alpha: 0.5),
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
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator(color: beastHide)),
              )
            else if (_searchQuery.isNotEmpty && _filteredResults.isEmpty)
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'Nenhum resultado encontrado.',
                    style: TextStyle(color: fishBone),
                  ),
                ),
              )
            else if (_searchQuery.isNotEmpty && _filteredResults.isNotEmpty)
              Material(
                color: Colors.black.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: beastHide.withValues(alpha: 0.3)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filteredResults.length,
                  separatorBuilder: (context, index) => Divider(color: beastHide.withValues(alpha: 0.1), height: 1),
                  itemBuilder: (context, index) {
                    final item = _filteredResults[index];
                    return ListTile(
                      leading: Icon(item.icon, color: beastHide),
                      title: Text(item.title, style: TextStyle(color: fishBone, fontWeight: FontWeight.bold)),
                      subtitle: Text(item.subtitle, style: TextStyle(color: fishBone.withValues(alpha: 0.7), fontSize: 12)),
                      onTap: item.onTap,
                    );
                  },
                ),
              )),
            
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

