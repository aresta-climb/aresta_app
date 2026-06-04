import 'package:flutter/material.dart';
import '../main.dart';
import 'navigation_tree.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';

/// API de navegação centralizada para o sistema de navegação baseado em árvore do aresta.
///
/// Toda a navegação no aplicativo deve passar por esses métodos estáticos.
/// Eles extraem automaticamente o contexto pai correto (pico, croqui, cragId)
/// a partir do nó atual na árvore, de modo que os chamadores só precisam fornecer
/// o item de destino para o qual desejam navegar.
///
/// Exemplo:
///   AppNav.toPico(context, pico: meuPico, croqui: meuCroqui, cragId: id);
///   AppNav.toSetor(context, setor: meuSetor);
///   AppNav.toVia(context, escalada: minhaEscalada);
///   AppNav.back(context);
class AppNav {
  AppNav._(); // Não instanciável

  static TreeNavigationController? _ctrl(BuildContext context) {
    try {
      return TreeNavigationWrapper.of(context).treeController;
    } catch (e) {
      // Retorna nulo se chamado fora do TreeNavigationWrapper (ex: testes isolados)
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Auxiliares para extrair pico/croqui/cragId de qualquer nó que os contenha
  // ---------------------------------------------------------------------------

  static _PicoContext? _picoCtx(NavNode? node) {
    if (node == null) return null;
    NavNode current = node;
    while (true) {
      if (current is PicoContextNode) {
        return _PicoContext(current.pico, current.croqui, current.cragId);
      }
      final parentNode = current.parent;
      if (parentNode == null) break;
      current = parentNode;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Métodos públicos de navegação
  // ---------------------------------------------------------------------------

  /// Navega para a página de um Pico.
  /// Requer pico/croqui/cragId explícitos, pois isso é normalmente chamado a partir da Home,
  /// onde ainda não existe um contexto de pico.
  static void toPico(
    BuildContext context, {
    Pico? pico,
    Croqui? croqui,
    String? cragId,
    bool scrollToMapaGeral = false,
    Setor? returnToSetor,
  }) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    
    final ctx = _picoCtx(ctrl.currentNode);
    
    final finalPico = pico ?? (ctx?.pico);
    final finalCroqui = croqui ?? (ctx?.croqui);
    final finalCragId = cragId ?? (ctx?.cragId);

    if (finalPico == null || finalCroqui == null || finalCragId == null) return;
    
    ctrl.navigateTo(PicoNode(
      pico: finalPico,
      croqui: finalCroqui,
      cragId: finalCragId,
      scrollToMapaGeral: scrollToMapaGeral,
      returnToSetor: returnToSetor,
      parent: ctrl.currentNode,
    ));
  }

  static void toMapaGeralPico(BuildContext context, {Setor? returnToSetor}) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    
    final ctx = _picoCtx(ctrl.currentNode);
    if (ctx == null) return;
    
    ctrl.navigateTo(MapaGeralPicoNode(
      pico: ctx.pico,
      croqui: ctx.croqui,
      cragId: ctx.cragId,
      returnToSetor: returnToSetor,
      parent: ctrl.currentNode,
    ));
  }

  static void toMapaInterativo(
    BuildContext context, {
    required Mapa mapa,
    required String cragId,
    required List<Escalada> escaladas,
    required List<ArquivoSetor> setores,
    String? initialSelectedId,
    Setor? setorContext,
  }) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    
    ctrl.navigateTo(MapaInterativoNode(
      mapa: mapa,
      cragId: cragId,
      escaladas: escaladas,
      setores: setores,
      initialSelectedId: initialSelectedId,
      setorContext: setorContext,
      parent: ctrl.currentNode,
    ));
  }

  /// Navega para a página de um Setor.
  /// Herda automaticamente pico/croqui/cragId a partir do nó atual, se não fornecidos.
  static void toSetor(
    BuildContext context, {
    required Setor setor,
    Escalada? scrollToEscalada,
    Pico? pico,
    Croqui? croqui,
    String? cragId,
  }) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    final ctx = _picoCtx(ctrl.currentNode);
    
    final finalPico = pico ?? (ctx?.pico);
    final finalCroqui = croqui ?? (ctx?.croqui);
    final finalCragId = cragId ?? (ctx?.cragId);

    assert(finalPico != null && finalCroqui != null && finalCragId != null, 
      'AppNav.toSetor requer contexto de pico explícito ou herdado');
    if (finalPico == null || finalCroqui == null || finalCragId == null) return;
    
    ctrl.navigateTo(SetorNode(
      setor: setor,
      scrollToEscalada: scrollToEscalada,
      pico: finalPico,
      croqui: finalCroqui,
      cragId: finalCragId,
      parent: ctrl.currentNode,
    ));
  }

