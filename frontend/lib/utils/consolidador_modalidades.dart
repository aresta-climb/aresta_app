// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../aresta_api/proto/generated/croqui.pb.dart';
import 'filtro_grau_escalada.dart';

/// Modalidades de escalada suportadas para agregação e exibição em badges.
enum ModalidadeEscaladaEnum {
  esportiva,
  movel,
  boulder,
  multienfiada,
  highline,
}

/// Representa a contagem de uma modalidade específica com seu texto formatado
/// com estrita concordância gramatical no singular ou plural e faixa de graduação.
class ItemModalidade {
  /// A modalidade de escalada representada.
  final ModalidadeEscaladaEnum modalidade;

  /// Quantidade total de escaladas desta modalidade (ou quantidade filtrada).
  final int quantidade;

  /// Quantidade total de escaladas desta modalidade no setor/grupo quando há filtro ativo.
  final int? quantidadeTotal;

  /// Faixa de graus formatada para esta modalidade específica (ex: "6a a 10c", "v0 a v7" ou "7a").
  final String? faixaGraus;

  /// Rótulo pronto para exibição com número, modalidade flexionada e opcionalmente faixa de graus.
  /// Exemplos: "19 esportivas - 6a a 10c", "3 de 19 esportivas - 6a a 7c", "1 esportiva".
  final String rotuloFormatado;

  const ItemModalidade({
    required this.modalidade,
    required this.quantidade,
    this.quantidadeTotal,
    this.faixaGraus,
    required this.rotuloFormatado,
  });
}

/// Utilitário responsável por consolidar escaladas de setores e grupos e formatar
/// os rótulos de acordo com as regras gramaticais em português.
abstract class ConsolidadorModalidades {
  /// Retorna o rótulo formatado no singular ou plural para a modalidade e quantidade informadas,
  /// incorporando proporção filtrada ("X de Y") e faixa de graus caso fornecidos.
  ///
  /// Regras gramaticais aplicadas:
  /// - esportiva: "1 esportiva" / "$quantidade esportivas"
  /// - móvel: "1 móvel" / "$quantidade móveis"
  /// - boulder: "1 boulder" / "$quantidade boulders"
  /// - multienfiada: "1 multienfiada" / "$quantidade multienfiadas"
  /// - highline: "1 highline" / "$quantidade highlines"
  ///
  /// Com filtro ativo e total superior:
  /// - "3 de 19 esportivas - 6a a 7c"
  static String formatarRotulo(
    ModalidadeEscaladaEnum modalidade,
    int quantidade, {
    int? quantidadeTotal,
    String? faixaGraus,
  }) {
    final String singular;
    final String plural;
    switch (modalidade) {
      case ModalidadeEscaladaEnum.esportiva:
        singular = 'esportiva';
        plural = 'esportivas';
        break;
      case ModalidadeEscaladaEnum.movel:
        singular = 'móvel';
        plural = 'móveis';
        break;
      case ModalidadeEscaladaEnum.boulder:
        singular = 'boulder';
        plural = 'boulders';
        break;
      case ModalidadeEscaladaEnum.multienfiada:
        singular = 'multienfiada';
        plural = 'multienfiadas';
        break;
      case ModalidadeEscaladaEnum.highline:
        singular = 'highline';
        plural = 'highlines';
        break;
    }

    final String textoBase;
    if (quantidadeTotal != null && quantidadeTotal > quantidade) {
      textoBase = '$quantidade de $quantidadeTotal $plural';
    } else {
      textoBase = quantidade == 1 ? '1 $singular' : '$quantidade $plural';
    }

    if (faixaGraus != null && faixaGraus.trim().isNotEmpty) {
      return '$textoBase - $faixaGraus';
    }

    return textoBase;
  }

  /// Retorna o resumo quantitativo formatado para um grupo agregador (ex: "5 setores • 42 escaladas").
  ///
  /// Aplica flexão de singular para 1 e plural para mais de 1 em ambos os contadores.
  static String formatarResumoGrupo({
    required int totalSetores,
    required int totalEscaladas,
  }) {
    final rotuloSetor = totalSetores == 1 ? '1 setor' : '$totalSetores setores';
    final rotuloEscalada =
        totalEscaladas == 1 ? '1 escalada' : '$totalEscaladas escaladas';
    return '$rotuloSetor • $rotuloEscalada';
  }

