// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'arvore_navegacao.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../utils/construtor_caminho_trajeto.dart';
import '../utils/formatador_escalada.dart';
import '../services/autenticacao/servico_autenticacao.dart';
import '../services/controlador_interacoes_usuario.dart';
import '../services/repositorio_dataset.dart';

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
abstract final class AppNav {
  /// Canal nativo do Android responsável por operações não-destrutivas de ciclo de vida da tarefa.
  static const MethodChannel canalCicloVida = MethodChannel(
    'app.escalada.croquis/ciclo_vida',
  );

  /// Move a tarefa do aplicativo para segundo plano preservando a `MainActivity`
  /// e a `FlutterEngine` vivas em memória (`moveTaskToBack`), evitando destruir a
  /// atividade e forçar um novo *Cold Start* na reabertura subsequente.
  ///
  /// Caso o canal nativo não esteja disponível ou retorne `false`, realiza fallback
  /// seguro para [SystemNavigator.pop].
  static Future<void> minimizarAplicativo() async {
    try {
      final movidoParaSegundoPlano = await canalCicloVida.invokeMethod<bool>(
        'minimizarTarefa',
      );
      if (movidoParaSegundoPlano == true) {
        return;
      }
    } catch (_) {
      // Fallback seguro para SystemNavigator.pop() abaixo
    }
    await SystemNavigator.pop();
  }

  static TreeNavigationController? _ctrl(BuildContext context) {
    try {
      final state = TreeNavigationWrapper.of(context);
      return state.treeController;
    } catch (e) {
      // Fallback para o controlador global quando chamado de contextos fora da árvore (ex: dialogs/overlays)
      return TreeNavigationWrapper.currentTreeController;
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

    ctrl.navigateTo(
      PicoNode(
        cragId: finalCragId,
        scrollToMapaGeral: scrollToMapaGeral,
        returnToSetorNome: returnToSetor?.nome,
        parent: ctrl.currentNode,
      ),
    );
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

    ctrl.navigateTo(
      MapasCarrosselNode(
        cragId: cragId,
        initialIndex: initialIndex,
        mapas: mapas,
        imageProviderOverride: imageProviderOverride,
        parent: ctrl.currentNode,
      ),
    );
  }

  /// Navega para o Mapa Global.
  ///
  /// Permite especificar [picoIds] em texto ou lista [crags] contendo cards/picos,
  /// normalizando os identificadores para armazenamento no [MapaGlobalNode].
  static void toMapaGlobal(
    BuildContext context, {
    dynamic crags,
    List<String>? picoIds,
  }) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;

    final List<String> ids = [];
    if (picoIds != null) {
      ids.addAll(picoIds);
    }

    final List<dynamic> picos;
    if (crags is Iterable) {
      picos = crags.toList();
      if (ids.isEmpty) {
        for (final item in picos) {
          if (item is String && item.isNotEmpty) {
            ids.add(item);
          } else {
            try {
              final id = (item as dynamic).id?.toString();
              if (id != null && id.isNotEmpty) {
                ids.add(id);
              }
            } catch (_) {
              if (item is Map && item['id'] != null) {
                ids.add(item['id'].toString());
              }
            }
          }
        }
      }
    } else {
      picos = const [];
    }

    ctrl.navigateTo(MapaGlobalNode(
      picoIds: ids,
      crags: picos,
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

    ctrl.navigateTo(
      SetorNode(
        setorNome: setor.nome,
        grupoNome: grupoContext?.nome,
        scrollToEscaladaNome: scrollToEscalada != null
            ? obterNomeEscalada(scrollToEscalada, padrao: '')
            : null,
        cragId: finalCragId,
        parent: ctrl.currentNode,
      ),
    );
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

    ctrl.navigateTo(
      GrupoNode(
        grupoNome: grupo.nome,
        cragId: finalCragId,
        parent: ctrl.currentNode,
      ),
    );
  }

  /// Navega para a página do Índice de Escaladas.
  /// Herda automaticamente cragId a partir do nó atual, se não fornecido.
  static void toIndiceEscaladas(
    BuildContext context, {
    String? cragId,
  }) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    final ctx = _picoCtx(ctrl.currentNode);

    final finalCragId = cragId ?? (ctx?.cragId);

    if (finalCragId == null) return;

    ctrl.navigateTo(
      IndiceEscaladasNode(
        cragId: finalCragId,
        parent: ctrl.currentNode,
      ),
    );
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

    ctrl.navigateTo(
      ViaNode(
        escaladaNome: obterNomeEscalada(escalada, padrao: ''),
        setorNome: setor?.nome,
        grupoNome: grupo?.nome,
        cragId: finalCragId,
        parent: ctrl.currentNode,
      ),
    );
  }

  /// Localiza e navega para a página de uma Via ([ViaNode]) a partir de seu [escaladaUid]
  /// (NanoID 14c) nos croquis disponíveis localmente ou em sessão ativa, preservando o nó
  /// atual da árvore (ex.: [CadernetaNode]) como ancestral direto.
  ///
  /// Retorna `true` se a via foi encontrada e a navegação ocorreu, ou `false` caso contrário.
  static bool toViaPorUid(
    BuildContext context,
    String escaladaUid, {
    DatasetRepository? datasetRepo,
  }) {
    final ctrl = _ctrl(context);
    final wrapperState =
        TreeNavigationWrapper.maybeOf(context) ??
        TreeNavigationWrapper.navKey.currentState;
    final repo = datasetRepo ?? wrapperState?.widget.datasetRepo;
    if (ctrl == null || repo == null || escaladaUid.isEmpty) return false;

    final croquis = <Croqui>[];
    final active = repo.activeDataset.value;
    if (active != null) {
      for (final p in active.picosBaixados) {
        if (p.croqui != null) {
          croquis.add(p.croqui!);
        }
      }
      croquis.addAll(active.croquisBaixados);
    }
    croquis.addAll(repo.gerenciadorSessaoOnline.croquisEmMemoria.values);

    final localizacao = localizarEscaladaPorUidEmCroquis(escaladaUid, croquis);
    if (localizacao == null) return false;

    ctrl.navigateTo(
      ViaNode(
        escaladaNome: localizacao.escaladaNome,
        setorNome: localizacao.setorNome,
        grupoNome: localizacao.grupoNome,
        cragId: localizacao.idCroqui,
        parent: ctrl.currentNode,
      ),
    );
    return true;
  }

  /// Navega para a página de GPS do pico atual.
  /// Herda automaticamente pico/croqui/cragId a partir do nó atual.
  static void toGPS(BuildContext context) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    final ctx = _picoCtx(ctrl.currentNode);

    if (ctx == null) return;
    if (ctrl.currentNode is GPSNode) return; // Já está aqui

    ctrl.navigateTo(GPSNode(cragId: ctx.cragId, parent: ctrl.currentNode));
  }

