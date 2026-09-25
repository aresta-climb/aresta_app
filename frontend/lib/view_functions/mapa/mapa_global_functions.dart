// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../browse_functions.dart';
import '../../services/dataset/modelos/resumo_pico.dart';
import '../../services/dataset/modelos/metadados_indice.dart';

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
  final ResumoPico pico = crag is MetadadosIndice
      ? crag.paraResumoPico()
      : (crag is ResumoPico
          ? crag
          : ResumoPico.deMapa(crag is Map<String, dynamic>
              ? crag
              : Map<String, dynamic>.from(crag as Map)));

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

/// Representa as faixas de zoom discretas do Mapa Global para escalonamento visual dos marcadores.
enum FaixaZoomMapa {
  /// Visão macro (zoom < 6.0): Pinos pequenos (40px) sem balão de texto.
  macro,

  /// Visão regional (6.0 <= zoom < 9.0): Pinos médios (65px) sem balão de texto.
  regional,

  /// Visão local (zoom >= 9.0): Pinos completos (85px) com balão de texto compacto.
  local,
}

/// Classifica o nível de zoom da câmera na respectiva [FaixaZoomMapa].
FaixaZoomMapa obterFaixaZoom(double zoom) {
  if (zoom < 6.0) {
    return FaixaZoomMapa.macro;
  }
  if (zoom < 9.0) {
    return FaixaZoomMapa.regional;
  }
  return FaixaZoomMapa.local;
}

/// Constrói o conjunto de marcadores para o mapa baseado na lista de picos disponíveis
/// e na faixa de zoom ativa.
///
/// Trata de forma resiliente os ícones de texto ([textIcons]) e ícones das faixas ([macroIcon], [regionalIcon]),
/// garantindo fallback para [customIcon] ou [BitmapDescriptor.defaultMarker], prevenindo exceções de
/// `Null check operator` em tempo de execução.
Set<Marker> buildMapMarkers({
  required BuildContext context,
  required dynamic crags,
  required ValueListenable<Map<String, double>> downloadingCrags,
  required Function(dynamic) onDownload,
  Function(dynamic)? onOpen,
  BitmapDescriptor? macroIcon,
  BitmapDescriptor? regionalIcon,
  BitmapDescriptor? customIcon,
  Map<String, BitmapDescriptor?>? textIcons,
  double currentZoom = 4.0,
  FaixaZoomMapa? faixaZoom,
}) {
  final markers = <Marker>{};
  final faixa = faixaZoom ?? obterFaixaZoom(currentZoom);

  // Determina o ícone de fallback baseado na faixa atual
  BitmapDescriptor fallbackIcon;
  switch (faixa) {
    case FaixaZoomMapa.macro:
      fallbackIcon = macroIcon ?? customIcon ?? BitmapDescriptor.defaultMarker;
      break;
    case FaixaZoomMapa.regional:
      fallbackIcon = regionalIcon ?? customIcon ?? BitmapDescriptor.defaultMarker;
      break;
    case FaixaZoomMapa.local:
      fallbackIcon = customIcon ?? regionalIcon ?? BitmapDescriptor.defaultMarker;
      break;
  }

  final List<ResumoPico> picos;
  if (crags is List<ResumoPico>) {
    picos = crags;
  } else if (crags is List) {
    picos = crags.map((item) {
      if (item is ResumoPico) return item;
      if (item is MetadadosIndice) return item.paraResumoPico();
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

      BitmapDescriptor iconToUse = fallbackIcon;
      // Rótulos de texto com nome só são exibidos na faixa local para evitar sobreposição
      if (faixa == FaixaZoomMapa.local && textIcons != null) {
        iconToUse = textIcons[id] ?? fallbackIcon;
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
