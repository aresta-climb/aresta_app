// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../services/firebase/app_logger.dart';

/// Utilitário central de domínio para conversão e estilização de trajetos vetoriais.
///
/// Este componente centraliza e encapsula o uso da biblioteca [path_drawing], atuando como
/// uma barreira arquitetural que previne o acoplamento de componentes gráficos ou páginas com
/// pacotes externos de manipulação de caminhos SVG.
///
/// Principais responsabilidades:
/// - Conversão de strings de comandos SVG em instâncias nativas de [Path] do Flutter.
/// - Aplicação de estilos de traçado da FEMEMG (sólido, tracejado para escalada livre, pontilhado).
/// - Cache em memória dos caminhos processados para evitar alocações excessivas de objetos durante
///   operações de pan e zoom a 60/120 FPS.
/// - Conversão resiliente de cores hexadecimais com suporte a fallback de alto contraste.
/// - Amostragem geométrica de segmentos para suporte a detecção ergonômica de toques (hit-testing).
class ConstrutorCaminhoTrajeto {
  /// Cache de instâncias de [Path] processadas indexadas por chave de cache e estilo.
  static final Map<String, Path> _cacheCaminhos = {};

  /// Cache de instâncias de [Path] decompostas no espaço de tela do viewport.
  static final Map<String, Path> _cacheCaminhosViewport = {};

  /// Limpa o cache de caminhos em memória.
  ///
  /// Deve ser acionado em eventos de invalidação de dados, migração de croquis ou recarga do mapa.
  static void limparCache() {
    _cacheCaminhos.clear();
    _cacheCaminhosViewport.clear();
  }

