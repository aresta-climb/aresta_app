// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/main.dart';
import 'package:frontend/navigation/arvore/pico_nodes.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/widgets/linha_localizacao_setor.dart';

import '../mocks/mock_telemetry_service.dart';

void main() {
  late MockTelemetryService mockTelemetry;

  setUp(() {
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
  });

  Widget criarWidgetDeTeste({
    required Widget child,
    TreeNavigationController? treeController,
  }) {
    final datasetRepo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
    final syncService = SyncService(datasetRepository: datasetRepo);
    final controller = treeController ??
        TreeNavigationController(
          estadoInicial: const ArvoreNavegacao(
            noAtual: PicoNode(cragId: 'pico1', parent: HomeNode()),
          ),
        );

    return MaterialApp(
      theme: construirTemaEscuro(),
      home: TreeNavigationWrapper(
        key: TreeNavigationWrapper.navKey,
        datasetRepo: datasetRepo,
        syncService: syncService,
        treeController: controller,
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets(
    'renderiza apenas o nome do setor e botão Ver no croqui quando grupo é nulo',
    (tester) async {
      final setor = Setor(nome: 'Falésia Central');
      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Via das Sombras');

      await tester.pumpWidget(
        criarWidgetDeTeste(
          child: LinhaLocalizacaoSetor(
            cragId: 'pico1',
            setor: setor,
            escalada: escalada,
          ),
        ),
      );

      expect(find.textContaining('Falésia Central'), findsOneWidget);
      expect(find.text('Ver no croqui'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    },
  );

  testWidgets(
    'renderiza hierarquia completa (Grupo > Setor) quando grupo estiver presente',
    (tester) async {
      final grupo = Grupo(nome: 'Face Norte');
      final setor = Setor(nome: 'Falésia Superior');
      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Tragédia');

      await tester.pumpWidget(
        criarWidgetDeTeste(
          child: LinhaLocalizacaoSetor(
            cragId: 'pico1',
            grupo: grupo,
            setor: setor,
            escalada: escalada,
          ),
        ),
      );

      expect(find.textContaining('Face Norte > Falésia Superior'), findsOneWidget);
      expect(find.text('Ver no croqui'), findsOneWidget);
    },
  );

  testWidgets(
    'executa callback customizado onAbrirSetor se fornecido ao ser tocado',
    (tester) async {
      bool clicou = false;
      final setor = Setor(nome: 'Setor do Bosque');

      await tester.pumpWidget(
        criarWidgetDeTeste(
          child: LinhaLocalizacaoSetor(
            cragId: 'pico1',
            setor: setor,
            onAbrirSetor: () {
              clicou = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(LinhaLocalizacaoSetor));
      await tester.pumpAndSettle();

      expect(clicou, isTrue);
    },
  );

  testWidgets(
    'navega para SetorNode e registra telemetria quando tocado sem callback customizado',
    (tester) async {
      final grupo = Grupo(nome: 'Setor Principal');
      final setor = Setor(nome: 'Parede da Esquerda');
      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Diedro Amarelo');

      final controller = TreeNavigationController(
        estadoInicial: const ArvoreNavegacao(
          noAtual: PicoNode(cragId: 'pico1', parent: HomeNode()),
        ),
      );

      await tester.pumpWidget(
        criarWidgetDeTeste(
          treeController: controller,
          child: LinhaLocalizacaoSetor(
            cragId: 'pico1',
            grupo: grupo,
            setor: setor,
            escalada: escalada,
          ),
        ),
      );

      await tester.tap(find.text('Ver no croqui'));
      await tester.pumpAndSettle();

      expect(controller.currentNode, isA<SetorNode>());
      final node = controller.currentNode as SetorNode;
      expect(node.setorNome, 'Parede da Esquerda');
      expect(node.grupoNome, 'Setor Principal');
      expect(node.cragId, 'pico1');
      expect(node.scrollToEscaladaNome, 'Diedro Amarelo');

      expect(mockTelemetry.recordedEvents.contains('acao_escalada'), isTrue);
    },
  );
}
