// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../data/dtos/card_croqui_dto.dart';
import '../services/dataset/modelos/metadados_indice.dart';
import '../view_functions/browse_functions.dart';
import '../view_functions/view_models/browse_view_model.dart';
import '../theme/app_colors.dart';

/// Re-exportação de [OrdemOrdenacaoPico] para compatibilidade de tipos.
typedef SortOrder = OrdemOrdenacaoPico;

/// Uma página que permite aos usuários explorar e pesquisar picos disponíveis (Dumb UI).
///
/// Renderiza visualmente o catálogo e delega buscas, filtros e ordenação ao [BrowseViewModel].
class BrowsePage extends StatelessWidget {
  /// ViewModel de apresentação e negócios da tela de catálogo.
  final BrowseViewModel viewModel;

  const BrowsePage({
    super.key,
    required this.viewModel,
  });

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  late final BrowseViewModel _viewModel;
  late final bool _criouViewModel;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _criouViewModel = false;
    } else {
      _viewModel = BrowseViewModel(
        datasetRepo: widget.datasetRepo!,
        syncService: widget.syncService!,
      );
      _criouViewModel = true;
    }
  }

  @override
  void dispose() {
    if (_criouViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  BrowseViewModel get viewModel => _viewModel;

  /// Aciona o download dos dados binários de um pico (.binarypb).
  @visibleForTesting
  void handleDownload(dynamic crag) async {
    final MetadadosIndice pico = crag is MetadadosIndice
        ? crag
        : (crag is ResumoPico
            ? MetadadosIndice(
                id: crag.id,
                nome: crag.nome,
                descricao: crag.descricao,
                caminhoRelativo: crag.url,
                checksumSha256Croqui: crag.checksum,
              )
            : MetadadosIndice(
                id: (crag as Map)['id']?.toString() ?? '',
                nome: crag['nome']?.toString() ?? '',
              ));
    final String name = pico.nome.isEmpty ? 'Pico' : pico.nome;

    if (await viewModel.syncService.isNetworkDisabled()) {
      if (mounted) {
        showDeprecatedAppVersionSnackBar(context);
      }
      return;
    }
    if (!mounted) return;

    if (viewModel.datasetRepo.indiceData.value == null) {
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

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Baixando $name...')));

    final success = await viewModel.baixarPico(pico);

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

  void _mostrarFiltroOrdenacao(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.caveShadow,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'ORDENAÇÃO DE PICOS',
                    style: TextStyle(
                      color: context.colors.rustIron,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Divider(color: context.colors.graniteEdge),
                _buildSortOption(
                  context,
                  'Padrão',
                  OrdemOrdenacaoPico.padrao,
                ),
                _buildSortOption(
                  context,
                  'Alfabético (A-Z)',
                  OrdemOrdenacaoPico.alfabetico,
                ),
                _buildSortOption(
                  context,
                  'Por número de escaladas',
                  OrdemOrdenacaoPico.escaladas,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String title,
    OrdemOrdenacaoPico order,
  ) {
    final isSelected = viewModel.ordem == order;
    return InkWell(
      onTap: () {
        viewModel.alterarOrdem(order);
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
                color: isSelected ? context.colors.rustIron : Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: context.colors.rustIron, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.deepBasalt,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            if (viewModel.carregando) {
              return Center(child: CircularProgressIndicator(color: beastHide));
            }

            final filteredCrags = viewModel.picosFiltrados;
            final isEditor = viewModel.modoEditorAtivo;

            final addCallback = isEditor
                ? () => mostrarDialogConexao(
                      context,
                      viewModel.datasetRepo,
                      titulo: 'Trocar serving',
                    )
                : null;

            return buildBrowseBody(
              context,
              filteredCrags,
              viewModel.syncService.downloadingCrags,
              isDownloadedChecker: viewModel.estaBaixado,
              onSearchChanged: viewModel.alterarTermoBusca,
              onDownload: handleDownload,
              onOpen: (crag) => handlePicoSelection(
                context,
                viewModel.datasetRepo,
                crag,
                source: 'explorar',
              ),
              onAddExperimental: addCallback,
              onSyncPressed: () async {
                await handleSyncServing(
                  context,
                  viewModel.datasetRepo,
                  viewModel.syncService,
                );
              },
              onFilterPressed: () => _mostrarFiltroOrdenacao(context),
            );
          },
        ),
      ),
    );
  }
}
