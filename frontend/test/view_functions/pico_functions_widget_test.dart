// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/pico_functions.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/widgets/mapa_thumbnail.dart';
import 'package:frontend/view_functions/offline_markdown.dart';
import 'package:frontend/widgets/badges_modalidades.dart';

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

  testWidgets('buildSectorTile renderiza badges de modalidades quando o setor possui escaladas', (
    WidgetTester tester,
  ) async {
    final setor = Setor()
      ..nome = 'Setor Sol'
      ..escaladas.addAll([
        Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via E1'),
        Escalada()..viaMovel = (ViaMovel()..nome = 'Via M1'),
        Escalada()..viaMovel = (ViaMovel()..nome = 'Via M2'),
      ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildSectorTile(context, setor, 'crag1'),
          ),
        ),
      ),
    );

    expect(find.text('Setor Sol'), findsOneWidget);
    expect(find.byType(BadgesModalidades), findsOneWidget);
    expect(find.text('1 esportiva'), findsOneWidget);
    expect(find.text('2 móveis'), findsOneWidget);
  });

  testWidgets('buildSectorTile não renderiza badges quando setor não tem escaladas', (
    WidgetTester tester,
  ) async {
    final setor = Setor()..nome = 'Setor Vazio';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildSectorTile(context, setor, 'crag1'),
          ),
        ),
      ),
    );

    expect(find.text('Setor Vazio'), findsOneWidget);
    expect(find.byType(BadgesModalidades), findsNothing);
  });

  testWidgets('buildGrupoTile renderiza resumo em duas linhas com contagem e badges', (
    WidgetTester tester,
  ) async {
    final setor1 = Setor()
      ..nome = 'Bloco 1'
      ..escaladas.addAll([
        Escalada()..boulder = (Boulder()..nome = 'B1'),
        Escalada()..boulder = (Boulder()..nome = 'B2'),
      ]);
    final setor2 = Setor()
      ..nome = 'Bloco 2'
      ..escaladas.add(Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'E1'));

    final grupo = Grupo()
      ..nome = 'Vale Secreto'
      ..setores.addAll([
        ArquivoSetor()..conteudo = setor1,
        ArquivoSetor()..conteudo = setor2,
      ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => buildGrupoTile(context, grupo, 'crag1'),
          ),
        ),
      ),
    );

    expect(find.text('Vale Secreto'), findsOneWidget);
    expect(find.text('2 setores • 3 escaladas'), findsOneWidget);
    expect(find.byType(BadgesModalidades), findsOneWidget);
    expect(find.text('2 boulders'), findsOneWidget);
    expect(find.text('1 esportiva'), findsOneWidget);
  });
}
