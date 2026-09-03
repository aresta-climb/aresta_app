// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/construtor_caminho_trajeto.dart';

void main() {
  setUp(() {
    ConstrutorCaminhoTrajeto.limparCache();
  });

  group('ConstrutorCaminhoTrajeto - Conversão e Estilos', () {
    const svgExemplo = 'M 100 800 C 120 700, 140 600, 160 500';

    test('deve converter SVG válido para Path no estilo SOLIDO', () {
      final caminho = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: 'linha_1',
        caminhoSvg: svgExemplo,
        estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
      );

      expect(caminho, isNotNull);
      final bounds = caminho.getBounds();
      expect(bounds.left, closeTo(100.0, 1.0));
      expect(bounds.right, closeTo(160.0, 1.0));
      expect(bounds.top, closeTo(500.0, 1.0));
      expect(bounds.bottom, closeTo(800.0, 1.0));
    });

    test('deve converter SVG para Path no estilo TRACEJADO', () {
      final caminhoSolido = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: 'linha_solida',
        caminhoSvg: svgExemplo,
        estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
      );

      final caminhoTracejado = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: 'linha_tracejada',
        caminhoSvg: svgExemplo,
        estilo: LinhaTrajeto_EstiloTraco.TRACEJADO,
      );

      expect(caminhoTracejado, isNotNull);
      // O tracejado gera múltiplos sub-caminhos (métricas)
      final metricasTracejado = caminhoTracejado.computeMetrics().toList();
      final metricasSolido = caminhoSolido.computeMetrics().toList();

      expect(metricasTracejado.length, greaterThan(metricasSolido.length));
    });

    test('deve converter SVG para Path no estilo PONTILHADO', () {
      final caminhoPontilhado = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: 'linha_pontilhada',
        caminhoSvg: svgExemplo,
        estilo: LinhaTrajeto_EstiloTraco.PONTILHADO,
      );

      expect(caminhoPontilhado, isNotNull);
      final metricas = caminhoPontilhado.computeMetrics().toList();
      expect(metricas.length, greaterThan(1));
    });

    test('deve retornar Path vazio sem erro para string SVG vazia', () {
      final caminho = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: 'linha_vazia',
        caminhoSvg: '',
        estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
      );

      expect(caminho, isNotNull);
      expect(caminho.getBounds().isEmpty, isTrue);
    });

    test('deve retornar Path vazio defensivamente para SVG corrompido ou inválido', () {
      final caminho = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: 'linha_corrompida',
        caminhoSvg: 'COMANDO_TOTALMENTE_INVALIDO_XYZ 123 456',
        estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
      );

      expect(caminho, isNotNull);
      expect(caminho.getBounds().isEmpty, isTrue);
    });
  });

  group('ConstrutorCaminhoTrajeto - Cache de Memória', () {
    const svgExemplo = 'M 0 0 L 100 100';

    test('deve reutilizar a mesma instância de Path em chamadas consecutivas com mesma chave', () {
      final caminho1 = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: 'linha_cache',
        caminhoSvg: svgExemplo,
        estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
      );

      final caminho2 = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: 'linha_cache',
        caminhoSvg: svgExemplo,
        estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
      );

      expect(identical(caminho1, caminho2), isTrue);
    });

    test('limparCache deve invalidar as entradas cacheadas', () {
      final caminho1 = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: 'linha_cache_limpeza',
        caminhoSvg: svgExemplo,
        estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
      );

      ConstrutorCaminhoTrajeto.limparCache();

      final caminho2 = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: 'linha_cache_limpeza',
        caminhoSvg: svgExemplo,
        estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
      );

      expect(identical(caminho1, caminho2), isFalse);
    });
  });

  group('ConstrutorCaminhoTrajeto - Conversão de Cor Hexadecimal', () {
    test('deve converter cor hexadecimal válida de 6 caracteres com #', () {
      final cor = ConstrutorCaminhoTrajeto.converterCorHex('#FF6D00');
      expect(cor, const Color(0xFFFF6D00));
    });

    test('deve converter cor hexadecimal sem #', () {
      final cor = ConstrutorCaminhoTrajeto.converterCorHex('00E5FF');
      expect(cor, const Color(0xFF00E5FF));
    });

    test('deve usar fallback se a string hexadecimal for inválida ou nula', () {
      const fallbackEsperado = Color(0xFFE27D60);
      expect(
        ConstrutorCaminhoTrajeto.converterCorHex('INVALIDO', fallback: fallbackEsperado),
        fallbackEsperado,
      );
      expect(
        ConstrutorCaminhoTrajeto.converterCorHex('', fallback: fallbackEsperado),
        fallbackEsperado,
      );
      expect(
        ConstrutorCaminhoTrajeto.converterCorHex(null, fallback: fallbackEsperado),
        fallbackEsperado,
      );
    });
  });

  group('ConstrutorCaminhoTrajeto - Amostragem de Curvas e Distância Euclidiana', () {
    test('deve amostrar pontos ao longo do caminho para cálculo de proximidade', () {
      final caminho = Path()..moveTo(0, 0)..lineTo(100, 0);
      final segmentos = ConstrutorCaminhoTrajeto.amostrarSegmentos(caminho, passo: 20.0);

      expect(segmentos.length, greaterThanOrEqualTo(5));
      expect(segmentos.first, const Offset(0, 0));
      expect(segmentos.last.dx, closeTo(100.0, 1.0));
      expect(segmentos.last.dy, closeTo(0.0, 1.0));
    });

    test('deve calcular distância euclidiana mínima corretamente até a linha', () {
      final segmentos = [
        const Offset(0, 0),
        const Offset(50, 0),
        const Offset(100, 0),
      ];

      // Toque a 10 unidades de distância no eixo Y
      final dist1 = ConstrutorCaminhoTrajeto.calcularDistanciaAoCaminho(
        const Offset(50, 10),
        segmentos,
      );
      expect(dist1, closeTo(10.0, 0.01));

      // Toque a 25 unidades de distância
      final dist2 = ConstrutorCaminhoTrajeto.calcularDistanciaAoCaminho(
        const Offset(50, 25),
        segmentos,
      );
      expect(dist2, closeTo(25.0, 0.01));
    });

    test('deve calcular distância quando segmentos contém pontos coincidentes (l2 == 0)', () {
      final distancia = ConstrutorCaminhoTrajeto.calcularDistanciaAoCaminho(
        const Offset(10, 10),
        [const Offset(0, 0), const Offset(0, 0)],
      );
      expect(distancia, closeTo(14.14, 0.1));
    });

    test('calcularDistanciaAoCaminho retorna infinito para lista vazia e distância direta para 1 ponto', () {
      expect(
        ConstrutorCaminhoTrajeto.calcularDistanciaAoCaminho(
          const Offset(10, 10),
          [],
        ),
        double.infinity,
      );
      expect(
        ConstrutorCaminhoTrajeto.calcularDistanciaAoCaminho(
          const Offset(10, 10),
          [const Offset(10, 20)],
        ),
        10.0,
      );
    });

    test('deve converter SVG para Path no estilo CAMINHADA', () {
      final path = ConstrutorCaminhoTrajeto.obterCaminho(
        chaveCache: 'caminhada_teste',
        caminhoSvg: 'M 0 0 L 100 100',
        estilo: LinhaTrajeto_EstiloTraco.CAMINHADA,
      );
      expect(path, isNotNull);
      expect(path.computeMetrics().isNotEmpty, isTrue);
    });
  });
}
