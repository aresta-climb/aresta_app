// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/cores_app.dart';
import '../../utils/extrator_detalhes_tecnicos_via.dart';

/// Anel vetorial compacto (Dumb UI) que desenha a proporção pré-calculada de votos mais suaves,
/// justos e mais duros ao lado do grau sugerido pela comunidade na `ViaPage`.
class AnelConsensoGrauVia extends StatelessWidget {
  /// Modelo visual imutável do consenso comunitário da escalada.
  final ApresentacaoConsensoGrauVia apresentacao;

  /// Dimensão lateral do anel em pixels lógicos.
  final double tamanho;

  /// Cria uma instância de [AnelConsensoGrauVia].
  const AnelConsensoGrauVia({
    super.key,
    required this.apresentacao,
    this.tamanho = 30,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return SizedBox.square(
      key: const Key('anel_consenso_grau_via'),
      dimension: tamanho,
      child: CustomPaint(
        painter: _PintorAnelConsenso(
          votosSuaves: apresentacao.votosSuaves,
          votosJustos: apresentacao.votosJustos,
          votosDuros: apresentacao.votosDuros,
          corMaisSuave: cores.fernGreen,
          corJusto: cores.beastHide,
          corMaisDuro: cores.rustIron,
          corTrilhaVazia: cores.graniteEdge,
        ),
      ),
    );
  }
}

class _PintorAnelConsenso extends CustomPainter {
  final int votosSuaves;
  final int votosJustos;
  final int votosDuros;
  final Color corMaisSuave;
  final Color corJusto;
  final Color corMaisDuro;
  final Color corTrilhaVazia;

  const _PintorAnelConsenso({
    required this.votosSuaves,
    required this.votosJustos,
    required this.votosDuros,
    required this.corMaisSuave,
    required this.corJusto,
    required this.corMaisDuro,
    required this.corTrilhaVazia,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const espessura = 4.5;
    final centro = size.center(Offset.zero);
    final raio = (math.min(size.width, size.height) - espessura) / 2;
    final retanguloArco = Rect.fromCircle(center: centro, radius: raio);

    final pincelBase = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura
      ..color = corTrilhaVazia;
    canvas.drawCircle(centro, raio, pincelBase);

    final total = votosSuaves + votosJustos + votosDuros;
    if (total == 0) return;

    final segmentos = <(int, Color)>[
      (votosSuaves, corMaisSuave),
      (votosJustos, corJusto),
      (votosDuros, corMaisDuro),
    ];

    var anguloInicial = -math.pi / 2;
    for (final (contagem, cor) in segmentos) {
      if (contagem <= 0) continue;
      final varredura = (contagem / total) * 2 * math.pi;
      final pincelSegmento = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura
        ..strokeCap = StrokeCap.butt
        ..color = cor;
      canvas.drawArc(
        retanguloArco,
        anguloInicial,
        varredura,
        false,
        pincelSegmento,
      );
      anguloInicial += varredura;
    }
  }

  @override
  bool shouldRepaint(covariant _PintorAnelConsenso oldDelegate) {
    return oldDelegate.votosSuaves != votosSuaves ||
        oldDelegate.votosJustos != votosJustos ||
        oldDelegate.votosDuros != votosDuros;
  }
}

/// Gráfico de barras horizontais exibindo a distribuição democrática de votos (`-2` a `+2`)
/// com os respectivos graus resolvidos ao lado do Grau Oficial do Conquistador.
class BarrasDistribuicaoGrauVia extends StatelessWidget {
  /// Sequência canônica de deltas exibida no gráfico.
  static const List<int> deltasOrdenados = [-2, -1, 0, 1, 2];

  /// Consenso consolidado da escalada.
  final ConsensoGrauVia consenso;

  /// Código numérico Protobuf do grau oficial para rotular cada faixa com o grau correspondente.
  final int? codigoGrauOficial;

  /// Indica se a escalada pertence à escala V de boulder.
  final bool ehBoulder;

  /// Cria uma instância de [BarrasDistribuicaoGrauVia].
  const BarrasDistribuicaoGrauVia({
    super.key,
    required this.consenso,
    required this.codigoGrauOficial,
    required this.ehBoulder,
  });

  @override
  Widget build(BuildContext context) {
    if (!consenso.possuiVotos || consenso.distribuicaoDeltas.isEmpty) {
      return const SizedBox.shrink();
    }

    final cores = context.colors;
    var maiorContagem = 1;
    for (final delta in deltasOrdenados) {
      final qtd = consenso.distribuicaoDeltas[delta] ?? 0;
      if (qtd > maiorContagem) {
        maiorContagem = qtd;
      }
    }

    return Column(
      key: const Key('grafico_distribuicao_grau_via'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DISTRIBUIÇÃO DE VOTOS (${consenso.totalVotos})',
          style: TextStyle(
            color: cores.ashGrey,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        ...deltasOrdenados.map((delta) {
          final contagem = consenso.distribuicaoDeltas[delta] ?? 0;
          final ehModa = contagem == maiorContagem && contagem > 0;
          final corBarra = delta < 0
              ? cores.fernGreen
              : (delta == 0 ? cores.beastHide : cores.rustIron);
          final rotulo = _formatarRotuloFaixa(
            delta,
            codigoGrauOficial: codigoGrauOficial,
            ehBoulder: ehBoulder,
          );

          return Padding(
            key: Key('barra_delta_grau_$delta'),
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ehModa ? cores.chalkWhite : cores.ashGrey,
                      fontSize: 11,
                      fontWeight: ehModa ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: cores.graniteEdge,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: contagem / maiorContagem,
                      child: Container(
                        decoration: BoxDecoration(
                          color: corBarra,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 18),
                  child: Text(
                    '$contagem',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: ehModa ? cores.chalkWhite : cores.ashGrey,
                      fontSize: 11,
                      fontWeight: ehModa ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
