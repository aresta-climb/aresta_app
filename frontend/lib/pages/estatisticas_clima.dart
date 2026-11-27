// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import '../data/modelos/modelos_estatisticas_clima.dart';
import '../idioma/tradutor_app.dart';
import '../theme/cores_app.dart';
import '../widgets/clima/grafico_distribuicao_z_clima.dart';
import '../widgets/navegacao/botao_voltar_com_retorno_inicio.dart';

/// Página declarativa (Dumb UI) dedicada exclusivamente à demonstração matemática,
/// verificação pela Tabela Normal Padrão (`Tabela Z`) e detalhamento das 6 fontes de dados
/// que fundamentam o índice empírico de `~85%` da ferramenta climática do Aresta Climb.
class PaginaEstatisticasClima extends StatelessWidget {
  const PaginaEstatisticasClima({super.key});

  @override
  Widget build(BuildContext context) {
    context.idiomaApp;
    final cores = context.colors;
    const matriz = EstudoEstatisticoClimaAresta.matrizChuvaRegional;
    final ic95 = matriz.intervaloConfianca95Z();
    final zContra50 = matriz.calcularEscoreZContraH0(0.50);
    final zContra83 = matriz.calcularEscoreZContraH0(0.83);
    final zHeidke = matriz.calcularEscoreZHeidkeGlobal();

    return Scaffold(
      key: const Key('pagina_estatisticas_clima'),
      backgroundColor: cores.deepBasalt,
      appBar: AppBar(
        backgroundColor: cores.deepBasalt,
        elevation: 0,
        leading: BotaoVoltarComRetornoInicio(corIcone: cores.chalkWhite),
        centerTitle: true,
        title: Text(
          context.tr(ChaveTexto.estatClimaTituloPagina),
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: cores.chalkWhite,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
          children: [
            _construirCartaoHeroi85(context, cores, ic95),
            const SizedBox(height: 18),
            _construirSecaoComposicao(context, cores, matriz),
            const SizedBox(height: 18),
            _construirSecaoMatrizEFormulas(
              context,
              cores,
              matriz,
              ic95,
              zContra50,
              zContra83,
              zHeidke,
            ),
            const SizedBox(height: 18),
            _construirSecaoTabelaZ(context, cores),
            const SizedBox(height: 18),
            _construirSecaoFontesEspecificas(context, cores),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cores.caveShadow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cores.graniteEdge),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: cores.rustIron),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr(ChaveTexto.estatClimaAvisoFinal),
                      style: TextStyle(color: cores.ashGrey, fontSize: 12.5, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCartaoHeroi85(
    BuildContext context,
    AppColors cores,
    ({double inferior, double superior}) ic95,
  ) {
    final infPct = (ic95.inferior * 100.0).toStringAsFixed(1);
    final supPct = (ic95.superior * 100.0).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cores.caveShadow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cores.rustIron.withValues(alpha: 0.45), width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            '~${EstudoEstatisticoClimaAresta.taxaReferenciaExibidaPercentual}%',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: cores.rustIron,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '95% Z-CI: [$infPct% – $supPct%]  •  N = 5.133',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: cores.chalkWhite,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr(ChaveTexto.estatClimaSubtituloHeroi),
            textAlign: TextAlign.center,
            style: TextStyle(color: cores.ashGrey, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _construirSecaoComposicao(
    BuildContext context,
    AppColors cores,
    MatrizContingenciaClima matriz,
  ) {
    return _CartaoSecaoEstatistica(
      titulo: context.tr(ChaveTexto.estatClimaSecaoComposicaoTitulo),
      cores: cores,
      filho: Column(
        children: [
          _LinhaBarraMetrica(
            rotulo: context.tr(ChaveTexto.estatClimaComposicaoChuvaMapa),
            valorFormatado: '${(matriz.taxaDeteccaoPod * 100).toStringAsFixed(1)}%',
            fator: matriz.taxaDeteccaoPod,
            cores: cores,
          ),
          const SizedBox(height: 12),
          _LinhaBarraMetrica(
            rotulo: context.tr(ChaveTexto.estatClimaComposicaoUmidade4d),
            valorFormatado:
                '${(EstudoEstatisticoClimaAresta.taxaDeteccaoJanelaQuatroDias * 100).toStringAsFixed(1)}%',
            fator: EstudoEstatisticoClimaAresta.taxaDeteccaoJanelaQuatroDias,
            cores: cores,
          ),
          const SizedBox(height: 12),
          _LinhaBarraMetrica(
            rotulo: context.tr(ChaveTexto.estatClimaComposicaoIncendioNasa),
            valorFormatado:
                '${(EstudoEstatisticoClimaAresta.taxaDeteccaoIncendioViirsNasa * 100).toStringAsFixed(1)}%',
            fator: EstudoEstatisticoClimaAresta.taxaDeteccaoIncendioViirsNasa,
            cores: cores,
          ),
        ],
      ),
    );
  }

  Widget _construirSecaoMatrizEFormulas(
    BuildContext context,
    AppColors cores,
    MatrizContingenciaClima matriz,
    ({double inferior, double superior}) ic95,
    double zContra50,
    double zContra83,
    double zHeidke,
  ) {
    final pHat = (matriz.taxaDeteccaoPod * 100).toStringAsFixed(2);
    final sePct = (matriz.erroPadraoDeteccao * 100).toStringAsFixed(2);
    final infPct = (ic95.inferior * 100).toStringAsFixed(2);
    final supPct = (ic95.superior * 100).toStringAsFixed(2);
    final accPct = (matriz.acuraciaGlobal * 100).toStringAsFixed(2);
    final csiPct = (matriz.indiceSucessoCriticoCsi * 100).toStringAsFixed(2);

    return _CartaoSecaoEstatistica(
      titulo: context.tr(ChaveTexto.estatClimaSecaoMatrizTitulo),
      cores: cores,
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(ChaveTexto.estatClimaMatrizExplicacao),
            style: TextStyle(color: cores.ashGrey, fontSize: 12.5, height: 1.42),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CelulaMatriz(
                  sigla: 'TP = ${matriz.verdadeirosPositivos}',
                  detalhe: 'Hit (Chuva real)',
                  destaque: true,
                  cores: cores,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CelulaMatriz(
                  sigla: 'FP = ${matriz.falsosPositivos}',
                  detalhe: 'Alarme falso',
                  destaque: false,
                  cores: cores,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CelulaMatriz(
                  sigla: 'FN = ${matriz.falsosNegativos}',
                  detalhe: 'Omissão',
                  destaque: false,
                  cores: cores,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CelulaMatriz(
                  sigla: 'TN = ${matriz.verdadeirosNegativos}',
                  detalhe: 'Seco confirmado',
                  destaque: true,
                  cores: cores,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cores.deepBasalt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cores.graniteEdge),
            ),
            child: SelectableText(
              'p̂ (POD) = TP / (TP + FN) = 1306 / 1528 = $pHat%\n'
              'SE = √[p̂(1 − p̂) / 1528] = $sePct%\n'
              'IC 95% (Z = 1.96) = $pHat% ± 1.96 × $sePct% = [$infPct%, $supPct%]\n'
              'Acurácia Global = (TP + TN) / 5133 = $accPct%  |  CSI = $csiPct%\n'
              'Z (vs H₀ = 50%) = +${zContra50.toStringAsFixed(2)}σ  |  Z (Heidke) = +${zHeidke.toStringAsFixed(2)}σ\n'
              'Z (vs H₀ ≤ 83%) = +${zContra83.toStringAsFixed(2)}σ → Φ(+2.57) = 0.9949 (p = 0.0051)',
              style: TextStyle(
                fontFamily: 'monospace',
                color: cores.chalkWhite,
                fontSize: 11.5,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSecaoTabelaZ(BuildContext context, AppColors cores) {
    return _CartaoSecaoEstatistica(
      titulo: context.tr(ChaveTexto.estatClimaSecaoTabelaZTitulo),
      cores: cores,
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(ChaveTexto.estatClimaTabelaZExplicacao),
            style: TextStyle(color: cores.ashGrey, fontSize: 12.5, height: 1.42),
          ),
          const SizedBox(height: 12),
          GraficoDistribuicaoZClima(
            rotuloH0: context.tr(ChaveTexto.estatClimaGraficoH0Rotulo),
            rotuloCaudaDireita: context.tr(ChaveTexto.estatClimaGraficoCaudaRotulo),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cores.deepBasalt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cores.graniteEdge),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      _celulaCabecalhoTabelaZ(context.tr(ChaveTexto.estatClimaColunaZ), 52, cores),
                      _celulaCabecalhoTabelaZ(context.tr(ChaveTexto.estatClimaColunaPhi), 68, cores),
                      _celulaCabecalhoTabelaZ(context.tr(ChaveTexto.estatClimaColunaCauda), 68, cores),
                      Expanded(child: _textoCabecalhoTabelaZ(context.tr(ChaveTexto.estatClimaColunaNota), cores)),
                    ],
                  ),
                ),
                Divider(height: 1, color: cores.graniteEdge),
                for (final linha in EstudoEstatisticoClimaAresta.linhasTabelaPadraoZ)
                  Container(
                    color: linha.destacar ? cores.rustIron.withValues(alpha: 0.12) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          child: Text(
                            '+${linha.escoreZ.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: linha.destacar ? cores.rustIron : cores.chalkWhite,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 68,
                          child: Text(
                            linha.probabilidadeAcumuladaPhi.toStringAsFixed(4),
                            style: TextStyle(fontFamily: 'monospace', color: cores.chalkWhite, fontSize: 11.5),
                          ),
                        ),
                        SizedBox(
                          width: 68,
                          child: Text(
                            linha.caudaDireitaP.toStringAsFixed(4),
                            style: TextStyle(fontFamily: 'monospace', color: cores.ashGrey, fontSize: 11.5),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            context.tr(linha.chaveInterpretacao),
                            style: TextStyle(
                              color: linha.destacar ? cores.chalkWhite : cores.ashGrey,
                              fontSize: 11,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

