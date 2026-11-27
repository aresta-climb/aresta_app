// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_estatisticas_clima.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/clima/componentes_estatisticas_clima.dart';

void main() {
  group('Componentes visuais de estatísticas climáticas', () {
    testWidgets(
      'renderiza cartões de seção, fórmulas, linhas da Tabela Z, barras, células 2x2 e fontes sem overflow',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
            home: Scaffold(
              body: ListView(
                children: [
                  CartaoSecaoEstatisticaClima(
                    icone: Icons.analytics_outlined,
                    titulo: 'Seção de Teste',
                    filho: Column(
                      children: [
                        const LinhaBarraMetricaClima(
                          rotulo: 'Chuva ativa',
                          valorFormatado: '85.5%',
                          fator: 0.855,
                        ),
                        const LinhaFormulaEstatisticaClima(
                          titulo: 'POD',
                          equacao: '1306 / 1528',
                          resultado: '85.47%',
                          destaque: true,
                        ),
                        const LinhaFormulaEstatisticaClima(
                          titulo: 'SE',
                          equacao: 'Erro padrão',
                          resultado: '0.90%',
                        ),
                        const Row(
                          children: [
                            Expanded(
                              child: CelulaMatrizClima(
                                sigla: 'TP = 1306',
                                detalhe: 'Hit',
                                destaque: true,
                              ),
                            ),
                            Expanded(
                              child: CelulaMatrizClima(
                                sigla: 'FP = 179',
                                detalhe: 'Alarme',
                              ),
                            ),
                          ],
                        ),
                        for (final linha
                            in EstudoEstatisticoClimaAresta.linhasTabelaPadraoZ.take(4))
                          LinhaTabelaZResponsivaClima(linha: linha),
                        CartaoFonteDadosClima(
                          fonte: EstudoEstatisticoClimaAresta.fontesMeteorologicas.first,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Seção de Teste'), findsOneWidget);
        expect(find.text('85.47%'), findsOneWidget);
        expect(find.text('TP = 1306'), findsOneWidget);
        expect(find.text('+1.96'), findsOneWidget);
        expect(find.text('Open-Meteo'), findsOneWidget);
      },
    );
  });
}
