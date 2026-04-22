import 'package:flutter/material.dart';
import '../functions/browse_functions.dart';
import '../functions/common_functions.dart';
import '../services/dataset_repository.dart';

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
    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar('Explorar Locais'),

      // ValueListenableBuilder reconstrói automaticamente esta parte da interface
      // sempre que o conjunto de dados no repositório muda (após a busca inicial).
      body: ValueListenableBuilder<TopoDataset?>(
        valueListenable: widget.datasetRepo.activeDataset,
        builder: (context, dataset, child) {
          // Enquanto o repositório ainda está inicializando/buscando, mostra um spinner.
          if (dataset == null) {
            return const Center(
              child: CircularProgressIndicator(color: beastHide),
            );
          }

          final allCrags = dataset.availablePicos;

          /* Filtra a lista localmente com base na consulta de pesquisa do usuário.
           Verificamos tanto o nome quanto a localização.
           safeString é usado para evitar falhas se um campo for inesperadamente nulo. */
          final filteredCrags = allCrags.where((crag) {
            final name = safeString(crag['nome']).toLowerCase();
            final location = safeString(crag['local']).toLowerCase();
            final query = _searchQuery.toLowerCase();

            return name.contains(query) || location.contains(query);
          }).toList();

          // Passamos os filteredCrags diretamente para buildBrowseBody.
          return buildBrowseBody(
            context,
            filteredCrags,
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onDownload: _handleDownload,
          );
        },
      ),
    );
  }
}
