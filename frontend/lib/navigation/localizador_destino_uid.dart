// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../aresta_api/proto/generated/croqui.pb.dart';
import '../services/repositorio_dataset.dart';
import '../utils/consulta_dataset.dart';
import 'arvore_navegacao.dart';

/// Encapsula o resultado da localização de um identificador estável (NanoID 14c) para navegação.
///
/// Fornece o nó de navegação pronto para ativação pelo [TreeNavigationController],
/// além de metadados de auditoria e telemetria para identificação do destino.
class DestinoUidLocalizado {
  /// Nó da árvore de navegação reativa que deve ser ativado na interface.
  final NavNode noNavegacao;

  /// Identificador do croqui/pico hospedeiro da entidade (ex: "br_mg_igarape_pedra_grande").
  final String idCroqui;

  /// Tipo de destino para efeitos de telemetria e rastreabilidade ('via', 'setor', 'grupo', 'pico').
  final String tipoDestino;

  /// Nome legível da entidade encontrada (para registros de log e acessibilidade).
  final String nomeEntidade;

  const DestinoUidLocalizado({
    required this.noNavegacao,
    required this.idCroqui,
    required this.tipoDestino,
    required this.nomeEntidade,
  });

  @override
  String toString() =>
      'DestinoUidLocalizado(idCroqui: $idCroqui, tipo: $tipoDestino, nome: $nomeEntidade)';
}

/// Localizador independente de entidades de escalada a partir de identificadores estáveis NanoID 14c.
///
/// Implementa a estratégia em cascata definida no documento oficial de arquitetura:
/// 1. Verificação no índice catalogado em memória (metadados disponíveis).
/// 2. Verificação nos croquis baixados no cache offline local.
/// 3. Verificação nos croquis em sessão online ativa.
class LocalizadorDestinoUid {
  final DatasetRepository datasetRepo;

  LocalizadorDestinoUid({required this.datasetRepo});

  /// Localiza o destino de um [uid] universal, retornando [DestinoUidLocalizado] ou `null` se não encontrado.
  Future<DestinoUidLocalizado?> localizar(String uid) async {
    final active = datasetRepo.activeDataset.value;

    // 1. Verifica se o UID corresponde a um Croqui no catálogo de metadados
    if (active != null) {
      for (final meta in active.metadadosDisponiveis) {
        if (meta.croquiUid == uid || meta.id == uid) {
          return DestinoUidLocalizado(
            noNavegacao: PicoNode(cragId: meta.id, parent: const HomeNode()),
            idCroqui: meta.id,
            tipoDestino: 'pico',
            nomeEntidade: meta.nome,
          );
        }
      }
    }

    // 2. Busca nos picos baixados no cache offline local
    if (active != null) {
      for (final p in active.picosBaixados) {
        if (p.pico != null && p.croqui != null) {
          final destino = _localizarEmPicoECroqui(
            idCroqui: p.id,
            pico: p.pico!,
            croqui: p.croqui!,
            uid: uid,
          );
          if (destino != null) return destino;
        }
      }
    }

    // 3. Busca nas sessões online ativas em memória
    final croquisOnline = datasetRepo.gerenciadorSessaoOnline.croquisEmMemoria;
    for (final entry in croquisOnline.entries) {
      final idCroqui = entry.key;
      final croqui = entry.value;
      for (final pico in croqui.picos) {
        final destino = _localizarEmPicoECroqui(
          idCroqui: idCroqui,
          pico: pico,
          croqui: croqui,
          uid: uid,
        );
        if (destino != null) return destino;
      }
    }

    return null;
  }

  DestinoUidLocalizado? _localizarEmPicoECroqui({
    required String idCroqui,
    required Pico pico,
    required Croqui croqui,
    required String uid,
  }) {
    // Verifica se o próprio croqui possui este UID
    if (croqui.hasUid() && croqui.uid == uid) {
      return DestinoUidLocalizado(
        noNavegacao: PicoNode(cragId: idCroqui, parent: const HomeNode()),
        idCroqui: idCroqui,
        tipoDestino: 'pico',
        nomeEntidade: pico.nome.isNotEmpty ? pico.nome : idCroqui,
      );
    }

    final resolver = DatasetResolver(pico: pico, croqui: croqui);
    final entidade = resolver.obterPorUid(uid);
    if (entidade == null) return null;

    final raiz = const HomeNode();
    final picoNode = PicoNode(cragId: idCroqui, parent: raiz);

    switch (entidade.tipo) {
      case TipoEntidadeResolved.escalada:
        if (entidade.escalada == null || entidade.setor == null) return null;
        NavNode paiDoSetor = picoNode;
        if (entidade.grupo != null) {
          paiDoSetor = GrupoNode(
            grupoNome: entidade.grupo!.nome,
            cragId: idCroqui,
            parent: picoNode,
          );
        }
        final setorNode = SetorNode(
          setorNome: entidade.setor!.nome,
          grupoNome: entidade.grupo?.nome,
          cragId: idCroqui,
          parent: paiDoSetor,
        );
        final viaNode = ViaNode(
          escaladaNome: entidade.escalada!.nome,
          setorNome: entidade.setor!.nome,
          grupoNome: entidade.grupo?.nome,
          cragId: idCroqui,
          parent: setorNode,
        );
        return DestinoUidLocalizado(
          noNavegacao: viaNode,
          idCroqui: idCroqui,
          tipoDestino: 'via',
          nomeEntidade: entidade.escalada!.nome,
        );

      case TipoEntidadeResolved.setor:
        if (entidade.setor == null) return null;
        NavNode paiDoSetor = picoNode;
        if (entidade.grupo != null) {
          paiDoSetor = GrupoNode(
            grupoNome: entidade.grupo!.nome,
            cragId: idCroqui,
            parent: picoNode,
          );
        }
        final setorNode = SetorNode(
          setorNome: entidade.setor!.nome,
          grupoNome: entidade.grupo?.nome,
          cragId: idCroqui,
          parent: paiDoSetor,
        );
        return DestinoUidLocalizado(
          noNavegacao: setorNode,
          idCroqui: idCroqui,
          tipoDestino: 'setor',
          nomeEntidade: entidade.setor!.nome,
        );

      case TipoEntidadeResolved.grupo:
        if (entidade.grupo == null) return null;
        final grupoNode = GrupoNode(
          grupoNome: entidade.grupo!.nome,
          cragId: idCroqui,
          parent: picoNode,
        );
        return DestinoUidLocalizado(
          noNavegacao: grupoNode,
          idCroqui: idCroqui,
          tipoDestino: 'grupo',
          nomeEntidade: entidade.grupo!.nome,
        );

      case TipoEntidadeResolved.botao:
        // Botões operam no contexto do pico
        return DestinoUidLocalizado(
          noNavegacao: picoNode,
          idCroqui: idCroqui,
          tipoDestino: 'pico',
          nomeEntidade: entidade.botao?.texto ?? idCroqui,
        );
    }
  }
}