  /// Consolida uma lista iterável de [Escalada] retornando apenas as modalidades
  /// que possuam contagem maior que zero, na ordem canônica de exibição.
  ///
  /// Se [todasEscaladas] for fornecido e contiver mais escaladas do que a lista filtrada,
  /// os itens exibirão a proporção ("X de Y").
  static List<ItemModalidade> consolidarEscaladas(
    Iterable<Escalada> escaladas, {
    Iterable<Escalada>? todasEscaladas,
  }) {
    final List<Escalada> esportivas = [];
    final List<Escalada> moveis = [];
    final List<Escalada> boulders = [];
    final List<Escalada> multienfiadas = [];
    final List<Escalada> highlines = [];

    for (final escalada in escaladas) {
      switch (escalada.whichTipo()) {
        case Escalada_Tipo.viaEsportiva:
          esportivas.add(escalada);
          break;
        case Escalada_Tipo.viaMovel:
          moveis.add(escalada);
          break;
        case Escalada_Tipo.boulder:
          boulders.add(escalada);
          break;
        case Escalada_Tipo.viaMultiplasEnfiadas:
          multienfiadas.add(escalada);
          break;
        case Escalada_Tipo.highline:
          highlines.add(escalada);
          break;
        default:
          break;
      }
    }

    Map<ModalidadeEscaladaEnum, int>? contagemTotal;
    if (todasEscaladas != null) {
      contagemTotal = {
        ModalidadeEscaladaEnum.esportiva: 0,
        ModalidadeEscaladaEnum.movel: 0,
        ModalidadeEscaladaEnum.boulder: 0,
        ModalidadeEscaladaEnum.multienfiada: 0,
        ModalidadeEscaladaEnum.highline: 0,
      };
      for (final escalada in todasEscaladas) {
        switch (escalada.whichTipo()) {
          case Escalada_Tipo.viaEsportiva:
            contagemTotal[ModalidadeEscaladaEnum.esportiva] =
                contagemTotal[ModalidadeEscaladaEnum.esportiva]! + 1;
            break;
          case Escalada_Tipo.viaMovel:
            contagemTotal[ModalidadeEscaladaEnum.movel] =
                contagemTotal[ModalidadeEscaladaEnum.movel]! + 1;
            break;
          case Escalada_Tipo.boulder:
            contagemTotal[ModalidadeEscaladaEnum.boulder] =
                contagemTotal[ModalidadeEscaladaEnum.boulder]! + 1;
            break;
          case Escalada_Tipo.viaMultiplasEnfiadas:
            contagemTotal[ModalidadeEscaladaEnum.multienfiada] =
                contagemTotal[ModalidadeEscaladaEnum.multienfiada]! + 1;
            break;
          case Escalada_Tipo.highline:
            contagemTotal[ModalidadeEscaladaEnum.highline] =
                contagemTotal[ModalidadeEscaladaEnum.highline]! + 1;
            break;
          default:
            break;
        }
      }
    }

    final List<ItemModalidade> resultado = [];

    void adicionarModalidade(ModalidadeEscaladaEnum mod, List<Escalada> lista) {
      if (lista.isEmpty) return;
      final total = contagemTotal?[mod];
      final faixa = formatarFaixaGrausSetor(lista);
      final faixaFormatada = faixa.isNotEmpty ? faixa : null;
      resultado.add(
        ItemModalidade(
          modalidade: mod,
          quantidade: lista.length,
          quantidadeTotal: total,
          faixaGraus: faixaFormatada,
          rotuloFormatado: formatarRotulo(
            mod,
            lista.length,
            quantidadeTotal: total,
            faixaGraus: faixaFormatada,
          ),
        ),
      );
    }

    adicionarModalidade(ModalidadeEscaladaEnum.esportiva, esportivas);
    adicionarModalidade(ModalidadeEscaladaEnum.movel, moveis);
    adicionarModalidade(ModalidadeEscaladaEnum.boulder, boulders);
    adicionarModalidade(ModalidadeEscaladaEnum.multienfiada, multienfiadas);
    adicionarModalidade(ModalidadeEscaladaEnum.highline, highlines);

    return resultado;
  }

