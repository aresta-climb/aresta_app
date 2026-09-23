// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'indexador_escaladas.dart';
import '../view_functions/pico_functions.dart';
import '../view_functions/common_functions.dart';

/// Define uma faixa de grau rápida pré-configurada para seleção imediata.
class FaixaRapidaGrau {
  /// Identificador único da faixa (ex: 'ate_5', '6_a_7c').
  final String id;

  /// Rótulo amigável para exibição em botão/chip (ex: "Até 5º", "6º a 7c").
  final String rotulo;

  /// Valor numérico mínimo correspondente ao peso da graduação.
  final int minGrauValor;

  /// Valor numérico máximo correspondente ao peso da graduação.
  final int maxGrauValor;

  const FaixaRapidaGrau({
    required this.id,
    required this.rotulo,
    required this.minGrauValor,
    required this.maxGrauValor,
  });
}

/// Faixas pré-configuradas de graduação para vias e boulders.
abstract class FaixasPredefinidasGrau {
  // --- Vias (Escala Brasileira) ---
  static const viaAte5 = FaixaRapidaGrau(
    id: 'via_ate_5',
    rotulo: 'Até 5º',
    minGrauValor: 0,
    maxGrauValor: 605, // 5ºsup
  );

  static const via6a7c = FaixaRapidaGrau(
    id: 'via_6_a_7c',
    rotulo: '6º a 7c',
    minGrauValor: 606,
    maxGrauValor: 835, // 7c
  );

  static const via8a9c = FaixaRapidaGrau(
    id: 'via_8a_a_9c',
    rotulo: '8a a 9c',
    minGrauValor: 836,
    maxGrauValor: 1035, // 9c
  );

  static const via10aPlus = FaixaRapidaGrau(
    id: 'via_10a_plus',
    rotulo: '10a+',
    minGrauValor: 1036,
    maxGrauValor: 9997,
  );

  static const List<FaixaRapidaGrau> faixasVias = [
    viaAte5,
    via6a7c,
    via8a9c,
    via10aPlus,
  ];

  // --- Boulders (Escala V) ---
  static const boulderV0aV3 = FaixaRapidaGrau(
    id: 'boulder_v0_v3',
    rotulo: 'V0 a V3',
    minGrauValor: 0,
    maxGrauValor: 400,
  );

  static const boulderV4aV6 = FaixaRapidaGrau(
    id: 'boulder_v4_v6',
    rotulo: 'V4 a V6',
    minGrauValor: 401,
    maxGrauValor: 700,
  );

  static const boulderV7aV9 = FaixaRapidaGrau(
    id: 'boulder_v7_v9',
    rotulo: 'V7 a V9',
    minGrauValor: 701,
    maxGrauValor: 1000,
  );

  static const boulderV10Plus = FaixaRapidaGrau(
    id: 'boulder_v10_plus',
    rotulo: 'V10+',
    minGrauValor: 1001,
    maxGrauValor: 9997,
  );

  static const List<FaixaRapidaGrau> faixasBoulders = [
    boulderV0aV3,
    boulderV4aV6,
    boulderV7aV9,
    boulderV10Plus,
  ];
}

/// Representa uma opção individual de grau para seletores e menus suspensos.
class OpcaoGrauFiltro {
  final String rotulo;
  final int valor;

  const OpcaoGrauFiltro({required this.rotulo, required this.valor});
}

