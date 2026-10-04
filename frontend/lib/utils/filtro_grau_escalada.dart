// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'indexador_escaladas.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/function_library/via_functions.dart';

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

/// Converte a graduação de um boulder para o peso equivalente aproximado na escala de vias brasileira.
int converterGrauBoulderParaPesoVia(GrauBoulder_GrauBoulder grau) {
  switch (grau) {
    case GrauBoulder_GrauBoulder.VB:
      return 450; // ~3º/4º
    case GrauBoulder_GrauBoulder.V0:
      return 550; // ~4º/5º
    case GrauBoulder_GrauBoulder.V1:
      return 650; // ~5ºsup/6a
    case GrauBoulder_GrauBoulder.V2:
      return 750; // ~6b
    case GrauBoulder_GrauBoulder.V3:
      return 810; // ~7a
    case GrauBoulder_GrauBoulder.V4:
      return 825; // ~7b/7c
    case GrauBoulder_GrauBoulder.V5:
      return 870; // ~7c/8a
    case GrauBoulder_GrauBoulder.V6:
      return 915; // ~8a/8b
    case GrauBoulder_GrauBoulder.V7:
      return 925; // ~8b/8c
    case GrauBoulder_GrauBoulder.V8:
      return 970; // ~8c/9a
    case GrauBoulder_GrauBoulder.V9:
      return 1020; // ~9b
    case GrauBoulder_GrauBoulder.V10:
      return 1070; // ~9c/10a
    case GrauBoulder_GrauBoulder.V11:
      return 1120; // ~10b
    case GrauBoulder_GrauBoulder.V12:
      return 1170; // ~10c/11a
    case GrauBoulder_GrauBoulder.V13:
      return 1220; // ~11b
    case GrauBoulder_GrauBoulder.V14:
      return 1230; // ~11c
    case GrauBoulder_GrauBoulder.V15:
    case GrauBoulder_GrauBoulder.V16:
    case GrauBoulder_GrauBoulder.V17:
      return 1310; // ~12a+
    case GrauBoulder_GrauBoulder.INDEFINIDO:
      return 9998;
    default:
      return 9998;
  }
}

/// Retorna o peso numérico normalizado de uma escalada para comparação uniforme de dificuldade
/// entre vias e boulders (utilizado na ordenação de setores por mediana de grau).
int obterPesoDificuldadeUnificado(Escalada escalada) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return getGradeSortWeight(escalada.viaEsportiva.dificuldade.name);
    case Escalada_Tipo.viaMovel:
      return getGradeSortWeight(escalada.viaMovel.dificuldade.name);
    case Escalada_Tipo.viaMultiplasEnfiadas:
      return getGradeSortWeight(escalada.viaMultiplasEnfiadas.dificuldadeMaxima.name);
    case Escalada_Tipo.boulder:
      return converterGrauBoulderParaPesoVia(escalada.boulder.dificuldade);
    default:
      return 9998;
  }
}

/// Calcula a mediana do grau de dificuldade das escaladas de um setor utilizando
/// a escala unificada de pesos numéricos.
///
/// Retorna 9998.0 caso a lista não contenha nenhuma escalada com grau válido.
double calcularMedianaGrauSetor(Iterable<Escalada> escaladas) {
  final pesos = escaladas
      .map(obterPesoDificuldadeUnificado)
      .where((p) => p > 0 && p < 9998)
      .toList()
    ..sort();

  if (pesos.isEmpty) return 9998.0;

  final n = pesos.length;
  if (n % 2 == 1) {
    return pesos[n ~/ 2].toDouble();
  } else {
    return (pesos[(n ~/ 2) - 1] + pesos[n ~/ 2]) / 2.0;
  }
}

/// Formata a faixa de graus das escaladas de um setor (ex: "5º a 8a" ou "7a").
///
/// Retorna string vazia se não houver escaladas com grau definido.
String formatarFaixaGrausSetor(Iterable<Escalada> escaladas) {
  final escaladasValidas = escaladas
      .where((e) {
        final p = obterPesoDificuldadeUnificado(e);
        return p > 0 && p < 9998;
      })
      .toList();

  if (escaladasValidas.isEmpty) return '';

  escaladasValidas.sort(
    (a, b) => obterPesoDificuldadeUnificado(a).compareTo(obterPesoDificuldadeUnificado(b)),
  );

  final menor = getGrauString(escaladasValidas.first);
  final maior = getGrauString(escaladasValidas.last);

  if (menor.isEmpty) return maior;
  if (maior.isEmpty) return menor;
  if (menor == maior) return menor;
  return '$menor a $maior';
}

