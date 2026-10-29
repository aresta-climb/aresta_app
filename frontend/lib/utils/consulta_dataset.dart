// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../aresta_api/proto/generated/croqui.pb.dart';

import '../navigation/arvore/nos_modais.dart';
import '../services/dataset/normalizador_croqui.dart';

/// Define o tipo discriminador da entidade indexada e resolvida pelo [DatasetResolver].
enum TipoEntidadeResolved {
  /// Entidade do tipo botão interativo ou textual do croqui.
  botao,

  /// Entidade do tipo grupo contendo múltiplos setores de escalada.
  grupo,

  /// Entidade do tipo setor contendo escaladas ou vias.
  setor,

  /// Entidade do tipo escalada (via esportiva, móvel, boulder, etc.).
  escalada,
}

/// Associa uma [referencia] específica ao [mapa] onde ela se encontra desenhada,
/// registrando opcionalmente os contextos de [setorContexto] e [grupoContexto] do mapa.
class ReferenciaNoMapa {
  /// O mapa que contém a referência visual.
  final Mapa mapa;

  /// A referência visual traçada no mapa.
  final Mapa_Referencia referencia;

  /// O setor ao qual o mapa pertence (nulo se for mapa do grupo ou mapa geral do pico).
  final Setor? setorContexto;

  /// O grupo ao qual o mapa pertence (nulo se for mapa geral do pico ou setor solto).
  final Grupo? grupoContexto;

