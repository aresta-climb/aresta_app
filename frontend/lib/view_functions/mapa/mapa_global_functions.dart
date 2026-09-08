// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../browse_functions.dart';
import '../../services/dataset/modelos/resumo_pico.dart';

/// Coleção de funções de UI puras (view_functions) para o Mapa Global.
///
/// Este arquivo concentra a lógica de construção visual isolada para o mapa,
/// como a geração do widget [GoogleMap], a extração e mapeamento das
/// coordenadas em [Marker]s, e a exibição de modais (BottomSheet)
/// detalhando o croqui quando o usuário toca em algum marcador no mapa.

/// Exibe um modal inferior (BottomSheet) contendo o card expansível do crag selecionado.
void showCragModal({
  required BuildContext context,
  required dynamic crag,
  required ValueListenable<Map<String, double>> downloadingCrags,
  required VoidCallback onDownload,
  VoidCallback? onOpen,
}) {
  final ResumoPico pico = crag is ResumoPico
      ? crag
      : ResumoPico.deMapa(crag is Map<String, dynamic>
          ? crag
          : Map<String, dynamic>.from(crag as Map));

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return SafeArea(
        child: Padding(
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
                  pico,
                  downloadingCrags,
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
        ),
      );
    },
  );
}

/// Constrói o conjunto de marcadores para o mapa baseado na lista de picos disponíveis.
///
/// Trata de forma resiliente os ícones de texto ([textIcons]), garantindo que caso uma
/// chave não exista ou resolva para nulo, seja utilizado o [customIcon] ou o marcador padrão,
/// prevenindo exceções de `Null check operator` em tempo de execução.
Set<Marker> buildMapMarkers({
  required BuildContext context,
  required dynamic crags,
  required ValueListenable<Map<String, double>> downloadingCrags,
  required Function(dynamic) onDownload,
  Function(dynamic)? onOpen,
  BitmapDescriptor? customIcon,
  Map<String, BitmapDescriptor?>? textIcons,
  double currentZoom = 4.0,
}) {
  final markers = <Marker>{};
  final bool showText = currentZoom >= 4.0;

  final List<ResumoPico> picos;
  if (crags is List<ResumoPico>) {
    picos = crags;
  } else if (crags is List) {
    picos = crags.map((item) {
      if (item is ResumoPico) return item;
      if (item is Map<String, dynamic>) return ResumoPico.deMapa(item);
      if (item is Map) return ResumoPico.deMapa(Map<String, dynamic>.from(item));
      return const ResumoPico(id: '', nome: '', local: '');
    }).toList();
  } else {
    picos = const [];
  }

  for (final crag in picos) {
    if (crag.latitude != null && crag.longitude != null) {
      final double lat = crag.latitude!;
      final double lng = crag.longitude!;
      final String id = crag.id;

      BitmapDescriptor iconToUse = customIcon ?? BitmapDescriptor.defaultMarker;
      if (showText && textIcons != null) {
        iconToUse = textIcons[id] ?? iconToUse;
      }

      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(lat, lng),
          icon: iconToUse,
          onTap: () {
            showCragModal(
              context: context,
              crag: crag,
              downloadingCrags: downloadingCrags,
              onDownload: () => onDownload(crag),
              onOpen: onOpen != null ? () => onOpen(crag) : null,
            );
          },
        ),
      );
    }
  }

  return markers;
}

/// Constrói o widget do Google Map para a página do Mapa Global.
Widget buildMapaGlobalMap({
  required LatLng initialTarget,
  required Set<Marker> markers,
}) {
  return GoogleMap(
    initialCameraPosition: CameraPosition(target: initialTarget, zoom: 4.0),
    markers: markers,
    myLocationEnabled: true,
    myLocationButtonEnabled: true,
    mapToolbarEnabled: false,
    zoomControlsEnabled: false,
  );
}
