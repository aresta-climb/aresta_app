// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../view/view_models/mapa_pico_view_model.dart';
import '../view/function_library/mapa/mapa_global_functions.dart';
import '../view/function_library/mapa/mapa_marker.dart';
import '../view/view_models/mapa_global_view_model.dart';
import '../view/function_library/common_functions.dart';
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
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted && (fromButton || !MapaGlobalPage.hasShownLocationWarning)) {
        MapaGlobalPage.hasShownLocationWarning = true;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização bloqueada nas configurações.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 7.0,
            ),
          ),
        );
      } else if (position == null && mounted) {
        if (fromButton || !MapaGlobalPage.hasShownLocationWarning) {
          MapaGlobalPage.hasShownLocationWarning = true;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível encontrar sua localização.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Ignora falhas ao pegar localização
    }
  }

  Future<void> _loadCustomIcons() async {
    try {
      final macro = await createCustomMarkerBitmap('assets/logo_app.png', size: 40);
      final regional = await createCustomMarkerBitmap('assets/logo_app.png', size: 65);
      final custom = await createCustomMarkerBitmap('assets/logo_app.png', size: 85);
      if (mounted) {
        setState(() {
          _macroIcon = macro;
          _regionalIcon = regional;
          _customIcon = custom;
        });
      }

      for (final MapaPicoViewModel crag in widget.viewModel.picosNoMapa) {
        final name = crag.nome.isEmpty ? 'Pico' : crag.nome;
        final textIcon = await createCustomMarkerLabelBitmap(name);
        if (mounted) {
          setState(() {
            _textIcons[crag.id] = textIcon;
          });
        }
      }
    } catch (e) {
      // Silently fall back to default marker
    }
  }

  void _handleOpen(MapaPicoViewModel pico) {
    widget.viewModel.abrirPico(context, pico.id);
  }

  @override
  Widget build(BuildContext context) {
    final picos = widget.viewModel.picosNoMapa;
    LatLng initialTarget = const LatLng(-14.2350, -51.9253);
    if (picos.isNotEmpty) {
      final first = picos.first;
      if (first.latitude != null && first.longitude != null) {
        initialTarget = LatLng(first.latitude!, first.longitude!);
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildCommonAppBar(
        context,
        'Mapa Global',
        actions: [buildFeedbackButton(context)],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? context.colors.caveShadow
            : context.colors.chalkWhite,
        foregroundColor: AppColors.brandColor,
        mini: true,
        onPressed: _initLocation,
        child: const Icon(Icons.my_location),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final picosAtuais = widget.viewModel.picosNoMapa;

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: _currentZoom,
            ),
            markers: buildMapMarkers(
              context: context,
              crags: picosAtuais,
              downloadingCrags: widget.viewModel.downloadingCrags,
              onDownload: (crag) {
                if (crag is MapaPicoViewModel) {
                  _handleDownload(crag);
                }
              },
              onOpen: (crag) {
                if (crag is MapaPicoViewModel) {
                  _handleOpen(crag);
                }
              },
              macroIcon: _macroIcon,
              regionalIcon: _regionalIcon,
              customIcon: _customIcon,
              textIcons: _textIcons,
              currentZoom: _currentZoom,
              faixaZoom: _currentFaixaZoom,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: (CameraPosition position) {
              if (mounted) {
                try {
                  final novaFaixa = obterFaixaZoom(position.zoom);
                  _currentZoom = position.zoom;
                  if (_currentFaixaZoom != novaFaixa) {
                    setState(() {
                      _currentFaixaZoom = novaFaixa;
                    });
                  }
                } catch (_) {}
              }
            },
          );
        },
      ),
    );
  }
}