  /// Cria uma nova associação imutável entre [mapa], [referencia] e seus contextos.
  const ReferenciaNoMapa({
    required this.mapa,
    required this.referencia,
    this.setorContexto,
    this.grupoContexto,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenciaNoMapa &&
          runtimeType == other.runtimeType &&
          mapa == other.mapa &&
          referencia == other.referencia &&
          setorContexto == other.setorContexto &&
          grupoContexto == other.grupoContexto;

  @override
  int get hashCode => Object.hash(mapa, referencia, setorContexto, grupoContexto);
}

/// Representa o resultado da resolução de uma entidade estrutural em tempo constante O(1).
///
/// Encapsula a entidade correspondente, seu [tipo], suas hierarquias ancestrais
/// (como [grupo] e [setor] quando aplicáveis) e todas as ocorrências visuais em
/// [referencias] pré-computadas na inicialização.
class ResolvedDataset {
  /// O tipo da entidade resolvida.
  final TipoEntidadeResolved tipo;

  /// Instância de [Botao], se [tipo] for [TipoEntidadeResolved.botao].
  final Botao? botao;

  /// Instância de [Grupo] resolvido ou ancestral de [setor]/[escalada].
  final Grupo? grupo;

  /// Instância de [Setor] resolvido ou ancestral de [escalada].
  final Setor? setor;

  /// Instância de [Escalada], se [tipo] for [TipoEntidadeResolved.escalada].
  final Escalada? escalada;

  /// Ocorrências visuais em mapas onde esta entidade é desenhada ou apontada.
  final List<ReferenciaNoMapa> referencias;

  /// Cria um [ResolvedDataset] imutável.
  ResolvedDataset({
    required this.tipo,
    this.botao,
    this.grupo,
    this.setor,
    this.escalada,
    List<ReferenciaNoMapa>? referencias,
  }) : referencias = List.unmodifiable(referencias ?? const []);

  /// Retorna o nome amigável da entidade resolvida.
  String get nome {
    switch (tipo) {
      case TipoEntidadeResolved.botao:
        return botao?.texto ?? '';
      case TipoEntidadeResolved.grupo:
        return grupo?.nome ?? '';
      case TipoEntidadeResolved.setor:
        return setor?.nome ?? '';
      case TipoEntidadeResolved.escalada:
        return escalada?.nome ?? '';
    }
  }

  /// Resolve a lista de [CarrosselItemData] para alimentar diretamente o carrossel unificado da escalada.
  ///
  /// Garante que mapas próprios locais da escalada venham antes e sem foco de ponto (`initialSelectedId: null`),
  /// seguidos pelos mapas onde a escalada é referenciada, com o primeiro UID de ponto selecionado.
  List<CarrosselItemData> resolverCarrosselUnificado() {
    if (escalada == null) return const [];
    final escaladaNome = escalada!.nome;

    final itensProprios = escalada!.mapas
        .where((m) =>
            m.caminhoImagemMapa.isNotEmpty &&
            m.larguraMapa > 0 &&
            m.alturaMapa > 0)
        .map(
          (m) => CarrosselItemData(
            mapaCaminhoImagem: m.caminhoImagemMapa,
            setorContextNome: setor?.nome,
            grupoContextNome: grupo?.nome,
            escaladaContextNome: escaladaNome,
            initialSelectedId: null,
          ),
        );

    final itensReferencias = referencias
        .where((r) =>
            r.mapa.caminhoImagemMapa.isNotEmpty &&
            r.mapa.larguraMapa > 0 &&
            r.mapa.alturaMapa > 0)
        .map(
          (r) => CarrosselItemData(
            mapaCaminhoImagem: r.mapa.caminhoImagemMapa,
            setorContextNome: r.setorContexto?.nome,
            grupoContextNome: r.grupoContexto?.nome,
            escaladaContextNome: escaladaNome,
            initialSelectedId: r.referencia.pontosUids.isNotEmpty
                ? r.referencia.pontosUids.first
                : null,
          ),
        );

    return [...itensProprios, ...itensReferencias];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedDataset &&
          runtimeType == other.runtimeType &&
          tipo == other.tipo &&
          botao == other.botao &&
          grupo == other.grupo &&
          setor == other.setor &&
          escalada == other.escalada &&
          _compararListas(referencias, other.referencias);

  @override
  int get hashCode => Object.hash(
        tipo,
        botao,
        grupo,
        setor,
        escalada,
        referencias.length,
      );

  static bool _compararListas(
    List<ReferenciaNoMapa> a,
    List<ReferenciaNoMapa> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Extensão utilitária para extração do nome amigável de uma [Escalada].
extension EscaladaExtension on Escalada {
  /// Retorna o nome da via ou problema conforme sua modalidade.
  String get nome {
    switch (whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        return viaEsportiva.nome;
      case Escalada_Tipo.viaMovel:
        return viaMovel.nome;
      case Escalada_Tipo.boulder:
        return boulder.nome;
      case Escalada_Tipo.viaMultiplasEnfiadas:
        return viaMultiplasEnfiadas.nome;
      case Escalada_Tipo.highline:
        return highline.nome;
      default:
        return '';
    }
  }
}

/// Resolvedor e catálogo relacional em tempo constante O(1) de entidades de croqui por UIDs.
///
/// Indexa exclusivamente as entidades do quarteto estrutural ([Botao], [Grupo],
/// [Setor] e [Escalada]) em uma única passada durante a inicialização, associando
/// diretamente as ocorrências visuais de mapas em cada [ResolvedDataset].
class DatasetResolver {
  /// Cache de referências fracas que associa cada instância de [Pico] em memória
  /// à sua instância já indexada de [DatasetResolver], evitando reindexações O(N)
  /// repetidas entre transições de página e referências de mapas.
  static final Expando<DatasetResolver> _cachePorPico =
      Expando<DatasetResolver>('DatasetResolverPorPico');

  final Map<String, ResolvedDataset> _entidadesPorUid;
  final bool _possuiBotoesIndexados;

  /// Retorna uma instância indexada em O(N) (ou reutilizada em O(1) via cache de [Expando])
  /// a partir de um [pico] e opcionalmente seu [croqui] pai ou [botoes].
  factory DatasetResolver({
    required Pico pico,
    Croqui? croqui,
    List<Botao>? botoes,
  }) {
    final listaBotoes = botoes ?? croqui?.botoes ?? const <Botao>[];
    final temNovosBotoes = listaBotoes.isNotEmpty;
    final existente = _cachePorPico[pico];
    if (existente != null &&
        (!temNovosBotoes || existente._possuiBotoesIndexados)) {
      return existente;
    }

    final novo = DatasetResolver._interno(
      pico: pico,
      croqui: croqui,
      botoes: botoes,
      possuiBotoesIndexados: temNovosBotoes,
    );
    _cachePorPico[pico] = novo;
    return novo;
  }

  DatasetResolver._interno({
    required Pico pico,
    Croqui? croqui,
    List<Botao>? botoes,
    required bool possuiBotoesIndexados,
  })  : _entidadesPorUid =
            _indexarComNormalizacao(pico, croqui: croqui, botoes: botoes),
        _possuiBotoesIndexados = possuiBotoesIndexados;

  static Map<String, ResolvedDataset> _indexarComNormalizacao(
    Pico pico, {
    Croqui? croqui,
    List<Botao>? botoes,
  }) {
    NormalizadorCroqui.normalizarPico(pico);
    if (croqui != null) {
      NormalizadorCroqui.normalizarCroqui(croqui);
    }
    return _indexar(pico, croqui: croqui, botoes: botoes);
  }

  /// Retorna o [ResolvedDataset] correspondente ao [uid], ou nulo se não encontrado.
  ResolvedDataset? obterPorUid(String uid) => _entidadesPorUid[uid];

  /// Atalho para [obterPorUid].
  ResolvedDataset? operator [](String uid) => _entidadesPorUid[uid];

  /// Localiza a entidade resolvida buscando pela hierarquia de nomes como fallback retrocompatível.
  ResolvedDataset? buscarPorNome({
    String? grupoNome,
    String? setorNome,
    String? escaladaNome,
  }) {
    for (final resolved in _entidadesPorUid.values) {
      if (escaladaNome != null) {
        if (resolved.tipo == TipoEntidadeResolved.escalada &&
            resolved.escalada?.nome == escaladaNome &&
            (setorNome == null || resolved.setor?.nome == setorNome) &&
            (grupoNome == null || resolved.grupo?.nome == grupoNome)) {
          return resolved;
        }
      } else if (setorNome != null) {
        if (resolved.tipo == TipoEntidadeResolved.setor &&
            resolved.setor?.nome == setorNome &&
            (grupoNome == null || resolved.grupo?.nome == grupoNome)) {
          return resolved;
        }
      } else if (grupoNome != null) {
        if (resolved.tipo == TipoEntidadeResolved.grupo &&
            resolved.grupo?.nome == grupoNome) {
          return resolved;
        }
      }
    }
    return null;
  }

  /// Resolve a entidade referenciada por [referencia] utilizando seu `alvoUid`.
  ResolvedDataset? resolverReferencia(Mapa_Referencia referencia) {
    if (referencia.alvoUid.isEmpty) return null;
    return _entidadesPorUid[referencia.alvoUid];
  }

  /// Resolve uma [referencia] estaticamente a partir de um [pico].
  ///
  /// Lança [Exception] caso a referência não contenha `alvoUid` ou não seja encontrada.
  static ResolvedDataset resolveReferencia({
    required Pico pico,
    required Mapa_Referencia referencia,
    Croqui? croqui,
    String? defaultGrupoNome,
    String? defaultSetorNome,
  }) {
    if (referencia.alvoUid.isEmpty) {
      throw Exception('Reference is empty');
    }

    final resolver = DatasetResolver(pico: pico, croqui: croqui);
    final resolved = resolver.obterPorUid(referencia.alvoUid);

    if (resolved == null) {
      throw Exception('Referenced entity not found for uid: ${referencia.alvoUid}');
    }

    return resolved;
  }

  /// Resolve entidades por nome para suporte retrocompatível da árvore de navegação reativa.
  static ResolvedDataset resolve({
    required Pico pico,
    String? grupoNome,
    String? setorNome,
    String? escaladaNome,
  }) {
    Grupo? matchedGrupo;
    Setor? matchedSetor;
    Escalada? matchedEscalada;

    if (grupoNome != null) {
      matchedGrupo = pico.setoresOuGrupos
          .where(
            (sg) =>
                sg.whichTipo() == SetorOuGrupo_Tipo.grupo &&
                sg.grupo.hasConteudo(),
          )
          .map<Grupo?>((sg) => sg.grupo.conteudo)
          .firstWhere((g) => g?.nome == grupoNome, orElse: () => null);
    }

    if (setorNome != null) {
      if (matchedGrupo != null) {
        matchedSetor = matchedGrupo.setores
            .where((s) => s.hasConteudo())
            .map<Setor?>((s) => s.conteudo)
            .firstWhere((s) => s?.nome == setorNome, orElse: () => null);
      } else {
        matchedSetor = pico.setoresOuGrupos
            .where(
              (sg) =>
                  sg.whichTipo() == SetorOuGrupo_Tipo.setor &&
                  sg.setor.hasConteudo(),
            )
            .map<Setor?>((sg) => sg.setor.conteudo)
            .firstWhere((s) => s?.nome == setorNome, orElse: () => null);

        if (matchedSetor == null && grupoNome == null) {
          for (final sg in pico.setoresOuGrupos) {
            if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo &&
                sg.grupo.hasConteudo()) {
              matchedSetor = sg.grupo.conteudo.setores
                  .where((s) => s.hasConteudo())
                  .map<Setor?>((s) => s.conteudo)
                  .firstWhere((s) => s?.nome == setorNome, orElse: () => null);

              if (matchedSetor != null) {
                matchedGrupo = sg.grupo.conteudo;
                break;
              }
            }
          }
        }
      }
    }

    if (grupoNome != null && matchedGrupo == null) {
      throw Exception('Grupo not found: "$grupoNome"');
    }

    if (setorNome != null && matchedSetor == null) {
      throw Exception(
        'Setor not found: "$setorNome" (in grupo: "${grupoNome ?? 'global/all'}")',
      );
    }

    if (escaladaNome != null && matchedSetor != null) {
      matchedEscalada = matchedSetor.escaladas
          .map<Escalada?>((e) => e)
          .firstWhere((e) => e?.nome == escaladaNome, orElse: () => null);
    }

    if (escaladaNome != null && matchedEscalada == null) {
      throw Exception('Escalada not found');
    }

    final tipo = matchedEscalada != null
        ? TipoEntidadeResolved.escalada
        : (matchedSetor != null
            ? TipoEntidadeResolved.setor
            : TipoEntidadeResolved.grupo);

    return ResolvedDataset(
      tipo: tipo,
      grupo: matchedGrupo,
      setor: matchedSetor,
      escalada: matchedEscalada,
    );
  }

  /// Realiza a indexação única de todas as entidades e referências de mapas em tempo O(N).
  static Map<String, ResolvedDataset> _indexar(
    Pico pico, {
    Croqui? croqui,
    List<Botao>? botoes,
  }) {
    final mapaReferencias = <String, List<ReferenciaNoMapa>>{};

    void coletarReferenciasDeMapas(
      List<Mapa> mapas, {
      Setor? setorContexto,
      Grupo? grupoContexto,
    }) {
      for (final mapa in mapas) {
        for (final ref in mapa.referencias) {
          if (ref.alvoUid.isNotEmpty) {
            mapaReferencias
                .putIfAbsent(ref.alvoUid, () => [])
                .add(ReferenciaNoMapa(
                  mapa: mapa,
                  referencia: ref,
                  setorContexto: setorContexto,
                  grupoContexto: grupoContexto,
                ));
          }
        }
      }
    }

    // Coleta mapas gerais
    if (pico.hasMapasGerais() && pico.mapasGerais.hasConteudo()) {
      coletarReferenciasDeMapas(pico.mapasGerais.conteudo.mapas);
    }

    // Coleta mapas de grupos, setores e escaladas
    for (final sg in pico.setoresOuGrupos) {
      if (sg.hasGrupo() && sg.grupo.hasConteudo()) {
        final grupo = sg.grupo.conteudo;
        coletarReferenciasDeMapas(grupo.mapas, grupoContexto: grupo);

        for (final s in grupo.setores) {
          if (s.hasConteudo()) {
            final setor = s.conteudo;
            coletarReferenciasDeMapas(
              setor.mapas,
              setorContexto: setor,
              grupoContexto: grupo,
            );
            for (final esc in setor.escaladas) {
              coletarReferenciasDeMapas(
                esc.mapas,
                setorContexto: setor,
                grupoContexto: grupo,
              );
            }
          }
        }
      } else if (sg.hasSetor() && sg.setor.hasConteudo()) {
        final setor = sg.setor.conteudo;
        coletarReferenciasDeMapas(setor.mapas, setorContexto: setor);
        for (final esc in setor.escaladas) {
          coletarReferenciasDeMapas(esc.mapas, setorContexto: setor);
        }
      }
    }

    final resultado = <String, ResolvedDataset>{};

    // 1. Indexação de botões
    final listaBotoes = botoes ?? croqui?.botoes ?? const <Botao>[];
    for (final botao in listaBotoes) {
      if (botao.uid.isNotEmpty) {
        resultado[botao.uid] = ResolvedDataset(
          tipo: TipoEntidadeResolved.botao,
          botao: botao,
          referencias: mapaReferencias[botao.uid],
        );
      }
    }

    // 2. Indexação de grupos, setores e escaladas
    for (final sg in pico.setoresOuGrupos) {
      if (sg.hasGrupo() && sg.grupo.hasConteudo()) {
        final grupo = sg.grupo.conteudo;
        if (grupo.uid.isNotEmpty) {
          resultado[grupo.uid] = ResolvedDataset(
            tipo: TipoEntidadeResolved.grupo,
            grupo: grupo,
            referencias: mapaReferencias[grupo.uid],
          );
        }

        for (final s in grupo.setores) {
          if (s.hasConteudo()) {
            final setor = s.conteudo;
            if (setor.uid.isNotEmpty) {
              resultado[setor.uid] = ResolvedDataset(
                tipo: TipoEntidadeResolved.setor,
                grupo: grupo,
                setor: setor,
                referencias: mapaReferencias[setor.uid],
              );
            }

            for (final esc in setor.escaladas) {
              if (esc.uid.isNotEmpty) {
                resultado[esc.uid] = ResolvedDataset(
                  tipo: TipoEntidadeResolved.escalada,
                  grupo: grupo,
                  setor: setor,
                  escalada: esc,
                  referencias: mapaReferencias[esc.uid],
                );
              }
            }
          }
        }
      } else if (sg.hasSetor() && sg.setor.hasConteudo()) {
        final setor = sg.setor.conteudo;
        if (setor.uid.isNotEmpty) {
          resultado[setor.uid] = ResolvedDataset(
            tipo: TipoEntidadeResolved.setor,
            setor: setor,
            referencias: mapaReferencias[setor.uid],
          );
        }

        for (final esc in setor.escaladas) {
          if (esc.uid.isNotEmpty) {
            resultado[esc.uid] = ResolvedDataset(
              tipo: TipoEntidadeResolved.escalada,
              setor: setor,
              escalada: esc,
              referencias: mapaReferencias[esc.uid],
            );
          }
        }
      }
    }

    return resultado;
  }
}
