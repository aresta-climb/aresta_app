// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/tradutor_app.dart';
import 'package:frontend/pages/estatisticas_clima.dart';
import 'package:frontend/widgets/navegacao/botao_voltar_com_retorno_inicio.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await ControladorIdiomaApp.instancia.definirIdioma(IdiomaApp.portugues);
  });

  group('PaginaEstatisticasClima', () {
    testWidgets(
      'exibe lógica matemática do índice de ~85%, matriz 2x2, Tabela Z verificável e as 6 fontes específicas',
      (tester) async {
        await tester.pumpWidget(
          EscopoIdiomaApp(
            notificador: ControladorIdiomaApp.instancia.notificadorIdioma,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      key: const Key('abrir_pagina_estat'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PaginaEstatisticasClima(),
                          ),
                        );
                      },
                      child: const Text('Abrir'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('abrir_pagina_estat')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('pagina_estatisticas_clima')), findsOneWidget);
        expect(find.textContaining('85%'), findsWidgets);
        expect(find.textContaining('5.133'), findsWidgets);

        // Rola até a Tabela Z e verifica entradas canônicas (1.96 -> 0.9750, 2.57 -> 0.9949)
        await tester.scrollUntilVisible(
          find.text('+2.57'),
          240.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('+1.96'), findsOneWidget);
        expect(find.text('0.9750'), findsOneWidget);
        expect(find.text('+2.57'), findsOneWidget);
        expect(find.text('0.9949'), findsOneWidget);

        // Rola até a seção das 6 fontes específicas (3 meteorológicas + 3 NASA)
        await tester.scrollUntilVisible(
          find.text('NASA Blue Marble'),
          260.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Open-Meteo'), findsOneWidget);
        expect(find.text('RainViewer'), findsOneWidget);
        expect(find.text('INPE BDQueimadas'), findsOneWidget);
        expect(find.text('NASA FIRMS (VIIRS 375m / MODIS)'), findsOneWidget);
        expect(find.text('NASA SRTM (30m)'), findsOneWidget);
        expect(find.text('NASA Blue Marble'), findsOneWidget);

        // Reage à mudança de idioma em tempo real e retorna ao tocar no botão voltar
        await ControladorIdiomaApp.instancia.definirIdioma(IdiomaApp.ingles);
        await tester.pumpAndSettle();
        expect(find.textContaining('STATISTICS'), findsWidgets);

        await tester.tap(find.byType(BotaoVoltarComRetornoInicio));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('pagina_estatisticas_clima')), findsNothing);
      },
    );
  });
}
