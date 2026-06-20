import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../view_functions/mapao/mapao_global_functions.dart';
import '../view_functions/common_functions.dart';
import '../services/dataset_repository.dart';
import '../services/http/sync_service.dart';
import '../view_functions/mapao/mapao_marker.dart';
import '../view_functions/home_functions.dart';

/// Arquivo principal da tela do "Mapão Global" (Mapa de Picos).
class MapaoGlobalPage extends StatefulWidget {
  final List<Map<String, dynamic>> crags;
  final DatasetRepository datasetRepo;
  final SyncService syncService;

  const MapaoGlobalPage({
    super.key,
    required this.crags,
    required this.datasetRepo,
    required this.syncService,
  });

  @override
  State<MapaoGlobalPage> createState() => _MapaoGlobalPageState();
}

class _MapaoGlobalPageState extends State<MapaoGlobalPage> {
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Baixando $name...')),
    );

    final success = await widget.syncService.downloadCrag(resumo);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '$name baixado com sucesso!' : 'Falha ao baixar $name'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  BitmapDescriptor? _customIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomIcon();
  }

  Future<void> _loadCustomIcon() async {
    try {
      final icon = await createCustomMarkerBitmap('assets/logo_app.png', size: 120);
      if (mounted) {
        setState(() {
          _customIcon = icon;
        });
      }
    } catch (e) {
      // Silently fall back to default marker
    }
  }

  void _handleOpen(Map<String, dynamic> crag) {
    handlePicoSelection(context, widget.datasetRepo, crag, source: 'mapao_global');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: widget.syncService.downloadingCrags,
      builder: (context, downloadingCrags, _) {
        final markers = buildMapMarkers(
          context: context,
          crags: widget.crags,
          downloadingCrags: downloadingCrags,
          onDownload: _handleDownload,
          onOpen: _handleOpen,
          customIcon: _customIcon,
        );

        LatLng initialTarget = const LatLng(-14.2350, -51.9253);
        if (markers.isNotEmpty) {
          initialTarget = markers.first.position;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: buildCommonAppBar(context, 'Mapão Global'),
          body: buildMapaoGlobalMap(
            initialTarget: initialTarget,
            markers: markers,
          ),
        );
      },
    );
  }
}
