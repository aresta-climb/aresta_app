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
}
