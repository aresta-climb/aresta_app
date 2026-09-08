// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'nav_node.dart';
import '../../services/dataset/modelos/resumo_pico.dart';

/// O nó raiz da navegação do aplicativo. Representa a tela inicial (HomeView).
class HomeNode extends NavNode {
  const HomeNode() : super(parent: null);

  @override
  NavNode copyWithMergedAncestor(covariant HomeNode matchingAncestor) {
    return const HomeNode();
  }

  @override
  String get rotuloAmigavel => 'Início';

  @override
  String obterCaminhoCurto() => 'Início';

  @override
  String toString() => 'HomeNode';
}

/// Nó que representa a tela de busca e catálogo de picos (BrowseView).
class BrowseNode extends NavNode {
  const BrowseNode(NavNode parent) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant BrowseNode matchingAncestor) {
    return BrowseNode(matchingAncestor.parent!);
  }

  @override
  String get rotuloAmigavel => 'Buscar';

  @override
  String obterCaminhoCurto() => 'Início -> Buscar';

  @override
  String toString() => 'BrowseNode';
}

/// Nó que representa o mapa global acessado a partir da Busca.
class MapaGlobalNode extends NavNode {
  final List<ResumoPico> crags;

  const MapaGlobalNode({
    required this.crags,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(covariant MapaGlobalNode matchingAncestor) {
    return MapaGlobalNode(crags: crags, parent: matchingAncestor.parent);
  }

  @override
  String get rotuloAmigavel => 'Mapa Global';

  @override
  String obterCaminhoCurto() => 'Início -> Mapa Global';

  @override
  String toString() => 'MapaGlobalNode(${crags.length} picos)';
}

/// Nó que representa a tela de configurações gerais do aplicativo (SettingsView).
class SettingsNode extends NavNode {
  const SettingsNode(NavNode parent) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant SettingsNode matchingAncestor) {
    return SettingsNode(matchingAncestor.parent!);
  }

  @override
  String get rotuloAmigavel => 'Configurações';

  @override
  String obterCaminhoCurto() => 'Início -> Configurações';

  @override
  String toString() => 'SettingsNode';
}

/// Nó que representa a tela de comunidade global.
class ComunidadeNode extends NavNode {
  const ComunidadeNode(NavNode parent) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant ComunidadeNode matchingAncestor) {
    return ComunidadeNode(matchingAncestor.parent!);
  }

  @override
  String get rotuloAmigavel => 'Comunidade';

  @override
  String obterCaminhoCurto() => 'Início -> Comunidade';

  @override
  String toString() => 'ComunidadeNode';
}

/// Nó que representa a tela sobre o time de desenvolvimento.
class SobreTimeNode extends NavNode {
  const SobreTimeNode(NavNode parent) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant SobreTimeNode matchingAncestor) {
    return SobreTimeNode(matchingAncestor.parent!);
  }

  @override
  String get rotuloAmigavel => 'Sobre o Time';

  @override
  String obterCaminhoCurto() => 'Início -> Sobre o Time';

  @override
  String toString() => 'SobreTimeNode';
}

/// Nó que representa a tela dos croquis baixados pelo usuário.
class MeusCroquisNode extends NavNode {
  const MeusCroquisNode(NavNode parent) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant MeusCroquisNode matchingAncestor) {
    return MeusCroquisNode(matchingAncestor.parent!);
  }

  @override
  String get rotuloAmigavel => 'Meus Croquis';

  @override
  String obterCaminhoCurto() => 'Início -> Meus Croquis';

  @override
  String toString() => 'MeusCroquisNode';
}
