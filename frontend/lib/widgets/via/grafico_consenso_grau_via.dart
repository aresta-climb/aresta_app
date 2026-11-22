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

/// Gráfico declarativo (Dumb UI) de barras horizontais exibindo as faixas pré-calculadas
/// de votos (`-2` a `+2`) junto ao Grau Oficial do Conquistador.
class BarrasDistribuicaoGrauVia extends StatelessWidget {
  /// Apresentação pré-calculada das faixas de consenso.
  final ApresentacaoConsensoGrauVia apresentacao;

  /// Cria uma instância de [BarrasDistribuicaoGrauVia].
  const BarrasDistribuicaoGrauVia({
    super.key,
    required this.apresentacao,
  });

  @override
  Widget build(BuildContext context) {
    if (!apresentacao.possuiVotos || apresentacao.faixasDistribuicao.isEmpty) {
      return const SizedBox.shrink();
    }

    final cores = context.colors;

    return Column(
      key: const Key('grafico_distribuicao_grau_via'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          apresentacao.tituloDistribuicao,
          style: TextStyle(
            color: cores.ashGrey,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        ...apresentacao.faixasDistribuicao.map((faixa) {
          final corBarra = faixa.delta < 0
              ? cores.fernGreen
              : (faixa.delta == 0 ? cores.beastHide : cores.rustIron);

          return Padding(
            key: Key('barra_delta_grau_${faixa.delta}'),
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    faixa.rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: faixa.ehModa ? cores.chalkWhite : cores.ashGrey,
                      fontSize: 11,
                      fontWeight:
                          faixa.ehModa ? FontWeight.w800 : FontWeight.w600,
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
                      widthFactor: faixa.fatorLargura,
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
                    '${faixa.contagem}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: faixa.ehModa ? cores.chalkWhite : cores.ashGrey,
                      fontSize: 11,
                      fontWeight:
                          faixa.ehModa ? FontWeight.w800 : FontWeight.w500,
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

/// Fileira responsiva (Dumb UI) de 5 pílulas interativas (`-2` a `+2`) posicionada sob o gráfico
/// de consenso para votação direta de 1 toque na percepção de grau da escalada.
class SeletorPilulasVotoGrauVia extends StatelessWidget {
  /// Cinco opções pré-formatadas fornecidas pelo `ViaViewModel`.
  final List<OpcaoPilulaVotoGrauVia> pilulas;

  /// Callback acionado ao tocar em uma pílula de grau (`-2` a `+2`).
  final ValueChanged<int> aoSelecionarDelta;

  /// Cria uma instância de [SeletorPilulasVotoGrauVia].
  const SeletorPilulasVotoGrauVia({
    super.key,
    required this.pilulas,
    required this.aoSelecionarDelta,
  });

  @override
  Widget build(BuildContext context) {
    if (pilulas.isEmpty) return const SizedBox.shrink();
    final cores = context.colors;

    return LayoutBuilder(
      builder: (context, restricoes) {
        if (restricoes.maxWidth < 260) {
          return Wrap(
            spacing: 6,
            runSpacing: 6,
            children: pilulas
                .map((opcao) => _construirPilula(cores, opcao, expandir: false))
                .toList(growable: false),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < pilulas.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _construirPilula(cores, pilulas[i], expandir: true),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _construirPilula(
    AppColors cores,
    OpcaoPilulaVotoGrauVia opcao, {
    required bool expandir,
  }) {
    final selecionada = opcao.selecionada;
    final filho = InkWell(
      key: Key('pilula_voto_grau_${opcao.delta}'),
      borderRadius: BorderRadius.circular(10),
      onTap: () => aoSelecionarDelta(opcao.delta),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 6,
          horizontal: expandir ? 2 : 10,
        ),
        decoration: BoxDecoration(
          color: selecionada ? AppColors.brandColor : cores.deepBasalt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selecionada ? AppColors.brandColor : cores.graniteEdge,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              opcao.grauExibicao,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selecionada ? Colors.white : cores.chalkWhite,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
    return filho;
  }
}
