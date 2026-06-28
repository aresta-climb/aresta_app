import 'package:flutter/material.dart';

/// Definições dos nós de navegação e o controlador do estado de navegação.
///
/// Este arquivo define o sistema de navegação baseado em árvore (Tree Navigation) do aplicativo.
/// Ele evita o problema de empilhamento infinito de páginas idênticas (por exemplo, transições repetidas
/// entre mapas e vias) que ocorre ao usar o Navigator clássico em pilha.
///
/// Cada página principal ou estado de visualização do aplicativo é representado por um [NavNode],
/// que carrega as dependências necessárias (como o pico, croqui ou cragId) e mantém uma referência
/// apontando para o seu nó pai (`parent`). Isso permite que o aplicativo saiba exatamente o caminho
/// de volta correto, independentemente dos atalhos que o usuário tome na interface.

// --- DEFINIÇÕES DOS NÓS ---

/// Classe base abstrata para todos os nós da árvore de navegação.
///
/// Cada nó possui uma referência opcional para o seu [parent] (nó pai).
/// A raiz da árvore (geralmente [HomeNode]) tem `parent` nulo.
abstract class NavNode {
  /// O nó pai na hierarquia de navegação. É nulo apenas para a raiz da árvore.
  final NavNode? parent;
  const NavNode({this.parent});

  /// Cria uma cópia deste nó, anexando-o ao pai do ancestral correspondente.
  /// Subclasses devem sobrescrever isso para mesclar estado da interface (como alvos de rolagem).
  NavNode copyWithMergedAncestor(covariant NavNode matchingAncestor) {
    return this; 
  }

  /// Retorna a lista de nós desde a raiz até este nó.
  List<NavNode> get path {
    final List<NavNode> p = [];
    NavNode? current = this;
    while (current != null) {
      p.add(current);
      current = current.parent;
    }
    return p.reversed.toList();
  }
}

/// Classe base abstrata para nós que dependem do contexto de um Pico.
abstract class PicoContextNode extends NavNode {
  final String cragId;

  const PicoContextNode({
    required this.cragId,
    super.parent,
  });
}

/// O nó raiz da navegação do aplicativo. Representa a tela inicial (HomeView).
class HomeNode extends NavNode {
  const HomeNode() : super(parent: null);
  
  @override
  NavNode copyWithMergedAncestor(covariant HomeNode matchingAncestor) {
    return const HomeNode();
  }

  @override
  String toString() => 'HomeNode';
}

/// Nó que representa a tela de busca de picos novos (BrowseView).
class BrowseNode extends NavNode {
  const BrowseNode(NavNode parent) : super(parent: parent);
  
  @override
  NavNode copyWithMergedAncestor(covariant BrowseNode matchingAncestor) {
    return BrowseNode(matchingAncestor.parent!);
  }

  @override
  String toString() => 'BrowseNode';
}

/// Nó que representa o mapa global (Mapão Global) acessado a partir da Busca.
class MapaoGlobalNode extends NavNode {
  final List<Map<String, dynamic>> crags;

  const MapaoGlobalNode({
    required this.crags,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(covariant MapaoGlobalNode matchingAncestor) {
    return MapaoGlobalNode(
      crags: crags,
      parent: matchingAncestor.parent,
    );
  }

  @override
  String toString() => 'MapaoGlobalNode(${crags.length} picos)';
}

/// Nó que representa a tela de configurações do aplicativo (SettingsView).
class SettingsNode extends NavNode {
  const SettingsNode(NavNode parent) : super(parent: parent);
  
  @override
  NavNode copyWithMergedAncestor(covariant SettingsNode matchingAncestor) {
    return SettingsNode(matchingAncestor.parent!);
  }

  @override
  String toString() => 'SettingsNode';
}

/// Nó que representa a tela de detalhes de um Pico específico (PicoView).
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
  String toString() => 'PicoNode($cragId)';
}

/// Nó que representa a tela de detalhes de um Setor específico dentro de um Pico (SetorView).
class SetorNode extends PicoContextNode {
  final String setorNome;
  final String? scrollToEscaladaNome;

  const SetorNode({
    required this.setorNome,
    this.scrollToEscaladaNome,
    required super.cragId,
    required NavNode parent,
  }) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant SetorNode matchingAncestor) {
    final hasScroll = scrollToEscaladaNome != null;
    return SetorNode(
      setorNome: setorNome,
      scrollToEscaladaNome: hasScroll ? scrollToEscaladaNome : matchingAncestor.scrollToEscaladaNome,
      cragId: cragId,
      parent: matchingAncestor.parent!,
    );
  }

  @override
  String toString() => 'SetorNode($setorNome)';
}

/// Nó que representa a visualização de um Grupo.
class GrupoNode extends PicoContextNode {
  final String grupoNome;

  const GrupoNode({
    required this.grupoNome,
    required super.cragId,
    required NavNode parent,
  }) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant GrupoNode matchingAncestor) {
    return GrupoNode(
      grupoNome: grupoNome,
      cragId: cragId,
      parent: matchingAncestor.parent!,
    );
  }

  @override
  String toString() => 'GrupoNode($grupoNome)';
}

/// Nó que representa a tela de visualização de uma Via específica de escalada (ViaView).
class ViaNode extends PicoContextNode {
  final String escaladaNome;
  final String? setorNome;

  const ViaNode({
    required this.escaladaNome,
    this.setorNome,
    required super.cragId,
    required NavNode parent,
  }) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant ViaNode matchingAncestor) {
    return ViaNode(
      escaladaNome: escaladaNome,
      setorNome: setorNome,
      cragId: cragId,
      parent: matchingAncestor.parent!,
    );
  }

  @override
  String toString() => 'ViaNode($escaladaNome)';
}