/// Lista de graus disponíveis para seleção detalhada.
abstract class OpcoesGrau {
  static const List<OpcaoGrauFiltro> grausVia = [
    OpcaoGrauFiltro(rotulo: '1º', valor: 200),
    OpcaoGrauFiltro(rotulo: '2º', valor: 300),
    OpcaoGrauFiltro(rotulo: '3º', valor: 400),
    OpcaoGrauFiltro(rotulo: '4º', valor: 500),
    OpcaoGrauFiltro(rotulo: '5º', valor: 600),
    OpcaoGrauFiltro(rotulo: '5ºsup', valor: 605),
    OpcaoGrauFiltro(rotulo: '6º', valor: 700),
    OpcaoGrauFiltro(rotulo: '6ºsup', valor: 705),
    OpcaoGrauFiltro(rotulo: '7a', valor: 810),
    OpcaoGrauFiltro(rotulo: '7b', valor: 820),
    OpcaoGrauFiltro(rotulo: '7c', valor: 830),
    OpcaoGrauFiltro(rotulo: '8a', valor: 910),
    OpcaoGrauFiltro(rotulo: '8b', valor: 920),
    OpcaoGrauFiltro(rotulo: '8c', valor: 930),
    OpcaoGrauFiltro(rotulo: '9a', valor: 1010),
    OpcaoGrauFiltro(rotulo: '9b', valor: 1020),
    OpcaoGrauFiltro(rotulo: '9c', valor: 1030),
    OpcaoGrauFiltro(rotulo: '10a', valor: 1110),
    OpcaoGrauFiltro(rotulo: '10b', valor: 1120),
    OpcaoGrauFiltro(rotulo: '10c', valor: 1130),
    OpcaoGrauFiltro(rotulo: '11a', valor: 1210),
    OpcaoGrauFiltro(rotulo: '11b', valor: 1220),
    OpcaoGrauFiltro(rotulo: '11c', valor: 1230),
    OpcaoGrauFiltro(rotulo: '12a', valor: 1310),
  ];

  static const List<OpcaoGrauFiltro> grausBoulder = [
    OpcaoGrauFiltro(rotulo: 'V0', valor: 100),
    OpcaoGrauFiltro(rotulo: 'V1', valor: 200),
    OpcaoGrauFiltro(rotulo: 'V2', valor: 300),
    OpcaoGrauFiltro(rotulo: 'V3', valor: 400),
    OpcaoGrauFiltro(rotulo: 'V4', valor: 500),
    OpcaoGrauFiltro(rotulo: 'V5', valor: 600),
    OpcaoGrauFiltro(rotulo: 'V6', valor: 700),
    OpcaoGrauFiltro(rotulo: 'V7', valor: 800),
    OpcaoGrauFiltro(rotulo: 'V8', valor: 900),
    OpcaoGrauFiltro(rotulo: 'V9', valor: 1000),
    OpcaoGrauFiltro(rotulo: 'V10', valor: 1100),
    OpcaoGrauFiltro(rotulo: 'V11', valor: 1200),
    OpcaoGrauFiltro(rotulo: 'V12', valor: 1300),
    OpcaoGrauFiltro(rotulo: 'V13', valor: 1400),
    OpcaoGrauFiltro(rotulo: 'V14', valor: 1500),
    OpcaoGrauFiltro(rotulo: 'V15', valor: 1600),
  ];

  static List<OpcaoGrauFiltro> opcoesParaModalidade(String modalidade) {
    if (modalidade.toLowerCase() == 'boulder') {
      return grausBoulder;
    }
    return grausVia;
  }
}

/// Modos de ordenação disponíveis na listagem do Índice.
enum OrdenacaoIndice {
  dificuldadeAsc,
  dificuldadeDesc,
  alfabeticaAsc,
  alfabeticaDesc,
  setorAsc,
}

/// Estado imutável dos filtros e busca de uma aba do Índice de Escaladas.
class EstadoFiltrosIndice {
  final int? minGrauValor;
  final int? maxGrauValor;
  final Set<String> setores;
  final Set<String> conquistadores;
  final bool apenasClassicas;
  final String termoBusca;
  final OrdenacaoIndice ordenacao;

  const EstadoFiltrosIndice({
    this.minGrauValor,
    this.maxGrauValor,
    this.setores = const {},
    this.conquistadores = const {},
    this.apenasClassicas = false,
    this.termoBusca = '',
    this.ordenacao = OrdenacaoIndice.dificuldadeAsc,
  });

  /// Indica se qualquer filtro ou busca está ativo além do padrão.
  bool get temFiltrosAtivos =>
      minGrauValor != null ||
      maxGrauValor != null ||
      setores.isNotEmpty ||
      conquistadores.isNotEmpty ||
      apenasClassicas ||
      termoBusca.trim().isNotEmpty;

