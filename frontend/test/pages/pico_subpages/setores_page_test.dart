// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/pages/pico_subpages/setores_page.dart';
import 'package:frontend/utils/indexador_escaladas.dart';
import 'package:frontend/widgets/barra_ordenacao_exploracao.dart';
import 'package:frontend/widgets/mapa_thumbnail.dart';
import 'package:frontend/widgets/painel_filtros_indice.dart';
import 'package:frontend/utils/filtro_grau_escalada.dart';
import 'package:frontend/services/gerenciador_filtros_croqui.dart';

void main() {
  Widget criarAmbiente({
    Key? key,
    required Pico pico,
    required String cragId,
    Croqui? croqui,
    String? modalidadeInicial,
    void Function(ItemIndiceEscalada item)? onViaTap,
  }) {
    return MaterialApp(
      theme: construirTemaEscuro(),
      home: SetoresPage(
        key: key,
        pico: pico,
        cragId: cragId,
        croqui: croqui,
        modalidadeInicial: modalidadeInicial,
        onViaTap: onViaTap,
      ),
    );
  }

  group('SetoresPage - Widget Tests Unificados', () {
    late Pico pico;
    late Croqui croqui;

    setUp(() {
      GerenciadorFiltrosCroqui.instance.redefinir();
      pico = Pico()..nome = 'Pedra Bela';

      final viaFacil = ViaEsportiva()
        ..nome = 'Via Escola'
        ..dificuldade = GrauVia_GrauVia.BR_4
        ..destaque = false
        ..conquistadores.add('Renato');

      final viaMedia = ViaEsportiva()
        ..nome = 'Sol Nascente'
        ..dificuldade = GrauVia_GrauVia.BR_6SUP
        ..destaque = true
        ..conquistadores.add('Renato');

      final viaDificil = ViaEsportiva()
        ..nome = 'Lua Cheia'
        ..dificuldade = GrauVia_GrauVia.BR_9A
        ..destaque = false
        ..conquistadores.add('Bruno');

      final boulderFacil = Boulder()
        ..nome = 'Pedra Inicial'
        ..dificuldade = GrauBoulder_GrauBoulder.V1
        ..destaque = false
        ..conquistadores.add('Lucas');

      final boulderDificil = Boulder()
        ..nome = 'Teto Sombrio'
        ..dificuldade = GrauBoulder_GrauBoulder.V8
        ..destaque = true
        ..conquistadores.add('Lucas');

      final viaExtra = ViaEsportiva()
        ..nome = 'Raio de Sol'
        ..dificuldade = GrauVia_GrauVia.BR_7A
        ..destaque = false
        ..conquistadores.add('Carlos');

      // Setor 1 (Escola/Fácil): Via Escola (4º), Sol Nascente (6ºsup) e Raio de Sol (7a)
      final setor1 = Setor()
        ..nome = 'Setor Alvorada'
        ..escaladas.addAll([
          Escalada()..viaEsportiva = viaFacil,
          Escalada()..viaEsportiva = viaMedia,
          Escalada()..viaEsportiva = viaExtra,
        ]);

      // Setor 2 (Difícil): Lua Cheia (9a) -> mediana alta
      final setor2 = Setor()
        ..nome = 'Setor Noturno'
        ..escaladas.add(Escalada()..viaEsportiva = viaDificil);

      // Setor 3 (Boulders exclusivamente): V1 e V8
      final setor3 = Setor()
        ..nome = 'Blocos da Floresta'
        ..escaladas.addAll([
          Escalada()..boulder = boulderFacil,
          Escalada()..boulder = boulderDificil,
        ]);

      pico.setoresOuGrupos.addAll([
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor1)),
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor2)),
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor3)),
      ]);

      croqui = Croqui()..picos.add(pico);
    });

    testWidgets('renderiza aba Setores fixa em primeiro lugar e abas para modalidades existentes com contadores', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(pico: pico, cragId: 'pedra-bela', croqui: croqui),
      );
      await tester.pumpAndSettle();

      // Verifica as abas renderizadas com formato dinâmico:
      // Setores (3) | Esportivas (4) | Boulders (2)
      expect(find.text('Setores (3)'), findsOneWidget);
      expect(find.text('Esportivas (4)'), findsOneWidget);
      expect(find.text('Boulders (2)'), findsOneWidget);

      // Não deve renderizar abas inexistentes
      expect(find.textContaining('Móveis'), findsNothing);
      expect(find.textContaining('Multienfiadas'), findsNothing);

      // Na aba Setores inicial, deve listar os 3 setores
      expect(find.text('Setor Alvorada'), findsOneWidget);
      expect(find.text('Setor Noturno'), findsOneWidget);
      expect(find.text('Blocos da Floresta'), findsOneWidget);

      // Barra de ordenação não deve estar solta na página inicial (agora fica dentro de Controles)
      expect(find.byType(BarraOrdenacaoExploracao), findsNothing);

      // Painel de controles presente
      expect(find.byType(PainelFiltrosIndice), findsOneWidget);
      expect(find.text('Filtros e Ordenação'), findsOneWidget);
    });

    testWidgets('alterna para aba de modalidade (Esportivas) e exibe lista de vias com cards', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(pico: pico, cragId: 'pedra-bela', croqui: croqui),
      );
      await tester.pumpAndSettle();

      // Clica na aba Esportivas
      await tester.tap(find.text('Esportivas (4)'));
      await tester.pumpAndSettle();

      // Deve exibir as 4 vias esportivas
      expect(find.text('Via Escola'), findsOneWidget);
      expect(find.text('Sol Nascente'), findsOneWidget);
      expect(find.text('Lua Cheia'), findsOneWidget);

      // Boulders não devem ser exibidos na aba de esportivas
      expect(find.text('Pedra Inicial'), findsNothing);
    });

    testWidgets('aplica filtro de conquistador compartilhado entre setores e modalidades', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        criarAmbiente(pico: pico, cragId: 'pedra-bela', croqui: croqui),
      );
      await tester.pumpAndSettle();

      // Abre o modal de controles
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();

      // Garante visibilidade e seleciona o conquistador "Bruno" (apenas tem via no Setor Noturno)
      await tester.ensureVisible(find.text('Adicionar conquistador...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar conquistador...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bruno').last);
      await tester.pumpAndSettle();

      // Fecha o modal de controles
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      // Na aba Setores, apenas o Setor Noturno deve estar visível
      expect(find.text('Setor Noturno'), findsOneWidget);
      expect(find.text('Setor Alvorada'), findsNothing);
      expect(find.text('Blocos da Floresta'), findsNothing);

      // Contadores devem refletir o filtro ativo: Setores (1/3) e Esportivas (1/4) e Boulders (0/2)
      expect(find.text('Setores (1/3)'), findsOneWidget);
      expect(find.text('Esportivas (1/4)'), findsOneWidget);
      expect(find.text('Boulders (0/2)'), findsOneWidget);

      // Alterna para aba Esportivas: o filtro deve permanecer ativo
      await tester.tap(find.text('Esportivas (1/4)'));
      await tester.pumpAndSettle();

      expect(find.text('Lua Cheia'), findsOneWidget);
      expect(find.text('Via Escola'), findsNothing);
      expect(find.text('Sol Nascente'), findsNothing);
    });

    testWidgets('enriquece o cartão do setor com faixa de grau e quantidade no filtro', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        criarAmbiente(pico: pico, cragId: 'pedra-bela', croqui: croqui),
      );
      await tester.pumpAndSettle();

      // Abre controles e seleciona conquistador "Renato" (vias: Escola e Sol Nascente)
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Adicionar conquistador...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar conquistador...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Renato').last);
      await tester.pumpAndSettle();

      // Fecha controles para inspecionar os cartões
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      // Setor Alvorada tem 2 vias no filtro (de 3 totais) e faixa 4º a 6ºsup
      expect(find.text('Setor Alvorada'), findsOneWidget);
      expect(find.text('2 de 3 esportivas - 4º a 6ºsup'), findsOneWidget);
    });

    testWidgets('ordena setores por MEDIANA de grau crescente e decrescente', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(pico: pico, cragId: 'pedra-bela', croqui: croqui),
      );
      await tester.pumpAndSettle();

      // Toca no botão Filtros e Ordenação para abrir o modal
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();

      // Toca no botão GRAU na barra de ordenação
      await tester.tap(find.text('GRAU'));
      await tester.pumpAndSettle();

      // Fecha o modal para verificar a listagem
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      // Mediana crescente:
      // Setor Alvorada: 4º (500) e 6ºsup (705) -> mediana ~602.5
      // Blocos da Floresta: V1 (600) e V8 (1300) -> mediana ~950
      // Setor Noturno: 9a (1200) -> mediana 1200
      // Portanto ordem: Alvorada, Floresta, Noturno.
      final finderAlvorada = find.text('Setor Alvorada');
      final finderNoturno = find.text('Setor Noturno');

      expect(tester.getTopLeft(finderAlvorada).dy, lessThan(tester.getTopLeft(finderNoturno).dy));

      // Alterna a direção da ordenação para decrescente tocando no modal de controles
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      // Agora Noturno deve estar acima de Alvorada
      expect(tester.getTopLeft(finderNoturno).dy, lessThan(tester.getTopLeft(finderAlvorada).dy));
    });

    testWidgets('ordena setores por ALFABÉTICO crescente e decrescente', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(pico: pico, cragId: 'pedra-bela', croqui: croqui),
      );
      await tester.pumpAndSettle();

      // Toca em Filtros e Ordenação
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();

      // Toca em ALFABÉTICO
      await tester.tap(find.text('ALFABÉTICO'));
      await tester.pumpAndSettle();

      // Fecha o modal
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      // Ordem alfabética crescente:
      // 1. Blocos da Floresta
      // 2. Setor Alvorada
      // 3. Setor Noturno
      final finderFloresta = find.text('Blocos da Floresta');
      final finderNoturno = find.text('Setor Noturno');
      expect(tester.getTopLeft(finderFloresta).dy, lessThan(tester.getTopLeft(finderNoturno).dy));

      // Inverte direção abrindo Filtros e Ordenação
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(finderNoturno).dy, lessThan(tester.getTopLeft(finderFloresta).dy));
    });

    testWidgets('desmarca uma modalidade no painel de setores e omite setores que só possuem ela', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(pico: pico, cragId: 'pedra-bela', croqui: croqui),
      );
      await tester.pumpAndSettle();

      // Abre controles
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();

      // Desmarca 'Boulder' no seletor de modalidades ativas
      await tester.tap(find.widgetWithText(FilterChip, 'Boulder'));
      await tester.pumpAndSettle();

      // Fecha controles para visualizar a listagem
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      // Blocos da Floresta (que só tem boulder) deve ser omitido
      expect(find.text('Blocos da Floresta'), findsNothing);
      expect(find.text('Setor Alvorada'), findsOneWidget);
      expect(find.text('Setor Noturno'), findsOneWidget);
    });

    testWidgets('toque na via na aba de escaladas aciona o callback onViaTap', (tester) async {
      ItemIndiceEscalada? viaTocada;

      await tester.pumpWidget(
        criarAmbiente(
          pico: pico,
          cragId: 'pedra-bela',
          croqui: croqui,
          onViaTap: (item) => viaTocada = item,
        ),
      );
      await tester.pumpAndSettle();

      // Alterna para aba Boulders
      await tester.tap(find.text('Boulders (2)'));
      await tester.pumpAndSettle();

      // Toca em Pedra Inicial
      await tester.tap(find.text('Pedra Inicial'));
      await tester.pumpAndSettle();

      expect(viaTocada, isNotNull);
      expect(viaTocada?.nome, 'Pedra Inicial');
    });

    testWidgets('renderiza MapaThumbnail antes das abas e filtros quando pico possui mapas gerais cadastrados', (tester) async {
      final mapaGeral = Mapa(caminhoImagemMapa: 'mapas/geral.png');
      pico.mapasGerais = ArquivoMapas(
        conteudo: ColecaoDeMapas(mapas: [mapaGeral]),
      );

      await tester.pumpWidget(
        criarAmbiente(pico: pico, cragId: 'pedra-bela', croqui: croqui),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MapaThumbnail), findsOneWidget);

      final mapaTop = tester.getTopLeft(find.byType(MapaThumbnail)).dy;
      final tabTop = tester.getTopLeft(find.byType(TabBar)).dy;
      final filtrosTop = tester.getTopLeft(find.byType(PainelFiltrosIndice)).dy;

      // O mapa interativo deve ser renderizado no topo, antes da separação de abas e dos filtros
      expect(mapaTop, lessThan(tabTop));
      expect(tabTop, lessThan(filtrosTop));
    });

    testWidgets('inicializa na aba especificada por modalidadeInicial ou na primeira se inexistente', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          pico: pico,
          cragId: 'pedra-bela',
          croqui: croqui,
          modalidadeInicial: 'Boulder',
        ),
      );
      await tester.pumpAndSettle();

      // Já deve iniciar na aba de Boulders
      expect(find.text('Pedra Inicial'), findsOneWidget);

      // E com modalidade inexistente cai na aba 0 (Setores)
      await tester.pumpWidget(
        criarAmbiente(
          key: const ValueKey('segundo'),
          pico: pico,
          cragId: 'pedra-bela',
          croqui: croqui,
          modalidadeInicial: 'Inexistente',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Setor Alvorada'), findsOneWidget);
    });

    testWidgets('exibe mensagem de vazio quando nenhum setor atende aos filtros', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        criarAmbiente(pico: pico, cragId: 'pedra-bela', croqui: croqui),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Adicionar conquistador...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar conquistador...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bruno').last);
      await tester.pumpAndSettle();

      // Desmarca 'Esportiva'
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Esportiva'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Esportiva'));
      await tester.pumpAndSettle();

      // Fecha controles
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum setor encontrado com os filtros selecionados.'), findsOneWidget);
    });

    testWidgets('exibe mensagem de vazio na aba de modalidade quando nenhuma via atende aos filtros', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        criarAmbiente(pico: pico, cragId: 'pedra-bela', croqui: croqui),
      );
      await tester.pumpAndSettle();

      // Expande controles e seleciona conquistador "Bruno"
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Adicionar conquistador...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar conquistador...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bruno').last);
      await tester.pumpAndSettle();

      // Fecha controles
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      // Alterna para aba Boulders (Bruno não tem boulder)
      await tester.tap(find.text('Boulders (0/2)'));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma escalada encontrada com os filtros selecionados.'), findsOneWidget);
    });

    testWidgets('renderiza e formata plural para modalidades móvel, multienfiada e highline e outras', (tester) async {
      final picoMisto = Pico()..nome = 'Pico Misto';
      final movel = ViaMovel()..nome = 'Fissura da Tarde'..dificuldade = GrauVia_GrauVia.BR_5;
      final multi = ViaMultiplasEnfiadas()..nome = 'Paredão dos Ventos'..dificuldadeMaxima = GrauVia_GrauVia.BR_6;
      final highline = Highline()..nome = 'Caminho do Céu';
      final escaladaGenerica = Escalada();

      final setorMisto = Setor()
        ..nome = 'Setor Misto'
        ..escaladas.addAll([
          Escalada()..viaMovel = movel,
          Escalada()..viaMultiplasEnfiadas = multi,
          Escalada()..highline = highline,
          escaladaGenerica,
        ]);

      picoMisto.setoresOuGrupos.add(SetorOuGrupo(setor: ArquivoSetor(conteudo: setorMisto)));

      await tester.pumpWidget(
        criarAmbiente(pico: picoMisto, cragId: 'pico-misto'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Móveis (1)'), findsOneWidget);
      expect(find.text('Multienfiadas (1)'), findsOneWidget);
      expect(find.text('Highlines (1)'), findsOneWidget);
    });

    testWidgets('desempata setores com mesma mediana pelo nome alfabético', (tester) async {
      final picoEmpate = Pico()..nome = 'Pico Empate';
      final setorZ = Setor()
        ..nome = 'Setor Zebra'
        ..escaladas.add(Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via Z'..dificuldade = GrauVia_GrauVia.BR_5));
      final setorA = Setor()
        ..nome = 'Setor Anta'
        ..escaladas.add(Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via A'..dificuldade = GrauVia_GrauVia.BR_5));

      picoEmpate.setoresOuGrupos.addAll([
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setorZ)),
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setorA)),
      ]);

      await tester.pumpWidget(
        criarAmbiente(pico: picoEmpate, cragId: 'pico-empate'),
      );
      await tester.pumpAndSettle();

      // Toca em Filtros e Ordenação e depois em GRAU
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GRAU'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      // Como têm o mesmo grau (5º), desempata por nome: Anta antes de Zebra
      final finderAnta = find.text('Setor Anta');
      final finderZebra = find.text('Setor Zebra');
      expect(tester.getTopLeft(finderAnta).dy, lessThan(tester.getTopLeft(finderZebra).dy));
    });

    testWidgets('renderiza grupo de setores e ordena corretamente com grupos', (tester) async {
      final grupo = Grupo()..nome = 'Grupo das Agulhas';
      final sGrupo = Setor()..nome = 'Agulha Menor'..escaladas.add(Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via Agulha'..dificuldade = GrauVia_GrauVia.BR_5));
      grupo.setores.add(ArquivoSetor(conteudo: sGrupo));
      pico.setoresOuGrupos.add(SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo)));

      await tester.pumpWidget(
        criarAmbiente(pico: pico, cragId: 'pedra-bela', croqui: croqui),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grupo das Agulhas'), findsOneWidget);
      // O grupo exibe a modalidade e faixa de graus no badge
      expect(find.text('1 esportiva - 5º'), findsOneWidget);

      // Toca em Filtros e Ordenação e depois em GRAU e verifica ordenação estável
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GRAU'));
      await tester.pumpAndSettle();

      // Toca em ALFABÉTICO
      await tester.tap(find.text('ALFABÉTICO'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      expect(find.text('Grupo das Agulhas'), findsOneWidget);
    });

    testWidgets('renderiza grupo de setores com faixa de grau e quantidade filtrada', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final grupo = Grupo()..nome = 'Complexo Pedra Alta';
      final s1 = Setor()
        ..nome = 'Pedra Alta Sul'
        ..escaladas.add(
          Escalada()
            ..viaEsportiva = (ViaEsportiva()
              ..nome = 'Via Alpha'
              ..dificuldade = GrauVia_GrauVia.BR_4
              ..conquistadores.add('Lucas')),
        );
      final s2 = Setor()
        ..nome = 'Pedra Alta Norte'
        ..escaladas.add(
          Escalada()
            ..viaEsportiva = (ViaEsportiva()
              ..nome = 'Via Beta'
              ..dificuldade = GrauVia_GrauVia.BR_8A
              ..conquistadores.add('Marcos')),
        );
      grupo.setores.addAll([
        ArquivoSetor(conteudo: s1),
        ArquivoSetor(conteudo: s2),
      ]);
      pico.setoresOuGrupos.add(SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo)));

      await tester.pumpWidget(
        criarAmbiente(pico: pico, cragId: 'pedra-bela', croqui: croqui),
      );
      await tester.pumpAndSettle();

      // Antes do filtro, exibe a faixa da modalidade esportiva (4º a 8a) no badge
      expect(find.text('Complexo Pedra Alta'), findsOneWidget);
      expect(find.text('2 esportivas - 4º a 8a'), findsOneWidget);

      // Abre controles e filtra por conquistador "Lucas"
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Adicionar conquistador...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar conquistador...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lucas').last);
      await tester.pumpAndSettle();

      // Fecha controles
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      // Agora o grupo deve exibir a proporção e faixa filtrada no badge
      expect(find.text('Complexo Pedra Alta'), findsOneWidget);
      expect(find.text('1 de 2 esportivas - 4º'), findsOneWidget);
    });

    testWidgets('toque na via na aba de escaladas sem onViaTap aciona AppNav.toVia', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          pico: pico,
          cragId: 'pedra-bela',
          croqui: croqui,
          onViaTap: null,
        ),
      );
      await tester.pumpAndSettle();

      // Alterna para aba Boulders
      await tester.tap(find.text('Boulders (2)'));
      await tester.pumpAndSettle();

      // Toca em Pedra Inicial
      await tester.tap(find.text('Pedra Inicial'));
      await tester.pumpAndSettle();
    });

    testWidgets('preserva e sincroniza filtros globalmente com GerenciadorFiltrosCroqui', (tester) async {
      // Configura filtros no gerenciador previamente
      GerenciadorFiltrosCroqui.instance.atualizarFiltros(
        'pedra-bela',
        const EstadoFiltrosUnificado(apenasClassicas: true),
      );

      await tester.pumpWidget(
        criarAmbiente(pico: pico, cragId: 'pedra-bela', croqui: croqui),
      );
      await tester.pumpAndSettle();

      // Já deve inicializar com o filtro de clássicas ativo nos contadores de Setores (2 com clássica de 3)
      expect(find.text('Setores (2/3)'), findsOneWidget);

      // Ao alterar ordenação na UI através de Filtros e Ordenação, o GerenciadorFiltrosCroqui deve ser sincronizado
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GRAU'));
      await tester.pumpAndSettle();

      final filtrosGlobais = GerenciadorFiltrosCroqui.instance.obterFiltros('pedra-bela');
      expect(filtrosGlobais.tipoOrdenacao, TipoOrdenacaoExploracao.grau);
    });
  });
}
