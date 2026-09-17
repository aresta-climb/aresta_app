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
import '../utils/resolvedor_rotulos_referencia.dart';

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

  /// Suporte a indexação por chave para compatibilidade retroativa.
  dynamic operator [](String key) {
    if (key == 'mapIndicator') return mapIndicator;
    if (key == 'resolvedLabel') return resolvedLabel;
    return null;
  }
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
      final resolvedLabel = extrairRotuloReferencia(mapa, referencia);
      final mapIndicator = setor.mapas.length > 1 ? 'M${i + 1}' : '';
      return RotulosVia(
        mapIndicator: mapIndicator,
        resolvedLabel: resolvedLabel,
      );
    }
  }

  return const RotulosVia(mapIndicator: '', resolvedLabel: '');
}

/// Extrai nome, informação de modalidade/grau e status de destaque da via.
(String nome, String info, bool destaque) _extrairInfoEscalada(Escalada escalada) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return (
        escalada.viaEsportiva.nome,
        'Esportiva | ${getGrauString(escalada)}',
        escalada.viaEsportiva.destaque,
      );
    case Escalada_Tipo.viaMovel:
      return (
        escalada.viaMovel.nome,
        'Móvel | ${getGrauString(escalada)}',
        escalada.viaMovel.destaque,
      );
    case Escalada_Tipo.boulder:
      return (
        escalada.boulder.nome,
        'Boulder | ${getGrauString(escalada)}',
        escalada.boulder.destaque,
      );
    case Escalada_Tipo.viaMultiplasEnfiadas:
      return (
        escalada.viaMultiplasEnfiadas.nome,
        'Multipitch | ${getGrauString(escalada)}',
        escalada.viaMultiplasEnfiadas.destaque,
      );
    case Escalada_Tipo.highline:
      return (
        escalada.highline.nome,
        'Highline | ${escalada.highline.distancia}m',
        escalada.highline.destaque,
      );
    case Escalada_Tipo.notSet:
      return ('Sem Nome', '', false);
  }
}

/// Constrói o badge indicador visual com número do mapa e rótulo da via.
Widget _buildBadgeRotulos(BuildContext context, RotulosVia rotulos) {
  if (rotulos.resolvedLabel.isEmpty) {
    return Icon(Icons.terrain_outlined, color: beastHide);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    constraints: const BoxConstraints(minWidth: 40, maxWidth: 60),
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.colors.deepBasalt,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: beastHide.withValues(alpha: 0.5)),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (rotulos.mapIndicator.isNotEmpty)
            Text(
              rotulos.mapIndicator,
              style: TextStyle(
                color: fishBone.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            rotulos.resolvedLabel,
            style: TextStyle(
              color: fishBone,
              fontWeight: FontWeight.bold,
              fontSize: rotulos.resolvedLabel.length > 3 ? 12 : 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

/// Constrói o selo de estrela para vias em destaque.
Widget _buildIconeDestaque(BuildContext context) {
  return Positioned(
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
  );
}

/// Animação de realce suave quando a via é o alvo direto de busca ou navegação.
Widget _buildEfeitoRealceAlvo({required Widget child, required bool isTarget}) {
  if (!isTarget) return child;

  return TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0.0, end: 1.0),
    duration: const Duration(milliseconds: 2500),
    builder: (context, value, childWidget) {
      final double fadeProgress = value < 0.40 ? 0.0 : (value - 0.40) / 0.60;
      final Color color = value < 0.40
          ? Colors.transparent
          : AppColors.brandColor.withValues(alpha: 0.3 * (1.0 - fadeProgress));

      return Stack(
        clipBehavior: Clip.none,
        children: [
          childWidget!,
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 10,
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
    child: child,
  );
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
  final (nome, info, destaque) = _extrairInfoEscalada(escalada);
  final rotulos = resolveRouteLabels(escalada, setor);

  final card = Stack(
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
            leading: _buildBadgeRotulos(context, rotulos),
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
      if (destaque) _buildIconeDestaque(context),
    ],
  );

  return _buildEfeitoRealceAlvo(child: card, isTarget: isTarget);
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