  /// Cria uma cópia com campos atualizados.
  EstadoFiltrosIndice copyWith({
    int? minGrauValor,
    bool clearMinGrau = false,
    int? maxGrauValor,
    bool clearMaxGrau = false,
    Set<String>? setores,
    bool clearSetores = false,
    Set<String>? conquistadores,
    bool clearConquistadores = false,
    bool? apenasClassicas,
    String? termoBusca,
    OrdenacaoIndice? ordenacao,
  }) {
    return EstadoFiltrosIndice(
      minGrauValor: clearMinGrau ? null : (minGrauValor ?? this.minGrauValor),
      maxGrauValor: clearMaxGrau ? null : (maxGrauValor ?? this.maxGrauValor),
      setores: clearSetores ? const {} : (setores ?? this.setores),
      conquistadores: clearConquistadores ? const {} : (conquistadores ?? this.conquistadores),
      apenasClassicas: apenasClassicas ?? this.apenasClassicas,
      termoBusca: termoBusca ?? this.termoBusca,
      ordenacao: ordenacao ?? this.ordenacao,
    );
  }

  /// Aplica todos os critérios de filtragem e ordenação sobre a lista de escaladas.
  List<ItemIndiceEscalada> aplicar(List<ItemIndiceEscalada> itens) {
    var resultado = List<ItemIndiceEscalada>.from(itens);

    // 1. Filtro por intervalo contínuo de grau (RangeSlider)
    if (minGrauValor != null || maxGrauValor != null) {
      resultado = resultado.where((item) {
        final grau = item.grauValor;
        if (minGrauValor != null && grau < minGrauValor!) return false;
        if (maxGrauValor != null && grau > maxGrauValor!) return false;
        return true;
      }).toList();
    }

    // 2. Filtro por múltiplos setores selecionados
    if (setores.isNotEmpty) {
      resultado = resultado.where((item) => setores.contains(item.setor.nome)).toList();
    }

    // 3. Filtro por múltiplos conquistadores selecionados
    if (conquistadores.isNotEmpty) {
      resultado = resultado.where((item) {
        return item.conquistadores.any((autor) => conquistadores.contains(autor.trim()));
      }).toList();
    }

    // 4. Apenas clássicas / estreladas
    if (apenasClassicas) {
      resultado = resultado.where((item) => item.isDestaque).toList();
    }

    // 5. Busca textual (se fornecida)
    final termo = termoBusca.trim();
    if (termo.isNotEmpty) {
      final queryNorm = normalizeSearchString(termo);
      resultado = resultado.where((item) {
        final nomeNorm = normalizeSearchString(item.nome);
        if (nomeNorm.contains(queryNorm)) return true;
        return item.conquistadores.any((autor) {
          return normalizeSearchString(autor).contains(queryNorm);
        });
      }).toList();
    }

    // 6. Ordenação
    resultado.sort((a, b) {
      switch (ordenacao) {
        case OrdenacaoIndice.dificuldadeAsc:
          final cmp = a.grauValor.compareTo(b.grauValor);
          if (cmp != 0) return cmp;
          return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        case OrdenacaoIndice.dificuldadeDesc:
          final cmp = b.grauValor.compareTo(a.grauValor);
          if (cmp != 0) return cmp;
          return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        case OrdenacaoIndice.alfabeticaAsc:
          return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        case OrdenacaoIndice.alfabeticaDesc:
          return b.nome.toLowerCase().compareTo(a.nome.toLowerCase());
        case OrdenacaoIndice.setorAsc:
          final cmp = a.setor.nome.toLowerCase().compareTo(b.setor.nome.toLowerCase());
          if (cmp != 0) return cmp;
          return a.grauValor.compareTo(b.grauValor);
      }
    });

    return resultado;
  }