/// Nó que representa o mapa interativo de um setor.
class MapaInterativoNode extends NavNode {
  final String cragId;
  final String mapaCaminhoImagem;
  final String? setorContextNome;
  final String? grupoContextNome;
  final String? initialSelectedId;
  final ImageProvider? imageProviderOverride;

  const MapaInterativoNode({
    required this.cragId,
    required this.mapaCaminhoImagem,
    this.setorContextNome,
    this.grupoContextNome,
    this.initialSelectedId,
    this.imageProviderOverride,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(covariant MapaInterativoNode matchingAncestor) {
    final hasInitialId = initialSelectedId != null;
    return MapaInterativoNode(
      cragId: cragId,
      mapaCaminhoImagem: mapaCaminhoImagem,
      setorContextNome: setorContextNome,
      grupoContextNome: grupoContextNome,
      initialSelectedId: hasInitialId ? initialSelectedId : matchingAncestor.initialSelectedId,
      imageProviderOverride: imageProviderOverride ?? matchingAncestor.imageProviderOverride,
      parent: matchingAncestor.parent!,
    );
  }

  @override
  String toString() => 'MapaInterativoNode(${mapaCaminhoImagem.split('/').last})';
}

/// Nó que representa o mapa geral do pico.
class MapaGeralPicoNode extends PicoContextNode {
  final String? returnToSetorNome;

  const MapaGeralPicoNode({
    required super.cragId,
    this.returnToSetorNome,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(covariant MapaGeralPicoNode matchingAncestor) {
    return MapaGeralPicoNode(
      cragId: cragId,
      returnToSetorNome: returnToSetorNome,
      parent: matchingAncestor.parent!,
    );
  }

  @override
  String toString() => 'MapaGeralPicoNode($cragId)';
}

/// Nó que representa a tela de rotas de GPS/localização.
class GPSNode extends PicoContextNode {
  const GPSNode({
    required super.cragId,
    required NavNode parent,
  }) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant GPSNode matchingAncestor) {
    return GPSNode(
      cragId: cragId,
      parent: matchingAncestor.parent!,
    );
  }

  @override
  String toString() => 'GPSNode($cragId)';
}

// --- NÓS MODAIS ---

/// Nó que representa um modal textual aberto sobre a página atual.
/// A página renderizada será a do nó pai.
class TextNode extends NavNode {
  final String title;
  final String content;
  final String cragId;

  const TextNode({
    required this.title,
    required this.content,
    required this.cragId,
    required NavNode parent,
  }) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant TextNode matchingAncestor) {
    return TextNode(
      title: title,
      content: content,
      cragId: cragId,
      parent: matchingAncestor.parent!,
    );
  }

  @override
  String toString() => 'TextNode($title)';
}

// --- CONTROLADOR ---

/// Controlador de estado de navegação que gerencia a árvore de nós.
class TreeNavigationController extends ChangeNotifier {
  NavNode _currentNode = const HomeNode();

  NavNode get currentNode => _currentNode;

  bool _isSameNode(NavNode a, NavNode b) {
    if (a.runtimeType != b.runtimeType) return false;
    if (a is HomeNode && b is HomeNode) return true;
    if (a is BrowseNode && b is BrowseNode) return true;
    if (a is MapaoGlobalNode && b is MapaoGlobalNode) return true;
    if (a is SettingsNode && b is SettingsNode) return true;
    if (a is MapaInterativoNode && b is MapaInterativoNode) {
      return a.cragId == b.cragId && a.setorContextNome == b.setorContextNome;
    }
    if (a is MapaGeralPicoNode && b is MapaGeralPicoNode) {
      return a.cragId == b.cragId;
    }
    if (a is PicoNode && b is PicoNode) {
      return a.cragId == b.cragId;
    }
    if (a is SetorNode && b is SetorNode) {
      return a.cragId == b.cragId && a.setorNome == b.setorNome;
    }
    if (a is GrupoNode && b is GrupoNode) {
      return a.cragId == b.cragId && a.grupoNome == b.grupoNome;
    }
    if (a is ViaNode && b is ViaNode) {
      return a.cragId == b.cragId && a.escaladaNome == b.escaladaNome;
    }
    if (a is GPSNode && b is GPSNode) {
      return a.cragId == b.cragId;
    }
    if (a is TextNode && b is TextNode) {
      return a.title == b.title;
    }
    return false;
  }

  void navigateTo(NavNode node) {
    NavNode current = _currentNode;
    NavNode? matchingAncestor;

    while (true) {
      if (_isSameNode(current, node)) {
        matchingAncestor = current;
        break;
      }
      final parentNode = current.parent;
      if (parentNode == null) break;
      current = parentNode;
    }

    if (matchingAncestor != null) {
      _currentNode = node.copyWithMergedAncestor(matchingAncestor);
    } else {
      _currentNode = node;
    }
    notifyListeners();
  }

  bool goBack() {
    final parentNode = _currentNode.parent;
    if (parentNode != null) {
      _currentNode = parentNode;
      notifyListeners();
      return true;
    }
    return false;
  }

  void goHome() {
    NavNode node = _currentNode;
    while (true) {
      final parentNode = node.parent;
      if (parentNode == null) break;
      node = parentNode;
    }
    
    if (_currentNode != node) {
      _currentNode = node;
      notifyListeners();
    }
  }
}
