// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/dataset_resolver.dart';

/// Classe auxiliar para converter Referências string-based e dados reais (Protobuf)
/// em uma chave de hashing universal. Essencial para construir mapas globais e
/// resolver O(1) de onde um setor/grupo/escalada se encontra em qualquer mapa do pico.
class ReferenceKey {
  final String? grupoNome;
  final String? setorNome;
  final String? escaladaNome;

  const ReferenceKey({this.grupoNome, this.setorNome, this.escaladaNome});

  /// Constrói uma `ReferenceKey` a partir de um [ResolvedDataset] já estabilizado,
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

/// Representa um Mapa que foi descoberto na hierarquia (Geral, de Grupo ou de Setor)
/// contendo todo o contexto `setorContext` e `grupoContext` apropriado para navegação e breadcrumbs.
class IndexedMap {
  /// O mapa de destino em que a referência foi encontrada
  final Mapa? mapa;

  /// O setor (se existente) que engloba esse mapa
  final Setor? setorContext;

  /// O grupo (se existente) que engloba esse mapa
  final Grupo? grupoContext;

  /// ID da referência (ponto SVG) encontrada dentro do mapa.
  final String referencedId;

  const IndexedMap({
    required this.mapa,
    this.setorContext,
    this.grupoContext,
    required this.referencedId,
  });
}

/// Um Índice Global pré-computado construído a partir de um [Pico].
/// Este índice atravessa a hierarquia inteira do arquivo e constrói uma tabela hash
/// relacionando cada [ReferenceKey] à lista de [IndexedMap]s onde tal referência aparece.
/// Evita loops pesados em O(n^3) no frontend folha (ex: `via_functions`) centralizando a lógica.
class CroquiMapIndex {
  final Map<ReferenceKey, List<IndexedMap>> _index = {};

  /// Analisa todo o pico recebido e constrói o mapa referencial de mapas.
  CroquiMapIndex(Pico pico) {
    // 1. Mapas do Pico (Globais)
    if (pico.hasMapasGerais() && pico.mapasGerais.hasConteudo()) {
      _indexMapas(pico, pico.mapasGerais.conteudo.mapas, null, null);
    }

    // 2. Mapas de Grupos e Setores
    for (var sg in pico.setoresOuGrupos) {
      if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
        final grupo = sg.grupo.conteudo;
        _indexMapas(pico, grupo.mapas, null, grupo);

        for (var s in grupo.setores) {
          if (s.hasConteudo()) {
            _indexMapas(pico, s.conteudo.mapas, s.conteudo, grupo);
          }
        }
      } else if (sg.whichTipo() == SetorOuGrupo_Tipo.setor &&
          sg.setor.hasConteudo()) {
        final setor = sg.setor.conteudo;
        _indexMapas(pico, setor.mapas, setor, null);
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
            );

            _index.putIfAbsent(key, () => []).add(indexedMap);
          }
        } catch (e) {
          // Se não resolveu, a referência está quebrada, então não indexamos
        }
      }
    }
  }

  List<IndexedMap> getMapasForReference(ResolvedDataset resolved) {
    if (resolved.escalada == null) return [];
    final key = ReferenceKey.fromResolved(resolved);
    return _index[key] ?? [];
  }
}
