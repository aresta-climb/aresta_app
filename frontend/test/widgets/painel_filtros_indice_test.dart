// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/utils/filtro_grau_escalada.dart';
import 'package:frontend/widgets/painel_filtros_indice.dart';
import '../mocks/mock_telemetry_service.dart';

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

      expect(find.text('Filtros'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
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
      await tester.tap(find.text('Filtros'));
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

      expect(find.text('Falésia Central'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Clica no X do chip para remover
      await tester.tap(find.byIcon(Icons.close));
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

      // Abre dropdown de conquistador
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

      expect(find.text('Alice'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
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
      await tester.tap(find.text('Filtros'));
      await tester.pumpAndSettle();

      expect(mockTelemetry.recordedEvents, contains('acao_indice_escaladas'));
      var params = mockTelemetry.recordedParams['acao_indice_escaladas']!;
      expect(params['id_croqui'], 'crag_pedra');
      expect(params['acao'], 'expandir_filtros');
      expect(params['origem'], 'indice_esportiva');

      // Colapsa
      mockTelemetry.clear();
      await tester.tap(find.text('Filtros'));
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
  });
}


