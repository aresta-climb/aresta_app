// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firebase/app_logger.dart';
import '../view/view_models/mapa_pico_view_model.dart';
import '../view/function_library/mapa/mapa_global_functions.dart';
import '../view/function_library/mapa/mapa_marker.dart';
import '../view/view_models/mapa_global_view_model.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../theme/cores_app.dart';

/// Arquivo principal da tela do "Mapa Global" (Mapa de Picos) (Dumb UI).
///
/// Renderiza visualmente o mapa com os marcadores de picos e delega downloads
/// e navegações para o [MapaGlobalViewModel].
class MapaGlobalPage extends StatefulWidget {
  static bool hasShownLocationWarning = false;
  final MapaGlobalViewModel viewModel;

  const MapaGlobalPage({
    super.key,
    required this.viewModel,
  });

  @override
  State<MapaGlobalPage> createState() => _MapaGlobalPageState();
}

class _MapaGlobalPageState extends State<MapaGlobalPage> {
  void _handleDownload(MapaPicoViewModel pico) async {
    final name = pico.nome.isEmpty ? 'Pico' : pico.nome;
    final String id = pico.id;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Baixando $name...')));
    }

    final success = await widget.viewModel.baixarPico(id);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '$name baixado' : 'Falha ao baixar $name'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
