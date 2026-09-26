// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../services/dataset_repository.dart';
import '../services/firebase/telemetry_service.dart';
import '../utils/dataset_resolver.dart';
import '../utils/slug_utils.dart';
import 'deep_link_route_parser.dart';
import 'navigation_tree.dart';

/// Serviço responsável por interceptar, resolver e navegar para rotas profundas
/// acionadas via Deep Links ou leitura de QR Codes.
class DeepLinkNavigatorService {
  final DatasetRepository datasetRepo;
  final TreeNavigationController treeController;
  final TelemetryService telemetryService;

  /// Callback para emissão de mensagens de aviso/erro à interface (opcional).
  void Function(String mensagem)? onMensagemAviso;

  DeepLinkNavigatorService({
    required this.datasetRepo,
    required this.treeController,
    this.onMensagemAviso,
    TelemetryService? telemetryService,
  }) : telemetryService = telemetryService ?? TelemetryService.instance;

  /// Processa uma URL ou Uri de deep link.
  ///
  /// Retorna `true` se o link foi processado e a navegação executada com sucesso,
  /// ou `false` caso o link seja inválido, o croqui não possa ser carregado ou o pico não exista.
  Future<bool> processarLink(
    dynamic link, {
    BuildContext? context,
    String? tipoStart,
  }) async {
    final rota = DeepLinkRouteParser.parse(link);
    if (rota == null) {
      return false;
    }

    final parametrosUtm = rota.parametros.isEmpty ? null : rota.parametros;

    // 1. Resolve o Pico e Croqui correspondente
    final dadosPico = await _obterPicoECroqui(rota.picoId);
    if (dadosPico == null) {
      await telemetryService.logDeepLinkAberto(
        idCroqui: rota.picoId,
        destino: _inferirDestino(rota),
        sucesso: false,
        tipoStart: tipoStart,
        motivoErro: 'pico_nao_encontrado_ou_sem_conexao',
        parametrosUtm: parametrosUtm,
      );

      final mensagem =
          'Não foi possível abrir o croqui de "${rota.picoId}". Verifique sua conexão à internet ou baixe o pico previamente.';
      if (context != null && !context.mounted) {
        if (onMensagemAviso != null) {
          onMensagemAviso!(mensagem);
        }
        return false;
      }
      _notificarAviso(mensagem, context);
      return false;
    }

    final pico = dadosPico.pico;

    // 2. Monta a linhagem ascendente da árvore a partir da raiz (Home)
    final NavNode raiz = const HomeNode();
    final picoNode = PicoNode(cragId: rota.picoId, parent: raiz);

    // Função auxiliar para navegar e registrar telemetria de sucesso
    Future<bool> navegarPara(NavNode node, String destino) async {
      treeController.navigateTo(node);
      await telemetryService.logDeepLinkAberto(
        idCroqui: rota.picoId,
        destino: destino,
        sucesso: true,
        tipoStart: tipoStart,
        parametrosUtm: parametrosUtm,
      );
      return true;
    }

    // Se o link aponta apenas para o Pico (nível 1)
    if (rota.profundidade == 0) {
      return navegarPara(picoNode, 'pico');
    }

    // 3. Procura se o primeiro segmento é um Grupo
    Grupo? grupoCorrespondente;
    for (final item in pico.setoresOuGrupos) {
      if (item.whichTipo() == SetorOuGrupo_Tipo.grupo &&
          item.grupo.hasConteudo()) {
        final g = item.grupo.conteudo;
        if (slugsCoincidem(g.nome, rota.primeiroSegmento!)) {
          grupoCorrespondente = g;
          break;
        }
      }
    }

    if (grupoCorrespondente != null) {
      final grupoNode = GrupoNode(
        grupoNome: grupoCorrespondente.nome,
        cragId: rota.picoId,
        parent: picoNode,
      );

      // Link aponta para o Grupo (nível 2)
      if (rota.profundidade == 1) {
        return navegarPara(grupoNode, 'grupo');
      }

      // Procura Setor dentro do Grupo (nível 3)
      Setor? setorNoGrupo;
      for (final sItem in grupoCorrespondente.setores) {
        if (sItem.hasConteudo()) {
          final s = sItem.conteudo;
          if (slugsCoincidem(s.nome, rota.segundoSegmento!)) {
            setorNoGrupo = s;
            break;
          }
        }
      }

      if (setorNoGrupo != null) {
        final setorNode = SetorNode(
          setorNome: setorNoGrupo.nome,
          grupoNome: grupoCorrespondente.nome,
          cragId: rota.picoId,
          parent: grupoNode,
        );

        // Link aponta para o Setor dentro de Grupo (nível 3)
        if (rota.profundidade == 2) {
          return navegarPara(setorNode, 'setor');
        }

        // Procura Via dentro do Setor do Grupo (nível 4)
        Escalada? viaNoSetor;
        for (final esc in setorNoGrupo.escaladas) {
          if (slugsCoincidem(esc.nome, rota.terceiroSegmento!)) {
            viaNoSetor = esc;
            break;
          }
        }

        if (viaNoSetor != null) {
          final viaNode = ViaNode(
            escaladaNome: viaNoSetor.nome,
            setorNome: setorNoGrupo.nome,
            grupoNome: grupoCorrespondente.nome,
            cragId: rota.picoId,
            parent: setorNode,
          );
          return navegarPara(viaNode, 'via');
        }

        // Fallback para o setor se a via não for encontrada
        return navegarPara(setorNode, 'setor');
      }

      // Fallback para o grupo se o setor não for encontrado
      return navegarPara(grupoNode, 'grupo');
    }

    // 4. Se não for Grupo, procura se o primeiro segmento é um Setor direto
    Setor? setorDireto;
    for (final item in pico.setoresOuGrupos) {
      if (item.whichTipo() == SetorOuGrupo_Tipo.setor &&
          item.setor.hasConteudo()) {
        final s = item.setor.conteudo;
        if (slugsCoincidem(s.nome, rota.primeiroSegmento!)) {
          setorDireto = s;
          break;
        }
      }
    }

    // Fallback: se não encontrou no nível raiz do pico, busca em qualquer grupo
    if (setorDireto == null) {
      for (final item in pico.setoresOuGrupos) {
        if (item.whichTipo() == SetorOuGrupo_Tipo.grupo &&
            item.grupo.hasConteudo()) {
          final g = item.grupo.conteudo;
          for (final sItem in g.setores) {
            if (sItem.hasConteudo()) {
              final s = sItem.conteudo;
              if (slugsCoincidem(s.nome, rota.primeiroSegmento!)) {
                setorDireto = s;
                grupoCorrespondente = g;
                break;
              }
            }
          }
          if (setorDireto != null) break;
        }
      }
    }

    if (setorDireto != null) {
      NavNode paiDoSetor = picoNode;
      if (grupoCorrespondente != null) {
        paiDoSetor = GrupoNode(
          grupoNome: grupoCorrespondente.nome,
          cragId: rota.picoId,
          parent: picoNode,
        );
      }

      final setorNode = SetorNode(
        setorNome: setorDireto.nome,
        grupoNome: grupoCorrespondente?.nome,
        cragId: rota.picoId,
        parent: paiDoSetor,
      );

      // Link aponta para o Setor (nível 2)
      if (rota.profundidade == 1) {
        return navegarPara(setorNode, 'setor');
      }

      // Procura Via dentro do Setor (nível 3)
      Escalada? viaNoSetor;
      for (final esc in setorDireto.escaladas) {
        if (slugsCoincidem(esc.nome, rota.segundoSegmento!)) {
          viaNoSetor = esc;
          break;
        }
      }

      if (viaNoSetor != null) {
        final viaNode = ViaNode(
          escaladaNome: viaNoSetor.nome,
          setorNome: setorDireto.nome,
          grupoNome: grupoCorrespondente?.nome,
          cragId: rota.picoId,
          parent: setorNode,
        );
        return navegarPara(viaNode, 'via');
      }

      // Fallback para o setor se a via não for encontrada
      return navegarPara(setorNode, 'setor');
    }

    // Se nenhum grupo ou setor for encontrado, abre o Pico como fallback
    return navegarPara(picoNode, 'pico');
  }