  /// Navega para a aba de exploração e catálogo de croquis (BrowseNode).
  static void toBrowse(BuildContext context) {
    ConstrutorCaminhoTrajeto.limparCache();
    final ctrl = _ctrl(context);
    if (ctrl == null) return;
    ctrl.navigateTo(BrowseNode(ctrl.currentNode));
  }

  /// Navega para a página de Configurações do aplicativo (SettingsNode).
  static void toSettings(BuildContext context) {
    final ctrl = _ctrl(context);
    if (ctrl != null) {
      ctrl.navigateTo(SettingsNode(ctrl.currentNode));
    }
  }

  /// Navega para a página de Login e Criação de Conta ([LoginNode]) na árvore de nós.
  ///
  /// Quando acionado a partir do [PerfilNode], substitui o nó de perfil mantendo o
  /// mesmo ancestral base para evitar ciclos entre Login e Perfil.
  static void toLogin(BuildContext context) {
    final ctrl = _ctrl(context);
    if (ctrl != null) {
      final ancestralBase = ctrl.currentNode is PerfilNode
          ? (ctrl.currentNode.parent ?? const HomeNode())
          : ctrl.currentNode;
      ctrl.navigateTo(LoginNode(ancestralBase));
    }
  }

  /// Abre diretamente o Hub de Perfil ([PerfilNode]) quando o escalador já está
  /// autenticado, ou direciona para a página de autenticação ([LoginNode]) caso contrário.
  static void abrirPerfilOuLogin(BuildContext context) {
    if (ServicoAutenticacaoLocal.instancia.estaAutenticado) {
      toPerfil(context);
    } else {
      toLogin(context);
    }
  }

  /// Navega para o Hub de Perfil e Caderneta Esportiva ([PerfilNode]) na árvore de nós.
  ///
  /// Quando chamado a partir do [LoginNode] (após autenticação ou ao escolher
  /// continuar sem conta), substitui o [LoginNode] preservando o ancestral base.
  static void toPerfil(BuildContext context) {
    final ctrl = _ctrl(context);
    if (ctrl != null) {
      final ancestralBase = ctrl.currentNode is LoginNode
          ? (ctrl.currentNode.parent ?? const HomeNode())
          : ctrl.currentNode;
      ctrl.navigateTo(PerfilNode(ancestralBase));
    }
  }

  /// Navega para a página de Caderneta Esportiva pessoal ([CadernetaNode]) na árvore de nós,
  /// caso o recurso esteja habilitado no ambiente e ativo nas preferências do usuário.
  static void toCaderneta(BuildContext context) {
    if (!ControladorInteracoesUsuario.instancia.exibirElementosInterativos) {
      return;
    }
    final ctrl = _ctrl(context);
    if (ctrl != null) {
      ctrl.navigateTo(CadernetaNode(ctrl.currentNode));
    }
  }

  /// Volta um nível na árvore de navegação ou desempilha rotas imperativas sobrepostas do Navigator.
  ///
  /// Quando chamado a partir de uma página declarativa da árvore (`ModalRoute.of(context)?.settings is Page`),
  /// delega diretamente para [TreeNavigationController.goBack] para que interceptadores de saída
  /// (`onBackInterceptor`) sejam avaliados antes de qualquer remoção de página no [Navigator].
  /// Quando chamado de uma rota imperativa sobreposta (`DialogRoute`, `ModalBottomSheetRoute`,
  /// `SearchPageRoute`, ou em testes sem [TreeNavigationController]), realiza o `pop()` da rota.
  static void back(BuildContext context) {
    final ctrl = _ctrl(context);
    final rotaAtual = ModalRoute.of(context);
    final isRotaDeclarativaDaArvore = rotaAtual?.settings is Page;

    if ((!isRotaDeclarativaDaArvore || ctrl == null) &&
        Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (ctrl != null) {
      ctrl.goBack();
    }
  }

  /// Volta todo o caminho de retorno para o nó Home (raiz).
  static void home(BuildContext context) {
    ConstrutorCaminhoTrajeto.limparCache();
    _ctrl(context)?.goHome();
  }

  /// Indica se o nó atual possui um pai (ou seja, se voltar é possível).
  static bool canGoBack(BuildContext context) {
    final ctrl = _ctrl(context);
    if (ctrl == null) return Navigator.of(context).canPop();
    return ctrl.currentNode.parent != null;
  }
}

// Auxiliar interno para empacotar os campos de contexto de um pico
class _PicoContext {
  final String cragId;
  _PicoContext(this.cragId);
}