/// Modos de ordenação para a página de exploração unificada de setores e escaladas.
enum TipoOrdenacaoExploracao {
  /// Ordem natural do croqui (sequência original na rocha / guia).
  padrao,

  /// Ordem por grau de dificuldade (mediana para setores, grau para escaladas).
  grau,

  /// Ordem alfabética pelo nome do setor ou escalada.
  alfabetico,
}

/// Estado imutável global dos filtros e ordenação da página de exploração de setores e escaladas.
class EstadoFiltrosUnificado {
  /// Modalidades ativas para exibição de setores. Se vazio, exibe todas as modalidades.
  final Set<String> modalidadesAtivas;

  /// Faixas de grau mínimo indexadas pelo nome da modalidade (ex: 'Esportiva' -> 800).
  final Map<String, int> minGrauPorModalidade;

  /// Faixas de grau máximo indexadas pelo nome da modalidade (ex: 'Esportiva' -> 900).
  final Map<String, int> maxGrauPorModalidade;

  /// Conjunto de nomes de setores selecionados para restrição.
  final Set<String> setores;

  /// Conjunto de nomes de grupos selecionados para restrição.
  final Set<String> grupos;

  /// Conjunto de nomes de conquistadores selecionados.
  final Set<String> conquistadores;

  /// Indica se devem ser exibidas apenas escaladas destacadas/clássicas.
  final bool apenasClassicas;

  /// Termo de busca textual por nome de via ou setor.
  final String termoBusca;

  /// Modo de ordenação ativo.
  final TipoOrdenacaoExploracao tipoOrdenacao;

  /// Direção da ordenação (true para crescente/A-Z, false para decrescente/Z-A).
  final bool direcaoCrescente;

  const EstadoFiltrosUnificado({
    this.modalidadesAtivas = const {},
    this.minGrauPorModalidade = const {},
    this.maxGrauPorModalidade = const {},
    this.setores = const {},
    this.grupos = const {},
    this.conquistadores = const {},
    this.apenasClassicas = false,
    this.termoBusca = '',
    this.tipoOrdenacao = TipoOrdenacaoExploracao.padrao,
    this.direcaoCrescente = true,
  });

  /// Indica se qualquer filtro de conteúdo além do padrão está ativo.
  bool get temFiltrosAtivos =>
      modalidadesAtivas.isNotEmpty ||
      minGrauPorModalidade.isNotEmpty ||
      maxGrauPorModalidade.isNotEmpty ||
      setores.isNotEmpty ||
      grupos.isNotEmpty ||
      conquistadores.isNotEmpty ||
      apenasClassicas ||
      termoBusca.trim().isNotEmpty;

  /// Cria uma cópia com campos modificados.
  EstadoFiltrosUnificado copyWith({
    Set<String>? modalidadesAtivas,
    bool clearModalidadesAtivas = false,
    Map<String, int>? minGrauPorModalidade,
    Map<String, int>? maxGrauPorModalidade,
    Set<String>? setores,
    bool clearSetores = false,
    Set<String>? grupos,
    bool clearGrupos = false,
    Set<String>? conquistadores,
    bool clearConquistadores = false,
    bool? apenasClassicas,
    String? termoBusca,
    TipoOrdenacaoExploracao? tipoOrdenacao,
    bool? direcaoCrescente,
  }) {
    return EstadoFiltrosUnificado(
      modalidadesAtivas: clearModalidadesAtivas
          ? const {}
          : (modalidadesAtivas ?? this.modalidadesAtivas),
      minGrauPorModalidade: minGrauPorModalidade ?? this.minGrauPorModalidade,
      maxGrauPorModalidade: maxGrauPorModalidade ?? this.maxGrauPorModalidade,
      setores: clearSetores ? const {} : (setores ?? this.setores),
      grupos: clearGrupos ? const {} : (grupos ?? this.grupos),
      conquistadores: clearConquistadores ? const {} : (conquistadores ?? this.conquistadores),
      apenasClassicas: apenasClassicas ?? this.apenasClassicas,
      termoBusca: termoBusca ?? this.termoBusca,
      tipoOrdenacao: tipoOrdenacao ?? this.tipoOrdenacao,
      direcaoCrescente: direcaoCrescente ?? this.direcaoCrescente,
    );
  }

