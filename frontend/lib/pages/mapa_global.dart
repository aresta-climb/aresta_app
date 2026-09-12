// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../view_functions/mapa/mapa_global_functions.dart';
import '../view_functions/common_functions.dart';
import '../services/dataset_repository.dart';
import '../services/http/sync_service.dart';
import '../services/http/servico_download_segundo_plano.dart';
import '../view_functions/mapa/mapa_marker.dart';
import '../view_functions/home_functions.dart';
import '../theme/app_colors.dart';

/// Arquivo principal da tela do "Mapa Global" (Mapa de Picos).
class MapaGlobalPage extends StatefulWidget {
  static bool hasShownLocationWarning = false;
  final List<Map<String, dynamic>> crags;
  final DatasetRepository datasetRepo;
  final SyncService syncService;

  const MapaGlobalPage({
    super.key,
    required this.crags,
    required this.datasetRepo,
    required this.syncService,
  });

  @override
  State<MapaGlobalPage> createState() => _MapaGlobalPageState();
}

class _MapaGlobalPageState extends State<MapaGlobalPage> {
  void _handleDownload(Map<String, dynamic> crag) async {
    final name = crag['nome'] ?? 'Pico';
    final String id = crag['id'];

    if (await widget.syncService.isNetworkDisabled()) {
      if (mounted) {
        showDeprecatedAppVersionSnackBar(context);
      }
      return;
    }

    final indice = widget.datasetRepo.indiceData.value;
    if (indice == null) return;

    final resumos = indice.croquis.where((r) => r.id == id).toList();
    if (resumos.isEmpty) return;

    final resumo = resumos.first;

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Baixando $name...')));
    }

    final servicoDownload =
        ServicoDownloadSegundoPlano(syncService: widget.syncService);
    final success = await servicoDownload.executarDownload(resumo);

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
      // Ícone para visão macro (40px)
      final macro = await createCustomMarkerBitmap(
        'assets/logo_app.png',
        size: 40,
      );
      // Ícone para visão regional (65px)
      final regional = await createCustomMarkerBitmap(
        'assets/logo_app.png',
        size: 65,
      );
      // Ícone para visão local / base (85px)
      final custom = await createCustomMarkerBitmap(
        'assets/logo_app.png',
        size: 85,
      );
      if (mounted) {
        setState(() {
          _macroIcon = macro;
          _regionalIcon = regional;
          _customIcon = custom;
        });
      }

      // Gera ícones com texto para visão local em segundo plano
      for (final crag in widget.crags) {
        final name = crag['nome'] ?? 'Pico';
        final textIcon = await createCustomMarkerBitmapWithText(
          'assets/logo_app.png',
          name,
          size: 85,
        );
        if (mounted) {
          setState(() {
            _textIcons[crag['id']] = textIcon;
          });
        }
      }
    } catch (e) {
      // Silently fall back to default marker
    }
  }

  void _handleOpen(Map<String, dynamic> crag) {
    handlePicoSelection(
      context,
      widget.datasetRepo,
      crag,
      source: 'mapa_global',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Removed markers generation from here since it needs to be inside body for zoom reactivity

    LatLng initialTarget = const LatLng(-14.2350, -51.9253);
    if (widget.crags.isNotEmpty) {
      final firstCrag = widget.crags.first;
      if (firstCrag['latitude'] != null && firstCrag['longitude'] != null) {
        initialTarget = LatLng(firstCrag['latitude'], firstCrag['longitude']);
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
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialTarget,
          zoom: _currentZoom,
        ),
        markers: buildMapMarkers(
          context: context,
          crags: widget.crags,
          downloadingCrags: widget.syncService.downloadingCrags,
          onDownload: _handleDownload,
          onOpen: _handleOpen,
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
            } catch (e) {
              // Ignora frames nulos ou incompletos emitidos por platform channels (OEM Android 11)
            }
          }
        },
      ),
    );
  }
}
