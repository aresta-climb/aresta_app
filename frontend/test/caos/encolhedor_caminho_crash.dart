// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'receita_crash_robo.dart';

/// Algoritmo de encolhimento de caminhos de crash baseado em *Delta Debugging* (`ddmin`) por busca binária.
///
/// Quando o robô caótico encontra uma falha após dezenas de passos aleatórios, este encolhedor
/// divide iterativamente o histórico em blocos e testa a remoção de cada bloco em uma instância
/// limpa do aplicativo até isolar a menor sequência de passos que reproduz a mesma assinatura de falha.
abstract final class EncolhedorCaminhoCrash {
  /// Reduz [passosOriginais] para a menor subsequência que continua retornando [assinaturaAlvo]
  /// ao ser avaliada por [testarSequencia].
  ///
  /// - [testarSequencia]: Função que executa a lista candidata em estado limpo e retorna a
  ///   assinatura da falha caso um crash ocorra, ou `null` caso a execução termine sem erros.
  /// - [maxTentativas]: Limite superior de execuções de replay para manter o tempo de shrinking previsível.
  static Future<List<PassoRobo>> encolher({
    required List<PassoRobo> passosOriginais,
    required String assinaturaAlvo,
    required Future<String?> Function(List<PassoRobo> candidato) testarSequencia,
    int maxTentativas = 25,
  }) async {
    if (passosOriginais.length <= 1) {
      return List<PassoRobo>.unmodifiable(passosOriginais);
    }

    var melhorCaminho = List<PassoRobo>.from(passosOriginais);
    var granularidade = 2;
    var tentativasRealizadas = 0;

    while (melhorCaminho.length >= 2 && tentativasRealizadas < maxTentativas) {
      final tamanhoBloco = math.max(1, (melhorCaminho.length / granularidade).ceil());
      var reduziuNestaRodada = false;
      var cursorInicio = 0;

      while (cursorInicio < melhorCaminho.length &&
          melhorCaminho.length >= 2 &&
          tentativasRealizadas < maxTentativas) {
        final fim = math.min(cursorInicio + tamanhoBloco, melhorCaminho.length);

        // Constrói o complemento removendo o bloco [cursorInicio, fim)
        final complemento = <PassoRobo>[
          ...melhorCaminho.sublist(0, cursorInicio),
          ...melhorCaminho.sublist(fim),
        ];

        if (complemento.isEmpty) {
          cursorInicio = fim;
          continue;
        }

        tentativasRealizadas++;
        final assinaturaObtida = await testarSequencia(complemento);

        if (assinaturaObtida == assinaturaAlvo) {
          // O bloco removido era irrelevante! Mantém cursorInicio na mesma posição
          // (que agora aponta para o próximo bloco na lista reduzida).
          melhorCaminho = complemento;
          reduziuNestaRodada = true;
        } else {
          // O bloco contém ao menos um passo essencial; avança para o próximo bloco.
          cursorInicio = fim;
        }
      }

      if (!reduziuNestaRodada) {
        if (tamanhoBloco == 1 || granularidade >= melhorCaminho.length) {
          break;
        }
        granularidade = math.min(granularidade * 2, melhorCaminho.length);
      } else {
        granularidade = math.min(granularidade * 2, melhorCaminho.length);
      }
    }

    return List<PassoRobo>.unmodifiable(melhorCaminho);
  }
}
