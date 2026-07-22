import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../view_functions/mapa/mapa_global_functions.dart';
import '../view_functions/common_functions.dart';
import '../services/dataset_repository.dart';
import '../services/http/sync_service.dart';
import '../view_functions/mapa/mapa_marker.dart';
import '../view_functions/home_functions.dart';

/// Arquivo principal da tela do "Mapa Global" (Mapa de Picos).
class MapaGlobalPage extends StatefulWidget {
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Baixando $name...')));

    final success = await widget.syncService.downloadCrag(resumo);

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

  BitmapDescriptor? _customIcon;
  final Map<String, BitmapDescriptor> _textIcons = {};
  double _currentZoom = 4.0;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
  }

  Future<void> _loadCustomIcons() async {
    try {
      final icon = await createCustomMarkerBitmap(
        'assets/logo_app.png',
        size: 120,
      );
      if (mounted) {
        setState(() {
          _customIcon = icon;
        });
      }

      // Generate text icons for each crag in background
      for (final crag in widget.crags) {
        final name = crag['nome'] ?? 'Pico';
        final textIcon = await createCustomMarkerBitmapWithText(
          'assets/logo_app.png',
          name,
          size: 120,
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
          customIcon: _customIcon,
          textIcons: _textIcons,
          currentZoom: _currentZoom,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (controller) {
          _mapController = controller;
        },
        onCameraMove: (CameraPosition position) {
          if (mounted) {
            // Only rebuild if we cross the zoom threshold (e.g., 4.0)
            final bool wasZoomedIn = _currentZoom >= 4.0;
            final bool isZoomedIn = position.zoom >= 4.0;
            if (wasZoomedIn != isZoomedIn) {
              setState(() {
                _currentZoom = position.zoom;
              });
            } else {
              _currentZoom = position.zoom;
            }
          }
        },
      ),
    );
  }
}
