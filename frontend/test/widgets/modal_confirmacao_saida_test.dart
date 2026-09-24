// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/widgets/modal_confirmacao_saida.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  late MockTelemetryService mockTelemetria;

  setUp(() {
    mockTelemetria = MockTelemetryService();
    TelemetryService.instance = mockTelemetria;
    ModalConfirmacaoSaida.resetarSessaoParaTestes();
  });

  group('ModalConfirmacaoSaida', () {
    testWidgets('exibe aviso de montanha, botao de feedback e opcoes de salvar ou sair', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalConfirmacaoSaida.mostrar(
                    context: context,
                    nomePico: 'Gruta do Baú',
                    tamanhoFormatado: '18.4 MB',
                    onSalvar: () {},
                    onSairSemSalvar: () {},
                  );
                },
                child: const Text('Abrir Guardião'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Guardião'));
      await tester.pumpAndSettle();

      expect(find.text('SALVAR PARA A PEDRA?'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
      expect(
        find.text(
          'Lembre-se: na rocha não há sinal de internet. Para consultar os croquis e graus de Gruta do Baú sem conexão, salve o guia offline.',
        ),
        findsOneWidget,
      );
      expect(find.text('Salvar Offline (18.4 MB)'), findsOneWidget);
      expect(find.text('Sair sem Salvar'), findsOneWidget);
    });

    testWidgets('dispara callback de salvar e fecha o modal', (tester) async {
      bool clicouSalvar = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalConfirmacaoSaida.mostrar(
                    context: context,
                    nomePico: 'Pedra Grande',
                    tamanhoFormatado: '12 MB',
                    onSalvar: () {
                      clicouSalvar = true;
                    },
                    onSairSemSalvar: () {},
                  );
                },
                child: const Text('Abrir Guardião'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Guardião'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar Offline (12 MB)'));
      await tester.pumpAndSettle();

      expect(clicouSalvar, isTrue);
      expect(find.text('SALVAR PARA A PEDRA?'), findsNothing);
    });

    testWidgets('exibe Salvar Offline sem parenteses quando tamanhoFormatado for nulo ou invalido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalConfirmacaoSaida.mostrar(
                    context: context,
                    nomePico: 'Pico Sem Tamanho',
                    tamanhoFormatado: null,
                    onSalvar: () {},
                    onSairSemSalvar: () {},
                  );
                },
                child: const Text('Abrir Guardião'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Guardião'));
      await tester.pumpAndSettle();

      expect(find.text('Salvar Offline'), findsOneWidget);
    });

    testWidgets('aparece apenas uma vez por sessao do app', (tester) async {
      bool saiuDireto = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalConfirmacaoSaida.mostrar(
                    context: context,
                    nomePico: 'Primeiro Pico',
                    tamanhoFormatado: '10 MB',
                    onSalvar: () {},
                    onSairSemSalvar: () {},
                  );
                },
                child: const Text('Primeira Saida'),
              ),
            ),
          ),
        ),
      );

      // Primeira vez na sessão: modal deve abrir normalmente
      await tester.tap(find.text('Primeira Saida'));
      await tester.pumpAndSettle();
      expect(find.text('SALVAR PARA A PEDRA?'), findsOneWidget);

      // Fecha o modal clicando em sair sem salvar
      await tester.tap(find.text('Sair sem Salvar'));
      await tester.pumpAndSettle();
      expect(find.text('SALVAR PARA A PEDRA?'), findsNothing);

      // Segunda vez na mesma sessão: NÃO deve exibir o modal e deve chamar onSairSemSalvar diretamente
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalConfirmacaoSaida.mostrar(
                    context: context,
                    nomePico: 'Segundo Pico',
                    tamanhoFormatado: '15 MB',
                    onSalvar: () {},
                    onSairSemSalvar: () {
                      saiuDireto = true;
                    },
                  );
                },
                child: const Text('Segunda Saida'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Segunda Saida'));
      await tester.pumpAndSettle();

      expect(find.text('SALVAR PARA A PEDRA?'), findsNothing);
      expect(saiuDireto, isTrue);
    });

    testWidgets('dispara telemetria exibir_modal ao abrir o guardiao', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalConfirmacaoSaida.mostrar(
                    context: context,
                    nomePico: 'Pico Telemetria',
                    cragId: 'crag_telemetria',
                    onSalvar: () {},
                    onSairSemSalvar: () {},
                  );
                },
                child: const Text('Abrir Guardião'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Guardião'));
      await tester.pumpAndSettle();

      expect(mockTelemetria.recordedEvents, contains('guardiao_saida'));
      final params = mockTelemetria.recordedParams['guardiao_saida']!;
      expect(params['id_croqui'], 'crag_telemetria');
      expect(params['acao'], 'exibir_modal');
      expect(params['origem'], 'guardiao_saida');
      expect(params['modo_acesso'], 'online');
    });

    testWidgets('dispara telemetria guardiao_salvar_offline ao salvar pelo modal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalConfirmacaoSaida.mostrar(
                    context: context,
                    nomePico: 'Pico Telemetria',
                    cragId: 'crag_telemetria',
                    onSalvar: () {},
                    onSairSemSalvar: () {},
                  );
                },
                child: const Text('Abrir Guardião'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Guardião'));
      await tester.pumpAndSettle();

      mockTelemetria.clear();
      await tester.tap(find.text('Salvar Offline'));
      await tester.pumpAndSettle();

      expect(mockTelemetria.recordedEvents, contains('guardiao_saida'));
      final params = mockTelemetria.recordedParams['guardiao_saida']!;
      expect(params['id_croqui'], 'crag_telemetria');
      expect(params['acao'], 'guardiao_salvar_offline');
      expect(params['origem'], 'guardiao_saida');
    });

    testWidgets('dispara telemetria guardiao_sair_sem_salvar ao fechar sem salvar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ModalConfirmacaoSaida.mostrar(
                    context: context,
                    nomePico: 'Pico Telemetria',
                    cragId: 'crag_telemetria',
                    onSalvar: () {},
                    onSairSemSalvar: () {},
                  );
                },
                child: const Text('Abrir Guardião'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Guardião'));
      await tester.pumpAndSettle();

      mockTelemetria.clear();
      await tester.tap(find.text('Sair sem Salvar'));
      await tester.pumpAndSettle();

      expect(mockTelemetria.recordedEvents, contains('guardiao_saida'));
      final params = mockTelemetria.recordedParams['guardiao_saida']!;
      expect(params['id_croqui'], 'crag_telemetria');
      expect(params['acao'], 'guardiao_sair_sem_salvar');
      expect(params['origem'], 'guardiao_saida');
    });
  });
}