  /// Retorna os nomes únicos e ordenados dos setores que possuem escaladas correspondentes
  /// aos filtros ativos (faixa de grau, destaque/clássicas e conquistadores selecionados).
  ///
  /// Este método não filtra pela propriedade `setores` do próprio estado, permitindo que a
  /// interface ofereça todas as opções adicionais de setores compatíveis para multi-seleção.
  List<String> obterSetoresDisponiveis(List<ItemIndiceEscalada> itens) {
    var candidatos = itens;

    // 1. Filtro por intervalo contínuo de grau (RangeSlider)
    if (minGrauValor != null || maxGrauValor != null) {
      candidatos = candidatos.where((item) {
        final grau = item.grauValor;
        if (minGrauValor != null && grau < minGrauValor!) return false;
        if (maxGrauValor != null && grau > maxGrauValor!) return false;
        return true;
      }).toList();
    }

    // 2. Filtro por conquistadores selecionados (se houver)
    if (conquistadores.isNotEmpty) {
      candidatos = candidatos.where((item) {
        return item.conquistadores.any((autor) => conquistadores.contains(autor.trim()));
      }).toList();
    }

    // 3. Apenas clássicas / estreladas
    if (apenasClassicas) {
      candidatos = candidatos.where((item) => item.isDestaque).toList();
    }

    final nomes = candidatos
        .map((item) => item.setor.nome)
        .where((nome) => nome.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    return nomes;
  }

  /// Retorna os nomes únicos e ordenados dos conquistadores que possuem escaladas correspondentes
  /// aos filtros ativos (faixa de grau, destaque/clássicas e setores selecionados).
  ///
  /// Este método não filtra pela propriedade `conquistadores` do próprio estado, permitindo que a
  /// interface ofereça todas as opções adicionais de autores compatíveis para multi-seleção.
  List<String> obterConquistadoresDisponiveis(List<ItemIndiceEscalada> itens) {
    var candidatos = itens;

    // 1. Filtro por intervalo contínuo de grau (RangeSlider)
    if (minGrauValor != null || maxGrauValor != null) {
      candidatos = candidatos.where((item) {
        final grau = item.grauValor;
        if (minGrauValor != null && grau < minGrauValor!) return false;
        if (maxGrauValor != null && grau > maxGrauValor!) return false;
        return true;
      }).toList();
    }

    // 2. Filtro por setores selecionados (se houver)
    if (setores.isNotEmpty) {
      candidatos = candidatos.where((item) => setores.contains(item.setor.nome)).toList();
    }

    // 3. Apenas clássicas / estreladas
    if (apenasClassicas) {
      candidatos = candidatos.where((item) => item.isDestaque).toList();
    }

    final autores = candidatos
        .expand((item) => item.conquistadores)
        .map((autor) => autor.trim())
        .where((autor) => autor.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    return autores;
  }

  /// Verifica se há pelo menos uma escalada clássica (em destaque) entre as opções
  /// que atendem aos filtros atuais (grau, setores e conquistadores selecionados).
  ///
  /// Se [apenasClassicas] já estiver ativo no estado, retorna sempre verdadeiro
  /// para assegurar que o controle permaneça visível na interface para permitir a desmarcação.
  bool temClassicasDisponiveis(List<ItemIndiceEscalada> itens) {
    if (apenasClassicas) return true;

    var candidatos = itens;

    // 1. Filtro por intervalo contínuo de grau (RangeSlider)
    if (minGrauValor != null || maxGrauValor != null) {
      candidatos = candidatos.where((item) {
        final grau = item.grauValor;
        if (minGrauValor != null && grau < minGrauValor!) return false;
        if (maxGrauValor != null && grau > maxGrauValor!) return false;
        return true;
      }).toList();
    }

    // 2. Filtro por setores selecionados (se houver)
    if (setores.isNotEmpty) {
      candidatos = candidatos.where((item) => setores.contains(item.setor.nome)).toList();
    }

    // 3. Filtro por conquistadores selecionados (se houver)
    if (conquistadores.isNotEmpty) {
      candidatos = candidatos.where((item) {
        return item.conquistadores.any((autor) => conquistadores.contains(autor.trim()));
      }).toList();
    }

    return candidatos.any((item) => item.isDestaque);
  }
}
