// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'nav_node.dart';
import 'navigation_tree_model.dart';

/// Controlador de estado reativo de navegação baseado na árvore de nós ([ArvoreNavegacao]).
///
/// Atua como a ponte entre o modelo de domínio puro e os widgets reativos do Flutter,
/// notificando ouvintes (`notifyListeners`) a cada transição de tela.
class TreeNavigationController extends ChangeNotifier {
  ArvoreNavegacao _arvore;

  /// Permite que uma página intercepte o botão voltar do sistema ou da AppBar.
  ///
  /// Se retornar `true`, a navegação padrão da árvore é cancelada pois a página já tratou a ação.
  bool Function()? onBackInterceptor;

  TreeNavigationController({ArvoreNavegacao? estadoInicial})
      : _arvore = estadoInicial ?? const ArvoreNavegacao();

  /// Retorna o modelo de árvore atual.
  ArvoreNavegacao get arvore => _arvore;

  /// Retorna o nó atualmente ativo no topo da árvore.
  NavNode get currentNode => _arvore.noAtual;

  /// Apelido em português brasileiro para [currentNode].
  NavNode get noAtual => _arvore.noAtual;

  /// Navega para um novo [node], aplicando regras de resolução e prevenção de ciclos.
  void navigateTo(NavNode node) {
    _arvore = _arvore.navegarPara(node);
    notifyListeners();
  }

  /// Retorna para o nó pai anterior.
  ///
  /// Executa primeiro o [onBackInterceptor], se registrado.
  /// Retorna `true` se a ação foi tratada ou se houve retorno com sucesso.
  bool goBack() {
    if (onBackInterceptor != null && onBackInterceptor!()) {
      return true;
    }

    final proximaArvore = _arvore.voltar();
    if (proximaArvore != null) {
      _arvore = proximaArvore;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Apelido em português brasileiro para [goBack].
  bool voltar() => goBack();

  /// Retorna diretamente para a raiz da árvore (Home).
  void goHome() {
    final arvoreRaiz = _arvore.irParaRaiz();
    if (_arvore != arvoreRaiz) {
      _arvore = arvoreRaiz;
      notifyListeners();
    }
  }

  /// Apelido em português brasileiro para [goHome].
  void irParaHome() => goHome();
}
