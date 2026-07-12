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
        return _PicoContext(current.cragId);
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
    final finalCragId = cragId ?? (ctx?.cragId);
    if (finalCragId == null) return;
    
    ctrl.navigateTo(PicoNode(
      cragId: finalCragId,
      scrollToMapaGeral: scrollToMapaGeral,
      returnToSetorNome: returnToSetor?.nome,
      parent: ctrl.currentNode,
    ));
  }


  /// Helper de navegação unificado para mapas.
  /// Recebe uma lista de [mapas] e delega a renderização para [MapasCarrosselNode].
  /// Esta abstração garante que o sistema escolha automaticamente entre mostrar um
  /// mapa simples ou um carrossel de mapas, prevenindo burlar a lógica de exibição.
  static void toMapas(
    BuildContext context, {
    required String cragId,
    required List<CarrosselItemData> mapas,
    int initialIndex = 0,
    ImageProvider? imageProviderOverride,
  }) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    
    ctrl.navigateTo(MapasCarrosselNode(
      cragId: cragId,
      initialIndex: initialIndex,
      mapas: mapas,
      imageProviderOverride: imageProviderOverride,
      parent: ctrl.currentNode,
    ));
  }

  /// Navega para o Mapa Global.
  static void toMapaGlobal(
    BuildContext context, {
    required List<Map<String, dynamic>> crags,
  }) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    
    ctrl.navigateTo(MapaGlobalNode(
      crags: crags,
      parent: ctrl.currentNode,
    ));
  }

  /// Navega para a página de um Setor.
  /// Herda automaticamente pico/croqui/cragId a partir do nó atual, se não fornecidos.
  static void toSetor(
    BuildContext context, {
    required Setor setor,
    Grupo? grupoContext,
    Escalada? scrollToEscalada,
    Pico? pico,
    Croqui? croqui,
    String? cragId,
  }) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    final ctx = _picoCtx(ctrl.currentNode);
    
    final finalCragId = cragId ?? (ctx?.cragId);

    if (finalCragId == null) return;
    
    ctrl.navigateTo(SetorNode(
      setorNome: setor.nome,
      grupoNome: grupoContext?.nome,
      scrollToEscaladaNome: scrollToEscalada != null ? _getNomeEscalada(scrollToEscalada) : null,
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
    
    final finalCragId = cragId ?? (ctx?.cragId);

    if (finalCragId == null) return;

    ctrl.navigateTo(GrupoNode(
      grupoNome: grupo.nome,
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
    Grupo? grupo,
    Pico? pico,
    Croqui? croqui,
    String? cragId,
  }) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    final ctx = _picoCtx(ctrl.currentNode);
    
    final finalCragId = cragId ?? (ctx?.cragId);

    if (finalCragId == null) return;

    ctrl.navigateTo(ViaNode(
      escaladaNome: _getNomeEscalada(escalada),
      setorNome: setor?.nome,
      grupoNome: grupo?.nome,
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
    
    if (ctx == null) return;
    if (ctrl.currentNode is GPSNode) return; // Já está aqui
    
    ctrl.navigateTo(GPSNode(
      cragId: ctx.cragId,
      parent: ctrl.currentNode,
    ));
  }

  /// Volta um nível na árvore de navegação.
  static void back(BuildContext context) {
    final ctrl = _ctrl(context);
    if (ctrl != null) {
      ctrl.goBack();
    } else {
      Navigator.of(context).maybePop();
    }
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

  static String _getNomeEscalada(Escalada e) {
    if (e.hasViaEsportiva()) return e.viaEsportiva.nome;
    if (e.hasViaMovel()) return e.viaMovel.nome;
    if (e.hasBoulder()) return e.boulder.nome;
    if (e.hasViaMultiplasEnfiadas()) return e.viaMultiplasEnfiadas.nome;
    if (e.hasHighline()) return e.highline.nome;
    return '';
  }
}

// Auxiliar interno para empacotar os campos de contexto de um pico
class _PicoContext {
  final String cragId;
  _PicoContext(this.cragId);
}