  String _inferirDestino(RotaDeepLink rota) {
    if (rota.profundidade >= 2) return 'via';
    if (rota.profundidade == 1) return 'setor';
    return 'pico';
  }

  Future<_DadosPico?> _obterPicoECroqui(String picoId) async {
    final active = datasetRepo.activeDataset.value;

    // 1. Tenta recuperar dos picos baixados no cache local
    if (active != null) {
      for (final p in active.picosBaixados) {
        if (p.id == picoId && p.pico != null && p.croqui != null) {
          return _DadosPico(p.pico!, p.croqui!);
        }
      }
    }

    // 2. Tenta recuperar da sessão online ativa em memória
    final croquiOnline =
        datasetRepo.gerenciadorSessaoOnline.obterCroquiOnline(picoId);
    if (croquiOnline != null && croquiOnline.picos.isNotEmpty) {
      return _DadosPico(croquiOnline.picos.first, croquiOnline);
    }

    // 3. Tenta carregar online sob demanda se houver URL registrada no catálogo
    if (active != null) {
      final picoItem = active.picosDisponiveis
          .where((p) => p.id == picoId)
          .firstOrNull;
      final url = picoItem?.url;
      if (url != null && url.isNotEmpty) {
        final croquiCarregado =
            await datasetRepo.servicoCroquiOnline.carregarCroquiRemoto(
          url,
          picoId: picoId,
        );
        if (croquiCarregado != null && croquiCarregado.picos.isNotEmpty) {
          return _DadosPico(croquiCarregado.picos.first, croquiCarregado);
        }
      }
    }

    return null;
  }

  void _notificarAviso(String mensagem, BuildContext? context) {
    if (onMensagemAviso != null) {
      onMensagemAviso!(mensagem);
    } else if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

class _DadosPico {
  final Pico pico;
  final Croqui croqui;
  _DadosPico(this.pico, this.croqui);
}