  /// Navega para a página de um Grupo.
  /// Herda automaticamente pico/croqui/cragId a partir do nó atual, se não fornecidos.
  static void toGrupo(
    BuildContext context, {
    required Grupo grupo,
    Pico? pico,
    Croqui? croqui,
    String? cragId,
  }) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    final ctx = _picoCtx(ctrl.currentNode);
    
    final finalPico = pico ?? (ctx?.pico);
    final finalCroqui = croqui ?? (ctx?.croqui);
    final finalCragId = cragId ?? (ctx?.cragId);

    assert(finalPico != null && finalCroqui != null && finalCragId != null, 
      'AppNav.toGrupo requer contexto de pico explícito ou herdado');
    if (finalPico == null || finalCroqui == null || finalCragId == null) return;

    ctrl.navigateTo(GrupoNode(
      grupo: grupo,
      pico: finalPico,
      croqui: finalCroqui,
      cragId: finalCragId,
      parent: ctrl.currentNode,
    ));
  }

  /// Navega para a página de uma Via (Escalada).
  /// Herda automaticamente pico/croqui/cragId a partir do nó atual, se não fornecidos.
  static void toVia(
    BuildContext context, {
    required Escalada escalada,
    Setor? setor,
    Pico? pico,
    Croqui? croqui,
    String? cragId,
  }) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    final ctx = _picoCtx(ctrl.currentNode);
    
    final finalPico = pico ?? (ctx?.pico);
    final finalCroqui = croqui ?? (ctx?.croqui);
    final finalCragId = cragId ?? (ctx?.cragId);

    assert(finalPico != null && finalCroqui != null && finalCragId != null, 
      'AppNav.toVia requer contexto de pico explícito ou herdado');
    if (finalPico == null || finalCroqui == null || finalCragId == null) return;

    ctrl.navigateTo(ViaNode(
      escalada: escalada,
      setor: setor,
      pico: finalPico,
      croqui: finalCroqui,
      cragId: finalCragId,
      parent: ctrl.currentNode,
    ));
  }

  /// Navega para a página de GPS do pico atual.
  /// Herda automaticamente pico/croqui/cragId a partir do nó atual.
  static void toGPS(BuildContext context) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    final ctx = _picoCtx(ctrl.currentNode);
    
    assert(ctx != null, 'AppNav.toGPS chamado a partir de um nó sem contexto de pico');
    if (ctx == null) return;
    if (ctrl.currentNode is GPSNode) return; // Já está aqui
    
    ctrl.navigateTo(GPSNode(
      pico: ctx.pico,
      croqui: ctx.croqui,
      cragId: ctx.cragId,
      parent: ctrl.currentNode,
    ));
  }

  /// Volta um nível na árvore de navegação.
  static void back(BuildContext context) {
    _ctrl(context)?.goBack();
  }

  /// Volta todo o caminho de retorno para o nó Home (raiz).
  static void home(BuildContext context) {
    _ctrl(context)?.goHome();
  }

  /// Indica se o nó atual possui um pai (ou seja, se voltar é possível).
  static bool canGoBack(BuildContext context) {
    try {
      final ctrl = _ctrl(context);
      if (ctrl == null) return Navigator.of(context).canPop();
      return ctrl.currentNode.parent != null;
    } catch (e) {
      return Navigator.of(context).canPop();
    }
  }
}

// Auxiliar interno para empacotar os campos de contexto de um pico
class _PicoContext {
  final Pico pico;
  final Croqui croqui;
  final String cragId;
  _PicoContext(this.pico, this.croqui, this.cragId);
}
