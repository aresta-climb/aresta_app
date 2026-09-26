// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/navigation/arvore/modal_nodes.dart';
import 'package:frontend/utils/dataset_resolver.dart';

/// Classe auxiliar para converter Referências string-based e dados reais (Protobuf)
/// em uma chave de hashing universal. Essencial para construir mapas globais e
/// resolver em O(1) onde um setor/grupo/escalada se encontra em qualquer mapa do pico.
class ReferenceKey {
  final String? grupoNome;
  final String? setorNome;
  final String? escaladaNome;

  const ReferenceKey({this.grupoNome, this.setorNome, this.escaladaNome});

  /// Constrói uma [ReferenceKey] a partir de um [ResolvedDataset] já estabilizado,
  /// utilizando os nomes canônicos de cada camada da hierarquia.
  factory ReferenceKey.fromResolved(ResolvedDataset resolved) {
    return ReferenceKey(
      grupoNome: resolved.grupo?.nome,
      setorNome: resolved.setor?.nome,
      escaladaNome: resolved.escalada?.nome,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceKey &&
          runtimeType == other.runtimeType &&
          grupoNome == other.grupoNome &&
          setorNome == other.setorNome &&
          escaladaNome == other.escaladaNome;

  @override
  int get hashCode =>
      (grupoNome?.hashCode ?? 0) ^
      (setorNome?.hashCode ?? 0) ^
      (escaladaNome?.hashCode ?? 0);
}

/// Representa um Mapa descoberto na hierarquia (Geral, Grupo, Setor ou Próprio de Escalada),
/// contendo os contextos `setorContext` e `grupoContext` apropriados para navegação e breadcrumbs.
class IndexedMap {
  /// O mapa de destino em que a referência foi encontrada ou o mapa próprio da escalada.
  final Mapa? mapa;

  /// O setor (se existente) que engloba esse mapa.
  final Setor? setorContext;

  /// O grupo (se existente) que engloba esse mapa.
  final Grupo? grupoContext;

  /// ID da referência (ponto SVG) encontrada dentro do mapa. Vazio para mapas próprios.
  final String referencedId;

  /// Indica se este mapa é próprio/local da escalada (true) ou referenciado em setor/grupo/pico (false).
  final bool ehMapaProprio;

  const IndexedMap({
    required this.mapa,
    this.setorContext,
    this.grupoContext,
    required this.referencedId,
    this.ehMapaProprio = false,
  });
}

/// Um Índice Global pré-computado construído a partir de um [Pico].
///
/// Este índice atravessa a hierarquia inteira do croqui e constrói tabelas hash em O(1):
/// 1. Tabela de mapas referenciados (onde cada escalada/setor aparece em panorâmicas de pico/grupo/setor).
/// 2. Tabela de mapas locais próprios de cada escalada (`escalada.mapas`).
///
/// Evita loops pesados em O(n^3) no frontend folha (ex: `via_functions`) centralizando a lógica.
class CroquiMapIndex {
  final Map<ReferenceKey, List<IndexedMap>> _index = {};
  final Map<ReferenceKey, List<IndexedMap>> _mapasProprios = {};

  /// Analisa todo o pico recebido e constrói o mapa referencial de mapas e os mapas próprios.
  CroquiMapIndex(Pico pico) {
    // 1. Mapas do Pico (Globais)
    if (pico.hasMapasGerais() && pico.mapasGerais.hasConteudo()) {
      _indexMapas(pico, pico.mapasGerais.conteudo.mapas, null, null);
    }

    // 2. Mapas de Grupos e Setores, além de Mapas Próprios de Escaladas
    for (var sg in pico.setoresOuGrupos) {
      if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
        final grupo = sg.grupo.conteudo;
        _indexMapas(pico, grupo.mapas, null, grupo);

        for (var s in grupo.setores) {
          if (s.hasConteudo()) {
            final setor = s.conteudo;
            _indexMapas(pico, setor.mapas, setor, grupo);
            _indexMapasEscaladas(setor.escaladas, setor, grupo);
          }
        }
      } else if (sg.whichTipo() == SetorOuGrupo_Tipo.setor &&
          sg.setor.hasConteudo()) {
        final setor = sg.setor.conteudo;
        _indexMapas(pico, setor.mapas, setor, null);
        _indexMapasEscaladas(setor.escaladas, setor, null);
      }
    }
  }

  void _indexMapas(Pico pico, List<Mapa> mapas, Setor? setor, Grupo? grupo) {
    for (var mapa in mapas) {
      for (var ref in mapa.referencias) {
        try {
          final resolved = DatasetResolver.resolveReferencia(
            pico: pico,
            referencia: ref,
            defaultGrupoNome: grupo?.nome,
            defaultSetorNome: setor?.nome,
          );

          if (resolved.escalada != null) {
            final key = ReferenceKey.fromResolved(resolved);
            final indexedMap = IndexedMap(
              mapa: mapa,
              setorContext: setor,
              grupoContext: grupo,
              referencedId: ref.ids.isNotEmpty ? ref.ids.first : '',
              ehMapaProprio: false,
            );

            _index.putIfAbsent(key, () => []).add(indexedMap);
          }
        } catch (e) {
          // Se não resolveu, a referência está quebrada, então não indexamos
        }
      }
    }
  }

  void _indexMapasEscaladas(List<Escalada> escaladas, Setor setor, Grupo? grupo) {
    for (var escalada in escaladas) {
      if (escalada.mapas.isNotEmpty) {
        final key = ReferenceKey(
          grupoNome: grupo?.nome,
          setorNome: setor.nome,
          escaladaNome: escalada.nome,
        );
        for (var mapa in escalada.mapas) {
          final indexedMap = IndexedMap(
            mapa: mapa,
            setorContext: setor,
            grupoContext: grupo,
            referencedId: '',
            ehMapaProprio: true,
          );
          _mapasProprios.putIfAbsent(key, () => []).add(indexedMap);
        }
      }
    }
  }

  /// Retorna os mapas próprios/locais cadastrados diretamente na escalada.
  List<IndexedMap> getMapasProprios(ResolvedDataset resolved) {
    if (resolved.escalada == null) return [];
    final key = ReferenceKey.fromResolved(resolved);
    return _mapasProprios[key] ?? [];
  }

  /// Indica se a escalada possui mapas próprios/locais cadastrados.
  bool temMapasProprios(ResolvedDataset resolved) {
    return getMapasProprios(resolved).isNotEmpty;
  }

  /// Retorna os mapas de setor, grupo ou pico onde a escalada foi referenciada.
  List<IndexedMap> getMapasForReference(ResolvedDataset resolved) {
    if (resolved.escalada == null) return [];
    final key = ReferenceKey.fromResolved(resolved);
    return _index[key] ?? [];
  }

  /// Retorna a lista completa unificada de mapas para a escalada:
  /// Primeiro os mapas próprios locais da escalada, seguidos pelos mapas onde ela é referenciada.
  List<IndexedMap> getTodosMapas(ResolvedDataset resolved) {
    return [
      ...getMapasProprios(resolved),
      ...getMapasForReference(resolved),
    ];
  }

  /// Resolve a lista de [CarrosselItemData] para alimentar diretamente o carrossel unificado.
  ///
  /// Garante que mapas próprios venham antes e sem foco de POI (`initialSelectedId: null`),
  /// enquanto mapas de setor/grupo carregam o traçado correspondente pré-focado.
  List<CarrosselItemData> resolverCarrosselUnificado(ResolvedDataset resolved) {
    if (resolved.escalada == null) return [];
    final todos = getTodosMapas(resolved);
    final escaladaNome = resolved.escalada!.nome;

    return todos
        .where((im) => im.mapa != null && im.mapa!.caminhoImagemMapa.isNotEmpty)
        .map(
          (im) => CarrosselItemData(
            mapaCaminhoImagem: im.mapa!.caminhoImagemMapa,
            setorContextNome: im.setorContext?.nome,
            grupoContextNome: im.grupoContext?.nome,
            escaladaContextNome: escaladaNome,
            initialSelectedId: im.referencedId.isNotEmpty ? im.referencedId : null,
          ),
        )
        .toList();
  }
}
