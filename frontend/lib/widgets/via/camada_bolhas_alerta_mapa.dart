// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../view/view_models/alertas_mapa_interativo_view_model.dart';
import 'bolha_alerta_seguranca_via.dart';
import 'snackbar_flutuante_seguro.dart';

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
          texto: 'Alerta em ${item.nomeEscalada} marcado como resolvido.',
          duracao: const Duration(seconds: 4),
          rotuloAcao: 'Desfazer',
          aoAcionar: () => viewModel.desfazerResolucaoAlerta(item.alerta.uid),
        );
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
            return Positioned(
              left: ancX - 40,
              top: ancY - 48,
              width: 80,
              height: 48,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform.scale(
                  scale: escalaInversa,
                  alignment: Alignment.bottomCenter,
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
