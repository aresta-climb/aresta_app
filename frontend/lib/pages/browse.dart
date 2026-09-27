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

  /// Aciona o download dos dados binários de um pico (.binarypb) com feedback visual.
  @visibleForTesting
  Future<void> handleDownload(BuildContext context, dynamic crag) async {
    final String id;
    final String name;

    if (crag is MetadadosIndice) {
      id = crag.id;
      name = crag.nome.isEmpty ? 'Pico' : crag.nome;
    } else if (crag is CardCroquiDTO) {
      id = crag.id;
      name = crag.titulo.isEmpty ? 'Pico' : crag.titulo;
    } else if (crag is Map) {
      id = crag['id']?.toString() ?? '';
      name = crag['nome']?.toString() ?? 'Pico';
    } else {
      id = crag.toString();
      name = 'Pico';
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Baixando $name...')));

    final success = await viewModel.baixarPicoPorId(id);

    if (context.mounted) {
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
              return Center(
                child: CircularProgressIndicator(
                  color: context.colors.beastHide,
                ),
              );
            }

            final filteredCrags = viewModel.picosFiltrados;
            final isEditor = viewModel.modoEditorAtivo;

            final addCallback = isEditor
                ? () => viewModel.trocarServing(context)
                : null;

            return buildBrowseBody(
              context,
              filteredCrags,
              viewModel.downloadingCrags,
              isDownloadedChecker: viewModel.estaBaixado,
              onSearchChanged: viewModel.alterarTermoBusca,
              onDownload: (crag) => handleDownload(context, crag),
              onOpen: (crag) {
                final String id = crag is MetadadosIndice
                    ? crag.id
                    : (crag is CardCroquiDTO ? crag.id : crag['id']?.toString() ?? '');
                viewModel.abrirPico(context, id);
              },
              onAddExperimental: addCallback,
              onSyncPressed: () async => await viewModel.sincronizarServing(context),
              onFilterPressed: () => _mostrarFiltroOrdenacao(context),
            );
          },
        ),
      ),
    );
  }
}
