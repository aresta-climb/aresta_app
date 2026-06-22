import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import 'common_functions.dart';
import 'offline_markdown.dart';
import 'via_functions.dart';
import '../widgets/mapa_thumbnail.dart';
import '../navigation/navigation_functions.dart';
import '../services/firebase/telemetry_service.dart';

/// Constrói o corpo rolável principal da página do Setor.
///
/// Ele extrai a descrição e itera por todas as vias disponíveis
/// ([Escalada]) e subsetores aninhados para renderizá-los.
Widget buildSetorBody(BuildContext context, Setor setor, String cragId, List<Escalada> sortedEscaladas, [Escalada? scrollToEscalada, GlobalKey? targetKey, Widget? sortButton]) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (setor.descricao.isNotEmpty) ...[
          _buildHeader('Descrição'),
          OfflineMarkdown(data: setor.descricao, cragId: cragId),
          const SizedBox(height: 20),
        ],

        if (setor.mapas.isNotEmpty) ...[
          ...setor.mapas.map((mapa) {
            if (mapa.caminhoImagemMapa.isNotEmpty && mapa.larguraMapa > 0 && mapa.alturaMapa > 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: mapa.larguraMapa / mapa.alturaMapa,
                    child: MapaThumbnail(
                      mapa: mapa,
                      cragId: cragId,
                      setorContext: setor,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],

        Builder(
          builder: (context) {
            // Use common function to check if area is predominantly boulders
            final bool boulderArea = isBoulderArea(sortedEscaladas);
            
            String headerText = 'Vias';
            String emptyText = 'Nenhuma via disponível.';
            if (boulderArea) {
              headerText = 'Boulders';
              emptyText = 'Nenhum boulder disponível.';
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeader(headerText),
                    ?sortButton,
                  ],
                ),
                if (sortedEscaladas.isEmpty)
                  Text(emptyText, style: TextStyle(color: fishBone))
                else ...[
                  ...sortedEscaladas.map((escalada) {
                    final bool isTarget = (scrollToEscalada != null && targetKey != null && escalada == scrollToEscalada);
                    final tile = _buildRouteTile(context, escalada, cragId, setor, isTarget: isTarget);
                    if (isTarget) {
                      return KeyedSubtree(
                        key: targetKey,
                        child: tile,
                      );
                    }
                    return tile;
                  }),
                ],
              ],
            );
          },
        ),
      ],
    ),
  );
}

Widget _buildHeader(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      title,
      style: TextStyle(
        color: beastHide,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}



/// Resolve the map indicator and concatenated labels for a given Escalada.
/// Returns a Map with 'mapIndicator' (e.g. 'M1') and 'resolvedLabel' (e.g. '1-X').
Map<String, String> resolveRouteLabels(Escalada escalada, Setor setor) {
  String resolvedLabel = '';
  String mapIndicator = '';

  String escaladaNome = '';
  int indiceMapaPadrao = 0;

  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      escaladaNome = escalada.viaEsportiva.nome;
      indiceMapaPadrao = escalada.viaEsportiva.indiceMapaPadrao;
      break;
    case Escalada_Tipo.viaMovel:
      escaladaNome = escalada.viaMovel.nome;
      indiceMapaPadrao = escalada.viaMovel.indiceMapaPadrao;
      break;
    case Escalada_Tipo.boulder:
      escaladaNome = escalada.boulder.nome;
      indiceMapaPadrao = escalada.boulder.indiceMapaPadrao;
      break;
    case Escalada_Tipo.viaMultiplasEnfiadas:
      escaladaNome = escalada.viaMultiplasEnfiadas.nome;
      indiceMapaPadrao = escalada.viaMultiplasEnfiadas.indiceMapaPadrao;
      break;
    case Escalada_Tipo.highline:
      escaladaNome = escalada.highline.nome;
      indiceMapaPadrao = escalada.highline.indiceMapaPadrao;
      break;
    default:
      break;
  }

  if (setor.mapas.isNotEmpty) {
    List<int> searchOrder = [];
    if (indiceMapaPadrao >= 0 && indiceMapaPadrao < setor.mapas.length) {
      searchOrder.add(indiceMapaPadrao);
    }
    for (int i = 0; i < setor.mapas.length; i++) {
      if (!searchOrder.contains(i)) {
        searchOrder.add(i);
      }
    }

    for (int i in searchOrder) {
      final mapa = setor.mapas[i];
      
      Mapa_Referencia? matchingRef;
      for (final ref in mapa.referencias) {
        if (ref.escalada == escaladaNome) {
          matchingRef = ref;
          break;
        }
      }

      if (matchingRef != null && matchingRef.ids.isNotEmpty) {
        List<String> labels = [];
        for (var id in matchingRef.ids) {
          for (var p in mapa.pontosDeInteresse) {
            if (p.id == id) {
              if (p.label.isNotEmpty) {
                labels.add(p.label);
              } else {
                labels.add(id); // Fallback to id if label is empty but requested
              }
              break;
            }
          }
        }
        resolvedLabel = labels.join('-');
        if (setor.mapas.length > 1) {
          mapIndicator = 'M${i + 1}'; 
        }
        break;
      }
    }
  }

  return {
    'mapIndicator': mapIndicator,
    'resolvedLabel': resolvedLabel,
  };
}

