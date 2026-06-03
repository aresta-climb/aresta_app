import 'package:flutter/material.dart';
import '../view_functions/browse_functions.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/settings_functions.dart';
import '../services/dataset_repository.dart';
import '../services/editor_croqui.dart';
import 'package:fuzzy/fuzzy.dart';

/// Uma página que permite aos usuários explorar e pesquisar picos disponíveis.
/// 
/// Ela exibe uma lista de picos buscada do [DatasetRepository] e
/// fornece uma barra de pesquisa para filtrar por nome ou localização.
class BrowsePage extends StatefulWidget {
  final DatasetRepository datasetRepo;

  const BrowsePage({super.key, required this.datasetRepo});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  /// O texto atual inserido na barra de pesquisa.
  String _searchQuery = '';

  /// Aciona o download dos dados binários de um pico (.binarypb).
  /// 
  /// Mostra um SnackBar durante o processo e outro para indicar
  /// sucesso ou falha após a conclusão.
  void _handleDownload(Map<String, dynamic> crag) async {
    final name = safeString(crag['nome'], fallback: 'Pico');
    
    // Mostra um SnackBar para fornecer feedback ao usuário
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Baixando $name...')),
    );

    // Executa o download real através do repositório.
    // O arquivo é salvo no diretório de documentos local do aplicativo.
    final success = await widget.datasetRepo.downloadCrag(crag);

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

  @override
  Widget build(BuildContext context) {
    final EditorDeCroqui configService = widget.datasetRepo.editorDeCroqui;

    return Scaffold(
      backgroundColor: nobleBlack,
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
                      titulo: 'Adicionar mais croquis',
                    );
                  } else {
                    addCallback = null;
                  }

                  return buildBrowseBody(
                    context,
                    filteredCrags,
                    onSearchChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onDownload: _handleDownload,
                    onAddExperimental: addCallback,
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

