// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Classe base abstrata para todos os nós da árvore de navegação do aplicativo.
///
/// Cada nó representa um estado de tela ou visualização e mantém uma referência
/// ao seu nó pai (`parent`). A raiz da árvore (geralmente [HomeNode]) possui `parent` nulo.
abstract class NavNode {
  /// O nó pai na hierarquia de navegação. É nulo apenas para o nó raiz.
  final NavNode? parent;

  const NavNode({this.parent});

  /// Cria uma cópia deste nó anexando-o ao pai do ancestral correspondente.
  ///
  /// Subclasses devem sobrescrever este método para preservar e mesclar
  /// estados contextuais específicos de interface (como alvos de rolagem).
  NavNode copyWithMergedAncestor(covariant NavNode matchingAncestor) {
    return this;
  }

  /// Verifica polimorficamente se este nó representa logicamente o mesmo destino que [other].
  ///
  /// Elimina a necessidade de grandes estruturas condicionais centralizadas no controlador.
  bool isSameNode(NavNode other) {
    return runtimeType == other.runtimeType;
  }

  /// Apelido em português brasileiro para [isSameNode].
  bool ehMesmoNo(NavNode outro) => isSameNode(outro);

  /// Retorna o rótulo conciso e legível deste nó (ex: 'Início', 'Setor (Falésia)').
  String get rotuloAmigavel => toString();

  /// Retorna o caminho canônico mais curto e direto da raiz até este nó.
  String obterCaminhoCurto() {
    if (parent == null) {
      return rotuloAmigavel;
    }
    return '${parent!.obterCaminhoCurto()} -> $rotuloAmigavel';
  }

  /// Retorna a lista sequencial de nós desde a raiz até este nó folha.
  List<NavNode> get path {
    final List<NavNode> p = [];
    NavNode? current = this;
    while (current != null) {
      p.add(current);
      current = current.parent;
    }
    return p.reversed.toList();
  }

  /// Apelido em português brasileiro para [path].
  List<NavNode> get caminho => path;
}

/// Classe base abstrata para nós cujo conteúdo depende do identificador de um Pico ([cragId]).
abstract class PicoContextNode extends NavNode {
  /// Identificador único do pico no catálogo.
  final String cragId;

  const PicoContextNode({
    required this.cragId,
    super.parent,
  });

  @override
  bool isSameNode(NavNode other) {
    if (other is! PicoContextNode) return false;
    return runtimeType == other.runtimeType && cragId == other.cragId;
  }
}

/// Typedefs para conveniência e conformidade com nomenclatura em português.
typedef NoNavegacao = NavNode;
typedef NoContextoPico = PicoContextNode;
