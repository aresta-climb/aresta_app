// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/pages/pico_subpages/explorar_local_page.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/utils/categorizacao_pico.dart';
import '../../mocks/mock_telemetria.dart';

void main() {
  late MockTelemetryService mockTelemetria;

  setUp(() {
    mockTelemetria = MockTelemetryService();
    TelemetryService.instance = mockTelemetria;
  });

  Widget criarWidgetTeste({
    required Pico pico,
    required String cragId,
    required PicoCategorizedData categories,
    Future<void> Function(String url, String nomeServico)? aoAbrirLinkExterno,
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [AppColors.dark],
      ),
      home: ExplorarLocalPage(
        pico: pico,
        cragId: cragId,
        categories: categories,
        aoAbrirLinkExterno: aoAbrirLinkExterno,
      ),
    );
  }

  group('ExplorarLocalPage - Botão Google Maps e Posicionamento', () {
    testWidgets(
      'exibe card Abrir no Google Maps priorizando urlGoogleMaps quando preenchida',
      (tester) async {
        String? urlAberta;
        final pico = Pico()
          ..nome = 'Pedra da Tartaruga'
          ..urlGoogleMaps = 'https://maps.app.goo.gl/exemploTartaruga'
          ..localizacao = (Coordenada()
            ..latitude = -198960870
            ..longitude = -436547850);

        final croqui = Croqui();
        final categories = PicoCategorizedData(croqui);

        await tester.pumpWidget(
          criarWidgetTeste(
            pico: pico,
            cragId: 'tartaruga',
            categories: categories,
            aoAbrirLinkExterno: (url, nome) async {
              urlAberta = url;
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Abrir no Google Maps'), findsOneWidget);
        expect(
          find.text('Ver localização e traçar rota até o pico.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Abrir no Google Maps'));
        await tester.pumpAndSettle();

        expect(urlAberta, equals('https://maps.app.goo.gl/exemploTartaruga'));
      },
    );

    testWidgets(
      'exibe card Abrir no Google Maps usando coordenadas como fallback',
      (tester) async {
        String? urlAberta;
        final pico = Pico()
          ..nome = 'Pedra Filha'
          ..localizacao = (Coordenada()
            ..latitude = -198960870
            ..longitude = -436547850);

        final croqui = Croqui();
        final categories = PicoCategorizedData(croqui);

        await tester.pumpWidget(
          criarWidgetTeste(
            pico: pico,
            cragId: 'pedra_filha',
            categories: categories,
            aoAbrirLinkExterno: (url, nome) async {
              urlAberta = url;
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Abrir no Google Maps'), findsOneWidget);

        await tester.tap(find.text('Abrir no Google Maps'));
        await tester.pumpAndSettle();

        expect(
          urlAberta,
          equals('https://www.google.com/maps/search/?api=1&query=-19.896087,-43.654785'),
        );
      },
    );

    testWidgets(
      'não exibe card Abrir no Google Maps quando urlGoogleMaps e coordenadas estão ausentes ou zeradas',
      (tester) async {
        final pico = Pico()..nome = 'Pico Sem Localização';
        final croqui = Croqui();
        final categories = PicoCategorizedData(croqui);

        await tester.pumpWidget(
          criarWidgetTeste(
            pico: pico,
            cragId: 'sem_loc',
            categories: categories,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Abrir no Google Maps'), findsNothing);
      },
    );

    testWidgets(
      'posiciona o card Abrir no Google Maps imediatamente abaixo de Como chegar',
      (tester) async {
        final pico = Pico()
          ..nome = 'Pedra Bela'
          ..urlGoogleMaps = 'https://maps.app.goo.gl/pedraBela';

        final croqui = Croqui()
          ..botoes.addAll([
            Botao(
              texto: 'Como chegar na pedra',
              destino: DestinoBotao(
                secaoTextual: ArquivoMarkdown()..conteudo = 'Siga pela estrada principal.',
              ),
            ),
            Botao(
              texto: 'Outras Dicas',
              destino: DestinoBotao(
                secaoTextual: ArquivoMarkdown()..conteudo = 'Dicas gerais.',
              ),
            ),
          ]);
        final categories = PicoCategorizedData(croqui);

        await tester.pumpWidget(
          criarWidgetTeste(
            pico: pico,
            cragId: 'pedra_bela',
            categories: categories,
          ),
        );
        await tester.pumpAndSettle();

        final posComoChegar = tester.getTopLeft(find.text('Como chegar')).dy;
        final posGoogleMaps = tester.getTopLeft(find.text('Abrir no Google Maps')).dy;
        final posOutros = tester.getTopLeft(find.text('Outras Dicas')).dy;

        expect(posComoChegar, lessThan(posGoogleMaps));
        expect(posGoogleMaps, lessThan(posOutros));
      },
    );

    testWidgets(
      'aciona abrirLinkExterno padrão quando nenhum callback é injetado e registra telemetria',
      (tester) async {
        final pico = Pico()
          ..nome = 'Pedra do Baú'
          ..urlGoogleMaps = 'https://maps.app.goo.gl/pedraDoBau';

        final croqui = Croqui();
        final categories = PicoCategorizedData(croqui);

        await tester.pumpWidget(
          criarWidgetTeste(
            pico: pico,
            cragId: 'pedra_do_bau',
            categories: categories,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Abrir no Google Maps'));
        await tester.pumpAndSettle();

        expect(mockTelemetria.recordedEvents, contains('link_externo'));
        expect(
          mockTelemetria.recordedParams['link_externo']!['url'],
          'https://maps.app.goo.gl/pedraDoBau',
        );
      },
    );
  });
}
