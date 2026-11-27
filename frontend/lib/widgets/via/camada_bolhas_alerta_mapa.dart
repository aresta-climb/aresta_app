// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../idioma/tradutor_app.dart';
import '../../view/view_models/alertas_mapa_interativo_view_model.dart';
import 'bolha_alerta_seguranca_via.dart';
import 'snackbar_flutuante_seguro.dart';

/// Coordenada normalizada da ponta da cauda em `_PintorBolhaChatVermelha` (`x = 0.24`, `y = 1.0`).
const Alignment _alinhamentoPontaCauda = Alignment(-0.52, 1.0);

/// Deslocamento em pixels lógicos de tela para apoiar a ponta da cauda na borda superior-direita do nó.
const double _deslocamentoTelaCaudaX = 5.0;
const double _deslocamentoTelaCaudaY = -10.0;

/// Caixa envolvente centrada na proporção `0.24` (`24 / 100`) para preservar área integral de toque em qualquer zoom.
const double _larguraCaixaAncora = 100.0;
const double _alturaCaixaAncora = 60.0;
const double _ancoraHorizontalPonta = 24.0;

/// Camada reativa (Dumb UI) que renderiza bolhas de alerta estilo Waze sobre o `MapaInterativoPage`,
/// compensando inversamente o fator de zoom para manter tamanho constante de toque na tela.
class CamadaBolhasAlertaMapa extends StatelessWidget {
  /// ViewModel das bolhas de alerta do mapa atual.
  final AlertasMapaInterativoViewModel viewModel;

  /// Controlador de transformação do `InteractiveViewer` para compensar a escala de zoom.
  final TransformationController transformationController;

  /// Largura atual renderizada da imagem do mapa no canvas.
  final double larguraCanvas;

  /// Altura atual renderizada da imagem do mapa no canvas.
  final double alturaCanvas;

  /// Cria uma instância de [CamadaBolhasAlertaMapa].
  const CamadaBolhasAlertaMapa({
    super.key,
    required this.viewModel,
    required this.transformationController,
    required this.larguraCanvas,
    required this.alturaCanvas,
  });

  Future<void> _abrirConfirmacao(
    BuildContext context,
    BolhaAlertaMapaApresentacao item,
  ) async {
    final despachanteSnack = capturarDespachanteSnackBarSeguro(context);
    await exibirModalConfirmacaoAlertaVia(
      context,
      alerta: item.alerta,
      estadoUsuario: viewModel.estadoInteracaoDoAlerta(item.alerta),
      aoResponder: (aindaEstaLa) async {
        if (aindaEstaLa) {
          await viewModel.confirmarAlerta(
            item.escaladaUid,
            item.alerta.uid,
            aindaEstaLa: true,
          );
          return;
        }

        viewModel.iniciarResolucaoAlertaComDesfazer(
          item.escaladaUid,
          item.alerta.uid,
        );
        despachanteSnack.exibir(
          texto: tr(
            ChaveTexto.alertaResolvidoNaViaToast,
            {'nome': item.nomeEscalada},
          ),
          duracao: const Duration(seconds: 4),
          rotuloAcao: tr(ChaveTexto.comumDesfazer),
          aoAcionar: () => viewModel.desfazerResolucaoAlerta(item.alerta.uid),
        );
      },
      aoSolicitarEdicao: () {
        if (!context.mounted) return;
        exibirModalReportarAlertaVia(
          context,
          alertaInicial: item.alerta,
          aoReportar: (novaCategoria, detalhe) async {
            final ok = await viewModel.editarAlerta(
              item.escaladaUid,
              item.alerta.uid,
              novaCategoria,
              detalhe: detalhe,
            );
            despachanteSnack.exibir(
              texto: ok
                  ? tr(ChaveTexto.alertaAtualizadoToast)
                  : tr(ChaveTexto.alertaFalhaAtualizarToast),
              duracao: const Duration(seconds: 2),
            );
          },
        );
      },
      aoSolicitarExclusao: () async {
        if (!context.mounted) return;
        final confirmado = await exibirDialogoConfirmarExclusaoInteracao(
          context,
          ehAlerta: true,
        );
        if (confirmado == true) {
          final ok = await viewModel.excluirAlerta(
            item.escaladaUid,
            item.alerta.uid,
          );
          if (ok) {
            despachanteSnack.exibir(
              texto: tr(ChaveTexto.alertaExcluidoToast),
              duracao: const Duration(seconds: 2),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (larguraCanvas <= 0 || alturaCanvas <= 0) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, transformationController]),
      builder: (context, _) {
        final bolhas = viewModel.bolhasNoMapa;
        if (bolhas.isEmpty) {
          return const SizedBox.shrink();
        }

        final zoom = transformationController.value
            .getMaxScaleOnAxis()
            .clamp(1.0, 10.0);
        final escalaInversa = 1.0 / zoom;

        return Stack(
          clipBehavior: Clip.none,
          children: bolhas.map((item) {
            final ancX = item.relX * larguraCanvas;
            final ancY = item.relY * alturaCanvas;
            final pontaX = ancX + _deslocamentoTelaCaudaX * escalaInversa;
            final pontaY = ancY + _deslocamentoTelaCaudaY * escalaInversa;
            return Positioned(
              left: pontaX - _ancoraHorizontalPonta,
              top: pontaY - _alturaCaixaAncora,
              width: _larguraCaixaAncora,
              height: _alturaCaixaAncora,
              child: Align(
                alignment: _alinhamentoPontaCauda,
                child: Transform.scale(
                  scale: escalaInversa,
                  alignment: _alinhamentoPontaCauda,
                  child: BolhaEmojiAlertaVia(
                    key: Key(
                      'bolha_mapa_${item.escaladaUid}_${item.alerta.categoria.codigoBanco}',
                    ),
                    alerta: item.alerta,
                    aoTocar: () => _abrirConfirmacao(context, item),
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}
