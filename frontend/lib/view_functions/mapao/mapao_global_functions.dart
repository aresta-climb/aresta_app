import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../browse_functions.dart';

/// Coleção de funções de UI puras (view_functions) para o Mapão Global.
///
/// Este arquivo concentra a lógica de construção visual isolada para o mapa,
/// como a geração do widget [GoogleMap], a extração e mapeamento das
/// coordenadas em [Marker]s, e a exibição de modais (BottomSheet)
/// detalhando o croqui quando o usuário toca em algum marcador no mapa.

/// Exibe um modal inferior (BottomSheet) contendo o card expansível do crag selecionado.
void showCragModal({
  required BuildContext context,
  required Map<String, dynamic> crag,
  required double? downloadProgress,
  required VoidCallback onDownload,
  VoidCallback? onOpen,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: buildCragListItem(
                crag,
                downloadProgress,
                () {
                  onDownload();
                  Navigator.of(context).pop();
                },
                onOpen: onOpen != null
                    ? () {
                        Navigator.of(context).pop();
                        onOpen();
                      }
                    : null,
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Constrói o conjunto de marcadores para o mapa baseado na lista de picos disponíveis.
Set<Marker> buildMapMarkers({
  required BuildContext context,
  required List<Map<String, dynamic>> crags,
  required Map<String, double> downloadingCrags,
  required Function(Map<String, dynamic>) onDownload,
  Function(Map<String, dynamic>)? onOpen,
  BitmapDescriptor? customIcon,
}) {
  final markers = <Marker>{};

  for (final crag in crags) {
    if (crag['latitude'] != null && crag['longitude'] != null) {
      final double lat = crag['latitude'];
      final double lng = crag['longitude'];

      markers.add(
        Marker(
          markerId: MarkerId(crag['id']),
          position: LatLng(lat, lng),
          icon: customIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: crag['nome'],
            snippet: crag['local'],
            onTap: () {
              showCragModal(
                context: context,
                crag: crag,
                downloadProgress: downloadingCrags[crag['id']],
                onDownload: () => onDownload(crag),
                onOpen: onOpen != null ? () => onOpen(crag) : null,
              );
            },
          ),
        ),
      );
    }
  }

  return markers;
}

/// Constrói o widget do Google Map para a página do Mapão Global.
Widget buildMapaoGlobalMap({
  required LatLng initialTarget,
  required Set<Marker> markers,
}) {
  return GoogleMap(
    initialCameraPosition: CameraPosition(
      target: initialTarget,
      zoom: 4.0,
    ),
    markers: markers,
    myLocationEnabled: true,
    myLocationButtonEnabled: true,
    mapToolbarEnabled: false,
    zoomControlsEnabled: false,
  );
}
