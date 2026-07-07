import 'dart:async';
import 'package:flutter/material.dart';
import '../view_functions/browse_functions.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/home_functions.dart';
import '../view_functions/settings_functions.dart';
import '../services/dataset_repository.dart';
import '../services/editor_croqui.dart';
import '../services/http/sync_service.dart';
import '../services/p2p/ambient_p2p_service.dart';
import '../services/p2p/p2p_transfer_manager.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';

/// Uma página que permite aos usuários explorar e pesquisar picos disponíveis.
/// 
/// Ela exibe uma lista de picos buscada do [DatasetRepository] e
/// fornece uma barra de pesquisa para filtrar por nome ou localização.
class BrowsePage extends StatefulWidget {
  final DatasetRepository datasetRepo;
  final SyncService syncService;

  const BrowsePage({super.key, required this.datasetRepo, required this.syncService});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  /// O texto atual inserido na barra de pesquisa.
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Inicializa os serviços P2P ao entrar na página de explorar
    AmbientP2PService.instance.init();
    P2PTransferManager.instance.init();
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
    final isP2P = AmbientP2PService.instance.nearbyAvailableCrags.value.contains(id);

    if (!isP2P && await widget.syncService.isNetworkDisabled()) {
      if (mounted) {
        showDeprecatedAppVersionSnackBar(context);
      }
      return;
    }

    final indice = widget.datasetRepo.indiceData.value;
    if (indice == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Índice não carregado. Tente novamente.')),
        );
      }
      return;
    }

    final resumos = indice.croquis.where((r) => r.id == id).toList();
    if (resumos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pico inédito ou não encontrado no índice local.')),
        );
      }
      return;
    }
    final resumo = resumos.first;
    
    // Mostra um SnackBar para fornecer feedback ao usuário
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isP2P ? 'Solicitando $name via P2P...' : 'Baixando $name...')),
    );

    if (isP2P) {
      P2PTransferManager.instance.requestCragFromPeer(id);
      // O P2PManager lida com o progresso internamente
    } else {
      final success = await widget.syncService.downloadCrag(resumo);

      if (mounted) {
        // Atualiza o usuário com o resultado
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '$name baixado com sucesso!' : 'Falha ao baixar $name'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final EditorDeCroqui configService = widget.datasetRepo.editorDeCroqui;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildCommonAppBar(context, 'Explorar Locais'),

      // ValueListenableBuilder reconstrói automaticamente esta parte da interface
      // sempre que o conjunto de dados no repositório muda (após a busca inicial).
      body: ValueListenableBuilder<TopoDataset?>(
        valueListenable: widget.datasetRepo.activeDataset,
        builder: (context, dataset, child) {
          // Enquanto o repositório ainda está inicializando/buscando, mostra um spinner.
          if (dataset == null) {
            return Center(
              child: CircularProgressIndicator(color: beastHide),
            );
          }

          final allCrags = dataset.availablePicos;

          List<Map<String, dynamic>> filteredCrags;
          if (_searchQuery.isEmpty) {
            filteredCrags = allCrags;
          } else {
            final fuse = Fuzzy<Map<String, dynamic>>(
              allCrags,
              options: FuzzyOptions(
                keys: [
                  WeightedKey(
                    name: 'nome',
                    getter: (Map<String, dynamic> c) => normalizeSearchString(safeString(c['nome'])),
                    weight: 1.0,
                  ),
                  WeightedKey(
                    name: 'local',
                    getter: (Map<String, dynamic> c) => normalizeSearchString(safeString(c['local'])),
                    weight: 0.5,
                  ),
                ],
                threshold: 0.4,
              ),
            );

            final queryLower = normalizeSearchString(_searchQuery);
            filteredCrags = fuse.search(queryLower).map((r) => r.item).toList();
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

                  return ValueListenableBuilder<Map<String, double>>(
                    valueListenable: widget.syncService.downloadingCrags,
                    builder: (context, downloadingCrags, child) {
                      return ValueListenableBuilder<Set<String>>(
                        valueListenable: AmbientP2PService.instance.nearbyAvailableCrags,
                        builder: (context, nearbyCrags, child) {
                          return buildBrowseBody(
                            context,
                            filteredCrags,
                            downloadingCrags,
                            onSearchChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                              
                              if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                              _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
                                if (_searchQuery.isNotEmpty) {
                                  TelemetryService.instance.logBuscaCroquis(_searchQuery, filteredCrags.length);
                                }
                              });
                            },
                            onDownload: _handleDownload,
                            onOpen: (crag) => handlePicoSelection(context, widget.datasetRepo, crag, source: 'explorar'),
                            onAddExperimental: addCallback,
                            nearbyAvailableCrags: nearbyCrags,
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
    );
  }
}

