// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/utils/filtro_grau_escalada.dart';
import 'package:frontend/widgets/painel_filtros_indice.dart';
import '../mocks/mock_telemetria.dart';

void main() {
  Widget criarAmbiente(Widget child) {
    return MaterialApp(
      theme: construirTemaEscuro(),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('PainelFiltrosIndice - Widget Tests', () {
    testWidgets('renderiza no modo colapsado com chips dos filtros ativos ao invés de apenas contador', (tester) async {
      final estado = const EstadoFiltrosIndice(
        apenasClassicas: true,
        setores: {'Falésia Norte'},
      );

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estado: estado,
            modalidade: 'Esportiva',
            setoresDisponiveis: const ['Falésia Norte', 'Face Leste'],
            conquistadoresDisponiveis: const ['Alice', 'Bob'],
            onFiltrosChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Filtros e Ordenação'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      // No modo colapsado, exibe os chips dos filtros ativos
      expect(find.text('Falésia Norte'), findsOneWidget);
      expect(find.text('Clássicas (★)'), findsOneWidget);
      // O badge '2 ativos' não deve aparecer no modo colapsado quando os chips estão presentes
      expect(find.text('2 ativos'), findsNothing);
    });

    testWidgets('expande o painel ao tocar no cabeçalho e exibe RangeSlider e seletores', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estado: const EstadoFiltrosIndice(),
            modalidade: 'Esportiva',
            setoresDisponiveis: const ['Setor 1', 'Setor 2'],
            conquistadoresDisponiveis: const ['Carlos'],
            onFiltrosChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(RangeSlider), findsNothing);

      // Toca no cabeçalho para expandir
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();

      expect(find.byType(RangeSlider), findsOneWidget);
      expect(find.text('Todos os graus'), findsOneWidget);
      expect(find.text('Adicionar setor...'), findsOneWidget);
      expect(find.text('Adicionar conquistador...'), findsOneWidget);
      expect(find.text('Apenas Clássicas (★)'), findsOneWidget);
    });

    testWidgets('seleciona setor no dropdown adiciona ao estado e renderiza chip com X', (tester) async {
      EstadoFiltrosIndice? novoEstado;

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estado: const EstadoFiltrosIndice(),
            modalidade: 'Esportiva',
            setoresDisponiveis: const ['Falésia Central', 'Setor do Bosque'],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosChanged: (estado) {
              novoEstado = estado;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre dropdown de setor
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();

      // Seleciona 'Falésia Central'
      await tester.tap(find.text('Falésia Central').last);
      await tester.pumpAndSettle();

      expect(novoEstado, isNotNull);
      expect(novoEstado?.setores.contains('Falésia Central'), isTrue);

      // Agora renderiza com o setor selecionado para validar o chip e sua remoção
      EstadoFiltrosIndice? estadoRemovido;
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estado: const EstadoFiltrosIndice(setores: {'Falésia Central'}),
            modalidade: 'Esportiva',
            setoresDisponiveis: const ['Falésia Central', 'Setor do Bosque'],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosChanged: (estado) {
              estadoRemovido = estado;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Falésia Central'), findsWidgets);
      expect(find.byIcon(Icons.close), findsWidgets);

      // Clica no X do chip para remover
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();

      expect(estadoRemovido, isNotNull);
      expect(estadoRemovido?.setores.isEmpty, isTrue);
    });

    testWidgets('seleciona conquistador no dropdown adiciona ao estado e renderiza chip com X', (tester) async {
      EstadoFiltrosIndice? novoEstado;

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estado: const EstadoFiltrosIndice(),
            modalidade: 'Esportiva',
            setoresDisponiveis: const ['Setor 1'],
            conquistadoresDisponiveis: const ['Alice', 'Bob'],
            inicialmenteExpandido: true,
            onFiltrosChanged: (estado) {
              novoEstado = estado;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abre dropdown de conquistador
      await tester.ensureVisible(find.byType(DropdownButton<String>).last);
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();

      // Seleciona 'Alice'
      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();

      expect(novoEstado, isNotNull);
      expect(novoEstado?.conquistadores.contains('Alice'), isTrue);

      // Renderiza com o conquistador ativo e testa remoção com o X
      EstadoFiltrosIndice? estadoRemovido;
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estado: const EstadoFiltrosIndice(conquistadores: {'Alice'}),
            modalidade: 'Esportiva',
            setoresDisponiveis: const ['Setor 1'],
            conquistadoresDisponiveis: const ['Alice', 'Bob'],
            inicialmenteExpandido: true,
            onFiltrosChanged: (estado) {
              estadoRemovido = estado;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsWidgets);
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();

      expect(estadoRemovido, isNotNull);
      expect(estadoRemovido?.conquistadores.isEmpty, isTrue);
    });

    testWidgets('botão limpar redefine todos os filtros ativos', (tester) async {
      EstadoFiltrosIndice? estadoResetado;

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estado: const EstadoFiltrosIndice(
              apenasClassicas: true,
              setores: {'Setor 1'},
              conquistadores: {'Daniel'},
            ),
            modalidade: 'Esportiva',
            setoresDisponiveis: const ['Setor 1'],
            conquistadoresDisponiveis: const ['Daniel'],
            inicialmenteExpandido: true,
            onFiltrosChanged: (estado) {
              estadoResetado = estado;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Limpar'));
      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(estadoResetado, isNotNull);
      expect(estadoResetado?.temFiltrosAtivos, isFalse);
      expect(estadoResetado?.apenasClassicas, isFalse);
      expect(estadoResetado?.setores.isEmpty, isTrue);
      expect(estadoResetado?.conquistadores.isEmpty, isTrue);
    });

    testWidgets('exibe dica de nenhum setor ou conquistador nos filtros atuais quando listas estão vazias', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estado: const EstadoFiltrosIndice(),
            modalidade: 'Esportiva',
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            possuiConquistadores: true,
            inicialmenteExpandido: true,
            onFiltrosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhum setor nos filtros atuais'), findsOneWidget);
      expect(find.text('Nenhum conquistador nos filtros atuais'), findsOneWidget);
    });

    testWidgets('exibe dica de todos adicionados quando todos os disponíveis foram selecionados', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estado: const EstadoFiltrosIndice(
              setores: {'Setor 1'},
              conquistadores: {'Alice'},
            ),
            modalidade: 'Esportiva',
            setoresDisponiveis: const ['Setor 1'],
            conquistadoresDisponiveis: const ['Alice'],
            inicialmenteExpandido: true,
            onFiltrosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Todos os setores adicionados'), findsOneWidget);
      expect(find.text('Todos os conquistadores adicionados'), findsOneWidget);
    });

    testWidgets('oculta seção de conquistadores quando possuiConquistadores for falso', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estado: const EstadoFiltrosIndice(),
            modalidade: 'Boulder',
            setoresDisponiveis: const ['Bloco 1'],
            conquistadoresDisponiveis: const [],
            possuiConquistadores: false,
            inicialmenteExpandido: true,
            onFiltrosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Conquista (Autores)'), findsNothing);
    });

    testWidgets('renderiza chips de grau, setor e conquistador no modo colapsado e permite remoção via X', (tester) async {
      EstadoFiltrosIndice? novoEstado;

      final estado = const EstadoFiltrosIndice(
        minGrauValor: 705, // 6ºsup
        maxGrauValor: 1310, // 12a
        setores: {'Setor Família I'},
        conquistadores: {'Mecena'},
      );

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estado: estado,
            modalidade: 'Esportiva',
            setoresDisponiveis: const ['Setor Família I'],
            conquistadoresDisponiveis: const ['Mecena'],
            inicialmenteExpandido: false,
            onFiltrosChanged: (e) => novoEstado = e,
          ),
        ),
      );

      // Verifica presença dos 3 chips exatamente como solicitado
      expect(find.text('6ºsup a 12a'), findsOneWidget);
      expect(find.text('Setor Família I'), findsOneWidget);
      expect(find.text('Mecena'), findsOneWidget);

      // Clica no X do chip de grau
      await tester.tap(find.descendant(
        of: find.widgetWithText(Chip, '6ºsup a 12a'),
        matching: find.byIcon(Icons.close),
      ));
      await tester.pumpAndSettle();

      expect(novoEstado, isNotNull);
      expect(novoEstado?.minGrauValor, isNull);
      expect(novoEstado?.maxGrauValor, isNull);
    });

    testWidgets('oculta botão apenas clássicas se temClassicasDisponiveis for falso', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estado: const EstadoFiltrosIndice(),
            modalidade: 'Esportiva',
            setoresDisponiveis: const ['Setor 1'],
            conquistadoresDisponiveis: const ['Alice'],
            temClassicasDisponiveis: false,
            inicialmenteExpandido: true,
            onFiltrosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apenas Clássicas (★)'), findsNothing);
    });

    testWidgets('exibe botão apenas clássicas se temClassicasDisponiveis for verdadeiro', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estado: const EstadoFiltrosIndice(),
            modalidade: 'Esportiva',
            setoresDisponiveis: const ['Setor 1'],
            conquistadoresDisponiveis: const ['Alice'],
            temClassicasDisponiveis: true,
            inicialmenteExpandido: true,
            onFiltrosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apenas Clássicas (★)'), findsOneWidget);
    });
  });

  group('PainelFiltrosIndice - Telemetria', () {
    late MockTelemetryService mockTelemetry;

    setUp(() {
      mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;
    });

    testWidgets('dispara expandir_filtros e colapsar_filtros ao tocar no cabeçalho', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            cragId: 'crag_pedra',
            estado: const EstadoFiltrosIndice(),
            modalidade: 'Esportiva',
            setoresDisponiveis: const ['Setor 1'],
            conquistadoresDisponiveis: const [],
            onFiltrosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expande
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      var params = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'expandir_filtros');
      expect(params['origem'], 'indice_esportiva');

      // Colapsa
      mockTelemetry.clear();
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      params = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'colapsar_filtros');
      expect(params['origem'], 'indice_esportiva');
    });

    testWidgets('dispara filtrar_setor ao selecionar setor no dropdown', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            cragId: 'crag_pedra',
            estado: const EstadoFiltrosIndice(),
            modalidade: 'Esportiva',
            setoresDisponiveis: const ['Setor Alpha'],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Setor Alpha').last);
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      final params = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'filtrar_setor');
      expect(params['origem'], 'indice_esportiva');
      expect(params['detalhe'], 'Setor Alpha');
    });

    testWidgets('dispara filtrar_conquistador ao selecionar conquistador no dropdown', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            cragId: 'crag_pedra',
            estado: const EstadoFiltrosIndice(),
            modalidade: 'Esportiva',
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const ['Carlos'],
            inicialmenteExpandido: true,
            onFiltrosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(DropdownButton<String>).last);
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carlos').last);
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      final params = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'filtrar_conquistador');
      expect(params['origem'], 'indice_esportiva');
      expect(params['detalhe'], 'Carlos');
    });

    testWidgets('dispara filtrar_classicas ao alternar botão de clássicas', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            cragId: 'crag_pedra',
            estado: const EstadoFiltrosIndice(apenasClassicas: false),
            modalidade: 'Esportiva',
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            temClassicasDisponiveis: true,
            inicialmenteExpandido: true,
            onFiltrosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apenas Clássicas (★)'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      final params = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'filtrar_classicas');
      expect(params['origem'], 'indice_esportiva');
      expect(params['detalhe'], 'true');
    });

    testWidgets('dispara filtrar_grau ao ajustar RangeSlider', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            cragId: 'crag_pedra',
            estado: const EstadoFiltrosIndice(),
            modalidade: 'Esportiva',
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rangeSliderFinder = find.byType(RangeSlider);
      expect(rangeSliderFinder, findsOneWidget);

      final slider = tester.widget<RangeSlider>(rangeSliderFinder);
      slider.onChangeEnd?.call(const RangeValues(3, 7));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      final params = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'filtrar_grau');
      expect(params['origem'], 'indice_esportiva');
      expect(params['detalhe'], isNotNull);
    });

    testWidgets('dispara limpar_filtros ao tocar no botão Limpar', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            cragId: 'crag_pedra',
            estado: const EstadoFiltrosIndice(apenasClassicas: true),
            modalidade: 'Esportiva',
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      final params = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'limpar_filtros');
      expect(params['origem'], 'indice_esportiva');
    });

    testWidgets('dispara alterar_ordenacao ao mudar tipo ou direcao de ordenacao no bottom sheet', (tester) async {
      EstadoFiltrosUnificado estado = const EstadoFiltrosUnificado();

      await tester.pumpWidget(
        criarAmbiente(
          StatefulBuilder(
            builder: (context, setState) {
              return PainelFiltrosIndice(
                cragId: 'crag_pedra',
                estadoUnificado: estado,
                abaAtiva: 'Esportiva',
                modalidadesDisponiveis: const ['Esportiva'],
                setoresDisponiveis: const [],
                conquistadoresDisponiveis: const [],
                inicialmenteExpandido: true,
                onFiltrosUnificadosChanged: (novo) {
                  setState(() => estado = novo);
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      mockTelemetry.clear();

      // Clica em 'GRAU' na barra de ordenação
      await tester.tap(find.text('GRAU'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      expect(mockTelemetry.recordedEvents, contains('alterar_ordenacao'));

      var paramsIndice = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(paramsIndice['id_croqui'], 'crag_pedra');
      expect(paramsIndice['acao'], 'alterar_ordenacao');
      expect(paramsIndice['origem'], 'indice_esportiva');
      expect(paramsIndice['detalhe'], 'grau_asc');

      var paramsOrd = mockTelemetry.recordedParams['alterar_ordenacao']!;
      expect(paramsOrd['origem'], 'esportiva');
      expect(paramsOrd['detalhe'], 'grau_asc');

      // Alterna a direção da ordenação tocando no botão de seta
      mockTelemetry.clear();
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      expect(mockTelemetry.recordedEvents, contains('alterar_ordenacao'));

      paramsIndice = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(paramsIndice['id_croqui'], 'crag_pedra');
      expect(paramsIndice['acao'], 'alterar_ordenacao');
      expect(paramsIndice['origem'], 'indice_esportiva');
      expect(paramsIndice['detalhe'], 'grau_desc');

      paramsOrd = mockTelemetry.recordedParams['alterar_ordenacao']!;
      expect(paramsOrd['origem'], 'esportiva');
      expect(paramsOrd['detalhe'], 'grau_desc');
    });

    testWidgets('dispara alterar_ordenacao ao excluir chip de ordenacao na barra externa', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            cragId: 'crag_pedra',
            estadoUnificado: const EstadoFiltrosUnificado(
              tipoOrdenacao: TipoOrdenacaoExploracao.grau,
              direcaoCrescente: false,
            ),
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      mockTelemetry.clear();

      final closeIcon = find.descendant(
        of: find.widgetWithText(Chip, 'Grau ▼'),
        matching: find.byIcon(Icons.close),
      );
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      expect(mockTelemetry.recordedEvents, contains('alterar_ordenacao'));

      final paramsIndice = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(paramsIndice['id_croqui'], 'crag_pedra');
      expect(paramsIndice['acao'], 'alterar_ordenacao');
      expect(paramsIndice['origem'], 'indice_esportiva');
      expect(paramsIndice['detalhe'], 'padrao_asc');

      final paramsOrd = mockTelemetry.recordedParams['alterar_ordenacao']!;
      expect(paramsOrd['origem'], 'esportiva');
      expect(paramsOrd['detalhe'], 'padrao_asc');
    });

    testWidgets('dispara filtrar_modalidade ao alternar modalidade no bottom sheet da aba Setores', (tester) async {
      EstadoFiltrosUnificado estado = const EstadoFiltrosUnificado();

      await tester.pumpWidget(
        criarAmbiente(
          StatefulBuilder(
            builder: (context, setState) {
              return PainelFiltrosIndice(
                cragId: 'crag_pedra',
                estadoUnificado: estado,
                abaAtiva: 'Setores',
                modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
                setoresDisponiveis: const [],
                conquistadoresDisponiveis: const [],
                inicialmenteExpandido: true,
                onFiltrosUnificadosChanged: (novo) {
                  setState(() => estado = novo);
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      mockTelemetry.clear();

      // Clica em 'Boulder' no seletor de modalidades
      await tester.tap(find.text('Boulder').first);
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      var params = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'filtrar_modalidade');
      expect(params['origem'], 'indice_setores');
      expect(params['detalhe'], 'Boulder:inativo');

      // Clica novamente em 'Boulder' para reativar
      mockTelemetry.clear();
      await tester.tap(find.text('Boulder').first);
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      params = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'filtrar_modalidade');
      expect(params['origem'], 'indice_setores');
      expect(params['detalhe'], 'Boulder:ativo');
    });

    testWidgets('dispara filtrar_modalidade ao excluir chip de modalidade na barra externa', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            cragId: 'crag_pedra',
            estadoUnificado: const EstadoFiltrosUnificado(
              modalidadesAtivas: {'Esportiva'},
            ),
            abaAtiva: 'Setores',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      mockTelemetry.clear();

      final closeIcon = find.descendant(
        of: find.widgetWithText(Chip, 'Esportiva'),
        matching: find.byIcon(Icons.close),
      );
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      final params = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'filtrar_modalidade');
      expect(params['origem'], 'indice_setores');
      expect(params['detalhe'], 'Esportiva:inativo');
    });

    testWidgets('no modo Superset (Setores), renderiza seleção de modalidades e omite dropdown de setores', (tester) async {
      EstadoFiltrosUnificado? estadoEmitido;

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: const EstadoFiltrosUnificado(),
            abaAtiva: 'Setores',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const ['Setor 1'],
            conquistadoresDisponiveis: const ['Carlos'],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (e) => estadoEmitido = e,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Deve exibir os seletores de modalidade ativa
      expect(find.text('Esportiva'), findsWidgets);
      expect(find.text('Boulder'), findsWidgets);

      // Não deve exibir dropdown de selecionar setores quando na aba Setores
      expect(find.text('Setor 1'), findsNothing);

      // Tocar no chip de Boulder deve atualizar estado
      await tester.tap(find.text('Boulder').first);
      await tester.pumpAndSettle();
      expect(estadoEmitido, isNotNull);
    });

    testWidgets('no modo contextual (ex: Esportiva), omite seleção de modalidades e exibe dropdown de setores', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: const EstadoFiltrosUnificado(),
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const ['Setor 1', 'Setor 2'],
            conquistadoresDisponiveis: const ['Carlos'],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exibe RangeSlider da modalidade
      expect(find.byType(RangeSlider), findsOneWidget);

      // Exibe seletor de setores
      expect(find.text('Adicionar setor...'), findsOneWidget);
    });

    testWidgets('ao desmarcar e remarcar todas as modalidades, normaliza estado para vazio sem filtro ativo', (tester) async {
      EstadoFiltrosUnificado? ultimoEstado;

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: const EstadoFiltrosUnificado(),
            abaAtiva: 'Setores',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (e) => ultimoEstado = e,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Desmarca Boulder: estado deve ter apenas Esportiva
      await tester.tap(find.text('Boulder').first);
      await tester.pumpAndSettle();
      expect(ultimoEstado?.modalidadesAtivas, {'Esportiva'});

      // Remarca Boulder: como todas as disponíveis estão selecionadas, deve normalizar para vazio
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: ultimoEstado!,
            abaAtiva: 'Setores',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (e) => ultimoEstado = e,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Boulder').first);
      await tester.pumpAndSettle();
      expect(ultimoEstado?.modalidadesAtivas.isEmpty, isTrue);

      // Re-renderiza com o novo estado normalizado
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: ultimoEstado!,
            abaAtiva: 'Setores',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (e) => ultimoEstado = e,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 ativo'), findsNothing);
    });

    testWidgets('na aba Setores omite filtro de grupos mesmo com gruposDisponiveis informados', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: const EstadoFiltrosUnificado(),
            abaAtiva: 'Setores',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const ['Setor 1'],
            gruposDisponiveis: const ['Grupo Principal'],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Localização (Grupos)'), findsNothing);
      expect(find.text('Adicionar grupo...'), findsNothing);
      expect(find.text('Grupo Principal'), findsNothing);
    });

    testWidgets('nas abas de modalidade exibe seletor de Localização unificado com setores e grupos', (tester) async {
      EstadoFiltrosUnificado? estadoEmitido;

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: const EstadoFiltrosUnificado(),
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const ['Setor Alpha'],
            gruposDisponiveis: const ['Grupo Beta'],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (e) => estadoEmitido = e,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Deve exibir um único título de "Localização", e o hint "Adicionar setor ou grupo..."
      expect(find.text('Localização'), findsOneWidget);
      expect(find.text('Localização (Setores)'), findsNothing);
      expect(find.text('Localização (Grupos)'), findsNothing);
      expect(find.text('Adicionar setor ou grupo...'), findsOneWidget);

      // Toca no dropdown de localização
      await tester.tap(find.text('Adicionar setor ou grupo...'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Seleciona o grupo Beta
      await tester.tap(find.text('Grupo Beta (Grupo)').last);
      await tester.pumpAndSettle();

      expect(estadoEmitido?.grupos, contains('Grupo Beta'));
    });

    testWidgets('faixa de grau com min e max conta como exatamente 1 filtro ativo', (tester) async {
      final estado = const EstadoFiltrosUnificado(
        minGrauPorModalidade: {'Esportiva': 800},
        maxGrauPorModalidade: {'Esportiva': 1000},
      );

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: estado,
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 ativo'), findsOneWidget);
      expect(find.text('2 ativos'), findsNothing);
    });

    testWidgets('ao selecionar apenas um conquistador, exibe exatamente 1 ativo', (tester) async {
      EstadoFiltrosUnificado? estadoEmitido;

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: const EstadoFiltrosUnificado(),
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const ['Lucas'],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (e) => estadoEmitido = e,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lucas').last);
      await tester.pumpAndSettle();

      expect(estadoEmitido?.conquistadores, {'Lucas'});
      expect(estadoEmitido?.minGrauPorModalidade, isEmpty);
      expect(estadoEmitido?.maxGrauPorModalidade, isEmpty);
      expect(estadoEmitido?.modalidadesAtivas, isEmpty);
      expect(estadoEmitido?.setores, isEmpty);
      expect(estadoEmitido?.grupos, isEmpty);
    });

    testWidgets('faixa de grau com apenas max conta como exatamente 1 filtro ativo e exibe chip no modo colapsado', (tester) async {
      final estado = const EstadoFiltrosUnificado(
        maxGrauPorModalidade: {'Esportiva': 800},
      );

      // No modo colapsado: exibe exatamente 1 chip
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: estado,
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: false,
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(Chip), findsOneWidget);

      // No modo expandido: exibe badge '1 ativo'
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            key: const ValueKey('expandido'),
            estadoUnificado: estado,
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 ativo'), findsOneWidget);
      expect(find.text('2 ativos'), findsNothing);
    });

    testWidgets('faixa de grau com min e max renderiza exatamente 1 chip no modo colapsado', (tester) async {
      final estado = const EstadoFiltrosUnificado(
        minGrauPorModalidade: {'Esportiva': 700},
        maxGrauPorModalidade: {'Esportiva': 900},
      );

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: estado,
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: false,
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('painel expandido não encapsula em scrollview interno restritivo', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: const EstadoFiltrosUnificado(),
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );

      final painelFinder = find.byType(PainelFiltrosIndice);
      final innerScrollFinder = find.descendant(
        of: painelFinder,
        matching: find.byType(SingleChildScrollView),
      );
      expect(innerScrollFinder, findsNothing);
    });

    testWidgets('no modo Superset com Esportiva, Tradicional e Boulder, renderiza no máximo 2 sliders (Vias e Boulders)', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: const EstadoFiltrosUnificado(),
            abaAtiva: 'Setores',
            modalidadesDisponiveis: const ['Esportiva', 'Tradicional', 'Boulder'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Deve encontrar exatamente 2 RangeSliders: 1 para Vias e 1 para Boulders
      expect(find.byType(RangeSlider), findsNWidgets(2));
      expect(find.text('Faixa de Grau (Vias)'), findsOneWidget);
      expect(find.text('Faixa de Grau (Boulders)'), findsOneWidget);
      expect(find.text('Faixa de Grau (ESPORTIVA)'), findsNothing);
      expect(find.text('Faixa de Grau (TRADICIONAL)'), findsNothing);
    });

    testWidgets('no modo Superset com apenas modalidades de vias, renderiza apenas 1 slider com título Faixa de Grau', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: const EstadoFiltrosUnificado(),
            abaAtiva: 'Setores',
            modalidadesDisponiveis: const ['Esportiva', 'Tradicional', 'Top Rope'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Apenas 1 RangeSlider para vias
      expect(find.byType(RangeSlider), findsOneWidget);
      expect(find.text('Faixa de Grau'), findsOneWidget);
      expect(find.text('Faixa de Grau (Vias)'), findsNothing);
      expect(find.text('Faixa de Grau (Boulders)'), findsNothing);
    });

    testWidgets('ao ajustar slider de Vias na aba Setores, atualiza chave "Via" no estado unificado', (tester) async {
      EstadoFiltrosUnificado? estadoEmitido;

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: const EstadoFiltrosUnificado(),
            abaAtiva: 'Setores',
            modalidadesDisponiveis: const ['Esportiva', 'Tradicional', 'Boulder'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (e) => estadoEmitido = e,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(RangeSlider);
      expect(sliders, findsNWidgets(2));

      // Primeiro slider é Vias
      final sliderVias = tester.widget<RangeSlider>(sliders.first);
      // Índice 4 em grausVia é 5º (valor 600), índice 8 é 7a (valor 810)
      sliderVias.onChanged?.call(const RangeValues(4, 8));
      await tester.pumpAndSettle();

      expect(estadoEmitido?.minGrauPorModalidade['Via'], 600);
      expect(estadoEmitido?.maxGrauPorModalidade['Via'], 810);
    });

    testWidgets('na aba Esportiva com filtros de grau de Via e Boulder ativos, exibe apenas chip de grau de Via e conta 1 ativo', (tester) async {
      final estado = const EstadoFiltrosUnificado(
        minGrauPorModalidade: {'Via': 700, 'Boulder': 600},
        maxGrauPorModalidade: {'Via': 1030, 'Boulder': 1200},
      );

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: estado,
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );

      // No modo colapsado, exibe apenas o chip da categoria correspondente à aba (Via -> 6º a 9c)
      expect(find.text('6º a 9c'), findsOneWidget);
      expect(find.text('V5 a V11'), findsNothing);
      expect(find.text('Boulders: V5 a V11'), findsNothing);
      expect(find.text('Vias: 6º a 9c'), findsNothing);

      // Ao expandir, o contador deve indicar exatamente 1 ativo (apenas o grau de via relevante para a aba)
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      expect(find.text('1 ativo'), findsOneWidget);
      expect(find.text('2 ativos'), findsNothing);
    });

    testWidgets('na aba Boulder com filtros de grau de Via e Boulder ativos, exibe apenas chip de grau de Boulder e conta 1 ativo', (tester) async {
      final estado = const EstadoFiltrosUnificado(
        minGrauPorModalidade: {'Via': 700, 'Boulder': 600},
        maxGrauPorModalidade: {'Via': 1030, 'Boulder': 1200},
      );

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: estado,
            abaAtiva: 'Boulder',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );

      // No modo colapsado, exibe apenas o chip da categoria correspondente à aba (Boulder -> V5 a V11)
      expect(find.text('V5 a V11'), findsOneWidget);
      expect(find.text('6º a 9c'), findsNothing);
      expect(find.text('Vias: 6º a 9c'), findsNothing);
      expect(find.text('Boulders: V5 a V11'), findsNothing);

      // Ao expandir, o contador deve indicar exatamente 1 ativo
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      expect(find.text('1 ativo'), findsOneWidget);
      expect(find.text('2 ativos'), findsNothing);
    });

    testWidgets('na aba Setores com filtros de grau de Via e Boulder ativos, exibe ambos os chips com prefixo de categoria e conta 2 ativos', (tester) async {
      final estado = const EstadoFiltrosUnificado(
        minGrauPorModalidade: {'Via': 700, 'Boulder': 600},
        maxGrauPorModalidade: {'Via': 1030, 'Boulder': 1200},
      );

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: estado,
            abaAtiva: 'Setores',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );

      // Na aba Setores, exibe ambos os chips com o prefixo para clareza
      expect(find.text('Vias: 6º a 9c'), findsOneWidget);
      expect(find.text('Boulders: V5 a V11'), findsOneWidget);

      // Ao expandir, o contador indica 2 ativos
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      expect(find.text('2 ativos'), findsOneWidget);
    });

    testWidgets('filtro de modalidadesAtivas só renderiza chip e conta como ativo na aba Setores', (tester) async {
      final estado = const EstadoFiltrosUnificado(
        modalidadesAtivas: {'Esportiva'},
      );

      // 1. Na aba Setores
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: estado,
            abaAtiva: 'Setores',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Esportiva'), findsOneWidget);
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();
      expect(find.text('1 ativo'), findsOneWidget);

      // 2. Na aba contextual Esportiva
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: estado,
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );

      // Não deve exibir chip de modalidade na aba dedicada à modalidade
      expect(find.text('Esportiva'), findsNothing);
      expect(find.text('1 ativo'), findsNothing);
    });

    testWidgets('ao limpar filtros na aba contextual Esportiva, redefine grau da aba mas preserva grau de Boulder', (tester) async {
      EstadoFiltrosUnificado? estadoEmitido;
      final estado = const EstadoFiltrosUnificado(
        minGrauPorModalidade: {'Via': 700, 'Boulder': 600},
        maxGrauPorModalidade: {'Via': 1030, 'Boulder': 1200},
        setores: {'Falésia Central'},
      );

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: estado,
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva', 'Boulder'],
            setoresDisponiveis: const ['Falésia Central'],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (e) => estadoEmitido = e,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(estadoEmitido, isNotNull);
      // Setores limpos
      expect(estadoEmitido!.setores, isEmpty);
      // Grau de Via limpo
      expect(estadoEmitido!.minGrauPorModalidade.containsKey('Via'), isFalse);
      expect(estadoEmitido!.maxGrauPorModalidade.containsKey('Via'), isFalse);
      // Grau de Boulder PRESERVADO
      expect(estadoEmitido!.minGrauPorModalidade['Boulder'], 600);
      expect(estadoEmitido!.maxGrauPorModalidade['Boulder'], 1200);
    });

    testWidgets('barra externa exibe botão Filtros e Ordenação com ícone tune e chips em scroll horizontal em linha única', (tester) async {
      final estado = const EstadoFiltrosUnificado(
        setores: {'Falésia Central', 'Setor Leste'},
        apenasClassicas: true,
      );

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: estado,
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva'],
            setoresDisponiveis: const ['Falésia Central', 'Setor Leste'],
            conquistadoresDisponiveis: const [],
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Filtros e Ordenação'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // Fila de chips em scroll horizontal
      final scrollFinder = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(scrollFinder, findsOneWidget);

      expect(find.text('Falésia Central'), findsOneWidget);
      expect(find.text('Setor Leste'), findsOneWidget);
      expect(find.text('Clássicas (★)'), findsOneWidget);
    });

    testWidgets('ordenação não-padrão renderiza chip dinâmico na barra externa e permite reset rápido via X', (tester) async {
      EstadoFiltrosUnificado? estadoEmitido;
      final estado = const EstadoFiltrosUnificado(
        tipoOrdenacao: TipoOrdenacaoExploracao.grau,
        direcaoCrescente: true,
      );

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: estado,
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            onFiltrosUnificadosChanged: (e) => estadoEmitido = e,
          ),
        ),
      );

      // Exibe chip com rótulo Grau ▲
      expect(find.text('Grau ▲'), findsOneWidget);

      // Clica no X do chip de ordenação
      final closeIcon = find.descendant(
        of: find.widgetWithText(Chip, 'Grau ▲'),
        matching: find.byIcon(Icons.close),
      );
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      expect(estadoEmitido, isNotNull);
      expect(estadoEmitido!.tipoOrdenacao, TipoOrdenacaoExploracao.padrao);
      expect(estadoEmitido!.direcaoCrescente, isTrue);
    });

    testWidgets('ordenação padrão Padrão ▲ não renderiza chip de ordenação para evitar poluição', (tester) async {
      final estado = const EstadoFiltrosUnificado(
        tipoOrdenacao: TipoOrdenacaoExploracao.padrao,
        direcaoCrescente: true,
      );

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: estado,
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva'],
            setoresDisponiveis: const [],
            conquistadoresDisponiveis: const [],
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Padrão ▲'), findsNothing);
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('toque no botão Filtros e Ordenação abre Modal Bottom Sheet com seções de Ordenação, Filtros e botão de Feedback', (tester) async {
      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: const EstadoFiltrosUnificado(),
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva'],
            setoresDisponiveis: const ['Falésia Central'],
            conquistadoresDisponiveis: const ['Carlos'],
            onFiltrosUnificadosChanged: (_) {},
          ),
        ),
      );

      // Não está visível antes do toque
      expect(find.text('ORDENAÇÃO'), findsNothing);
      expect(find.text('FILTROS'), findsNothing);

      // Toca em Filtros e Ordenação
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();

      // Modal Bottom Sheet aberto com as duas seções
      expect(find.text('ORDENAÇÃO'), findsOneWidget);
      expect(find.text('FILTROS'), findsOneWidget);
      expect(find.text('PADRÃO'), findsOneWidget);
      expect(find.text('GRAU'), findsOneWidget);
      expect(find.text('ALFABÉTICO'), findsOneWidget);
      expect(find.text('Faixa de Grau'), findsOneWidget);

      // Botão de feedback na extrema direita do cabeçalho do Bottom Sheet
      expect(find.byTooltip('Enviar Feedback/Bug'), findsOneWidget);
    });

    testWidgets('botão Limpar no Bottom Sheet zera filtros e restaura ordenação para padrão', (tester) async {
      EstadoFiltrosUnificado? estadoEmitido;
      final estado = const EstadoFiltrosUnificado(
        tipoOrdenacao: TipoOrdenacaoExploracao.grau,
        direcaoCrescente: false,
        setores: {'Falésia Central'},
        minGrauPorModalidade: {'Via': 700},
      );

      await tester.pumpWidget(
        criarAmbiente(
          PainelFiltrosIndice(
            estadoUnificado: estado,
            abaAtiva: 'Esportiva',
            modalidadesDisponiveis: const ['Esportiva'],
            setoresDisponiveis: const ['Falésia Central'],
            conquistadoresDisponiveis: const [],
            inicialmenteExpandido: true,
            onFiltrosUnificadosChanged: (e) => estadoEmitido = e,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(estadoEmitido, isNotNull);
      expect(estadoEmitido!.setores, isEmpty);
      expect(estadoEmitido!.minGrauPorModalidade.containsKey('Via'), isFalse);
      expect(estadoEmitido!.tipoOrdenacao, TipoOrdenacaoExploracao.padrao);
      expect(estadoEmitido!.direcaoCrescente, isTrue);
    });

    testWidgets('abrir modal de filtros com controlador de navegação ativo registra ControlesNode e restaura ao fechar', (tester) async {
      final editorDeCroqui = EditorDeCroqui();
      final datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
      final syncService = SyncService(datasetRepository: datasetRepo);
      final controller = TreeNavigationController();

      await tester.pumpWidget(
        MaterialApp(
          theme: construirTemaEscuro(),
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: datasetRepo,
            syncService: syncService,
            treeController: controller,
            child: Scaffold(
              body: PainelFiltrosIndice(
                cragId: 'pedra_bela',
                estado: const EstadoFiltrosIndice(),
                modalidade: 'Esportiva',
                setoresDisponiveis: const ['Setor 1'],
                conquistadoresDisponiveis: const [],
                onFiltrosChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Clica em 'Filtros e Ordenação' para abrir o bottom sheet
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();

      // Confirma que NÃO exibe Unknown Node e que o nó ativo na árvore é ControlesNode
      expect(find.text('Unknown Node'), findsNothing);
      expect(controller.currentNode, isA<ControlesNode>());
      expect((controller.currentNode as ControlesNode).cragId, 'pedra_bela');
      expect((controller.currentNode as ControlesNode).rotuloAmigavel, 'Filtros e Ordenação');

      // Fecha o modal pelo botão X
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      // O nó na árvore deve voltar ao nó original
      expect(controller.currentNode, isA<HomeNode>());
    });

    testWidgets('botão back do SO com modal de filtros aberto fecha o modal na primeira vez e preserva a página', (tester) async {
      final editorDeCroqui = EditorDeCroqui();
      final datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
      final syncService = SyncService(datasetRepository: datasetRepo);
      final controller = TreeNavigationController();
      controller.navigateTo(PicoNode(cragId: 'pedra_bela', parent: controller.currentNode));
      controller.navigateTo(SetoresNode(cragId: 'pedra_bela', parent: controller.currentNode));

      await tester.pumpWidget(
        MaterialApp(
          theme: construirTemaEscuro(),
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: datasetRepo,
            syncService: syncService,
            treeController: controller,
            child: Scaffold(
              body: PainelFiltrosIndice(
                cragId: 'pedra_bela',
                estado: const EstadoFiltrosIndice(),
                modalidade: 'Esportiva',
                setoresDisponiveis: const ['Setor 1'],
                conquistadoresDisponiveis: const [],
                onFiltrosChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Clica em 'Filtros e Ordenação' para abrir o bottom sheet
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();

      expect(controller.currentNode, isA<ControlesNode>());
      // Verifica que o modal está visível
      expect(find.text('Adicionar setor...'), findsOneWidget);

      // Simula o primeiro clique de "back" do SO (chamando controller.goBack())
      final retornoPrimeiroBack = controller.goBack();
      await tester.pumpAndSettle();

      expect(retornoPrimeiroBack, isTrue);
      // No primeiro back, o modal DEVE ter fechado
      expect(find.text('Adicionar setor...'), findsNothing);
      // E a página atual DEVE ser mantida (SetoresNode), não pode ter saído para PicoNode!
      expect(controller.currentNode, isA<SetoresNode>());

      // Segundo back: agora sim deve voltar da página (SetoresNode -> PicoNode)
      final retornoSegundoBack = controller.goBack();
      await tester.pumpAndSettle();

      expect(retornoSegundoBack, isTrue);
      expect(controller.currentNode, isA<PicoNode>());
    });

    testWidgets('botão back nativo do SO (handlePopRoute) fecha bottom sheet na primeira invocação e preserva a página', (tester) async {
      final editorDeCroqui = EditorDeCroqui();
      final datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
      final syncService = SyncService(datasetRepository: datasetRepo);
      final controller = TreeNavigationController();
      controller.navigateTo(PicoNode(cragId: 'pedra_bela', parent: controller.currentNode));
      controller.navigateTo(SetoresNode(cragId: 'pedra_bela', parent: controller.currentNode));

      await tester.pumpWidget(
        MaterialApp(
          theme: construirTemaEscuro(),
          home: TreeNavigationWrapper(
            key: TreeNavigationWrapper.navKey,
            datasetRepo: datasetRepo,
            syncService: syncService,
            treeController: controller,
            child: Scaffold(
              body: PainelFiltrosIndice(
                cragId: 'pedra_bela',
                estado: const EstadoFiltrosIndice(),
                modalidade: 'Esportiva',
                setoresDisponiveis: const ['Setor 1'],
                conquistadoresDisponiveis: const [],
                onFiltrosChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Clica em 'Filtros e Ordenação' para abrir o bottom sheet
      await tester.tap(find.text('Filtros e Ordenação'));
      await tester.pumpAndSettle();

      expect(controller.currentNode, isA<ControlesNode>());
      expect(find.text('Adicionar setor...'), findsOneWidget);

      // Simula o evento de pop disparado pelo SO (como a tecla Back do Android)
      await WidgetsBinding.instance.handlePopRoute();
      await tester.pumpAndSettle();

      // O modal DEVE ter fechado
      expect(find.text('Adicionar setor...'), findsNothing);
      // E a página atual SetoresNode deve ser preservada
      expect(controller.currentNode, isA<SetoresNode>());

      // Segundo pop do SO
      await WidgetsBinding.instance.handlePopRoute();
      await tester.pumpAndSettle();

      // Agora sim recua para PicoNode
      expect(controller.currentNode, isA<PicoNode>());
    });
  });
}




