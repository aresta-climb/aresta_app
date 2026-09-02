// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'no_navegacao.dart';
import 'nos_globais.dart';

/// Modelo de domínio puro e imutável que representa o estado e as regras estruturais
/// da árvore de navegação do aplicativo.
///
/// Encapsula a pilha hierárquica de nós, prevenção de loops infinitos e resolução
/// de ancestrais sem dependência do framework de UI do Flutter.
class ArvoreNavegacao {
  /// O nó folha atualmente ativo no topo da árvore de navegação.
  final NavNode noAtual;

  const ArvoreNavegacao({NavNode? noAtual})
      : noAtual = noAtual ?? const HomeNode();

  /// Retorna o nó atualmente ativo (apelido em inglês para compatibilidade).
  NavNode get currentNode => noAtual;

  /// Retorna a lista completa de nós desde a raiz até o nó ativo atual.
  List<NavNode> get caminho => noAtual.path;

  /// Retorna o caminho de nós (apelido em inglês para compatibilidade).
  List<NavNode> get path => caminho;

  /// Profundidade atual da árvore de navegação (número de nós no caminho).
  int get profundidade => caminho.length;

  /// Indica se o nó ativo atual é a raiz da árvore (sem pai).
  bool get estaNaRaiz => noAtual.parent == null;

  /// Percorre a cadeia de ancestrais a partir do nó atual para localizar
  /// um nó pré-existente equivalente a [novoNo].
  NavNode? encontrarAncestralCorrespondente(NavNode novoNo) {
    NavNode? current = noAtual;
    while (current != null) {
      if (current.isSameNode(novoNo)) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }

  /// Calcula a próxima transição da árvore ao navegar para [novoNo].
  ///
  /// Se um nó equivalente já existir na cadeia de ancestrais, a árvore é podada
  /// até esse ancestral e o estado é mesclado via `copyWithMergedAncestor`,
  /// impedindo loops infinitos de navegação (ex: mapas <-> vias).
  ArvoreNavegacao navegarPara(NavNode novoNo) {
    final matchingAncestor = encontrarAncestralCorrespondente(novoNo);

    if (matchingAncestor != null) {
      return ArvoreNavegacao(
        noAtual: novoNo.copyWithMergedAncestor(matchingAncestor),
      );
    } else {
      return ArvoreNavegacao(noAtual: novoNo);
    }
  }

  /// Retorna um novo estado retrocedendo para o nó pai (`parent`).
  ///
  /// Retorna `null` se a navegação já estiver na raiz da árvore.
  ArvoreNavegacao? voltar() {
    final parentNode = noAtual.parent;
    if (parentNode != null) {
      return ArvoreNavegacao(noAtual: parentNode);
    }
    return null;
  }

  /// Retorna um novo estado apontando diretamente para a raiz da árvore (Home).
  ArvoreNavegacao irParaRaiz() {
    NavNode node = noAtual;
    while (node.parent != null) {
      node = node.parent!;
    }
    if (noAtual == node) {
      return this;
    }
    return ArvoreNavegacao(noAtual: node);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArvoreNavegacao &&
          runtimeType == other.runtimeType &&
          noAtual.isSameNode(other.noAtual);

  @override
  int get hashCode => noAtual.hashCode;

  @override
  String toString() => 'ArvoreNavegacao(noAtual: $noAtual, profundidade: $profundidade)';
}
