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

  /// Intervalo de confiança bilateral de `95%` via Tabela Z (`Z = 1,96`).
  ({double inferior, double superior}) intervaloConfianca95Z() {
    final p = taxaDeteccaoPod;
    final margem = zCritico95Bilateral * erroPadraoDeteccao;
    return (inferior: p - margem, superior: p + margem);
  }

  /// Calcula a estatística `Z = (p_hat - p0) / sqrt(p0 * (1 - p0) / n)` contra uma hipótese nula `H0: p = p0`.
  double calcularEscoreZContraH0(double p0) {
    final seH0 = math.sqrt(
      (p0 * (1.0 - p0)) / totalEventosReaisChuva.toDouble(),
    );
    return (taxaDeteccaoPod - p0) / seH0;
  }

  /// Taxa marginal esperada por puro acaso climatológico (`Heidke Skill Score H0`).
  double get taxaBaseAcasoHeidke {
    final n = totalPicoDias.toDouble();
    final pRealChuva = (verdadeirosPositivos + falsosNegativos) / n;
    final pPrevChuva = (verdadeirosPositivos + falsosPositivos) / n;
    return pRealChuva * pPrevChuva +
        (1.0 - pRealChuva) * (1.0 - pPrevChuva);
  }

  /// Estatística `Z` na cauda direita sobre toda a matriz `N = 5.133` contra o acaso climatológico `H0`.
  double calcularEscoreZHeidkeGlobal() {
    final p0 = taxaBaseAcasoHeidke;
    final seGlobal = math.sqrt((p0 * (1.0 - p0)) / totalPicoDias.toDouble());
    return (acuraciaGlobal - p0) / seGlobal;
  }
}

/// Referência matemática e estatística pura do índice empírico de `~85%` exibido no aplicativo.
abstract final class EstudoEstatisticoClimaAresta {
  /// Percentual conservador exibido no aviso de uso (`85%`, arredondado de `84,3%–85,5%`).
  static const int taxaReferenciaExibidaPercentual = 85;

  /// Taxa empírica de detecção na janela conservadora de 4 dias de umidade no pico (`1.867 / 2.305`).
  static const double taxaDeteccaoJanelaQuatroDias = 0.8100;

  /// Taxa publicada de detecção de fogo ativo do sensor orbital `NASA VIIRS 375m (VNP14IMG)`.
  static const double taxaDeteccaoIncendioViirsNasa = 0.8650;

  /// Hindcast independente de 180 dias (`01/06/2024 – 27/11/2024`, `29` picos, ` NOAA GFS 0,25°` vs `ECMWF ERA5`).
  static const MatrizContingenciaClima matrizChuvaRegional =
      MatrizContingenciaClima(
        verdadeirosPositivos: 1306,
        verdadeirosNegativos: 3426,
        falsosPositivos: 179,
        falsosNegativos: 222,
      );

  /// Entradas de referência da Tabela Normal Padrão (`Φ(Z)`) para verificação manual direta.
  static const List<LinhaTabelaPadraoZ> linhasTabelaPadraoZ = [
    LinhaTabelaPadraoZ(
      escoreZ: 0.00,
      probabilidadeAcumuladaPhi: 0.5000,
      caudaDireitaP: 0.5000,
      chaveInterpretacao: ChaveTexto.estatClimaZNotaMedia,
    ),
    LinhaTabelaPadraoZ(
      escoreZ: 1.28,
      probabilidadeAcumuladaPhi: 0.8997,
      caudaDireitaP: 0.1003,
      chaveInterpretacao: ChaveTexto.estatClimaZNota90,
    ),
    LinhaTabelaPadraoZ(
      escoreZ: 1.65,
      probabilidadeAcumuladaPhi: 0.9505,
      caudaDireitaP: 0.0495,
      chaveInterpretacao: ChaveTexto.estatClimaZNota95,
    ),
    LinhaTabelaPadraoZ(
      escoreZ: 1.96,
      probabilidadeAcumuladaPhi: 0.9750,
      caudaDireitaP: 0.0250,
      chaveInterpretacao: ChaveTexto.estatClimaZNotaIC95,
      destacar: true,
    ),
    LinhaTabelaPadraoZ(
      escoreZ: 2.33,
      probabilidadeAcumuladaPhi: 0.9901,
      caudaDireitaP: 0.0099,
      chaveInterpretacao: ChaveTexto.estatClimaZNota99,
    ),
    LinhaTabelaPadraoZ(
      escoreZ: 2.57,
      probabilidadeAcumuladaPhi: 0.9949,
      caudaDireitaP: 0.0051,
      chaveInterpretacao: ChaveTexto.estatClimaZNotaTeste83,