  /// Converte a string SVG compilada em um [Path] nativo, aplicando o estilo configurado.
  ///
  /// Utiliza [chaveCache] para reutilizar instâncias já calculadas, evitando reconstrução de
  /// métricas de traço a cada quadro do método `paint`.
  static Path obterCaminho({
    required String chaveCache,
    required String caminhoSvg,
    required LinhaTrajeto_EstiloTraco estilo,
  }) {
    final chave = '$chaveCache-${estilo.name}';
    if (_cacheCaminhos.containsKey(chave)) {
      return _cacheCaminhos[chave]!;
    }

    if (caminhoSvg.trim().isEmpty) {
      final vazio = Path();
      _cacheCaminhos[chave] = vazio;
      return vazio;
    }

    try {
      final basePath = parseSvgPathData(caminhoSvg);
      Path caminhoFinal;

      switch (estilo) {
        case LinhaTrajeto_EstiloTraco.TRACEJADO:
          // Padrão FEMEMG B3-a para escalada livre: traços longos com espaçamento intermediário
          caminhoFinal = dashPath(
            basePath,
            dashArray: CircularIntervalList<double>([12.0, 6.0]),
          );
          break;
        case LinhaTrajeto_EstiloTraco.PONTILHADO:
          // Padrão FEMEMG B3-b para trechos em artificial: pontos curtos
          caminhoFinal = dashPath(
            basePath,
            dashArray: CircularIntervalList<double>([3.0, 5.0]),
          );
          break;
        case LinhaTrajeto_EstiloTraco.CAMINHADA:
          // Padrão FEMEMG B3-c para caminhadas / acessos
          caminhoFinal = dashPath(
            basePath,
            dashArray: CircularIntervalList<double>([8.0, 4.0]),
          );
          break;
        case LinhaTrajeto_EstiloTraco.SOLIDO:
        default:
          caminhoFinal = basePath;
          break;
      }

      _cacheCaminhos[chave] = caminhoFinal;
      return caminhoFinal;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Falha ao converter SVG de trajeto para Path ($chave)',
        error: e,
        stackTrace: stackTrace,
      );
      final fallback = Path();
      _cacheCaminhos[chave] = fallback;
      return fallback;
    }
  }

  /// Aplica a decomposição métrica de estilo de traço diretamente no espaço do viewport local (dp).
  ///
  /// Ao aplicar o tracejado após a projeção para coordenadas de tela, garante-se que os intervalos
  /// de traço e espaço mantenham dimensões constantes e nítidas (independente da resolução do mapa base).
  ///
  /// Padrões adotados (em dp lógicos de tela):
  /// - `TRACEJADO` (Escalada livre): 8.0dp traço / 4.0dp vão
  /// - `PONTILHADO` (Artificial): 3.0dp traço / 4.0dp vão
  /// - `CAMINHADA` (Trilhas / Acessos): 6.0dp traço / 4.0dp vão
  /// - `SOLIDO`: Retorna o próprio [caminhoTransformado] sem cortes
  static Path aplicarEstiloNoViewport(
    Path caminhoTransformado,
    LinhaTrajeto_EstiloTraco estilo, {
    String? chaveCache,
  }) {
    if (chaveCache != null) {
      final chave = '$chaveCache-${estilo.name}';
      if (_cacheCaminhosViewport.containsKey(chave)) {
        return _cacheCaminhosViewport[chave]!;
      }
    }

    Path caminhoFinal;
    switch (estilo) {
      case LinhaTrajeto_EstiloTraco.TRACEJADO:
        caminhoFinal = dashPath(
          caminhoTransformado,
          dashArray: CircularIntervalList<double>([8.0, 4.0]),
        );
        break;
      case LinhaTrajeto_EstiloTraco.PONTILHADO:
        caminhoFinal = dashPath(
          caminhoTransformado,
          dashArray: CircularIntervalList<double>([3.0, 4.0]),
        );
        break;
      case LinhaTrajeto_EstiloTraco.CAMINHADA:
        caminhoFinal = dashPath(
          caminhoTransformado,
          dashArray: CircularIntervalList<double>([6.0, 4.0]),
        );
        break;
      case LinhaTrajeto_EstiloTraco.SOLIDO:
      default:
        caminhoFinal = caminhoTransformado;
        break;
    }

    if (chaveCache != null) {
      final chave = '$chaveCache-${estilo.name}';
      _cacheCaminhosViewport[chave] = caminhoFinal;
    }

    return caminhoFinal;
  }

  /// Converte uma string hexadecimal (#RRGGBB ou RRGGBB) para uma instância de [Color].
  ///
  /// Retorna [fallback] caso a string seja nula, vazia ou inválida.
  static Color converterCorHex(
    String? hexString, {
    Color fallback = const Color(0xFFE27D60),
  }) {
    if (hexString == null || hexString.trim().isEmpty) {
      return fallback;
    }

    try {
      var limpo = hexString.trim();
      if (limpo.startsWith('#')) {
        limpo = limpo.substring(1);
      }
      if (limpo.length == 6) {
        limpo = 'FF$limpo';
      }
      return Color(int.parse(limpo, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  /// Amostra pontos regulares ao longo de um [Path] para formar uma polilinha aproximada.
  ///
  /// Utilizado para cálculo de menor distância euclidiana durante a detecção de toques.
  static List<Offset> amostrarSegmentos(
    Path caminho, {
    double passo = 15.0,
  }) {
    final pontos = <Offset>[];
    for (final metrica in caminho.computeMetrics()) {
      if (metrica.length <= 0) continue;

      for (double d = 0; d < metrica.length; d += passo) {
        final tangente = metrica.getTangentForOffset(d);
        if (tangente != null) {
          pontos.add(tangente.position);
        }
      }

      // Garante que o ponto final do contorno seja incluído
      final tangenteFinal = metrica.getTangentForOffset(metrica.length);
      if (tangenteFinal != null) {
        pontos.add(tangenteFinal.position);
      }
    }
    return pontos;
  }

  /// Calcula a menor distância euclidiana entre um ponto de toque e a polilinha amostrada.
  static double calcularDistanciaAoCaminho(
    Offset ponto,
    List<Offset> segmentos,
  ) {
    if (segmentos.isEmpty) return double.infinity;
    if (segmentos.length == 1) return (ponto - segmentos.first).distance;

    double menorDistanciaSq = double.infinity;

    for (int i = 0; i < segmentos.length - 1; i++) {
      final p1 = segmentos[i];
      final p2 = segmentos[i + 1];

      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final l2 = dx * dx + dy * dy;

      double distSq;
      if (l2 == 0) {
        final distDx = ponto.dx - p1.dx;
        final distDy = ponto.dy - p1.dy;
        distSq = distDx * distDx + distDy * distDy;
      } else {
        var t = ((ponto.dx - p1.dx) * dx + (ponto.dy - p1.dy) * dy) / l2;
        t = t.clamp(0.0, 1.0);
        final projX = p1.dx + t * dx;
        final projY = p1.dy + t * dy;
        final distDx = ponto.dx - projX;
        final distDy = ponto.dy - projY;
        distSq = distDx * distDx + distDy * distDy;
      }

      if (distSq < menorDistanciaSq) {
        menorDistanciaSq = distSq;
      }
    }

    return math.sqrt(menorDistanciaSq);
  }
}
