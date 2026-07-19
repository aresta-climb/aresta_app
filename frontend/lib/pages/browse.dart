import 'dart:async';
import 'package:flutter/material.dart';
import '../view_functions/browse_functions.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/home_functions.dart';
import '../view_functions/settings_functions.dart';
import '../services/dataset_repository.dart';
import '../services/editor_croqui.dart';
import '../services/http/sync_service.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../theme/app_colors.dart';

enum SortOrder { padrao, alfabetico, escaladas }

/// Uma página que permite aos usuários explorar e pesquisar picos disponíveis.
///
/// Ela exibe uma lista de picos buscada do [DatasetRepository] e
/// fornece uma barra de pesquisa para filtrar por nome ou localização.
class BrowsePage extends StatefulWidget {
  final DatasetRepository datasetRepo;
  final SyncService syncService;

  const BrowsePage({
    super.key,
    required this.datasetRepo,
    required this.syncService,
  });

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  /// O texto atual inserido na barra de pesquisa.
  String _searchQuery = '';
  Timer? _debounceTimer;
  SortOrder _sortOrder = SortOrder.padrao;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Aciona o download dos dados binários de um pico (.binarypb).
  ///
  /// Mostra um SnackBar durante o processo e outro para indicar
  /// sucesso ou falha após a conclusão.
  void _handleDownload(Map<String, dynamic> crag) async {
    final name = safeString(crag['nome'], fallback: 'Pico');
    final String id = crag['id'];
    if (await widget.syncService.isNetworkDisabled()) {
      if (mounted) {
        showDeprecatedAppVersionSnackBar(context);
      }
      return;
    }

    final indice = widget.datasetRepo.indiceData.value;
    if (indice == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
          const SnackBar(
            content: Text('Erro: Índice não carregado. Tente novamente.'),
          ),
        );
      }
      return;
    }

    final resumos = indice.croquis.where((r) => r.id == id).toList();
    if (resumos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
          const SnackBar(
            content: Text('Pico inédito ou não encontrado no índice local.'),
          ),
        );
      }
      return;
    }
    final resumo = resumos.first;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
      SnackBar(content: Text('Baixando $name...')),
    );

    final success = await widget.syncService.downloadCrag(resumo);

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
        SnackBar(
          content: Text(success ? '$name baixado' : 'Falha ao baixar $name'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final EditorDeCroqui configService = widget.datasetRepo.editorDeCroqui;

    return Scaffold(
      backgroundColor: context.colors.deepBasalt, // Use new theme background
      
      // ValueListenableBuilder reconstrói automaticamente esta parte da interface
      // sempre que o conjunto de dados no repositório muda (após a busca inicial).
      body: SafeArea(
        child: ValueListenableBuilder<TopoDataset?>(
          valueListenable: widget.datasetRepo.activeDataset,
        builder: (context, dataset, child) {
          // Enquanto o repositório ainda está inicializando/buscando, mostra um spinner.
          if (dataset == null) {
            return Center(child: CircularProgressIndicator(color: beastHide));
          }

          final allCrags = dataset.availablePicos;

          List<Map<String, dynamic>> filteredCrags;
          if (_searchQuery.isEmpty) {
            filteredCrags = allCrags.toList();
          } else {
            final fuse = Fuzzy<Map<String, dynamic>>(
              allCrags,
              options: FuzzyOptions(
                keys: [
                  WeightedKey(
                    name: 'nome',
                    getter: (Map<String, dynamic> c) =>
                        normalizeSearchString(safeString(c['nome'])),
                    weight: 1.0,
                  ),
                  WeightedKey(
                    name: 'local',
                    getter: (Map<String, dynamic> c) =>
                        normalizeSearchString(safeString(c['local'])),
                    weight: 0.5,
                  ),
                ],
                threshold: 0.4,
              ),
            );

            final queryLower = normalizeSearchString(_searchQuery);
            filteredCrags = fuse.search(queryLower).map((r) => r.item).toList();
          }

          if (_sortOrder == SortOrder.alfabetico) {
            filteredCrags.sort((a, b) => safeString(a['nome']).compareTo(safeString(b['nome'])));
          } else if (_sortOrder == SortOrder.escaladas) {
            filteredCrags.sort((a, b) {
              final statsA = a['estatisticas'] ?? {};
              final statsB = b['estatisticas'] ?? {};
              final viasA = (statsA['totalVias'] as num?)?.toInt() ?? 0;
              final viasB = (statsB['totalVias'] as num?)?.toInt() ?? 0;
              return viasB.compareTo(viasA);
            });
          }

          // Verifica se o modo editor está ativo para passar as funções de importação
          return ValueListenableBuilder<bool>(
            valueListenable: configService.isExperimentalMode,
            builder: (context, isExperimental, child) {
              return ValueListenableBuilder<String?>(
                valueListenable: configService.editorUrl,
                builder: (context, activeUrl, child) {
                  final isEditor = activeUrl != null || isExperimental;

                  VoidCallback? addCallback;
                  if (isEditor) {
                    addCallback = () => mostrarDialogConexao(
                      context,
                      widget.datasetRepo,
                      titulo: 'Trocar serving',
                    );
                  } else {
                    addCallback = null;
                  }

                  return buildBrowseBody(
                    context,
                    filteredCrags,
                    widget.syncService.downloadingCrags,
                    onSearchChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });

                      if (_debounceTimer?.isActive ?? false)
                        _debounceTimer!.cancel();
                      _debounceTimer = Timer(
                        const Duration(milliseconds: 1000),
                        () {
                          if (_searchQuery.isNotEmpty) {
                            TelemetryService.instance.logBuscaCroquis(
                              _searchQuery,
                              filteredCrags.length,
                            );
                          }
                        },
                      );
                    },
                    onDownload: _handleDownload,
                    onOpen: (crag) => handlePicoSelection(
                      context,
                      widget.datasetRepo,
                      crag,
                      source: 'explorar',
                    ),
                    onAddExperimental: addCallback,
                    onFilterPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) {
                          return SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(
                                      'ORDENAÇÃO DE PICOS',
                                      style: TextStyle(
                                        color: const Color(0xFFC05244),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  const Divider(),
                                  _buildSortOption(
                                    context,
                                    'Padrão',
                                    SortOrder.padrao,
                                  ),
                                  _buildSortOption(
                                    context,
                                    'Alfabético (A-Z)',
                                    SortOrder.alfabetico,
                                  ),
                                  _buildSortOption(
                                    context,
                                    'Por número de escaladas',
                                    SortOrder.escaladas,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      ),
    );
  }

  Widget _buildSortOption(BuildContext context, String title, SortOrder order) {
    final isSelected = _sortOrder == order;
    return InkWell(
      onTap: () {
        setState(() {
          _sortOrder = order;
        });
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFFC05244) : context.colors.slateBlue,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFFC05244), size: 20),
          ],
        ),
      ),
    );
  }
}
