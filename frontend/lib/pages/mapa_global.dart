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

  BitmapDescriptor? _macroIcon;
  BitmapDescriptor? _regionalIcon;
  BitmapDescriptor? _customIcon;
  final Map<String, BitmapDescriptor> _textIcons = {};
  double _currentZoom = 4.0;
  FaixaZoomMapa _currentFaixaZoom = FaixaZoomMapa.macro;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _currentFaixaZoom = obterFaixaZoom(_currentZoom);
    _loadCustomIcons();
    _initLocation(fromButton: false);
  }

  Future<void> _initLocation({bool fromButton = true}) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted && (fromButton || !MapaGlobalPage.hasShownLocationWarning)) {
        MapaGlobalPage.hasShownLocationWarning = true;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ative o GPS para vermos sua localização.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted && (fromButton || !MapaGlobalPage.hasShownLocationWarning)) {
          MapaGlobalPage.hasShownLocationWarning = true;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissão de localização negada.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
