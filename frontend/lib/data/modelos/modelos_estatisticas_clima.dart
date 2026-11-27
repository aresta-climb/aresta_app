// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;

import '../../idioma/modelo_idioma_app.dart';

/// Classificação das fontes de dados utilizadas pelo radar climático e topográfico do Aresta.
enum CategoriaFonteClimaMapa {
  meteorologiaRadar,
  missaoPublicaNasa,
}

/// Metadados imutáveis de uma fonte específica utilizada na camada de clima, fogo e relevo.
class FonteDadosClimaMapa {
  final String id;
  final String nome;
  final String resolucaoEspacial;
  final CategoriaFonteClimaMapa categoria;
  final ChaveTexto chaveDescricao;

  const FonteDadosClimaMapa({
    required this.id,
    required this.nome,
    required this.resolucaoEspacial,
    required this.categoria,
    required this.chaveDescricao,
  });
}

/// Entrada canônica da Tabela Normal Padrão (`Tabela Z`) para conferência manual pelo usuário.
class LinhaTabelaPadraoZ {
  final double escoreZ;
  final double probabilidadeAcumuladaPhi;
  final double caudaDireitaP;
  final ChaveTexto chaveInterpretacao;
  final bool destacar;

  const LinhaTabelaPadraoZ({
    required this.escoreZ,
    required this.probabilidadeAcumuladaPhi,
    required this.caudaDireitaP,
    required this.chaveInterpretacao,
    this.destacar = false,
  });
}

/// Matriz de contingência `2x2` validada empiricamente em `N = 5.133` pico-dias reais.
class MatrizContingenciaClima {
  static const double zCritico95Bilateral = 1.959963984540054;

  final int verdadeirosPositivos;
  final int verdadeirosNegativos;
  final int falsosPositivos;
  final int falsosNegativos;

  const MatrizContingenciaClima({
    required this.verdadeirosPositivos,
    required this.verdadeirosNegativos,
    required this.falsosPositivos,
    required this.falsosNegativos,
  });

  /// Total de observações independentes (`N = TP + TN + FP + FN`).
  int get totalPicoDias =>
      verdadeirosPositivos +
      verdadeirosNegativos +
      falsosPositivos +
      falsosNegativos;

  /// Total de dias com precipitação real observada no pico (`n = TP + FN`).
  int get totalEventosReaisChuva => verdadeirosPositivos + falsosNegativos;

  /// Taxa empírica de detecção / sensibilidade (`POD = TP / (TP + FN)`).
  double get taxaDeteccaoPod =>
      verdadeirosPositivos / totalEventosReaisChuva.toDouble();

  /// Acurácia binária global incluindo dias secos (`(TP + TN) / N`).
  double get acuraciaGlobal =>
      (verdadeirosPositivos + verdadeirosNegativos) / totalPicoDias.toDouble();

  /// Índice de Sucesso Crítico / Threat Score (`CSI = TP / (TP + FP + FN)`).
  double get indiceSucessoCriticoCsi =>
      verdadeirosPositivos /
      (verdadeirosPositivos + falsosPositivos + falsosNegativos).toDouble();

  /// Erro padrão amostral da taxa de detecção (`SE = sqrt(p * (1 - p) / n)`).
  double get erroPadraoDeteccao {
    final p = taxaDeteccaoPod;
    return math.sqrt((p * (1.0 - p)) / totalEventosReaisChuva.toDouble());
  }

