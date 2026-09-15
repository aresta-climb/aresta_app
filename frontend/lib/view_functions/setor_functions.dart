// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import 'common_functions.dart';
import 'offline_markdown.dart';
import 'via_functions.dart';
import '../widgets/mapa_thumbnail.dart';
import '../theme/app_colors.dart';
import '../navigation/navigation_functions.dart';
import '../services/firebase/telemetry_service.dart';

/// Constrói o corpo rolável principal da página do Setor.
///
/// Ele extrai a descrição e itera por todas as vias disponíveis
/// ([Escalada]) e subsetores aninhados para renderizá-los.
Widget buildSetorBody(
  BuildContext context,
  Setor setor,
  String cragId,
  List<Escalada> sortedEscaladas, [
  Escalada? scrollToEscalada,
  GlobalKey? targetKey,
  Widget? sortButton,
  Grupo? grupoContext,
]) {
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
          (() {
            final validMapas = setor.mapas.where((m) => m.caminhoImagemMapa.isNotEmpty && m.larguraMapa > 0 && m.alturaMapa > 0).toList();
            if (validMapas.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: validMapas.first.larguraMapa / validMapas.first.alturaMapa,
                    child: MapaThumbnail(
                      mapas: validMapas,
                      cragId: cragId,
                      setorContext: setor,
                      grupoContext: grupoContext,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          })(),
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
                  children: [_buildHeader(headerText)],
                ),
                if (sortButton != null) ...[
                  sortButton,
                  const SizedBox(height: 16),
                ],
                if (sortedEscaladas.isEmpty)
                  Text(emptyText, style: TextStyle(color: fishBone))
                else ...[
                  ...sortedEscaladas.map((escalada) {
                    final bool isTarget =
                        (scrollToEscalada != null &&
                        targetKey != null &&
                        escalada == scrollToEscalada);
                    final tile = _buildRouteTile(
                      context,
                      escalada,
                      cragId,
                      setor,
                      isTarget: isTarget,
                    );
                    if (isTarget) {
                      return KeyedSubtree(key: targetKey, child: tile);
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

/// Rótulos resolvidos para uma via de escalada em relação ao mapa do setor.
class RotulosVia {
  final String mapIndicator;
  final String resolvedLabel;

  const RotulosVia({
    required this.mapIndicator,
    required this.resolvedLabel,
  });
}

/// Extrai o nome da via e o índice do mapa padrão a partir da [Escalada].
(String nome, int indiceMapaPadrao) _extrairNomeEIndiceMapa(Escalada escalada) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return (escalada.viaEsportiva.nome, escalada.viaEsportiva.indiceMapaPadrao);
    case Escalada_Tipo.viaMovel:
      return (escalada.viaMovel.nome, escalada.viaMovel.indiceMapaPadrao);
    case Escalada_Tipo.boulder:
      return (escalada.boulder.nome, escalada.boulder.indiceMapaPadrao);
    case Escalada_Tipo.viaMultiplasEnfiadas:
      return (escalada.viaMultiplasEnfiadas.nome, escalada.viaMultiplasEnfiadas.indiceMapaPadrao);
    case Escalada_Tipo.highline:
      return (escalada.highline.nome, escalada.highline.indiceMapaPadrao);
    default:
      return ('', 0);
  }
}

/// Calcula a ordem de busca nos mapas priorizando o índice padrão configurado.
List<int> _calcularOrdemBuscaMapas(int indicePadrao, int totalMapas) {
  final List<int> ordem = [];
  if (indicePadrao >= 0 && indicePadrao < totalMapas) {
    ordem.add(indicePadrao);
  }
  for (int i = 0; i < totalMapas; i++) {
    if (!ordem.contains(i)) {
      ordem.add(i);
    }
  }
  return ordem;
}

/// Localiza a primeira referência associada ao nome da escalada no mapa.
Mapa_Referencia? _buscarReferenciaNoMapa(Mapa mapa, String escaladaNome) {
  for (final ref in mapa.referencias) {
    if (ref.escalada == escaladaNome) {
      return ref;
    }
  }
  return null;
}

/// Extrai os rótulos visuais dos pontos de interesse correspondentes aos IDs.
List<String> _extrairRotulosDosPontos(Mapa mapa, List<String> ids) {
  final List<String> rotulos = [];
  for (final id in ids) {
    for (final ponto in mapa.pontosDeInteresse) {
      if (ponto.id == id) {
        rotulos.add(ponto.label.isNotEmpty ? ponto.label : id);
        break;
      }
    }
  }
  return rotulos;
}

/// Resolve o indicador do mapa e os rótulos concatenados para uma dada Escalada.
RotulosVia resolveRouteLabels(Escalada escalada, Setor setor) {
  if (setor.mapas.isEmpty) {
    return const RotulosVia(mapIndicator: '', resolvedLabel: '');
  }

  final (nome, indicePadrao) = _extrairNomeEIndiceMapa(escalada);
  final ordem = _calcularOrdemBuscaMapas(indicePadrao, setor.mapas.length);

  for (final i in ordem) {
    final mapa = setor.mapas[i];
    final referencia = _buscarReferenciaNoMapa(mapa, nome);

    if (referencia != null && referencia.ids.isNotEmpty) {
      final rotulos = _extrairRotulosDosPontos(mapa, referencia.ids);
      final mapIndicator = setor.mapas.length > 1 ? 'M${i + 1}' : '';
      return RotulosVia(
        mapIndicator: mapIndicator,
        resolvedLabel: rotulos.join('-'),
      );
    }
  }

  return const RotulosVia(mapIndicator: '', resolvedLabel: '');
}

/// Constrói um tile interativo para uma única via de escalada.
///
/// Ele determina o tipo da via para buscar o nome e grau apropriados,
/// e configura um botão de toque para navegar para a [ViaPage].
Widget _buildRouteTile(
  BuildContext context,
  Escalada escalada,
  String cragId,
  Setor setor, {
  bool isTarget = false,
}) {
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

  final rotulos = resolveRouteLabels(escalada, setor);
  final mapIndicator = rotulos.mapIndicator;
  final resolvedLabel = rotulos.resolvedLabel;

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
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      maxWidth: 60,
                    ),
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colors.deepBasalt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: beastHide.withValues(alpha: 0.5),
                      ),
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
            subtitle: Text(
              info,
              style: TextStyle(
                color: fishBone.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: beastHide),
            onTap: () {
              TelemetryService.instance.logAcaoEscalada(
                cragId,
                setor.nome,
                nome,
                'abrir_detalhes',
                'lista_setor',
              );
              AppNav.toVia(context, escalada: escalada, setor: setor);
            },
          ),
        ),
      ),
      if (destaque)
        Positioned(
          top: -6,
          left: -6,
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.deepBasalt,
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
      duration: const Duration(
        milliseconds: 2500,
      ), // 1000ms scroll delay + 1500ms fade
      builder: (context, value, child) {
        Color color;
        double fadeProgress = 0.0;
        // 1000ms / 2500ms = 0.40
        if (value < 0.40) {
          color = Colors.transparent;
        } else {
          fadeProgress = (value - 0.40) / 0.60;
          color = AppColors.brandColor.withValues(
            alpha: 0.3 * (1.0 - fadeProgress),
          );
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
                    boxShadow: (color.a * 255.0).round().clamp(0, 255) == 0
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.brandColor.withValues(
                                alpha: 0.6 * (1.0 - fadeProgress),
                              ),
                              blurRadius: 15 * (1.0 - fadeProgress),
                              spreadRadius: 2 * (1.0 - fadeProgress),
                            ),
                          ],
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

enum EscaladaSortMode {
  original,
  alphaAsc,
  alphaDesc,
  gradeAsc,
  gradeDesc,
  protectionsAsc,
  protectionsDesc,
}

Widget buildEscaladaSortGrid(
  BuildContext context,
  EscaladaSortMode currentMode,
  Function(EscaladaSortMode)? onSortChanged,
) {
  return GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 1.6,
    children: [
      _buildEscaladaSortCard(
        context: context,
        label: 'PADRÃO',
        icon: Icons.grid_view_rounded,
        isActive: currentMode == EscaladaSortMode.original,
        onTap: () => onSortChanged?.call(EscaladaSortMode.original),
      ),
      _buildEscaladaSortCard(
        context: context,
        label: 'ALFABÉTICO',
        icon: Icons.sort_by_alpha,
        isActive:
            currentMode == EscaladaSortMode.alphaAsc ||
            currentMode == EscaladaSortMode.alphaDesc,
        onTap: () {
          if (currentMode == EscaladaSortMode.alphaAsc) {
            onSortChanged?.call(EscaladaSortMode.alphaDesc);
          } else {
            onSortChanged?.call(EscaladaSortMode.alphaAsc);
          }
        },
      ),
      _buildEscaladaSortCard(
        context: context,
        label: 'DIFICULDADE',
        icon: Icons.trending_up,
        isActive:
            currentMode == EscaladaSortMode.gradeAsc ||
            currentMode == EscaladaSortMode.gradeDesc,
        onTap: () {
          if (currentMode == EscaladaSortMode.gradeAsc) {
            onSortChanged?.call(EscaladaSortMode.gradeDesc);
          } else {
            onSortChanged?.call(EscaladaSortMode.gradeAsc);
          }
        },
      ),
    ],
  );
}

Widget _buildEscaladaSortCard({
  required BuildContext context,
  required String label,
  required IconData icon,
  required bool isActive,
  required VoidCallback onTap,
}) {
  final Color activeColor = AppColors.brandColor;
  final Color inactiveColor = context.colors.fishBone.withValues(alpha: 0.5);
  final Color bgColor = context.colors.caveShadow;

  return Material(
    color: bgColor,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? activeColor : inactiveColor, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
