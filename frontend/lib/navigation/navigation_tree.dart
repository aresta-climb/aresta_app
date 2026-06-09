import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';

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
}

/// Classe base abstrata para nós que dependem do contexto de um Pico.
abstract class PicoContextNode extends NavNode {
  final Pico pico;
  final Croqui croqui;
  final String cragId;

  const PicoContextNode({
    required this.pico,
    required this.croqui,
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
}

/// Nó que representa a tela de busca de picos novos (BrowseView).
class BrowseNode extends NavNode {
  const BrowseNode(NavNode parent) : super(parent: parent);
  
  @override
  NavNode copyWithMergedAncestor(covariant BrowseNode matchingAncestor) {
    return BrowseNode(matchingAncestor.parent!);
  }
}

/// Nó que representa o mapa global (Mapão Global) acessado a partir da Busca.
class MapaoGlobalNode extends NavNode {
  final List<Map<String, dynamic>> crags;
  final Set<String> downloadingCrags;
  final Function(Map<String, dynamic>) onDownload;
  final Function(Map<String, dynamic>)? onOpen;

  const MapaoGlobalNode({
    required this.crags,
    required this.downloadingCrags,
    required this.onDownload,
    this.onOpen,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(covariant MapaoGlobalNode matchingAncestor) {
    return MapaoGlobalNode(
      crags: crags,
      downloadingCrags: downloadingCrags,
      onDownload: onDownload,
      onOpen: onOpen,
      parent: matchingAncestor.parent,
    );
  }
}

/// Nó que representa a tela de configurações do aplicativo (SettingsView).
class SettingsNode extends NavNode {
  const SettingsNode(NavNode parent) : super(parent: parent);
  
  @override
  NavNode copyWithMergedAncestor(covariant SettingsNode matchingAncestor) {
    return SettingsNode(matchingAncestor.parent!);
  }
}

/// Nó que representa a tela de detalhes de um Pico específico (PicoView).
class PicoNode extends PicoContextNode {
  final bool scrollToMapaGeral;
  final Setor? returnToSetor;

  const PicoNode({
    required super.pico,
    required super.croqui,
    required super.cragId,
    this.scrollToMapaGeral = false,
    this.returnToSetor,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(covariant PicoNode matchingAncestor) {
    return PicoNode(
      pico: pico,
      croqui: croqui,
      cragId: cragId,
      scrollToMapaGeral: scrollToMapaGeral,
      returnToSetor: returnToSetor,
      parent: matchingAncestor.parent,
    );
  }
}

/// Nó que representa a tela de detalhes de um Setor específico dentro de um Pico (SetorView).
class SetorNode extends PicoContextNode {
  final Setor setor;
  final Escalada? scrollToEscalada;

  const SetorNode({
    required this.setor,
    this.scrollToEscalada,
    required super.pico,
    required super.croqui,
    required super.cragId,
    required NavNode parent,
  }) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant SetorNode matchingAncestor) {
    final hasScroll = scrollToEscalada != null;
    return SetorNode(
      setor: setor,
      scrollToEscalada: hasScroll ? scrollToEscalada : matchingAncestor.scrollToEscalada,
      pico: pico,
      croqui: croqui,
      cragId: cragId,
      parent: matchingAncestor.parent!,
    );
  }
}

/// Nó que representa a visualização de um Grupo.
class GrupoNode extends PicoContextNode {
  final Grupo grupo;

  const GrupoNode({
    required this.grupo,
    required super.pico,
    required super.croqui,
    required super.cragId,
    required NavNode parent,
  }) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant GrupoNode matchingAncestor) {
    return GrupoNode(
      grupo: grupo,
      pico: pico,
      croqui: croqui,
      cragId: cragId,
      parent: matchingAncestor.parent!,
    );
  }
}

/// Nó que representa a tela de visualização de uma Via específica de escalada (ViaView).
class ViaNode extends PicoContextNode {
  final Escalada escalada;
  final Setor? setor;

  const ViaNode({
    required this.escalada,
    this.setor,
    required super.pico,
    required super.croqui,
    required super.cragId,
    required NavNode parent,
  }) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant ViaNode matchingAncestor) {
    return ViaNode(
      escalada: escalada,
      setor: setor,
      pico: pico,
      croqui: croqui,
      cragId: cragId,
      parent: matchingAncestor.parent!,
    );
  }
}

/// Nó que representa o mapa interativo de um setor.
class MapaInterativoNode extends NavNode {
  final Mapa mapa;
  final String cragId;
  final List<Escalada> escaladas;
  final List<ArquivoSetor> setores;
  final String? initialSelectedId;
  final Setor? setorContext;
  final ImageProvider? imageProviderOverride;

  const MapaInterativoNode({
    required this.mapa,
    required this.cragId,
    required this.escaladas,
    required this.setores,
    this.initialSelectedId,
    this.setorContext,
    this.imageProviderOverride,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(covariant MapaInterativoNode matchingAncestor) {
    final hasInitialId = initialSelectedId != null;
    return MapaInterativoNode(
      mapa: mapa,
      cragId: cragId,
      escaladas: escaladas,
      setores: setores,
      initialSelectedId: hasInitialId ? initialSelectedId : matchingAncestor.initialSelectedId,
      setorContext: setorContext,
      imageProviderOverride: imageProviderOverride ?? matchingAncestor.imageProviderOverride,
      parent: matchingAncestor.parent!,
    );
  }
}

/// Nó que representa o mapa geral do pico.
class MapaGeralPicoNode extends PicoContextNode {
  final Setor? returnToSetor;

  const MapaGeralPicoNode({
    required super.pico,
    required super.croqui,
    required super.cragId,
    this.returnToSetor,
    required super.parent,
  });

  @override
  NavNode copyWithMergedAncestor(covariant MapaGeralPicoNode matchingAncestor) {
    return MapaGeralPicoNode(
      pico: pico,
      croqui: croqui,
      cragId: cragId,
      returnToSetor: returnToSetor,
      parent: matchingAncestor.parent!,
    );
  }
}

/// Nó que representa a tela de rotas de GPS/localização.
class GPSNode extends PicoContextNode {
  const GPSNode({
    required super.pico,
    required super.croqui,
    required super.cragId,
    required NavNode parent,
  }) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant GPSNode matchingAncestor) {
    return GPSNode(
      pico: pico,
      croqui: croqui,
      cragId: cragId,
      parent: matchingAncestor.parent!,
    );
  }
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
      return a.cragId == b.cragId && a.mapa == b.mapa && a.setorContext == b.setorContext;
    }
    if (a is MapaGeralPicoNode && b is MapaGeralPicoNode) {
      return a.cragId == b.cragId && a.pico == b.pico;
    }
    if (a is PicoNode && b is PicoNode) {
      return a.cragId == b.cragId && a.pico == b.pico;
    }
    if (a is SetorNode && b is SetorNode) {
      return a.cragId == b.cragId && a.setor == b.setor;
    }
    if (a is GrupoNode && b is GrupoNode) {
      return a.cragId == b.cragId && a.grupo == b.grupo;
    }
    if (a is ViaNode && b is ViaNode) {
      return a.cragId == b.cragId && a.escalada == b.escalada;
    }
    if (a is GPSNode && b is GPSNode) {
      return a.cragId == b.cragId && a.pico == b.pico;
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
