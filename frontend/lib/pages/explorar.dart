// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import '../idioma/tradutor_app.dart';
import '../theme/cores_app.dart';
import '../view/function_library/funcoes_explorar.dart';
import '../view/view_models/cena_globo_explorar_view_model.dart';
import '../view/view_models/explorar_view_model.dart';
import '../widgets/explorar/barra_busca_filtros_explorar.dart';
import '../widgets/explorar/controlador_camera_globo.dart';
import '../widgets/explorar/gaveta_deslizante_explorar.dart';
import '../widgets/explorar/superficie_globo_explorar.dart';

/// Re-exportação de [OrdemOrdenacaoPico] para compatibilidade de tipos.
typedef SortOrder = OrdemOrdenacaoPico;

/// Página unificada da aba `Explorar` integrando Globo 3D/2D em 4 LODs,
/// busca com seletor rápido de croquis e gaveta deslizante sincronizada (Dumb UI).
///
/// Toda a resolução de filtros, marcadores geográficos, alvos de voo, rotas viárias
/// e downloads fica concentrada em [BrowseViewModel] e [CenaGloboExplorarViewModel],
/// mantendo esta página puramente declarativa.
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
  late final CenaGloboExplorarViewModel _cenaGlobo = CenaGloboExplorarViewModel(
    lodInicialCamera: _controladorCamera.lod,
  );

  @override
  void initState() {
    super.initState();
    widget.viewModel.solicitacaoRotaBuscaUsuario
        .addListener(_aoSolicitarRotaBuscaUsuario);
  }

  @override
  void didUpdateWidget(covariant BrowsePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.solicitacaoRotaBuscaUsuario
          .removeListener(_aoSolicitarRotaBuscaUsuario);
      widget.viewModel.solicitacaoRotaBuscaUsuario
          .addListener(_aoSolicitarRotaBuscaUsuario);
    }
  }

  @override
  void dispose() {
    widget.viewModel.solicitacaoRotaBuscaUsuario
        .removeListener(_aoSolicitarRotaBuscaUsuario);
    _cenaGlobo.dispose();
    _controladorCamera.dispose();
    _alturaGavetaPx.dispose();
    super.dispose();
  }

  void _aoSolicitarRotaBuscaUsuario() {
    final evento = widget.viewModel.solicitacaoRotaBuscaUsuario.value;
    if (evento == null) return;
    final picoId = evento.picoId;
    final locUsuario = widget.viewModel.localizacaoUsuarioAtiva;
    final destino = widget.viewModel.calcularDestinoVooPico(
      picoId,
      lodAtual: _controladorCamera.lod,
    );
    if (locUsuario == null || destino == null) return;

    final ativouRota = _cenaGlobo.acionarRotaViariaUsuarioAtePico(
      origemUsuarioLonLat: Offset(locUsuario.longitude, locUsuario.latitude),
      picoId: picoId,
      destinoPicoLonLat: Offset(destino.longitude, destino.latitude),
      picosCatalogo: widget.viewModel.referenciasRelevoCatalogo,
    );

    if (destino.altitudeBaseMetros != null) {
      _controladorCamera.definirElevacaoReferenciaCamera(
        destino.altitudeBaseMetros!,
      );
    }

    if (ativouRota) {
      final enquadramento = calcularEnquadramentoRotaUsuarioPico(
        usuarioLat: locUsuario.latitude,
        usuarioLon: locUsuario.longitude,
        picoLat: destino.latitude,
        picoLon: destino.longitude,
      );
      _controladorCamera.iniciarVooParabolico(
        destinoLat: enquadramento.destinoLat,
        destinoLon: enquadramento.destinoLon,
        destinoLod: enquadramento.destinoLod,
      );
    } else {
      _controladorCamera.iniciarVooParabolico(
        destinoLat: destino.latitude,
        destinoLon: destino.longitude,
        destinoLod: destino.destinoLod,
      );
    }
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
      destinoLon: destino.longitude,
      destinoLod: destino.destinoLod,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      backgroundColor: context.colors.deepBasalt,
      body: SafeArea(
        bottom: false,
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

            return Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: SuperficieGloboExplorar(
                    controlador: _controladorCamera,
                    cenaViewModel: _cenaGlobo,
                    picos: viewModel.marcadoresGlobo,
                    referenciasRelevoCatalogo:
                        viewModel.referenciasRelevoCatalogo,
                    bolhasAtivas: viewModel.bolhasChuvaAtivas,
                    incendiosAtivos: viewModel.bolhasIncendioAtivas,
                    camadaClimaAtiva: viewModel.radarClimaMapaAtivo,
                    aoAlterarCamadaClima: viewModel.definirRadarClimaMapaAtivo,
                    picoSelecionadoId: viewModel.picoSelecionadoId,
                    alturaGavetaNotificador: _alturaGavetaPx,
                    localizacaoUsuario: viewModel.localizacaoUsuarioAtiva,
                    buscandoLocalizacaoUsuario: viewModel.buscandoLocalizacao,
                    aoCentralizarNoUsuario: _centralizarNaLocalizacaoUsuario,
                    recuoSuperiorControles: 66.0,
                    aoSelecionarPicoNoMapa: (id) =>
                        viewModel.selecionarPico(id, origemMapa: true),
                  ),
                ),
                GavetaDeslizanteExplorar(
                  viewModel: viewModel,
                  alturaGavetaPx: _alturaGavetaPx,
                  posicaoInicial: PosicaoEncaixeGaveta.dividir,
                  aoAbrirPico: (card) => viewModel.abrirPico(context, card.id),
                  aoFocarPicoNaLista: _voarAtePicoSelecionadoNaLista,
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: RepaintBoundary(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _alturaGavetaPx,
                      builder: (context, alturaGaveta, child) {
                        final opacidadeFundoLista =
                            calcularOpacidadeFundoBarraTopo(
                          alturaGavetaPx: alturaGaveta,
                          alturaTelaPx: MediaQuery.sizeOf(context).height,
                        );
                        return ColoredBox(
                          color: const Color(0xF514181E)
                              .withValues(alpha: opacidadeFundoLista),
                          child: child,
                        );
                      },
                      child: BarraBuscaFiltrosExplorar(
                        viewModel: viewModel,
                        aoSincronizar: () async =>
                            await viewModel.sincronizarServing(context),
                        aoTrocarServing: viewModel.modoEditorAtivo
                            ? () => viewModel.trocarServing(context)
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