/// Constrói um tile interativo para uma única via de escalada.
///
/// Ele determina o tipo da via para buscar o nome e grau apropriados,
/// e configura um botão de toque para navegar para a [ViaPage].
Widget _buildRouteTile(BuildContext context, Escalada escalada, String cragId, Setor setor, {bool isTarget = false}) {
  String nome = '';
  String info = '';
  bool destaque = false;

  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      nome = escalada.viaEsportiva.nome;
      info = 'Esportiva | ${getGrauString(escalada)}';
      destaque = escalada.viaEsportiva.destaque;
      break;
    case Escalada_Tipo.viaMovel:
      nome = escalada.viaMovel.nome;
      info = 'Móvel | ${getGrauString(escalada)}';
      destaque = escalada.viaMovel.destaque;
      break;
    case Escalada_Tipo.boulder:
      nome = escalada.boulder.nome;
      info = 'Boulder | ${getGrauString(escalada)}';
      destaque = escalada.boulder.destaque;
      break;
    case Escalada_Tipo.viaMultiplasEnfiadas:
      nome = escalada.viaMultiplasEnfiadas.nome;
      info = 'Multipitch | ${getGrauString(escalada)}';
      destaque = escalada.viaMultiplasEnfiadas.destaque;
      break;
    case Escalada_Tipo.highline:
      nome = escalada.highline.nome;
      info = 'Highline | ${escalada.highline.distancia}m';
      destaque = escalada.highline.destaque;
      break;
    case Escalada_Tipo.notSet:
      nome = 'Sem Nome';
      break;
  }

  final labels = resolveRouteLabels(escalada, setor);
  final mapIndicator = labels['mapIndicator']!;
  final resolvedLabel = labels['resolvedLabel']!;

  Widget card = Stack(
    clipBehavior: Clip.none,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: beastHide.withValues(alpha: 0.2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
          leading: resolvedLabel.isNotEmpty 
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 40, maxWidth: 60),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: nobleBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: beastHide.withValues(alpha: 0.5)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (mapIndicator.isNotEmpty)
                          Text(
                            mapIndicator,
                            style: TextStyle(
                              color: fishBone.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          resolvedLabel,
                          style: TextStyle(
                            color: fishBone, 
                            fontWeight: FontWeight.bold,
                            fontSize: resolvedLabel.length > 3 ? 12 : 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Icon(Icons.terrain_outlined, color: beastHide),
          title: Text(nome, style: TextStyle(color: fishBone, fontSize: 16)),
          subtitle: Text(info, style: TextStyle(color: fishBone.withValues(alpha: 0.6), fontSize: 12)),
          trailing: Icon(Icons.chevron_right, color: beastHide),
          onTap: () {
            TelemetryService.instance.logAcaoEscalada(
              cragId,
              setor.nome,
              nome,
              'abrir_detalhes',
              'lista_setor'
            );
            AppNav.toVia(context, escalada: escalada, setor: setor);
          },
        ),
      )),
      if (destaque)
        Positioned(
          top: -6,
          left: -6,
          child: Container(
            decoration: BoxDecoration(
              color: nobleBlack,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.star, color: Colors.amber, size: 20),
          ),
        ),
    ],
  );

  if (isTarget) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2500), // 1000ms scroll delay + 1500ms fade
      builder: (context, value, child) {
        Color color;
        // 1000ms / 2500ms = 0.40
        if (value < 0.40) {
          color = Colors.transparent;
        } else {
          double fadeProgress = (value - 0.40) / 0.60;
          color = Colors.amber.withValues(alpha: 0.3 * (1.0 - fadeProgress));
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child!,
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 10, // Match the margin bottom of the card
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: card,
    );
  }

  return card;
}

enum EscaladaSortMode { original, alphaAsc, alphaDesc, gradeAsc, gradeDesc }
