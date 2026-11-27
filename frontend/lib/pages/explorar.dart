// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import '../idioma/tradutor_app.dart';
import '../theme/cores_app.dart';
import '../view/function_library/funcoes_explorar.dart';
import '../view/view_models/explorar_view_model.dart';
import '../widgets/explorar/barra_busca_filtros_explorar.dart';
import '../widgets/explorar/controlador_camera_globo.dart';
import '../widgets/explorar/gaveta_deslizante_explorar.dart';
import '../widgets/explorar/superficie_globo_explorar.dart';

/// Re-exportação de [OrdemOrdenacaoPico] para compatibilidade de tipos.
typedef SortOrder = OrdemOrdenacaoPico;

/// Página unificada da aba `Explorar` integrando Globo 3D/2D em 4 LODs,
/// busca com seletor rápido de grau e gaveta deslizante sincronizada (Dumb UI).
///
/// Toda a resolução de filtros, marcadores geográficos, alvos de voo e downloads
/// fica concentrada em [BrowseViewModel], mantendo esta página puramente declarativa.
class BrowsePage extends StatefulWidget {
  final BrowseViewModel viewModel;

  const BrowsePage({
    super.key,
    required this.viewModel,
  });

  /// Aciona o download dos dados binários de um pico (`.binarypb`) com feedback visual.
  @visibleForTesting
  Future<void> handleDownload(BuildContext context, dynamic crag) async {
    final alvo = viewModel.resolverAlvoDownload(crag);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(tr(ChaveTexto.comumBaixando, {'nome': alvo.nome})),
        ),
      );

    final sucesso = await viewModel.baixarPicoPorId(alvo.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            sucesso
                ? tr(ChaveTexto.comumBaixadoSucesso, {'nome': alvo.nome})
                : tr(ChaveTexto.comumFalhaBaixar, {'nome': alvo.nome}),
          ),
          backgroundColor: sucesso ? Colors.green : Colors.red,
        ),
      );
  }

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final ControladorCameraGlobo _controladorCamera = ControladorCameraGlobo();
  final ValueNotifier<double> _alturaGavetaPx = ValueNotifier<double>(340.0);

  @override
  void dispose() {
    _controladorCamera.dispose();
    _alturaGavetaPx.dispose();
    super.dispose();
  }

  Future<void> _centralizarNaLocalizacaoUsuario() async {
    final resultado = await widget.viewModel.obterLocalizacaoTempoReal();
    if (!mounted) return;
    final coord = resultado.coordenada;
    if (coord != null) {
      _controladorCamera.iniciarVooParabolico(
        destinoLat: coord.latitude,
        destinoLon: coord.longitude,
        destinoLod: calcularLodFocoLocalizacaoUsuario(_controladorCamera.lod),
      );
    }
    final aviso = resultado.aviso;
    if (aviso != null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(aviso)));
    }
  }

  void _voarAtePicoSelecionadoNaLista(String picoId) {
    final destino = widget.viewModel.calcularDestinoVooPico(
      picoId,
      lodAtual: _controladorCamera.lod,
    );
    if (destino == null) return;
    if (destino.altitudeBaseMetros != null) {
      _controladorCamera.definirElevacaoReferenciaCamera(
        destino.altitudeBaseMetros!,
      );
    }
    _controladorCamera.iniciarVooParabolico(
      destinoLat: destino.latitude,
                  ),
                ),
                Divider(color: context.colors.graniteEdge),
                _buildSortOption(
                  context,
                  'Mais próximos',
                  OrdemOrdenacaoPico.proximidade,
                ),
                _buildSortOption(
                  context,
                  'Alfabético (A-Z)',
                  OrdemOrdenacaoPico.alfabetico,
                ),
                _buildSortOption(
                  context,
                  'Mais escaladas',
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
    final isSelected = widget.viewModel.ordem == order;
    return InkWell(
      onTap: () {
        widget.viewModel.alterarOrdem(order);
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
    final viewModel = widget.viewModel;
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

            final filteredCrags = viewModel.picosCards;
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
              onDownload: (crag) => widget.handleDownload(context, crag),
              onOpen: (crag) {
                final String id = crag is CardCroquiViewModel
                    ? crag.id
                    : (crag is Map ? crag['id']?.toString() ?? '' : crag.toString());
                viewModel.abrirPico(context, id);
              },
              onAddExperimental: addCallback,
              onSyncPressed: () async => await viewModel.sincronizarServing(context),
              onFilterPressed: () => _mostrarFiltroOrdenacao(context),
              scrollController: _scrollController,
              chaveSetimoPico: _chaveSetimoPico,
            );
          },
        ),
      ),
    );
  }
}
