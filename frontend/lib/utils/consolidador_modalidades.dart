// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../aresta_api/proto/generated/croqui.pb.dart';

/// Modalidades de escalada suportadas para agregação e exibição em badges.
enum ModalidadeEscaladaEnum {
  esportiva,
  movel,
  boulder,
  multienfiada,
  highline,
}

/// Representa a contagem de uma modalidade específica com seu texto formatado
/// com estrita concordância gramatical no singular ou plural.
class ItemModalidade {
  /// A modalidade de escalada representada.
  final ModalidadeEscaladaEnum modalidade;

  /// Quantidade total de escaladas desta modalidade.
  final int quantidade;

  /// Rótulo pronto para exibição com número e modalidade flexionada (ex: "1 esportiva", "12 esportivas").
  final String rotuloFormatado;

  const ItemModalidade({
    required this.modalidade,
    required this.quantidade,
    required this.rotuloFormatado,
  });
}

/// Utilitário responsável por consolidar escaladas de setores e grupos e formatar
/// os rótulos de acordo com as regras gramaticais em português.
abstract class ConsolidadorModalidades {
  /// Retorna o rótulo formatado no singular ou plural para a modalidade e quantidade informadas.
  ///
  /// Regras gramaticais aplicadas:
  /// - esportiva: "1 esportiva" / "$quantidade esportivas"
  /// - móvel: "1 móvel" / "$quantidade móveis"
  /// - boulder: "1 boulder" / "$quantidade boulders"
  /// - multienfiada: "1 multienfiada" / "$quantidade multienfiadas"
  /// - highline: "1 highline" / "$quantidade highlines"
  static String formatarRotulo(ModalidadeEscaladaEnum modalidade, int quantidade) {
    switch (modalidade) {
      case ModalidadeEscaladaEnum.esportiva:
        return quantidade == 1 ? '1 esportiva' : '$quantidade esportivas';
      case ModalidadeEscaladaEnum.movel:
        return quantidade == 1 ? '1 móvel' : '$quantidade móveis';
      case ModalidadeEscaladaEnum.boulder:
        return quantidade == 1 ? '1 boulder' : '$quantidade boulders';
      case ModalidadeEscaladaEnum.multienfiada:
        return quantidade == 1 ? '1 multienfiada' : '$quantidade multienfiadas';
      case ModalidadeEscaladaEnum.highline:
        return quantidade == 1 ? '1 highline' : '$quantidade highlines';
    }
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
  static List<ItemModalidade> consolidarEscaladas(Iterable<Escalada> escaladas) {
    int totalEsportivas = 0;
    int totalMoveis = 0;
    int totalBoulders = 0;
    int totalMultienfiadas = 0;
    int totalHighlines = 0;

    for (final escalada in escaladas) {
      switch (escalada.whichTipo()) {
        case Escalada_Tipo.viaEsportiva:
          totalEsportivas++;
          break;
        case Escalada_Tipo.viaMovel:
          totalMoveis++;
          break;
        case Escalada_Tipo.boulder:
          totalBoulders++;
          break;
        case Escalada_Tipo.viaMultiplasEnfiadas:
          totalMultienfiadas++;
          break;
        case Escalada_Tipo.highline:
          totalHighlines++;
          break;
        default:
          break;
      }
    }

    final List<ItemModalidade> resultado = [];

    if (totalEsportivas > 0) {
      resultado.add(
        ItemModalidade(
          modalidade: ModalidadeEscaladaEnum.esportiva,
          quantidade: totalEsportivas,
          rotuloFormatado: formatarRotulo(
            ModalidadeEscaladaEnum.esportiva,
            totalEsportivas,
          ),
        ),
      );
    }
    if (totalMoveis > 0) {
      resultado.add(
        ItemModalidade(
          modalidade: ModalidadeEscaladaEnum.movel,
          quantidade: totalMoveis,
          rotuloFormatado: formatarRotulo(
            ModalidadeEscaladaEnum.movel,
            totalMoveis,
          ),
        ),
      );
    }
    if (totalBoulders > 0) {
      resultado.add(
        ItemModalidade(
          modalidade: ModalidadeEscaladaEnum.boulder,
          quantidade: totalBoulders,
          rotuloFormatado: formatarRotulo(
            ModalidadeEscaladaEnum.boulder,
            totalBoulders,
          ),
        ),
      );
    }
    if (totalMultienfiadas > 0) {
      resultado.add(
        ItemModalidade(
          modalidade: ModalidadeEscaladaEnum.multienfiada,
          quantidade: totalMultienfiadas,
          rotuloFormatado: formatarRotulo(
            ModalidadeEscaladaEnum.multienfiada,
            totalMultienfiadas,
          ),
        ),
      );
    }
    if (totalHighlines > 0) {
      resultado.add(
        ItemModalidade(
          modalidade: ModalidadeEscaladaEnum.highline,
          quantidade: totalHighlines,
          rotuloFormatado: formatarRotulo(
            ModalidadeEscaladaEnum.highline,
            totalHighlines,
          ),
        ),
      );
    }

    return resultado;
  }

  /// Consolida as modalidades de um [Setor].
  ///
  /// Prioriza a inspeção direta de [setor.escaladas]. Caso a lista esteja vazia
  /// mas [setor.precomputados] esteja disponível, utiliza os dados pré-computados como fallback.
  static List<ItemModalidade> consolidarSetor(Setor setor) {
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
  /// Caso os setores não contenham escaladas em memória mas o grupo possua [precomputados],
  /// utiliza os valores agregados pré-computados como fallback.
  static List<ItemModalidade> consolidarGrupo(Grupo grupo) {
    final List<Escalada> todasEscaladas = [];
    for (final arquivoSetor in grupo.setores) {
      if (arquivoSetor.hasConteudo()) {
        todasEscaladas.addAll(arquivoSetor.conteudo.escaladas);
      }
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
