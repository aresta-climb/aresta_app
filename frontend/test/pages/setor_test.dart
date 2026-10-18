// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/pages/setor.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/compartilhamento/servico_compartilhamento.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/gerenciador_filtros_croqui.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/utils/filtro_grau_escalada.dart';
import 'package:frontend/widgets/painel_filtros_indice.dart';

void main() {
  setUp(() {
    if (DatasetRepository.instance == null) {
      DatasetRepository(editorDeCroqui: EditorDeCroqui());
    }
  });

  tearDown(() {
    ServicoCompartilhamento.restaurarPadrao();
  });

  testWidgets('SetorPage should wrap body in SafeArea', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(setor: Setor()..nome = 'Setor Teste', cragId: 'crag1'),
      ),
    );

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);

    expect(find.byType(SafeArea), findsWidgets);
    final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
    expect(safeAreas.any((sa) => sa.bottom == true), isTrue);
  });

  testWidgets('SetorPage should handle scrollToEscalada gracefully without crashing', (tester) async {
    final via1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via 1'));
    final via2 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via 2'));
    final setor = Setor()
      ..nome = 'Setor Teste'
      ..escaladas.addAll([via1, via2]);

    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(
          setor: setor,
          cragId: 'crag1',
          scrollToEscalada: via2,
        ),
      ),
    );

    // Avança o timer de 400ms do delay do scroll e processa o post-frame callback
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Via 2'), findsOneWidget);

    // Atualiza o widget com outra via para exercitar o didUpdateWidget
    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(
          setor: setor,
          cragId: 'crag1',
          scrollToEscalada: via1,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Via 1'), findsOneWidget);
  });

  testWidgets('SetorPage re-resolve imagem de capa no didUpdateWidget durante Hot Reload', (tester) async {
    final setor1 = Setor()
      ..nome = 'Setor 1'
      ..caminhoImagemCapa = 'imagens/capa1.webp';
    final setor2 = Setor()
      ..nome = 'Setor 1'
      ..caminhoImagemCapa = 'imagens/capa2.webp';

    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(setor: setor1, cragId: 'crag1'),
      ),
    );
    await tester.pump();

    // Re-pump simulando hot reload com novo setor
    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(setor: setor2, cragId: 'crag1'),
      ),
    );
    await tester.pump();
  });

  testWidgets('SetorPage renderiza SliverAppBar expandido de 300px quando caminhoImagemCapa estiver preenchido', (tester) async {
    final setor = Setor()
      ..nome = 'Setor Com Capa'
      ..caminhoImagemCapa = 'imagens/capa.webp';

    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(setor: setor, cragId: 'crag1'),
      ),
    );
    await tester.pump();

    final sliverAppBarFinder = find.byType(SliverAppBar);
    expect(sliverAppBarFinder, findsOneWidget);
    final sliverAppBar = tester.widget<SliverAppBar>(sliverAppBarFinder);
    expect(sliverAppBar.expandedHeight, 300.0);
  });

  testWidgets('SetorPage renderiza SliverAppBar compacto quando não possui caminhoImagemCapa', (tester) async {
    final setor = Setor()
      ..nome = 'Setor Sem Capa';

    await tester.pumpWidget(
      MaterialApp(
        home: SetorPage(setor: setor, cragId: 'crag1'),
      ),
    );
    await tester.pump();

    final sliverAppBarFinder = find.byType(SliverAppBar);
    expect(sliverAppBarFinder, findsOneWidget);
    final sliverAppBar = tester.widget<SliverAppBar>(sliverAppBarFinder);
    expect(sliverAppBar.expandedHeight, isNull);
    expect(find.text('SETOR SEM CAPA'), findsOneWidget);
  });

  testWidgets('SetorPage exibe descrição sem o cabeçalho "Descrição"', (tester) async {
    final setor = Setor()
      ..nome = 'Setor Cachoeira'
      ..descricao = 'Acesso fácil pela trilha principal.';

    await tester.pumpWidget(
      MaterialApp(
        theme: construirTemaEscuro(),
        home: SetorPage(setor: setor, cragId: 'crag1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Descrição'), findsNothing);
    expect(find.text('Acesso fácil pela trilha principal.'), findsOneWidget);
  });

  testWidgets('SetorPage com múltiplas modalidades exibe abas ordenadas por volume decrescente sem aba Todas', (tester) async {
    final via1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Esportiva 1', dificuldade: GrauVia_GrauVia.BR_6));
    final via2 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Esportiva 2', dificuldade: GrauVia_GrauVia.BR_7A));
    final via3 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Esportiva 3', dificuldade: GrauVia_GrauVia.BR_7B));
    final boulder = Escalada(boulder: Boulder(nome: 'Boulder Único', dificuldade: GrauBoulder_GrauBoulder.V4));

    final setor = Setor()
      ..nome = 'Setor Misto'
      ..escaladas.addAll([boulder, via1, via2, via3]);

    await tester.pumpWidget(
      MaterialApp(
        theme: construirTemaEscuro(),
        home: SetorPage(setor: setor, cragId: 'crag-misto'),
      ),
    );
    await tester.pumpAndSettle();

    // Deve exibir TabBar com abas Esportivas (3) e Boulders (1), nessa ordem (volume decrescente)
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Esportivas (3)'), findsOneWidget);
    expect(find.text('Boulders (1)'), findsOneWidget);
    expect(find.text('Todas'), findsNothing);

    // Na aba inicial (Esportivas), exibe as vias esportivas e não o boulder
    expect(find.text('Esportiva 1'), findsOneWidget);
    expect(find.text('Esportiva 2'), findsOneWidget);
    expect(find.text('Esportiva 3'), findsOneWidget);
    expect(find.text('Boulder Único'), findsNothing);

    // Alterna para Boulders
    await tester.tap(find.text('Boulders (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Boulder Único'), findsOneWidget);
    expect(find.text('Esportiva 1'), findsNothing);
  });

  testWidgets('SetorPage com modalidade única oculta a barra de abas e exibe vias diretamente', (tester) async {
    final via1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Só Esportiva 1'));
    final via2 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Só Esportiva 2'));

    final setor = Setor()
      ..nome = 'Falésia Monomodal'
      ..escaladas.addAll([via1, via2]);

    await tester.pumpWidget(
      MaterialApp(
        theme: construirTemaEscuro(),
        home: SetorPage(setor: setor, cragId: 'crag-mono'),
      ),
    );
    await tester.pumpAndSettle();

    // Sem barra de abas
    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Via Só Esportiva 1'), findsOneWidget);
    expect(find.text('Via Só Esportiva 2'), findsOneWidget);
  });

  testWidgets('SetorPage herda e reflete filtros reativos do GerenciadorFiltrosCroqui', (tester) async {
    final via1 = Escalada(
      viaEsportiva: ViaEsportiva(
        nome: 'Via Fácil',
        dificuldade: GrauVia_GrauVia.BR_5,
        destaque: false,
      ),
    );
    final via2 = Escalada(
      viaEsportiva: ViaEsportiva(
        nome: 'Via Clássica Difícil',
        dificuldade: GrauVia_GrauVia.BR_8A,
        destaque: true,
      ),
    );

    final setor = Setor()
      ..nome = 'Setor Filtravel'
      ..escaladas.addAll([via1, via2]);

    final cragId = 'crag-filtros';
    GerenciadorFiltrosCroqui.instance.atualizarFiltros(
      cragId,
      EstadoFiltrosUnificado(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: construirTemaEscuro(),
        home: SetorPage(setor: setor, cragId: cragId),
      ),
    );
    await tester.pumpAndSettle();

    // Ambas aparecem inicialmente
    expect(find.text('Via Fácil'), findsOneWidget);
    expect(find.text('Via Clássica Difícil'), findsOneWidget);
    expect(find.byType(PainelFiltrosIndice), findsOneWidget);

    // Aplica filtro global de apenas clássicas
    GerenciadorFiltrosCroqui.instance.atualizarFiltros(
      cragId,
      EstadoFiltrosUnificado(apenasClassicas: true),
    );
    await tester.pumpAndSettle();

    // Apenas a clássica permanece visível
    expect(find.text('Via Fácil'), findsNothing);
    expect(find.text('Via Clássica Difícil'), findsOneWidget);
    expect(find.textContaining('Clássicas'), findsWidgets);
  });

  testWidgets('SetorPage seleciona automaticamente a aba correspondente quando scrollToEscalada for modalidade secundária', (tester) async {
    final via1 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Esportiva 1'));
    final via2 = Escalada(viaEsportiva: ViaEsportiva(nome: 'Esportiva 2'));
    final boulder = Escalada(boulder: Boulder(nome: 'Boulder Alvo'));

    final setor = Setor()
      ..nome = 'Setor com Alvo'
      ..escaladas.addAll([via1, via2, boulder]);

    await tester.pumpWidget(
      MaterialApp(
        theme: construirTemaEscuro(),
        home: SetorPage(
          setor: setor,
          cragId: 'crag-alvo',
          scrollToEscalada: boulder,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // A aba Boulders deve estar selecionada automaticamente
    expect(find.text('Boulder Alvo'), findsOneWidget);
  });

  testWidgets('SetorPage exibe botão de compartilhamento quando setor possui uid e usa nome do croqui em vez do slug', (tester) async {
    String? textoCompartilhado;
    ServicoCompartilhamento.instancia = ServicoCompartilhamento(
      executorCompartilhamento: (texto) async {
        textoCompartilhado = texto;
      },
    );
    DatasetRepository.instance?.indiceData.value = Indice(
      croquis: [
        ResumoCroqui(
          id: 'br_mg_igarape_pedra_grande',
          nome: 'Pedra Grande',
        ),
      ],
    );

    final setor = Setor()
      ..uid = 'uidSetorShare99'
      ..nome = 'Setor Estacionamento';
    final grupo = Grupo()..nome = 'Grupo Principal';

    await tester.pumpWidget(
      MaterialApp(
        theme: construirTemaEscuro(),
        home: SetorPage(
          setor: setor,
          grupoContext: grupo,
          cragId: 'br_mg_igarape_pedra_grande',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final botaoShare = find.byIcon(Icons.share_outlined);
    expect(botaoShare, findsOneWidget);

    await tester.tap(botaoShare);
    await tester.pumpAndSettle();

    expect(textoCompartilhado, isNotNull);
    expect(textoCompartilhado, contains('Confira o Setor Estacionamento, em Pedra Grande, no Aresta:'));
    expect(textoCompartilhado, isNot(contains('br_mg_igarape_pedra_grande')));
    expect(textoCompartilhado, contains('https://aresta.cc/s/uidSetorShare99'));
  });
}

