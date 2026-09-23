// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'nav_node.dart';

/// Nó que representa a tela de detalhes e hub de um Pico específico (PicoView).
class PicoNode extends PicoContextNode {
  final bool scrollToMapaGeral;
  final String? returnToSetorNome;

  const PicoNode({
    required super.cragId,
    this.scrollToMapaGeral = false,
    this.returnToSetorNome,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(covariant PicoNode matchingAncestor) {
    return PicoNode(
      cragId: cragId,
      scrollToMapaGeral: scrollToMapaGeral,
      returnToSetorNome: returnToSetorNome,
      parent: matchingAncestor.parent,
    );
  }

  @override
  String get rotuloAmigavel => 'Pico ($cragId)';

  @override
  String obterCaminhoCurto() => 'Início -> Pico ($cragId)';

  @override
  String toString() => 'PicoNode($cragId)';
}

/// Nó que representa a listagem de todos os setores de um pico.
class SetoresNode extends PicoContextNode {
  const SetoresNode({
    required super.cragId,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(covariant SetoresNode matchingAncestor) =>
      SetoresNode(cragId: cragId, parent: matchingAncestor.parent);

  @override
  String get rotuloAmigavel => 'Setores';

  @override
  String obterCaminhoCurto() => 'Início -> Pico ($cragId) -> Setores';

  @override
  String toString() => 'SetoresNode';
}

/// Nó que representa o índice e catálogo de todas as escaladas de um pico.
class IndiceEscaladasNode extends PicoContextNode {
  const IndiceEscaladasNode({
    required super.cragId,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(covariant IndiceEscaladasNode matchingAncestor) =>
      IndiceEscaladasNode(cragId: cragId, parent: matchingAncestor.parent);

  @override
  String get rotuloAmigavel => 'Índice de Escaladas';

  @override
  String obterCaminhoCurto() => 'Início -> Pico ($cragId) -> Índice de Escaladas';

  @override
  String toString() => 'IndiceEscaladasNode';
}

/// Nó que representa a tela de detalhes de um Setor específico dentro de um Pico (SetorView).
class SetorNode extends PicoContextNode {
  final String setorNome;
  final String? grupoNome;
  final String? scrollToEscaladaNome;

  const SetorNode({
    required this.setorNome,
    this.grupoNome,
    this.scrollToEscaladaNome,
    required super.cragId,
    required NavNode parent,
  }) : super(parent: parent);

  @override
  bool isSameNode(NavNode other) {
    if (other is! SetorNode) return false;
    return cragId == other.cragId &&
        setorNome == other.setorNome &&
        grupoNome == other.grupoNome;
  }

  @override
  NavNode copyWithMergedAncestor(covariant SetorNode matchingAncestor) {
    final hasScroll = scrollToEscaladaNome != null;
    return SetorNode(
      setorNome: setorNome,
      grupoNome: grupoNome ?? matchingAncestor.grupoNome,
      scrollToEscaladaNome: hasScroll
          ? scrollToEscaladaNome
          : matchingAncestor.scrollToEscaladaNome,
      cragId: cragId,
      parent: matchingAncestor.parent!,
    );
  }

  @override
  String get rotuloAmigavel => 'Setor ($setorNome)';

  @override
  String obterCaminhoCurto() {
    if (grupoNome != null && grupoNome!.isNotEmpty) {
      return 'Início -> Pico ($cragId) -> Grupo ($grupoNome) -> Setor ($setorNome)';
    }
    return 'Início -> Pico ($cragId) -> Setor ($setorNome)';
  }

  /// Retorna uma representação em string deste nó utilizada como chave base para o Navigator.
  @override
  String toString() => 'SetorNode($cragId, $setorNome, $grupoNome)';
}

/// Nó que representa a visualização de um Grupo de setores.
class GrupoNode extends PicoContextNode {
  final String grupoNome;

  const GrupoNode({
    required this.grupoNome,
    required super.cragId,
    required NavNode parent,
  }) : super(parent: parent);

  @override
  bool isSameNode(NavNode other) {
    if (other is! GrupoNode) return false;
    return cragId == other.cragId && grupoNome == other.grupoNome;
  }

  @override
  NavNode copyWithMergedAncestor(covariant GrupoNode matchingAncestor) {
    return GrupoNode(
      grupoNome: grupoNome,
      cragId: cragId,
      parent: matchingAncestor.parent!,
    );
  }

  @override
  String get rotuloAmigavel => 'Grupo ($grupoNome)';

  @override
  String obterCaminhoCurto() => 'Início -> Pico ($cragId) -> Grupo ($grupoNome)';

  @override
  String toString() => 'GrupoNode($cragId, $grupoNome)';
}

/// Nó que representa a tela de visualização de uma Via específica de escalada (ViaView).
class ViaNode extends PicoContextNode {
  final String escaladaNome;
  final String? setorNome;
  final String? grupoNome;

  const ViaNode({
    required this.escaladaNome,
    this.setorNome,
    this.grupoNome,
    required super.cragId,
    required NavNode parent,
  }) : super(parent: parent);

  @override
  bool isSameNode(NavNode other) {
    if (other is! ViaNode) return false;
    return cragId == other.cragId &&
        escaladaNome == other.escaladaNome &&
        setorNome == other.setorNome &&
        grupoNome == other.grupoNome;
  }

  @override
  NavNode copyWithMergedAncestor(covariant ViaNode matchingAncestor) {
    return ViaNode(
      escaladaNome: escaladaNome,
      setorNome: setorNome,
      grupoNome: grupoNome,
      cragId: cragId,
      parent: matchingAncestor.parent!,
    );
  }

  @override
  String get rotuloAmigavel => 'Via ($escaladaNome)';

  @override
  String obterCaminhoCurto() {
    if (setorNome != null && grupoNome != null && grupoNome!.isNotEmpty) {
      return 'Início -> Pico ($cragId) -> Grupo ($grupoNome) -> Setor ($setorNome) -> Via ($escaladaNome)';
    } else if (setorNome != null && setorNome!.isNotEmpty) {
      return 'Início -> Pico ($cragId) -> Setor ($setorNome) -> Via ($escaladaNome)';
    }
    return 'Início -> Pico ($cragId) -> Via ($escaladaNome)';
  }

  @override
  String toString() =>
      'ViaNode($cragId, $setorNome, $grupoNome, $escaladaNome)';
}

/// Nó que representa a página de exploração do local (como chegar, clima, etc.).
class ExplorarLocalNode extends PicoContextNode {
  const ExplorarLocalNode({
    required super.cragId,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(
    covariant ExplorarLocalNode matchingAncestor,
  ) => ExplorarLocalNode(cragId: cragId, parent: matchingAncestor.parent);

  @override
  String get rotuloAmigavel => 'Explorar Local';

  @override
  String obterCaminhoCurto() => 'Início -> Pico ($cragId) -> Explorar Local';

  @override
  String toString() => 'ExplorarLocalNode';
}

/// Nó que representa a comunidade e informações locais do pico.
class ComunidadePicoNode extends PicoContextNode {
  const ComunidadePicoNode({
    required super.cragId,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(
    covariant ComunidadePicoNode matchingAncestor,
  ) => ComunidadePicoNode(cragId: cragId, parent: matchingAncestor.parent);

  @override
  String get rotuloAmigavel => 'Comunidade';

  @override
  String obterCaminhoCurto() => 'Início -> Pico ($cragId) -> Comunidade';

  @override
  String toString() => 'ComunidadePicoNode';
}

/// Nó que representa a página de apoio e contribuição para o pico.
class ApoiePicoNode extends PicoContextNode {
  const ApoiePicoNode({
    required super.cragId,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(covariant ApoiePicoNode matchingAncestor) =>
      ApoiePicoNode(cragId: cragId, parent: matchingAncestor.parent);

  @override
  String get rotuloAmigavel => 'Apoie';

  @override
  String obterCaminhoCurto() => 'Início -> Pico ($cragId) -> Apoie';

  @override
  String toString() => 'ApoiePicoNode';
}

/// Nó que representa a tela de rotas de GPS e localização do pico.
class GPSNode extends PicoContextNode {
  const GPSNode({
    required super.cragId,
    required NavNode parent,
  }) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant GPSNode matchingAncestor) {
    return GPSNode(cragId: cragId, parent: matchingAncestor.parent!);
  }

  @override
  String get rotuloAmigavel => 'GPS';

  @override
  String obterCaminhoCurto() => 'Início -> Pico ($cragId) -> GPS';

  @override
  String toString() => 'GPSNode($cragId)';
}
