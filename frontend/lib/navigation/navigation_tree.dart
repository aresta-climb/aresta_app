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

  const PicoContextNode({required this.cragId, super.parent});
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

/// Nó que representa o mapa global (Mapa Global) acessado a partir da Busca.
class MapaGlobalNode extends NavNode {
  final List<Map<String, dynamic>> crags;

  const MapaGlobalNode({required this.crags, required super.parent});

  @override
  NavNode copyWithMergedAncestor(covariant MapaGlobalNode matchingAncestor) {
    return MapaGlobalNode(crags: crags, parent: matchingAncestor.parent);
  }

  @override
  String toString() => 'MapaGlobalNode(${crags.length} picos)';
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

class ComunidadeNode extends NavNode {
  const ComunidadeNode(NavNode parent) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant ComunidadeNode matchingAncestor) {
    return ComunidadeNode(matchingAncestor.parent!);
  }

  @override
  String toString() => 'ComunidadeNode';
}

class MeusCroquisNode extends NavNode {
  const MeusCroquisNode(NavNode parent) : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant MeusCroquisNode matchingAncestor) {
    return MeusCroquisNode(matchingAncestor.parent!);
  }

  @override
  String toString() => 'MeusCroquisNode';
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

  /// Retorna uma representação em string deste nó.
  ///
  /// **Importante**: O resultado deste método é utilizado como chave base (`ValueKey`)
  /// para o `MaterialPage` gerado no `Navigator` do Flutter em `main.dart`.
  /// Portanto, a string retornada DEVE refletir perfeitamente todas as variáveis
  /// que determinam a igualdade lógica deste nó em `_isSameNode`.
  /// Se nós estruturalmente distintos gerarem a mesma string, o Flutter lançará
  /// a exceção de chave duplicada (`!keyReservation.contains(key)`).
  @override
  String toString() => 'SetorNode($cragId, $setorNome, $grupoNome)';
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

  /// Retorna uma representação em string deste nó.
  ///
  /// **Importante**: O resultado deste método é utilizado como chave base (`ValueKey`)
  /// para o `MaterialPage` gerado no `Navigator` do Flutter em `main.dart`.
  /// Portanto, a string retornada DEVE refletir perfeitamente todas as variáveis
  /// que determinam a igualdade lógica deste nó em `_isSameNode`.
  /// Se nós estruturalmente distintos gerarem a mesma string, o Flutter lançará
  /// a exceção de chave duplicada (`!keyReservation.contains(key)`).
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
  NavNode copyWithMergedAncestor(covariant ViaNode matchingAncestor) {
    return ViaNode(
      escaladaNome: escaladaNome,
      setorNome: setorNome,
      grupoNome: grupoNome,
      cragId: cragId,
      parent: matchingAncestor.parent!,
    );
  }

  /// Retorna uma representação em string deste nó.
  ///
  /// **Importante**: O resultado deste método é utilizado como chave base (`ValueKey`)
  /// para o `MaterialPage` gerado no `Navigator` do Flutter em `main.dart`.
  /// Portanto, a string retornada DEVE refletir perfeitamente todas as variáveis
  /// que determinam a igualdade lógica deste nó em `_isSameNode`.
  /// Se nós estruturalmente distintos gerarem a mesma string, o Flutter lançará
  /// a exceção de chave duplicada (`!keyReservation.contains(key)`).
  @override
  String toString() =>
      'ViaNode($cragId, $setorNome, $grupoNome, $escaladaNome)';
}

/// Dados necessários para renderizar um item de mapa dentro do carrossel.
class CarrosselItemData {
  /// Caminho da imagem (asset ou arquivo local) do mapa/croqui.
  final String mapaCaminhoImagem;

  /// Nome do Setor ao qual este mapa pertence (se houver), usado para resolver SVG aninhado.
  final String? setorContextNome;

  /// Nome do Grupo ao qual este mapa pertence (se houver), usado para resolver SVG aninhado.
  final String? grupoContextNome;

  /// Nome da via/escalada que motivou a abertura deste mapa, usado para desambiguação de rotas que compartilham o mesmo marcador.
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
  String toString() =>
      'MapasCarrosselNode(${mapas.map((m) => m.mapaCaminhoImagem.split('/').last).join(',')})';
}

