// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/navigation/page_listenable_builder.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/navigation/navigation_tree.dart';

// Mock observer para testar se AppNav.back() foi chamado
class MockNavigatorObserver extends NavigatorObserver {
  bool hasPopped = false;

  @override
  void didPop(Route route, Route? previousRoute) {
    hasPopped = true;
    super.didPop(route, previousRoute);
  }
}

void main() {
  group('PageListenableBuilder Hot-Reload Tests', () {
    late DatasetRepository repo;
    late EditorDeCroqui editor;

    setUp(() {
      editor = EditorDeCroqui();
      repo = DatasetRepository(editorDeCroqui: editor);
    });

    testWidgets(
      'Deve injetar o Pico na UI e recarregar quando o dataset mudar',
      (WidgetTester tester) async {
        final picoV1 = Pico()..nome = 'Pico Versão 1';
        final picoV2 = Pico()..nome = 'Pico Versão 2';
        final croqui = Croqui();

        repo.activeDataset.value = ConjuntoDadosCroqui(
          picosBaixados: [
            {
              'id': 'pico_1',
              'data': {'pico': picoV1, 'croqui': croqui},
            },
          ],
          picosDisponiveis: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PageListenableBuilder(
              datasetRepo: repo,
              cragId: 'pico_1',
              builder: (context, pico, croqui, setor, grupo, escalada) {
                return Text(pico.nome);
              },
            ),
          ),
        );

        await tester.pump();

        // Verifica se a Versão 1 foi renderizada
        expect(find.text('Pico Versão 1'), findsOneWidget);
        expect(find.text('Pico Versão 2'), findsNothing);

        // Simula um Hot-Reload (Novo download do _checkForUpdates)
        repo.activeDataset.value = ConjuntoDadosCroqui(
          picosBaixados: [
            {
              'id': 'pico_1',
              'data': {'pico': picoV2, 'croqui': croqui},
            },
          ],
          picosDisponiveis: [],
        );

        await tester.pump();

        // Verifica se a UI se atualizou sozinha para a Versão 2
        expect(find.text('Pico Versão 1'), findsNothing);
        expect(find.text('Pico Versão 2'), findsOneWidget);
      },
    );

    testWidgets(
      'Deve executar AppNav.back() se o Setor for deletado do Dataset',
      (WidgetTester tester) async {
        final mockObserver = MockNavigatorObserver();

        final setorV1 = Setor()..nome = 'Setor de Teste';
        final arquivoSetor = ArquivoSetor()..conteudo = setorV1;

        final picoV1 = Pico()..nome = 'Pico V1';
        picoV1.setoresOuGrupos.add(SetorOuGrupo()..setor = arquivoSetor);

        final croqui = Croqui();

        repo.activeDataset.value = ConjuntoDadosCroqui(
          picosBaixados: [
            {
              'id': 'pico_1',
              'data': {'pico': picoV1, 'croqui': croqui},
            },
          ],
          picosDisponiveis: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            navigatorObservers: [mockObserver],
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PageListenableBuilder(
                            datasetRepo: repo,
                            cragId: 'pico_1',
                            setorNome: 'Setor de Teste',
                            builder:
                                (
                                  context,
                                  pico,
                                  croqui,
                                  setor,
                                  grupo,
                                  escalada,
                                ) {
                                  return Scaffold(
                                    body: Text('View do ${setor?.nome}'),
                                  );
                                },
                          ),
                        ),
                      );
                    },
                    child: const Text('Go'),
                  ),
                );
              },
            ),
          ),
        );

        // Entra na tela
        await tester.tap(find.text('Go'));
        await tester.pumpAndSettle();

        // Verifica que o Setor de Teste carregou
        expect(find.text('View do Setor de Teste'), findsOneWidget);
        expect(mockObserver.hasPopped, isFalse);

        // Hot-Reload: Um novo Pico entra, mas o "Setor de Teste" foi deletado no servidor!
        final picoV2 = Pico()..nome = 'Pico V2 Sem Setores';
        repo.activeDataset.value = ConjuntoDadosCroqui(
          picosBaixados: [
            {
              'id': 'pico_1',
              'data': {'pico': picoV2, 'croqui': croqui},
            },
          ],
          picosDisponiveis: [],
        );

        // Pump para processar o builder
        await tester.pump();

        // O PageListenableBuilder deve agendar um pop
        await tester.pumpAndSettle();

        // Verifica se ele fez pop de volta para a primeira tela
        expect(mockObserver.hasPopped, isTrue);
        expect(find.text('Go'), findsOneWidget);
      },
    );

    testWidgets('Deve encontrar Setor aninhado dentro de um Grupo', (
      WidgetTester tester,
    ) async {
      final mockObserver = MockNavigatorObserver();

      final subSetor = Setor()..nome = 'Sub-setor Teste';
      final arquivoSubSetor = ArquivoSetor()..conteudo = subSetor;

      final grupo = Grupo()..nome = 'Grupo Teste';
      grupo.setores.add(arquivoSubSetor);

      final arquivoGrupo = ArquivoGrupo()..conteudo = grupo;

      final pico = Pico()..nome = 'Pico Teste';
      pico.setoresOuGrupos.add(SetorOuGrupo()..grupo = arquivoGrupo);

      final croqui = Croqui();

      repo.activeDataset.value = ConjuntoDadosCroqui(
        picosBaixados: [
          {
            'id': 'pico_1',
            'data': {'pico': pico, 'croqui': croqui},
          },
        ],
        picosDisponiveis: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [mockObserver],
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PageListenableBuilder(
                          datasetRepo: repo,
                          cragId: 'pico_1',
                          setorNome: 'Sub-setor Teste',
                          builder:
                              (context, pico, croqui, setor, grupo, escalada) {
                                return Scaffold(
                                  body: Text('View do ${setor?.nome}'),
                                );
                              },
                        ),
                      ),
                    );
                  },
                  child: const Text('Go'),
                ),
              );
            },
          ),
        ),
      );

      // Entra na tela
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      // Verifica que o Sub-setor de Teste carregou e não fez pop
      expect(find.text('View do Sub-setor Teste'), findsOneWidget);
      expect(mockObserver.hasPopped, isFalse);
    });
    testWidgets('Deve exibir o popup bloqueante se houver recarga pendente', (
      WidgetTester tester,
    ) async {
      final picoV1 = Pico()..nome = 'Pico Teste';
      final croqui = Croqui();

      repo.activeDataset.value = ConjuntoDadosCroqui(
        picosBaixados: [
          {
            'id': 'pico_1',
            'data': {'pico': picoV1, 'croqui': croqui},
            'isDownloaded': true,
          },
        ],
        picosDisponiveis: [],
      );

      final syncService = SyncService(datasetRepository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: TreeNavigationWrapper(
            datasetRepo: repo,
            syncService: syncService,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      final wrapperState =
          tester.state<State<TreeNavigationWrapper>>(
                find.byType(TreeNavigationWrapper),
              )
              as dynamic;
      final treeController = wrapperState.treeController;

      treeController.navigateTo(
        PicoNode(cragId: 'pico_1', parent: const HomeNode()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Croqui Atualizado'), findsNothing);

      // Simula fim do download atômico
      syncService.recarga_pendente_pico_id.value = 'pico_1';
      await tester.pump(const Duration(milliseconds: 500));

      // O popup bloqueante deve aparecer
      expect(find.text('Croqui Atualizado'), findsOneWidget);
      expect(find.text('RECARREGAR'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsNWidgets(2));
      expect(
        find.text(
          'Uma nova versão deste croqui foi instalada em segundo plano. Recarregue a página para acessar as novidades.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'Não deve exibir o popup bloqueante de recarga pendente se estiver em modo experimental',
      (WidgetTester tester) async {
        final picoV1 = Pico()..nome = 'Pico Teste';
        final croqui = Croqui();

        editor.isExperimentalMode.value = true;
        repo.activeDataset.value = TopoDataset(
          downloadedPicos: [
            {
              'id': 'pico_1',
              'data': {'pico': picoV1, 'croqui': croqui},
              'isDownloaded': true,
            },
          ],
          availablePicos: [],
        );

        final syncService = SyncService(datasetRepository: repo);

        await tester.pumpWidget(
          MaterialApp(
            home: TreeNavigationWrapper(
              datasetRepo: repo,
              syncService: syncService,
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        final wrapperState =
            tester.state<State<TreeNavigationWrapper>>(
                  find.byType(TreeNavigationWrapper),
                )
                as dynamic;
        final treeController = wrapperState.treeController;

        treeController.navigateTo(
          PicoNode(cragId: 'pico_1', parent: const HomeNode()),
        );
        await tester.pump(const Duration(milliseconds: 500));

        // Mesmo que recarga_pendente_pico_id seja modificado, no modo experimental o popup não deve ser renderizado
        syncService.recarga_pendente_pico_id.value = 'pico_1';
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Croqui Atualizado'), findsNothing);
        expect(find.text('RECARREGAR'), findsNothing);
      },
    );
  });
}
