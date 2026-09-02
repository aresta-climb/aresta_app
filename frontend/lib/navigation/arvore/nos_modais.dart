// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'no_navegacao.dart';

/// Nó que representa um modal textual aberto sobre a página atual.
class TextNode extends NavNode {
  final String title;
  final String content;
  final String cragId;
  final IconData? icon;

  const TextNode({
    required this.title,
    required this.content,
    required this.cragId,
    required NavNode parent,
    this.icon,
  }) : super(parent: parent);

  @override
  bool isSameNode(NavNode other) {
    if (other is! TextNode) return false;
    return title == other.title;
  }

  @override
  NavNode copyWithMergedAncestor(covariant TextNode matchingAncestor) {
    return TextNode(
      title: title,
      content: content,
      cragId: cragId,
      icon: icon,
      parent: matchingAncestor.parent!,
    );
  }

  @override
  String get rotuloAmigavel => 'Texto ($title)';

  @override
  String obterCaminhoCurto() {
    if (parent != null) {
      return '${parent!.obterCaminhoCurto()} -> $rotuloAmigavel';
    }
    return 'Início -> $rotuloAmigavel';
  }

  @override
  String toString() => 'TextNode($title)';
}

/// Dados estruturados para um item dentro de um carrossel textual.
class TextCarouselData {
  final String title;
  final String content;
  final IconData? icon;

  const TextCarouselData({
    required this.title,
    required this.content,
    this.icon,
  });
}

/// Nó que representa um carrossel de páginas/seções textuais.
class TextCarouselNode extends NavNode {
  final String cragId;
  final List<TextCarouselData> texts;
  final int initialIndex;

  const TextCarouselNode({
    required this.cragId,
    required this.texts,
    this.initialIndex = 0,
    required super.parent,
  });

  @override
  bool isSameNode(NavNode other) {
    if (other is! TextCarouselNode) return false;
    return cragId == other.cragId &&
        texts.length == other.texts.length &&
        (texts.isNotEmpty ? texts.first.title == other.texts.first.title : true);
  }

  @override
  NavNode copyWithMergedAncestor(covariant TextCarouselNode matchingAncestor) {
    return TextCarouselNode(
      cragId: cragId,
      texts: texts,
      initialIndex: initialIndex,
      parent: matchingAncestor.parent!,
    );
  }

  @override
  String get rotuloAmigavel => 'Textos (${texts.length})';

  @override
  String obterCaminhoCurto() {
    if (parent != null) {
      return '${parent!.obterCaminhoCurto()} -> $rotuloAmigavel';
    }
    return 'Início -> Pico ($cragId) -> $rotuloAmigavel';
  }

  @override
  String toString() =>
      'TextCarouselNode(${texts.map((e) => e.title).join(',')})';
}

/// Dados necessários para renderizar um item de mapa dentro do carrossel.
class CarrosselItemData {
  /// Caminho da imagem (asset ou arquivo local) do mapa/croqui.
  final String mapaCaminhoImagem;

  /// Nome do Setor ao qual este mapa pertence (se houver), usado para resolver SVG aninhado.
  final String? setorContextNome;

  /// Nome do Grupo ao qual este mapa pertence (se houver), usado para resolver SVG aninhado.
  final String? grupoContextNome;

  /// Nome da via/escalada que motivou a abertura deste mapa.
  final String? escaladaContextNome;

  /// ID opcional (Ponto de Interesse) que deve receber o auto-zoom inicial.
  final String? initialSelectedId;

  const CarrosselItemData({
    required this.mapaCaminhoImagem,
    this.setorContextNome,
    this.grupoContextNome,
    this.escaladaContextNome,
    this.initialSelectedId,
  });
}

/// Nó que representa a tela do Carrossel de Mapas (múltiplos mapas sequenciais).
class MapasCarrosselNode extends NavNode {
  final String cragId;
  final int initialIndex;
  final List<CarrosselItemData> mapas;
  final ImageProvider? imageProviderOverride;

  const MapasCarrosselNode({
    required this.cragId,
    required this.initialIndex,
    required this.mapas,
    this.imageProviderOverride,
    required super.parent,
  });

  @override
  bool isSameNode(NavNode other) {
    if (other is! MapasCarrosselNode) return false;
    return cragId == other.cragId &&
        mapas.length == other.mapas.length &&
        (mapas.isNotEmpty
            ? mapas.first.mapaCaminhoImagem == other.mapas.first.mapaCaminhoImagem
            : true);
  }

  @override
  NavNode copyWithMergedAncestor(
    covariant MapasCarrosselNode matchingAncestor,
  ) {
    return MapasCarrosselNode(
      cragId: cragId,
      initialIndex: initialIndex,
      mapas: mapas,
      imageProviderOverride:
          imageProviderOverride ?? matchingAncestor.imageProviderOverride,
      parent: matchingAncestor.parent!,
    );
  }

  @override
  String get rotuloAmigavel => 'Mapa';

  @override
  String obterCaminhoCurto() {
    if (parent != null) {
      return '${parent!.obterCaminhoCurto()} -> Mapa';
    }
    return 'Início -> Pico ($cragId) -> Mapa';
  }

  @override
  String toString() =>
      'MapasCarrosselNode(${mapas.map((m) => m.mapaCaminhoImagem.split('/').last).join(',')})';
}
