// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view_functions/via_functions.dart';

/// Representa um item enriquecido do índice de escaladas, contendo a escalada
/// e sua resolução geográfica completa (setor e grupo correspondentes).
class ItemIndiceEscalada {
  /// A entidade de escalada do modelo protobuf.
  final Escalada escalada;

  /// O setor ao qual esta escalada pertence.
  final Setor setor;

  /// O grupo agregador do setor, caso este pertença a um grupo.
  final Grupo? grupo;

  /// O identificador único do pico (cragId).
  final String cragId;

  const ItemIndiceEscalada({
    required this.escalada,
    required this.setor,
    this.grupo,
    required this.cragId,
  });

  /// Nome formatado da escalada.
  String get nome => getEscaladaNome(escalada);

  /// Grau formatado para exibição visual (ex: "7a", "V4").
  String get grau => getGrauString(escalada);

  /// Valor numérico do grau para ordenação.
  int get grauValor => getGrauValue(escalada);

  /// Modalidade da escalada, padronizada em português (ex: "Esportiva", "Boulder", "Multienfiada").
  String get modalidade {
    final mod = getModalidadeEscalada(escalada);
    if (mod == 'Multipitch') return 'Multienfiada';
    return mod;
  }

  /// String de proteções no formato X+Y.
  String get protecoes => getProtecoesString(escalada);

  /// Quantidade de proteções para fins de ordenação.
  int get protecoesValor => getProtecoesValue(escalada);

  /// Indica se a via possui destaque (clássica/estrelada).
  bool get isDestaque {
    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        return escalada.viaEsportiva.destaque;
      case Escalada_Tipo.viaMovel:
        return escalada.viaMovel.destaque;
      case Escalada_Tipo.boulder:
        return escalada.boulder.destaque;
      case Escalada_Tipo.viaMultiplasEnfiadas:
        return escalada.viaMultiplasEnfiadas.destaque;
      case Escalada_Tipo.highline:
        return escalada.highline.destaque;
      default:
        return false;
    }
  }

  /// Lista de conquistadores da via.
  List<String> get conquistadores {
    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        return escalada.viaEsportiva.conquistadores;
      case Escalada_Tipo.viaMovel:
        return escalada.viaMovel.conquistadores;
      case Escalada_Tipo.boulder:
        return escalada.boulder.conquistadores;
      case Escalada_Tipo.viaMultiplasEnfiadas:
        return escalada.viaMultiplasEnfiadas.conquistadores;
      default:
        return const [];
    }
  }

  /// Texto descritivo da localização hierárquica (ex: "Grupo > Setor" ou apenas "Setor").
  String get localizacaoFormatada {
    if (grupo != null && grupo!.nome.isNotEmpty) {
      return '${grupo!.nome} › ${setor.nome}';
    }
    return setor.nome;
  }
}

/// Indexa todas as escaladas de um pico, mapeando cada uma com seu setor
/// e grupo correspondente em uma lista plana de [ItemIndiceEscalada].
List<ItemIndiceEscalada> indexarEscaladasDoPico(Pico pico, String cragId) {
  final List<ItemIndiceEscalada> resultado = [];

  for (final setorOuGrupo in pico.setoresOuGrupos) {
    if (setorOuGrupo.whichTipo() == SetorOuGrupo_Tipo.setor &&
        setorOuGrupo.setor.hasConteudo()) {
      final setor = setorOuGrupo.setor.conteudo;
      for (final escalada in setor.escaladas) {
        resultado.add(
          ItemIndiceEscalada(
            escalada: escalada,
            setor: setor,
            cragId: cragId,
          ),
        );
      }
    } else if (setorOuGrupo.whichTipo() == SetorOuGrupo_Tipo.grupo &&
        setorOuGrupo.grupo.hasConteudo()) {
      final grupo = setorOuGrupo.grupo.conteudo;
      for (final setorRef in grupo.setores) {
        if (setorRef.hasConteudo()) {
          final setor = setorRef.conteudo;
          for (final escalada in setor.escaladas) {
            resultado.add(
              ItemIndiceEscalada(
                escalada: escalada,
                setor: setor,
                grupo: grupo,
                cragId: cragId,
              ),
            );
          }
        }
      }
    }
  }

  return resultado;
}