/// Nó que representa a tela de rotas de GPS/localização.
class GPSNode extends PicoContextNode {
  const GPSNode({required super.cragId, required NavNode parent})
    : super(parent: parent);

  @override
  NavNode copyWithMergedAncestor(covariant GPSNode matchingAncestor) {
    return GPSNode(cragId: cragId, parent: matchingAncestor.parent!);
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
    if (a is MapaGlobalNode && b is MapaGlobalNode) return true;
    if (a is SettingsNode && b is SettingsNode) return true;
    if (a is ComunidadeNode && b is ComunidadeNode) return true;
    if (a is MeusCroquisNode && b is MeusCroquisNode) return true;
    if (a is MapasCarrosselNode && b is MapasCarrosselNode) {
      return a.cragId == b.cragId &&
          a.mapas.length == b.mapas.length &&
          (a.mapas.isNotEmpty
              ? a.mapas.first.mapaCaminhoImagem ==
                    b.mapas.first.mapaCaminhoImagem
              : true);
    }

    if (a is SetoresNode && b is SetoresNode) return a.cragId == b.cragId;
    if (a is ExplorarLocalNode && b is ExplorarLocalNode)
      return a.cragId == b.cragId;
    if (a is ComunidadePicoNode && b is ComunidadePicoNode)
      return a.cragId == b.cragId;
    if (a is ApoiePicoNode && b is ApoiePicoNode) return a.cragId == b.cragId;
    if (a is PicoNode && b is PicoNode) {
      return a.cragId == b.cragId;
    }
    if (a is SetorNode && b is SetorNode) {
      return a.cragId == b.cragId &&
          a.setorNome == b.setorNome &&
          a.grupoNome == b.grupoNome;
    }
    if (a is GrupoNode && b is GrupoNode) {
      return a.cragId == b.cragId && a.grupoNome == b.grupoNome;
    }
    if (a is ViaNode && b is ViaNode) {
      return a.cragId == b.cragId &&
          a.escaladaNome == b.escaladaNome &&
          a.setorNome == b.setorNome &&
          a.grupoNome == b.grupoNome;
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
      if (parentNode is SetorNode && _currentNode is ViaNode) {
        _currentNode = SetorNode(
          setorNome: parentNode.setorNome,
          grupoNome: parentNode.grupoNome,
          scrollToEscaladaNome: (_currentNode as ViaNode).escaladaNome,
          cragId: parentNode.cragId,
          parent: parentNode.parent!,
        );
      } else {
        _currentNode = parentNode;
      }
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

class SetoresNode extends PicoContextNode {
  const SetoresNode({required super.cragId, required super.parent});
  @override
  NavNode copyWithMergedAncestor(covariant SetoresNode matchingAncestor) =>
      SetoresNode(cragId: cragId, parent: matchingAncestor.parent);
  @override
  String toString() => 'SetoresNode';
}

class ExplorarLocalNode extends PicoContextNode {
  const ExplorarLocalNode({required super.cragId, required super.parent});
  @override
  NavNode copyWithMergedAncestor(
    covariant ExplorarLocalNode matchingAncestor,
  ) => ExplorarLocalNode(cragId: cragId, parent: matchingAncestor.parent);
  @override
  String toString() => 'ExplorarLocalNode';
}

class ComunidadePicoNode extends PicoContextNode {
  const ComunidadePicoNode({required super.cragId, required super.parent});
  @override
  NavNode copyWithMergedAncestor(
    covariant ComunidadePicoNode matchingAncestor,
  ) => ComunidadePicoNode(cragId: cragId, parent: matchingAncestor.parent);
  @override
  String toString() => 'ComunidadePicoNode';
}

class ApoiePicoNode extends PicoContextNode {
  const ApoiePicoNode({required super.cragId, required super.parent});
  @override
  NavNode copyWithMergedAncestor(covariant ApoiePicoNode matchingAncestor) =>
      ApoiePicoNode(cragId: cragId, parent: matchingAncestor.parent);
  @override
  String toString() => 'ApoiePicoNode';
}