  /// Consolida as modalidades de um [Setor].
  ///
  /// Prioriza [escaladasFiltradas] caso informadas, calculando a proporção em relação a [setor.escaladas].
  /// Caso contrário, prioriza a inspeção direta de [setor.escaladas]. Caso a lista esteja vazia
  /// mas [setor.precomputados] esteja disponível, utiliza os dados pré-computados como fallback.
  static List<ItemModalidade> consolidarSetor(
    Setor setor, {
    Iterable<Escalada>? escaladasFiltradas,
  }) {
    if (escaladasFiltradas != null) {
      return consolidarEscaladas(
        escaladasFiltradas,
        todasEscaladas: setor.escaladas.isNotEmpty ? setor.escaladas : null,
      );
    }

    if (setor.escaladas.isNotEmpty) {
      return consolidarEscaladas(setor.escaladas);
    }

    if (setor.hasPrecomputados()) {
      return _consolidarDePrecomputados(
        esportivas: setor.precomputados.totalEsportivas,
        moveis: setor.precomputados.totalMoveis,
        boulders: setor.precomputados.totalBoulders,
        multienfiadas: setor.precomputados.totalMultiplasEnfiadas,
        highlines: setor.precomputados.totalHighlines,
      );
    }

    return const [];
  }

  /// Consolida as modalidades de um [Grupo], agregando as escaladas de todos os seus setores filhos.
  ///
  /// Prioriza [escaladasFiltradas] caso informadas, calculando a proporção em relação às escaladas totais.
  /// Caso os setores não contenham escaladas em memória mas o grupo possua [precomputados],
  /// utiliza os valores agregados pré-computados como fallback.
  static List<ItemModalidade> consolidarGrupo(
    Grupo grupo, {
    Iterable<Escalada>? escaladasFiltradas,
  }) {
    final List<Escalada> todasEscaladas = [];
    for (final arquivoSetor in grupo.setores) {
      if (arquivoSetor.hasConteudo()) {
        todasEscaladas.addAll(arquivoSetor.conteudo.escaladas);
      }
    }

    if (escaladasFiltradas != null) {
      return consolidarEscaladas(
        escaladasFiltradas,
        todasEscaladas: todasEscaladas.isNotEmpty ? todasEscaladas : null,
      );
    }

    if (todasEscaladas.isNotEmpty) {
      return consolidarEscaladas(todasEscaladas);
    }

    if (grupo.hasPrecomputados()) {
      return _consolidarDePrecomputados(
        esportivas: grupo.precomputados.totalEsportivas,
        moveis: grupo.precomputados.totalMoveis,
        boulders: grupo.precomputados.totalBoulders,
        multienfiadas: grupo.precomputados.totalMultiplasEnfiadas,
        highlines: grupo.precomputados.totalHighlines,
      );
    }

    return const [];
  }

  static List<ItemModalidade> _consolidarDePrecomputados({
    required int esportivas,
    required int moveis,
    required int boulders,
    required int multienfiadas,
    required int highlines,
  }) {
    final List<ItemModalidade> resultado = [];

    if (esportivas > 0) {
      resultado.add(
        ItemModalidade(
          modalidade: ModalidadeEscaladaEnum.esportiva,
          quantidade: esportivas,
          rotuloFormatado: formatarRotulo(
            ModalidadeEscaladaEnum.esportiva,
            esportivas,
          ),
        ),
      );
    }
    if (moveis > 0) {
      resultado.add(
        ItemModalidade(
          modalidade: ModalidadeEscaladaEnum.movel,
          quantidade: moveis,
          rotuloFormatado: formatarRotulo(
            ModalidadeEscaladaEnum.movel,
            moveis,
          ),
        ),
      );
    }
    if (boulders > 0) {
      resultado.add(
        ItemModalidade(
          modalidade: ModalidadeEscaladaEnum.boulder,
          quantidade: boulders,
          rotuloFormatado: formatarRotulo(
            ModalidadeEscaladaEnum.boulder,
            boulders,
          ),
        ),
      );
    }
    if (multienfiadas > 0) {
      resultado.add(
        ItemModalidade(
          modalidade: ModalidadeEscaladaEnum.multienfiada,
          quantidade: multienfiadas,
          rotuloFormatado: formatarRotulo(
            ModalidadeEscaladaEnum.multienfiada,
            multienfiadas,
          ),
        ),
      );
    }
    if (highlines > 0) {
      resultado.add(
        ItemModalidade(
          modalidade: ModalidadeEscaladaEnum.highline,
          quantidade: highlines,
          rotuloFormatado: formatarRotulo(
            ModalidadeEscaladaEnum.highline,
            highlines,
          ),
        ),
      );
    }

    return resultado;
  }
}
