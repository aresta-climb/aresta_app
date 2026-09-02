// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/browse_functions.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  testWidgets(
    'buildBrowseBody passa onOpen corretamente e permite acionar telemetria',
    (WidgetTester tester) async {
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;

      final List<Map<String, dynamic>> availableCrags = [
        {
          'id': 'crag1',
          'nome': 'Pico Teste',
          'local': 'Local Teste',
          'isDownloaded': true, // Para mostrar o botão Abrir Croqui
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return buildBrowseBody(
                  context,
                  availableCrags,
                  ValueNotifier<Map<String, double>>({}),
                  onSearchChanged: (_) {},
                  onDownload: (_) {},
                  onOpen: (crag) {
                    // Simulando o comportamento definido na page browse.dart
                    TelemetryService.instance.logAcaoCroqui(
                      crag['id'],
                      'abrir_croqui',
                      origem: 'explorar',
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      // Agora o tap no card já chama onOpen diretamente se estiver baixado!
      await tester.tap(find.text('PICO TESTE'));
      await tester.pumpAndSettle();

      // Verifica a telemetria disparada pelo onOpen
      expect(mockTelemetry.recordedEvents, contains('acao_croqui'));
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['acao'],
        'abrir_croqui',
      );
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['origem'],
        'explorar',
      );
    },
  );

  testWidgets(
    'buildBrowseBody exibe animação de download quando o pico está em downloadingCrags',
    (WidgetTester tester) async {
      final List<Map<String, dynamic>> availableCrags = [
        {
          'id': 'crag_dl',
          'nome': 'Pico Baixando',
          'local': 'Local DL',
          'isDownloaded': false,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return buildBrowseBody(
                  context,
                  availableCrags,
                  ValueNotifier<Map<String, double>>({
                    'crag_dl': 0.5,
                  }), // Simula que está baixando com 50%
                  onSearchChanged: (_) {},
                  onDownload: (_) {},
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('PICO BAIXANDO'));
      await tester.pump(const Duration(milliseconds: 500));

      // O botão BAIXAR não deve estar presente de forma clicável, mas a animação sim.
      // Verifica se o CircularProgressIndicator com o percentual está presente no card.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    },
  );

  testWidgets('showDownloadBottomSheet exibe a descrição curta do pico caso exista', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> crag = {
      'id': 'crag_desc',
      'nome': 'Pico Descrição',
      'local': 'Local Desc',
      'descricao': 'Esta é a descrição curta e bacana do pico.',
      'isDownloaded': false,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDownloadBottomSheet(
                    context,
                    crag,
                    () {},
                    ValueNotifier<Map<String, double>>({}),
                  );
                },
                child: const Text('ABRIR MODAL'),
              );
            },
          ),
        ),
      ),
    );

    // Antes de abrir o modal, a descrição não existe
    expect(
      find.text('Esta é a descrição curta e bacana do pico.'),
      findsNothing,
    );

    await tester.tap(find.text('ABRIR MODAL'));
    await tester.pumpAndSettle();

    // Deve existir após abrir o modal
    expect(
      find.text('Esta é a descrição curta e bacana do pico.'),
      findsOneWidget,
    );
  });

  testWidgets('CragCard exibe estatísticas resumidas por padrão', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> crag = {
      'id': 'crag1',
      'nome': 'Pico Teste',
      'estatisticas': {
        'totalSetores': 2,
        'totalVias': 10,
        'totalBoulders': 5,
        'totalEsportivas': 5,
      },
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CragCard(
            crag: crag,
            downloadingCrags: ValueNotifier({}),
            onDownload: () {},
          ),
        ),
      ),
    );

    // Deve exibir 2 setores • 10 escaladas
    expect(find.text('2 setores • 10 escaladas'), findsOneWidget);
    
    // NÃO deve exibir a listagem de tipos (boulders, esportivas)
    expect(find.textContaining('boulders'), findsNothing);
  });

  testWidgets('CragCard exibe estatísticas detalhadas se showDetailedStats for true', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> crag = {
      'id': 'crag1',
      'nome': 'Pico Teste',
      'estatisticas': {
        'totalSetores': 3,
        'totalVias': 15,
        'totalBoulders': 10,
        'totalEsportivas': 5,
      },
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CragCard(
            crag: crag,
            downloadingCrags: ValueNotifier({}),
            showDetailedStats: true,
            onDownload: () {},
          ),
        ),
      ),
    );

    // Deve exibir o texto completo com os tipos
    expect(
      find.text('3 setores • 15 escaladas (10 boulders, 5 esportivas)'),
      findsOneWidget,
    );
  });
}
