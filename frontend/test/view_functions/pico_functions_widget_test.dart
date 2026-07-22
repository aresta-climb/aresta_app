import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/pico_functions.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/widgets/mapa_thumbnail.dart';
import 'package:frontend/view_functions/offline_markdown.dart';

void main() {
  testWidgets('buildPicoBody renders Mapas Gerais correctly', (
    WidgetTester tester,
  ) async {
    final mapa1 = Mapa()
      ..caminhoImagemMapa = 'path/to/image.png'
      ..larguraMapa = 1000
      ..alturaMapa = 1000;

    final mapasGerais = ArquivoMapas()
      ..conteudo = (ColecaoDeMapas()..mapas.add(mapa1));

    final pico = Pico()
      ..nome = 'Pico Teste'
      ..mapasGerais = mapasGerais;

    final croqui = Croqui();

    // We need to wrap it in a MaterialApp to provide Theme and Directionality
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    buildPicoBody(context, pico, croqui, 'crag1', GlobalKey()),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    // Should find the 'Mapas Gerais' header
    expect(find.text('Mapas Gerais'), findsOneWidget);

    // Should find the MapaThumbnail widget
    expect(find.byType(MapaThumbnail), findsOneWidget);
  });

  testWidgets('buildPicoBody renders Capa buttons inline', (
    WidgetTester tester,
  ) async {
    final botaoCapa = Botao()
      ..texto = 'Capa'
      ..destino = (DestinoBotao()
        ..secaoTextual = (ArquivoMarkdown()
          ..conteudo = '# Titulo da Capa\nEste é o texto da capa.'));

    final croqui = Croqui()..botoes.add(botaoCapa);
    final pico = Pico()..nome = 'Pico Capa';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return SingleChildScrollView(
                child: Column(
                  children: [buildPicoBody(context, pico, croqui, 'crag2')],
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(OfflineMarkdown), findsOneWidget);
  });
}
