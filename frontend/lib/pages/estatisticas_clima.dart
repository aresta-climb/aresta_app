// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import '../data/modelos/modelos_estatisticas_clima.dart';
import '../idioma/tradutor_app.dart';
import '../navigation/funcoes_navegacao.dart';
import '../theme/cores_app.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../widgets/clima/componentes_estatisticas_clima.dart';
import '../widgets/clima/grafico_distribuicao_z_clima.dart';

/// Página declarativa (Dumb UI) integrada à árvore de navegação (`EstatisticasClimaNode`)
/// dedicada à demonstração matemática, verificação pela Tabela Normal Padrão (`Tabela Z`)
/// e detalhamento das 6 fontes de dados que fundamentam o índice empírico de `~85%`.
class PaginaEstatisticasClima extends StatelessWidget {
  const PaginaEstatisticasClima({super.key});

  @override
  Widget build(BuildContext context) {
    context.idiomaApp;
    final cores = context.colors;
    final recuoInferior = MediaQuery.paddingOf(context).bottom;
    const matriz = EstudoEstatisticoClimaAresta.matrizChuvaRegional;
    final ic95 = matriz.intervaloConfianca95Z();
    final zContra50 = matriz.calcularEscoreZContraH0(0.50);
    final zContra83 = matriz.calcularEscoreZContraH0(0.83);
    final zHeidke = matriz.calcularEscoreZHeidkeGlobal();

    return Scaffold(
      key: const Key('pagina_estatisticas_clima'),
      backgroundColor: cores.deepBasalt,
      appBar: buildCommonAppBar(
        context,
        context.tr(ChaveTexto.estatClimaTituloPagina),
        onBack: () => AppNav.back(context),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 28 + recuoInferior),
          children: [
            _construirCartaoHeroi85(context, cores, ic95),
            const SizedBox(height: 16),
            _construirSecaoComposicao(context, matriz),
            const SizedBox(height: 16),
            _construirSecaoMatrizEFormulas(
              context,
              cores,
              matriz,
              ic95,
              zContra50,
              zContra83,
              zHeidke,
            ),
            const SizedBox(height: 16),
            _construirSecaoTabelaZ(context, cores),
            const SizedBox(height: 16),
            _construirSecaoFontesEspecificas(context, cores),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cores.caveShadow,
                borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: cores.caveShadow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cores.rustIron.withValues(alpha: 0.45), width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: cores.rustIron.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: cores.rustIron.withValues(alpha: 0.38)),
            ),
            child: Text(
              'N = 5.133  •  95% Z-CI [$infPct% – $supPct%]',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: cores.chalkWhite,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '~${EstudoEstatisticoClimaAresta.taxaReferenciaExibidaPercentual}%',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: cores.rustIron,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              height: 1.05,
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
    MatrizContingenciaClima matriz,
  ) {
    return CartaoSecaoEstatisticaClima(
      icone: Icons.layers_outlined,
      titulo: context.tr(ChaveTexto.estatClimaSecaoComposicaoTitulo),
      filho: Column(
        children: [
          LinhaBarraMetricaClima(
            rotulo: context.tr(ChaveTexto.estatClimaComposicaoChuvaMapa),
            valorFormatado: '${(matriz.taxaDeteccaoPod * 100).toStringAsFixed(1)}%',
            fator: matriz.taxaDeteccaoPod,
          ),
          const SizedBox(height: 14),
          LinhaBarraMetricaClima(
            rotulo: context.tr(ChaveTexto.estatClimaComposicaoUmidade4d),
            valorFormatado:
                '${(EstudoEstatisticoClimaAresta.taxaDeteccaoJanelaQuatroDias * 100).toStringAsFixed(1)}%',
            fator: EstudoEstatisticoClimaAresta.taxaDeteccaoJanelaQuatroDias,
          ),
          const SizedBox(height: 14),
          LinhaBarraMetricaClima(
            rotulo: context.tr(ChaveTexto.estatClimaComposicaoIncendioNasa),
            valorFormatado:
                '${(EstudoEstatisticoClimaAresta.taxaDeteccaoIncendioViirsNasa * 100).toStringAsFixed(1)}%',
            fator: EstudoEstatisticoClimaAresta.taxaDeteccaoIncendioViirsNasa,
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

    return CartaoSecaoEstatisticaClima(
      icone: Icons.grid_view_rounded,
      titulo: context.tr(ChaveTexto.estatClimaSecaoMatrizTitulo),
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(ChaveTexto.estatClimaMatrizExplicacao),
            style: TextStyle(color: cores.ashGrey, fontSize: 12.5, height: 1.44),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CelulaMatrizClima(
                  sigla: 'TP = ${matriz.verdadeirosPositivos}',
                  detalhe: 'ERA5 + GFS (Hit)',
                  destaque: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CelulaMatrizClima(
                  sigla: 'FP = ${matriz.falsosPositivos}',
                  detalhe: 'GFS > ERA5',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CelulaMatrizClima(
                  sigla: 'FN = ${matriz.falsosNegativos}',
                  detalhe: 'ERA5 > GFS',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CelulaMatrizClima(
                  sigla: 'TN = ${matriz.verdadeirosNegativos}',
                  detalhe: 'Seco (0 mm)',
                  destaque: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cores.deepBasalt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cores.graniteEdge),
            ),
            child: Column(
              children: [
                LinhaFormulaEstatisticaClima(
                  titulo: 'POD (p̂)',
                  equacao: 'TP / (TP + FN) = 1.306 / 1.528',
                  resultado: '$pHat%',
                  destaque: true,
                ),
                Divider(height: 14, color: cores.graniteEdge),
                LinhaFormulaEstatisticaClima(
                  titulo: 'SE & 95% Z-CI',
                  equacao: 'SE = $sePct%  •  p̂ ± 1.96 × SE',
                  resultado: '[$infPct%, $supPct%]',
                ),
                Divider(height: 14, color: cores.graniteEdge),
                LinhaFormulaEstatisticaClima(
                  titulo: 'ACC & CSI',
                  equacao: '(TP + TN) / 5.133  •  CSI = $csiPct%',
                  resultado: '$accPct%',
                ),
                Divider(height: 14, color: cores.graniteEdge),
                LinhaFormulaEstatisticaClima(
                  titulo: 'Z (H₀ = 0.50)',
                  equacao: 'Heidke global = +${zHeidke.toStringAsFixed(2)}σ',
                  resultado: '+${zContra50.toStringAsFixed(2)}σ',
                ),
                Divider(height: 14, color: cores.graniteEdge),
                LinhaFormulaEstatisticaClima(
                  titulo: 'Z (H₀ ≤ 0.83)',
                  equacao: 'Φ(+2.57) = 0.9949  (p = 0.0051)',
                  resultado: '+${zContra83.toStringAsFixed(2)}σ',
                  destaque: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSecaoTabelaZ(BuildContext context, AppColors cores) {
    return CartaoSecaoEstatisticaClima(
      icone: Icons.functions_rounded,
      titulo: context.tr(ChaveTexto.estatClimaSecaoTabelaZTitulo),
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(ChaveTexto.estatClimaTabelaZExplicacao),
            style: TextStyle(color: cores.ashGrey, fontSize: 12.5, height: 1.44),
          ),
          const SizedBox(height: 14),
          GraficoDistribuicaoZClima(
            rotuloH0: context.tr(ChaveTexto.estatClimaGraficoH0Rotulo),
            rotuloCaudaDireita: context.tr(ChaveTexto.estatClimaGraficoCaudaRotulo),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cores.deepBasalt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cores.graniteEdge),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(
                      children: [
                        Expanded(
                          child: _textoCabecalhoTabelaZ(
                            context.tr(ChaveTexto.estatClimaColunaZ),
                            cores,
                            TextAlign.left,
                          ),
                        ),
                        Expanded(
                          child: _textoCabecalhoTabelaZ(
                            context.tr(ChaveTexto.estatClimaColunaPhi),
                            cores,
                            TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: _textoCabecalhoTabelaZ(
                            context.tr(ChaveTexto.estatClimaColunaCauda),
                            cores,
                            TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: cores.graniteEdge),
                  for (final linha in EstudoEstatisticoClimaAresta.linhasTabelaPadraoZ)
                    LinhaTabelaZResponsivaClima(linha: linha),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textoCabecalhoTabelaZ(
    String texto,
    AppColors cores,
    TextAlign alinhamento,
  ) =>
      Text(
        texto,
        textAlign: alinhamento,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: cores.chalkWhite,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      );

  Widget _construirSecaoFontesEspecificas(
    BuildContext context,
    AppColors cores,
  ) {
    return CartaoSecaoEstatisticaClima(
      icone: Icons.satellite_alt_rounded,
      titulo: context.tr(ChaveTexto.estatClimaSecaoFontesTitulo),
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(ChaveTexto.estatClimaGrupoFontesMeteo),
            style: TextStyle(
              color: cores.rustIron,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          for (final fonte
              in EstudoEstatisticoClimaAresta.fontesMeteorologicas) ...[
            CartaoFonteDadosClima(fonte: fonte),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Text(
            context.tr(ChaveTexto.estatClimaGrupoFontesNasa),
            style: TextStyle(
              color: cores.rustIron,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          for (final fonte
              in EstudoEstatisticoClimaAresta.fontesMissoesNasa) ...[
            CartaoFonteDadosClima(fonte: fonte),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