  /// Retorna a categoria de grau ('Via' ou 'Boulder') para uma determinada modalidade de escalada.
  ///
  /// Modalidades como Esportiva, Tradicional, Top Rope e Artificial compartilham a escala
  /// brasileira de vias e portanto pertencem à categoria 'Via'. Boulders pertencem à categoria 'Boulder'.
  static String obterCategoriaGrau(String modalidade) {
    if (modalidade.trim().toLowerCase() == 'boulder') {
      return 'Boulder';
    }
    return 'Via';
  }

  /// Filtra a lista de escaladas de acordo com os filtros ativos.
  /// Se [modalidadeEspecifica] for informada, restringe àquela modalidade.
  List<ItemIndiceEscalada> filtrarEscaladas(
    List<ItemIndiceEscalada> itens, {
    String? modalidadeEspecifica,
  }) {
    var resultado = List<ItemIndiceEscalada>.from(itens);

    // 1. Filtro de Modalidade
    if (modalidadeEspecifica != null) {
      if (modalidadesAtivas.isNotEmpty && !modalidadesAtivas.contains(modalidadeEspecifica)) {
        return const [];
      }
      resultado = resultado.where((i) => i.modalidade == modalidadeEspecifica).toList();
    } else if (modalidadesAtivas.isNotEmpty) {
      resultado = resultado.where((i) => modalidadesAtivas.contains(i.modalidade)).toList();
    }

    // 2. Filtro de Faixa de Grau por Categoria (Vias vs Boulders) ou Modalidade
    if (minGrauPorModalidade.isNotEmpty || maxGrauPorModalidade.isNotEmpty) {
      resultado = resultado.where((item) {
        final categoria = obterCategoriaGrau(item.modalidade);
        final min = minGrauPorModalidade[categoria] ?? minGrauPorModalidade[item.modalidade];
        final max = maxGrauPorModalidade[categoria] ?? maxGrauPorModalidade[item.modalidade];
        final grau = item.grauValor;

        if (min != null && grau < min) return false;
        if (max != null && grau > max) return false;
        return true;
      }).toList();
    }

    // 3. Filtro por Localização (Setores e/ou Grupos)
    if (setores.isNotEmpty || grupos.isNotEmpty) {
      resultado = resultado.where((item) {
        final emSetor = setores.contains(item.setor.nome);
        final emGrupo = item.grupo != null && grupos.contains(item.grupo!.nome);
        return emSetor || emGrupo;
      }).toList();
    }

    // 5. Filtro por Conquistadores
    if (conquistadores.isNotEmpty) {
      resultado = resultado.where((item) {
        return item.conquistadores.any((c) => conquistadores.contains(c.trim()));
      }).toList();
    }

    // 6. Filtro por Clássicas
    if (apenasClassicas) {
      resultado = resultado.where((item) => item.isDestaque).toList();
    }

    // 7. Filtro por Termo de Busca
    if (termoBusca.trim().isNotEmpty) {
      final query = termoBusca.trim().toLowerCase();
      resultado = resultado.where((item) => item.nome.toLowerCase().contains(query)).toList();
    }

    // 8. Ordenação
    switch (tipoOrdenacao) {
      case TipoOrdenacaoExploracao.padrao:
        if (!direcaoCrescente) {
          resultado = resultado.reversed.toList();
        }
        break;
      case TipoOrdenacaoExploracao.grau:
        resultado.sort((a, b) {
          final comp = direcaoCrescente
              ? a.grauValor.compareTo(b.grauValor)
              : b.grauValor.compareTo(a.grauValor);
          if (comp != 0) return comp;
          return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        });
        break;
      case TipoOrdenacaoExploracao.alfabetico:
        resultado.sort((a, b) {
          final comp = direcaoCrescente
              ? a.nome.toLowerCase().compareTo(b.nome.toLowerCase())
              : b.nome.toLowerCase().compareTo(a.nome.toLowerCase());
          return comp;
        });
        break;
    }

    return resultado;
  }

