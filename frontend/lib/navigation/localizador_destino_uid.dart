// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../aresta_api/proto/generated/croqui.pb.dart';
import '../services/http/sync_service.dart';
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
/// 4. Verificação no banco SQLite local (`catalogo.db`) com carregamento sob demanda do croqui.
class LocalizadorDestinoUid {
  final DatasetRepository datasetRepo;
  final SyncService? syncService;

  LocalizadorDestinoUid({
    required this.datasetRepo,
    this.syncService,
  });

  Future<String?> _obterIdSlugLocal(String uid) async {
    final active = datasetRepo.activeDataset.value;
    if (active != null) {
      for (final meta in active.metadadosDisponiveis) {
        if (meta.croquiUid == uid || meta.id == uid) {
          return meta.id;
        }
      }
    }
    return datasetRepo.repositorioCatalogo.obterIdSlugPorUid(uid);
  }

  /// Localiza o destino de um [uid] universal, retornando [DestinoUidLocalizado] ou `null` se não encontrado.
  ///
  /// Quando [abrirMapa] é `true`, envolve o nó da entidade localizada como `parent` de um
  /// [MapasCarrosselNode] caso a entidade possua mapas válidos, ou realiza fallback gracioso
  /// para o nó principal caso contrário.
  Future<DestinoUidLocalizado?> localizar(
    String uid, {
    bool abrirMapa = false,
  }) async {
    final active = datasetRepo.activeDataset.value;

    // 1. Busca nos picos baixados no cache offline local
    if (active != null) {
      for (final p in active.picosBaixados) {
        if (p.pico != null && p.croqui != null) {
          final destino = _localizarEmPicoECroqui(
            idCroqui: p.id,
            pico: p.pico!,
            croqui: p.croqui!,
            uid: uid,
            abrirMapa: abrirMapa,
          );
          if (destino != null) return destino;
        }
      }
    }

    // 2. Busca nas sessões online ativas em memória
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
          abrirMapa: abrirMapa,
        );
        if (destino != null) return destino;
      }
    }

    // 3. Descobre o idSlug no índice de metadados em memória ou no catálogo SQLite (catalogo.db)
    //    e carrega o croqui sob demanda na sessão online antes de retornar o nó de navegação
    var idSlug = await _obterIdSlugLocal(uid);
    var indiceJaSincronizado = false;

    if (idSlug == null) {
      final sync = syncService ?? SyncService.instance;
      if (sync != null &&
          (syncService != null || identical(sync.datasetRepository, datasetRepo))) {
        await sync.syncIndex();
        indiceJaSincronizado = true;
        idSlug = await _obterIdSlugLocal(uid);
      }
    }

    if (idSlug != null) {
      final croqui = await datasetRepo.getCroqui(
        idSlug,
        indiceJaSincronizado: indiceJaSincronizado,
      );
      if (croqui != null) {
        for (final pico in croqui.picos) {
          final destino = _localizarEmPicoECroqui(
            idCroqui: idSlug,
            pico: pico,
            croqui: croqui,
            uid: uid,
            abrirMapa: abrirMapa,
          );
          if (destino != null) return destino;
        }
      }
    }

    return null;
  }

  static bool _mapaValido(Mapa m) =>
      m.caminhoImagemMapa.isNotEmpty && m.larguraMapa > 0 && m.alturaMapa > 0;

  static NavNode _envolverComMapaSeSolicitado(
    NavNode noBase,
    String idCroqui,
    List<CarrosselItemData> itensMapa,
    bool abrirMapa,
  ) {
    if (!abrirMapa || itensMapa.isEmpty) {
      return noBase;
    }
    return MapasCarrosselNode(
      cragId: idCroqui,
      initialIndex: 0,
      mapas: itensMapa,
      parent: noBase,
    );
  }

  DestinoUidLocalizado? _localizarEmPicoECroqui({
    required String idCroqui,
    required Pico pico,
    required Croqui croqui,
    required String uid,
    required bool abrirMapa,
  }) {
    // Verifica se o próprio croqui possui este UID (ou idCroqui)
    if ((croqui.hasUid() && croqui.uid == uid) || idCroqui == uid) {
      final picoNode = PicoNode(cragId: idCroqui, parent: const HomeNode());
      final itensMapa = (pico.hasMapasGerais() && pico.mapasGerais.hasConteudo())
          ? pico.mapasGerais.conteudo.mapas
              .where(_mapaValido)
              .map(
                (m) => CarrosselItemData(
                  mapaCaminhoImagem: m.caminhoImagemMapa,
                ),
              )
              .toList()
          : const <CarrosselItemData>[];
      return DestinoUidLocalizado(
        noNavegacao: _envolverComMapaSeSolicitado(
          picoNode,
          idCroqui,
          itensMapa,
          abrirMapa,
        ),
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
          noNavegacao: _envolverComMapaSeSolicitado(
            viaNode,
            idCroqui,
            entidade.resolverCarrosselUnificado(),
            abrirMapa,
          ),
          idCroqui: idCroqui,
          tipoDestino: 'via',
          nomeEntidade: entidade.escalada!.nome,
        );

      case TipoEntidadeResolved.setor:
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
        final itensMapa = entidade.setor!.mapas
            .where(_mapaValido)
            .map(
              (m) => CarrosselItemData(
                mapaCaminhoImagem: m.caminhoImagemMapa,
                setorContextNome: entidade.setor!.nome,
                grupoContextNome: entidade.grupo?.nome,
              ),
            )
            .toList();
        return DestinoUidLocalizado(
          noNavegacao: _envolverComMapaSeSolicitado(
            setorNode,
            idCroqui,
            itensMapa,
            abrirMapa,
          ),
          idCroqui: idCroqui,
          tipoDestino: 'setor',
          nomeEntidade: entidade.setor!.nome,
        );

      case TipoEntidadeResolved.grupo:
        final grupoNode = GrupoNode(
          grupoNome: entidade.grupo!.nome,
          cragId: idCroqui,
          parent: picoNode,
        );
        final itensMapa = entidade.grupo!.mapas
            .where(_mapaValido)
            .map(
              (m) => CarrosselItemData(
                mapaCaminhoImagem: m.caminhoImagemMapa,
                grupoContextNome: entidade.grupo!.nome,
              ),
            )
            .toList();
        return DestinoUidLocalizado(
          noNavegacao: _envolverComMapaSeSolicitado(
            grupoNode,
            idCroqui,
            itensMapa,
            abrirMapa,
          ),
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

