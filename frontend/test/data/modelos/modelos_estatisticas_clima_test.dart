// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_estatisticas_clima.dart';

void main() {
  group('EstudoEstatisticoClimaAresta e MatrizContingenciaClima', () {
    test(
      'calcula taxa empírica de detecção (~85%), erro padrão, IC 95% pela Tabela Z e escores Z contra H0',
      () {
        const matriz = EstudoEstatisticoClimaAresta.matrizChuvaRegional;

        expect(matriz.totalPicoDias, equals(5133));
        expect(matriz.totalEventosReaisChuva, equals(1528));
        expect(matriz.taxaDeteccaoPod, closeTo(0.8547, 0.0005));
        expect(matriz.acuraciaGlobal, closeTo(0.9219, 0.0005));
        expect(matriz.indiceSucessoCriticoCsi, closeTo(0.7651, 0.0005));
        expect(matriz.erroPadraoDeteccao, closeTo(0.0090, 0.0002));

        final ic95 = matriz.intervaloConfianca95Z();
        expect(ic95.inferior, closeTo(0.8370, 0.0005));
        expect(ic95.superior, closeTo(0.8724, 0.0005));

        // Contra hipótese nula sem habilidade (p0 = 0.50): Z = +27.73 sigma
        expect(matriz.calcularEscoreZContraH0(0.50), closeTo(27.73, 0.05));

        // Teste unilateral verificável dentro da Tabela Z impressa (H0: p <= 0.83 -> Z = +2.57)
        final zContra83 = matriz.calcularEscoreZContraH0(0.83);
        expect(zContra83, closeTo(2.57, 0.02));
        expect(
          1.0 - EstudoEstatisticoClimaAresta.aproximarPhiNormalPadrao(zContra83),
          closeTo(0.0051, 0.0005),
        );

        // Escore Z de Heidke global sobre N = 5.133 pico-dias
        expect(matriz.taxaBaseAcasoHeidke, closeTo(0.5853, 0.0005));
        expect(matriz.calcularEscoreZHeidkeGlobal(), closeTo(48.95, 0.10));

        expect(
          EstudoEstatisticoClimaAresta.taxaReferenciaExibidaPercentual,
          equals(85),
        );
      },
    );

    test(
      'aproxima integral acumulada Normal Padrão Phi(z) em conformidade com todas as linhas da Tabela Z',
      () {
        expect(
          EstudoEstatisticoClimaAresta.aproximarPhiNormalPadrao(0.0),
          closeTo(0.5000, 1e-4),
        );
        expect(
          EstudoEstatisticoClimaAresta.aproximarPhiNormalPadrao(-1.96),
          closeTo(0.0250, 2e-4),
        );

        for (final linha in EstudoEstatisticoClimaAresta.linhasTabelaPadraoZ) {
          final phiCalc = EstudoEstatisticoClimaAresta.aproximarPhiNormalPadrao(
            linha.escoreZ,
          );
          expect(phiCalc, closeTo(linha.probabilidadeAcumuladaPhi, 2e-4));
          expect(
            linha.probabilidadeAcumuladaPhi + linha.caudaDireitaP,
            closeTo(1.0, 2e-4),
          );
        }

        expect(EstudoEstatisticoClimaAresta.fontesMeteorologicas.length, equals(3));
        expect(EstudoEstatisticoClimaAresta.fontesMissoesNasa.length, equals(3));
      },
    );
  });
}
