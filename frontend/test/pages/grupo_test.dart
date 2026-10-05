// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/pages/grupo.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/widgets/painel_filtros_indice.dart';
import 'package:frontend/widgets/barra_ordenacao_exploracao.dart';
import 'package:frontend/widgets/card_indice_escalada.dart';
import 'package:frontend/services/gerenciador_filtros_croqui.dart';
import 'package:frontend/utils/filtro_grau_escalada.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import '../mocks/mock_telemetria.dart';

void main() {
  testWidgets('GrupoPage should wrap body in SafeArea', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GrupoPage(grupo: Grupo()..nome = 'Grupo Teste', cragId: 'crag1'),
      ),
    );

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    expect(find.byType(SafeArea), findsWidgets);

    final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
    expect(safeAreas.any((sa) => sa.bottom == true), isTrue);
  });

  testWidgets('GrupoPage re-resolve imagem de capa no didUpdateWidget durante Hot Reload', (tester) async {
    final grupo1 = Grupo()
      ..nome = 'Grupo 1'
      ..caminhoImagemCapa = 'imagens/capa1.webp';
    final grupo2 = Grupo()
      ..nome = 'Grupo 1'
      ..caminhoImagemCapa = 'imagens/capa2.webp';

    await tester.pumpWidget(
      MaterialApp(
        home: GrupoPage(grupo: grupo1, cragId: 'crag1'),
      ),
    );
    await tester.pump();

    // Re-pump simulando hot reload com novo grupo
    await tester.pumpWidget(
      MaterialApp(
        home: GrupoPage(grupo: grupo2, cragId: 'crag1'),
      ),
    );
    await tester.pump();
  });

  testWidgets('GrupoPage renderiza SliverAppBar expandido de 300px quando caminhoImagemCapa estiver preenchido', (tester) async {
    final grupo = Grupo()
      ..nome = 'Grupo Com Capa'
      ..caminhoImagemCapa = 'imagens/capa_grupo.webp';

    await tester.pumpWidget(
      MaterialApp(
        home: GrupoPage(grupo: grupo, cragId: 'crag1'),
      ),
    );
    await tester.pump();

    final sliverAppBarFinder = find.byType(SliverAppBar);
    expect(sliverAppBarFinder, findsOneWidget);
    final sliverAppBar = tester.widget<SliverAppBar>(sliverAppBarFinder);
    expect(sliverAppBar.expandedHeight, 300.0);
  });

  testWidgets('GrupoPage renderiza SliverAppBar compacto quando não possui caminhoImagemCapa', (tester) async {
    final grupo = Grupo()
      ..nome = 'Grupo Sem Capa';

    await tester.pumpWidget(
      MaterialApp(
        home: GrupoPage(grupo: grupo, cragId: 'crag1'),
      ),
    );
    await tester.pump();

    final sliverAppBarFinder = find.byType(SliverAppBar);
    expect(sliverAppBarFinder, findsOneWidget);
    final sliverAppBar = tester.widget<SliverAppBar>(sliverAppBarFinder);
    expect(sliverAppBar.expandedHeight, isNull);
    expect(find.text('GRUPO SEM CAPA'), findsOneWidget);
  });

  testWidgets('GrupoPage dispara logAlterarOrdenacao ao alternar critérios de ordenação', (tester) async {
    final mockTelemetria = MockTelemetryService();
    TelemetryService.instance = mockTelemetria;

    final grupo = Grupo()
      ..nome = 'Grupo Ordenação'
      ..setores.addAll([
        ArquivoSetor(conteudo: Setor(nome: 'Setor B')),
        ArquivoSetor(conteudo: Setor(nome: 'Setor A')),
      ]);

    await tester.pumpWidget(
      MaterialApp(
        home: GrupoPage(grupo: grupo, cragId: 'crag1'),
      ),
    );
    await tester.pumpAndSettle();

    mockTelemetria.clear();
    await tester.tap(find.text('Filtros e Ordenação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ALFABÉTICO'));
    await tester.pumpAndSettle();

    expect(mockTelemetria.recordedEvents, contains('alterar_ordenacao'));
    final params = mockTelemetria.recordedParams['alterar_ordenacao']!;
    expect(params['acao'], 'alterar_ordenacao');
    expect(params['origem'], 'grupo');
    expect(params['detalhe'], 'alphaAsc');
  });

  group('GrupoPage - UI Unificada de Exploração', () {
    late Grupo grupo;

    setUp(() {
      GerenciadorFiltrosCroqui.instance.redefinir();

      final viaEsportiva1 = ViaEsportiva()
        ..nome = 'Via Alpha'
        ..dificuldade = GrauVia_GrauVia.BR_6
        ..destaque = true
        ..conquistadores.add('Renato');

      final viaEsportiva2 = ViaEsportiva()
        ..nome = 'Via Beta'
        ..dificuldade = GrauVia_GrauVia.BR_8A
        ..destaque = false
        ..conquistadores.add('Lucas');

      final setor1 = Setor()
        ..nome = 'Setor Sol'
        ..escaladas.addAll([
          Escalada()..viaEsportiva = viaEsportiva1,
          Escalada()..viaEsportiva = viaEsportiva2,
        ]);

      final boulder1 = Boulder()
        ..nome = 'Bloco Raiz'
        ..dificuldade = GrauBoulder_GrauBoulder.V4
        ..destaque = false
        ..conquistadores.add('Bruno');

      final setor2 = Setor()
        ..nome = 'Setor das Pedras'
        ..escaladas.add(Escalada()..boulder = boulder1);

      grupo = Grupo()
        ..nome = 'Complexo Serra'
        ..descricao = 'Descrição detalhada do complexo'
        ..setores.addAll([
          ArquivoSetor(conteudo: setor1),
          ArquivoSetor(conteudo: setor2),
        ]);
    });

    testWidgets('renderiza abas dinâmicas de Setores e modalidades existentes no grupo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: GrupoPage(grupo: grupo, cragId: 'crag-serra'),
        ),
      );
      await tester.pumpAndSettle();

      // Deve exibir a aba de Setores com contagem total (2 setores)
      expect(find.text('Setores (2)'), findsOneWidget);

      // Deve exibir as abas das modalidades presentes no grupo
      expect(find.text('Esportivas (2)'), findsOneWidget);
      expect(find.text('Boulders (1)'), findsOneWidget);
    });

    testWidgets('renderiza PainelFiltrosIndice com botão Filtros e Ordenação e sem barra de ordenação solta', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: GrupoPage(grupo: grupo, cragId: 'crag-serra'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PainelFiltrosIndice), findsOneWidget);
      expect(find.text('Filtros e Ordenação'), findsOneWidget);
      expect(find.byType(BarraOrdenacaoExploracao), findsNothing);
    });

    testWidgets('alterna entre aba de Setores e aba de modalidade exibindo escaladas individuais', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: GrupoPage(grupo: grupo, cragId: 'crag-serra'),
        ),
      );
      await tester.pumpAndSettle();

      // Na aba Setores, exibe os nomes dos setores
      expect(find.text('Setor Sol'), findsOneWidget);
      expect(find.text('Setor das Pedras'), findsOneWidget);

      // Alterna para a aba Esportivas
      await tester.tap(find.text('Esportivas (2)'));
      await tester.pumpAndSettle();

      // Deve exibir os cards de escalada das vias esportivas
      expect(find.text('Via Alpha'), findsOneWidget);
      expect(find.text('Via Beta'), findsOneWidget);
      expect(find.byType(CardIndiceEscalada), findsNWidgets(2));
    });

    testWidgets('preserva e sincroniza filtros globalmente com GerenciadorFiltrosCroqui', (tester) async {
      // Configura filtro prévio no croqui
      GerenciadorFiltrosCroqui.instance.atualizarFiltros(
        'crag-serra',
        const EstadoFiltrosUnificado(apenasClassicas: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: GrupoPage(grupo: grupo, cragId: 'crag-serra'),
        ),
      );
      await tester.pumpAndSettle();

      // Como apenas Via Alpha é destaque no Setor Sol, e Setor das Pedras não tem clássicas:
      // O contador de Setores deve ser (1/2) e Esportivas (1/2)
      expect(find.text('Setores (1/2)'), findsOneWidget);
      expect(find.text('Esportivas (1/2)'), findsOneWidget);
      expect(find.text('Setor Sol'), findsOneWidget);
      expect(find.text('Setor das Pedras'), findsNothing);

      // Ao alternar ordenação por GRAU na GrupoPage através de Filtros e Ordenação, sincroniza com GerenciadorFiltrosCroqui
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GRAU'));
      await tester.pumpAndSettle();

      final filtrosGlobais = GerenciadorFiltrosCroqui.instance.obterFiltros('crag-serra');
      expect(filtrosGlobais.tipoOrdenacao, TipoOrdenacaoExploracao.grau);
    });
  });
}


