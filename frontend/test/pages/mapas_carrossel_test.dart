// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/mapas_carrossel.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/pages/mapa_interativo.dart';
import 'dart:typed_data';

// Dummy widget to inject as MapasCarrosselPage's mapBuilder to avoid complex MapHelper dependencies in tests.
class DummyMapaInterativo extends StatelessWidget {
  final int index;
  const DummyMapaInterativo(this.index, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text('MapaInterativo $index');
  }
}

void main() {
  group('MapasCarrosselPage Tests', () {
    testWidgets('Renders properly with multiple maps', (tester) async {
      final pico = Pico()..nome = 'Pico Teste';

      final mapas = [
        const CarrosselItemData(mapaCaminhoImagem: 'map1.png'),
        const CarrosselItemData(mapaCaminhoImagem: 'map2.png'),
        const CarrosselItemData(mapaCaminhoImagem: 'map3.png'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: MapasCarrosselPage(
            pico: pico,
            cragId: '1',
            mapas: mapas,
            initialIndex: 0,
            mapBuilder: (context, index, item) => DummyMapaInterativo(index),
          ),
        ),
      );

      // Should render the first map
      expect(find.text('MapaInterativo 0'), findsOneWidget);
      expect(find.text('MapaInterativo 1'), findsNothing);

      // Should render the pagination text
      expect(find.text('01 de 03'), findsOneWidget);

      // Verify that the new AppBar is present instead of just a floating widget
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Toca no botão de voltar da AppBar e aciona retorno de navegação', (tester) async {
      final pico = Pico()..nome = 'Pico Teste';
      final mapas = [
        const CarrosselItemData(mapaCaminhoImagem: 'map1.png'),
        const CarrosselItemData(mapaCaminhoImagem: 'map2.png'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapasCarrosselPage(
              pico: pico,
              cragId: '1',
              mapas: mapas,
              initialIndex: 0,
              mapBuilder: (context, index, item) => DummyMapaInterativo(index),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
    });

    testWidgets('Navigation arrows work correctly', (tester) async {
      final pico = Pico()..nome = 'Pico Teste';
      final mapas = [
        const CarrosselItemData(mapaCaminhoImagem: 'map1.png'),
        const CarrosselItemData(mapaCaminhoImagem: 'map2.png'),
        const CarrosselItemData(mapaCaminhoImagem: 'map3.png'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: MapasCarrosselPage(
            pico: pico,
            cragId: '1',
            mapas: mapas,
            initialIndex: 1, // Start in the middle
            mapBuilder: (context, index, item) => DummyMapaInterativo(index),
          ),
        ),
      );

      expect(find.text('02 de 03'), findsOneWidget);
      expect(find.text('MapaInterativo 1'), findsOneWidget);

      // Click Right
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('03 de 03'), findsOneWidget);
      expect(find.text('MapaInterativo 2'), findsOneWidget);

      // Click Right again (should do nothing because we are at the end)
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('03 de 03'), findsOneWidget);

      // Click Left x 2
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('01 de 03'), findsOneWidget);
      expect(find.text('MapaInterativo 0'), findsOneWidget);

      // Click Left again (should do nothing because we are at the beginning)
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(find.text('01 de 03'), findsOneWidget);
    });

    testWidgets('Updates page when initialIndex changes in didUpdateWidget', (
      tester,
    ) async {
      final pico = Pico()..nome = 'Pico Teste';
      final mapas = [
        const CarrosselItemData(mapaCaminhoImagem: 'map1.png'),
        const CarrosselItemData(mapaCaminhoImagem: 'map2.png'),
        const CarrosselItemData(mapaCaminhoImagem: 'map3.png'),
      ];

      Widget buildCarousel(int initialIndex) {
        return MaterialApp(
          home: MapasCarrosselPage(
            pico: pico,
            cragId: '1',
            mapas: mapas,
            initialIndex: initialIndex,
            mapBuilder: (context, index, item) => DummyMapaInterativo(index),
          ),
        );
      }

      await tester.pumpWidget(buildCarousel(0));
      expect(find.text('01 de 03'), findsOneWidget);
      expect(find.text('MapaInterativo 0'), findsOneWidget);

      // Update widget with new initialIndex (simulating clicking "Ver mapas (N)" again)
      await tester.pumpWidget(buildCarousel(2));
      await tester.pumpAndSettle();

      expect(find.text('03 de 03'), findsOneWidget);
      expect(find.text('MapaInterativo 2'), findsOneWidget);
    });

    testWidgets(
      'Renders simple map properly without carousel UI when only 1 map is provided',
      (tester) async {
        final pico = Pico()..nome = 'Pico Teste';
        final mapas = [const CarrosselItemData(mapaCaminhoImagem: 'map1.png')];

        await tester.pumpWidget(
          MaterialApp(
            home: MapasCarrosselPage(
              pico: pico,
              cragId: '1',
              mapas: mapas,
              initialIndex: 0,
              mapBuilder: (context, index, item) => DummyMapaInterativo(index),
            ),
          ),
        );

        // Should render the first map
        expect(find.text('MapaInterativo 0'), findsOneWidget);

        // Should NOT render any pagination text
        expect(find.text('01 de 01'), findsNothing);
        expect(find.text('01 de 03'), findsNothing);

        // Should NOT render chevron buttons
        expect(find.byIcon(Icons.chevron_left), findsNothing);
        expect(find.byIcon(Icons.chevron_right), findsNothing);

        // Should NOT have a PageView (since we just return the builder)
        expect(find.byType(PageView), findsNothing);
      },
    );
    testWidgets(
      'Renders single map with hideAppBar=false when only 1 map is provided (using default builder)',
      (tester) async {
        final mapa = Mapa()..caminhoImagemMapa = 'map1.png';
        final pico = Pico()
          ..nome = 'Pico Teste'
          ..mapasGerais = (ArquivoMapas()
            ..conteudo = (ColecaoDeMapas()..mapas.add(mapa)));
        final mapas = [const CarrosselItemData(mapaCaminhoImagem: 'map1.png')];

        await tester.pumpWidget(
          MaterialApp(
            home: MapasCarrosselPage(
              pico: pico,
              cragId: '1',
              mapas: mapas,
              initialIndex: 0,
              // Not providing mapBuilder so it uses _defaultMapBuilder
              imageProviderOverride: MemoryImage(
                Uint8List(0),
              ), // Avoid real image loading
            ),
          ),
        );

        // Should render the first map using MapaInterativoPage
        expect(find.byType(MapaInterativoPage), findsOneWidget);

        final mapaPage = tester.widget<MapaInterativoPage>(
          find.byType(MapaInterativoPage),
        );

        // hideAppBar should be false because there is only 1 map and no carousel UI is wrapping it
        expect(mapaPage.hideAppBar, isFalse);
      },
    );

    testWidgets(
      'TDD 1.3: _defaultMapBuilder passes popOnActionIfOriginal: false to MapaInterativoPage',
      (tester) async {
        final mapa1 = Mapa()..caminhoImagemMapa = 'map1.png';
        final mapa2 = Mapa()..caminhoImagemMapa = 'map2.png';
        final pico = Pico()
          ..nome = 'Pico Teste'
          ..mapasGerais = (ArquivoMapas()
            ..conteudo = (ColecaoDeMapas()..mapas.addAll([mapa1, mapa2])));
        final mapas = [
          const CarrosselItemData(mapaCaminhoImagem: 'map1.png'),
          const CarrosselItemData(mapaCaminhoImagem: 'map2.png'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: MapasCarrosselPage(
              pico: pico,
              cragId: '1',
              mapas: mapas,
              initialIndex: 0,
              imageProviderOverride: MemoryImage(Uint8List(0)),
            ),
          ),
        );

        // Should render the first map using MapaInterativoPage
        expect(find.byType(MapaInterativoPage), findsOneWidget);

        final mapaPage = tester.widget<MapaInterativoPage>(
          find.byType(MapaInterativoPage),
        );
        expect(mapaPage.popOnActionIfOriginal, isFalse);
      },
    );

    testWidgets(
      'TDD: didUpdateWidget deve reconstruir e propagar novos dados e provedores de imagem para MapaInterativoPage',
      (tester) async {
        final mapa1 = Mapa()..caminhoImagemMapa = 'map1.png';
        final mapa2 = Mapa()..caminhoImagemMapa = 'map2.png';
        final picoInicial = Pico()
          ..nome = 'Pico Teste'
          ..mapasGerais = (ArquivoMapas()
            ..conteudo = (ColecaoDeMapas()..mapas.addAll([mapa1, mapa2])));
        final mapas = [
          const CarrosselItemData(mapaCaminhoImagem: 'map1.png'),
          const CarrosselItemData(mapaCaminhoImagem: 'map2.png'),
        ];

        final provedorInicial = MemoryImage(Uint8List.fromList([1, 2, 3]));
        final provedorAtualizado = MemoryImage(Uint8List.fromList([4, 5, 6]));

        Widget construirCarrossel({
          required Pico pico,
          required ImageProvider imagemProvedor,
        }) {
          return MaterialApp(
            home: MapasCarrosselPage(
              pico: pico,
              cragId: '1',
              mapas: mapas,
              initialIndex: 0,
              imageProviderOverride: imagemProvedor,
            ),
          );
        }

        // 1. Renderiza inicialmente com o primeiro provedor
        await tester.pumpWidget(
          construirCarrossel(
            pico: picoInicial,
            imagemProvedor: provedorInicial,
          ),
        );
        await tester.pump();

        expect(find.byType(MapaInterativoPage), findsOneWidget);
        var paginaMapa = tester.widget<MapaInterativoPage>(
          find.byType(MapaInterativoPage),
        );
        expect(paginaMapa.imageProviderOverride, equals(provedorInicial));

        // 2. Simula a atualização do widget pai durante Live Reload com novo provedor
        final picoAtualizado = Pico()
          ..nome = 'Pico Teste Atualizado'
          ..mapasGerais = (ArquivoMapas()
            ..conteudo = (ColecaoDeMapas()..mapas.addAll([mapa1, mapa2])));

        await tester.pumpWidget(
          construirCarrossel(
            pico: picoAtualizado,
            imagemProvedor: provedorAtualizado,
          ),
        );
        await tester.pump();

        // 3. Deve ter reconstruído os filhos propagando o novo provedor
        paginaMapa = tester.widget<MapaInterativoPage>(
          find.byType(MapaInterativoPage),
        );
        expect(paginaMapa.imageProviderOverride, equals(provedorAtualizado));
      },
    );

    testWidgets(
      'TDD: Carrossel deve isolar traçados de mapas diferentes que compartilham o mesmo ponto.id',
      (tester) async {
        final pontoMapa1 = Mapa_PontoDeInteresse(
          id: 'linha_1',
          linha: LinhaTrajeto(
            estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
            compilado: DadosCompiladosLinha(
              caminhoSvg: 'M 0 0 L 100 100',
              caixaDelimitadora: BoundingRetangulo(
                x: 50,
                y: 50,
                comprimento: 100,
                largura: 100,
              ),
            ),
          ),
        );

        final pontoMapa2 = Mapa_PontoDeInteresse(
          id: 'linha_1',
          linha: LinhaTrajeto(
            estilo: LinhaTrajeto_EstiloTraco.SOLIDO,
            compilado: DadosCompiladosLinha(
              caminhoSvg: 'M 500 500 L 900 900',
              caixaDelimitadora: BoundingRetangulo(
                x: 700,
                y: 700,
                comprimento: 400,
                largura: 400,
              ),
            ),
          ),
        );

        final mapa1 = Mapa()
          ..caminhoImagemMapa = 'imagens/mapa1.png'
          ..larguraMapa = 1000
          ..alturaMapa = 1000
          ..pontosDeInteresse.add(pontoMapa1);

        final mapa2 = Mapa()
          ..caminhoImagemMapa = 'imagens/mapa2.png'
          ..larguraMapa = 1000
          ..alturaMapa = 1000
          ..pontosDeInteresse.add(pontoMapa2);

        final pico = Pico()
          ..nome = 'Pico Teste'
          ..mapasGerais = (ArquivoMapas()
            ..conteudo = (ColecaoDeMapas()..mapas.addAll([mapa1, mapa2])));

        final mapas = [
          const CarrosselItemData(mapaCaminhoImagem: 'imagens/mapa1.png'),
          const CarrosselItemData(mapaCaminhoImagem: 'imagens/mapa2.png'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: MapasCarrosselPage(
              pico: pico,
              cragId: '1',
              mapas: mapas,
              initialIndex: 0,
              imageProviderOverride: MemoryImage(Uint8List(0)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Mapa 1 ativo inicialmente
        expect(find.text('01 de 02'), findsOneWidget);

        // Avança para o Mapa 2
        final botaoProximo = find.byIcon(Icons.chevron_right);
        expect(botaoProximo, findsOneWidget);
        await tester.tap(botaoProximo);
        await tester.pumpAndSettle();

        expect(find.text('02 de 02'), findsOneWidget);
        expect(find.byType(MapaInterativoPage), findsOneWidget);

        final customPaints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
        final markerPainter = customPaints
            .map((cp) => cp.painter)
            .whereType<MarkerPainter>()
            .firstWhere((p) => p.isLinha);

        expect(markerPainter.chaveCache, equals('imagens/mapa2.png#linha_1'));
      },
    );
  });
}