  /// Extrai o nome identificador de um elemento [SetorOuGrupo].
  static String obterNomeSetorOuGrupo(SetorOuGrupo sg) {
    if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
      return sg.setor.conteudo.nome;
    } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
      return sg.grupo.conteudo.nome;
    }
    return '';
  }

  /// Filtra os setores (e grupos), mantendo apenas os que possuem vias correspondentes aos filtros ativos.
  List<SetorOuGrupo> filtrarSetores(
    List<SetorOuGrupo> setoresOuGrupos,
    List<ItemIndiceEscalada> todasEscaladas,
  ) {
    final escaladasValidas = filtrarEscaladas(todasEscaladas);

    final List<SetorOuGrupo> resultado = [];

    for (final sg in setoresOuGrupos) {
      if (sg.whichTipo() == SetorOuGrupo_Tipo.setor && sg.setor.hasConteudo()) {
        final setor = sg.setor.conteudo;

        if (grupos.isNotEmpty) {
          final item = todasEscaladas.firstWhere(
            (e) => e.setor.nome == setor.nome,
            orElse: () => ItemIndiceEscalada(escalada: Escalada(), setor: setor, cragId: ''),
          );
          if (item.grupo != null && !grupos.contains(item.grupo!.nome)) {
            continue;
          }
        }

        final viasDoSetor = escaladasValidas.where((e) => e.setor.nome == setor.nome).toList();
        if (viasDoSetor.isNotEmpty) {
          resultado.add(sg);
        }
      } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo && sg.grupo.hasConteudo()) {
        final grupo = sg.grupo.conteudo;
        if (grupos.isNotEmpty && !grupos.contains(grupo.nome)) {
          continue;
        }

        final viasDoGrupo = escaladasValidas.where((e) => e.grupo?.nome == grupo.nome).toList();
        if (viasDoGrupo.isNotEmpty) {
          resultado.add(sg);
        }
      }
    }

    // Ordenação dos setores/grupos
    switch (tipoOrdenacao) {
      case TipoOrdenacaoExploracao.padrao:
        if (!direcaoCrescente) {
          return resultado.reversed.toList();
        }
        return resultado;
      case TipoOrdenacaoExploracao.alfabetico:
        resultado.sort((a, b) {
          final nomeA = obterNomeSetorOuGrupo(a).toLowerCase();
          final nomeB = obterNomeSetorOuGrupo(b).toLowerCase();
          return direcaoCrescente ? nomeA.compareTo(nomeB) : nomeB.compareTo(nomeA);
        });
        return resultado;
      case TipoOrdenacaoExploracao.grau:
        resultado.sort((a, b) {
          final nomeA = obterNomeSetorOuGrupo(a);
          final nomeB = obterNomeSetorOuGrupo(b);

          final viasA = escaladasValidas
              .where((e) => e.setor.nome == nomeA || e.grupo?.nome == nomeA)
              .map((e) => e.escalada);
          final viasB = escaladasValidas
              .where((e) => e.setor.nome == nomeB || e.grupo?.nome == nomeB)
              .map((e) => e.escalada);

          final medA = calcularMedianaGrauSetor(viasA);
          final medB = calcularMedianaGrauSetor(viasB);

          final comp = direcaoCrescente ? medA.compareTo(medB) : medB.compareTo(medA);
          if (comp != 0) return comp;
          return nomeA.toLowerCase().compareTo(nomeB.toLowerCase());
        });
        return resultado;
    }
  }

  /// Retorna o contador formatado para a aba de setores.
  String obterContadorSetores(
    List<SetorOuGrupo> todosSetores,
    List<ItemIndiceEscalada> todasEscaladas,
  ) {
    final total = todosSetores.length;
    if (!temFiltrosAtivos) {
      return '($total)';
    }
    final filtrados = filtrarSetores(todosSetores, todasEscaladas).length;
    return '($filtrados/$total)';
  }

  /// Retorna o contador formatado para a aba da modalidade especificada.
  String obterContadorModalidade(
    String modalidade,
    List<ItemIndiceEscalada> todasEscaladas,
  ) {
    final total = todasEscaladas.where((e) => e.modalidade == modalidade).length;
    if (!temFiltrosAtivos) {
      return '($total)';
    }
    final filtradas = filtrarEscaladas(todasEscaladas, modalidadeEspecifica: modalidade).length;
    return '($filtradas/$total)';
  }
}


