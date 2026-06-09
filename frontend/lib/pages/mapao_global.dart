import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../view_functions/mapao_global_functions.dart';
import '../view_functions/common_functions.dart';

/// Arquivo principal da tela do "Mapão Global" (Mapa de Picos).
///
/// Esta página é responsável por exibir o mapa múndi interativo utilizando
/// o Google Maps, com marcadores que apontam a localização de cada croqui
/// disponível. Ela atua como um gerenciador de estado, delegando a
/// construção dos elementos visuais e de interação para as funções do
/// [mapao_global_functions.dart].
class MapaoGlobalPage extends StatefulWidget {
  final List<Map<String, dynamic>> crags;
  final Set<String> downloadingCrags;
  final Function(Map<String, dynamic>) onDownload;
  final Function(Map<String, dynamic>)? onOpen;

  const MapaoGlobalPage({
    super.key,
    required this.crags,
    required this.downloadingCrags,
    required this.onDownload,
    this.onOpen,
  });

  @override
  State<MapaoGlobalPage> createState() => _MapaoGlobalPageState();
}

class _MapaoGlobalPageState extends State<MapaoGlobalPage> {
  late Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    // A inicialização dos marcadores precisa ser no initState mas depende do context
    // para poder mostrar o BottomSheet depois, então usaremos o context do builder ou
    // geraremos no build se os marcadores não forem muito pesados. 
    // Como os marcadores capturam o context no onTap (para showModalBottomSheet), 
    // é mais seguro construí-los no build() ou em didChangeDependencies().
  }

  @override
  Widget build(BuildContext context) {
    // Reconstrói os marcadores caso as listas mudem
    _markers = buildMapMarkers(
      context: context,
      crags: widget.crags,
      downloadingCrags: widget.downloadingCrags,
      onDownload: widget.onDownload,
      onOpen: widget.onOpen,
    );

    LatLng initialTarget = const LatLng(-14.2350, -51.9253);
    if (_markers.isNotEmpty) {
      initialTarget = _markers.first.position;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildCommonAppBar(context, 'Mapão Global'),
      body: buildMapaoGlobalMap(
        initialTarget: initialTarget,
        markers: _markers,
      ),
    );
  }
}
