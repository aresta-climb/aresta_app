// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/navigation/deep_link_navigator_service.dart';
import 'package:frontend/navigation/gerenciador_deep_links.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';

class MockAppLinks extends Mock implements AppLinks {}

void main() {
  late MockAppLinks mockAppLinks;
  late StreamController<Uri> uriStreamController;
  late EditorDeCroqui editorDeCroqui;
  late DatasetRepository datasetRepo;
  late TreeNavigationController treeController;
  late DeepLinkNavigatorService navigatorService;
  late GerenciadorDeepLinks gerenciador;

  setUp(() {
    mockAppLinks = MockAppLinks();
    uriStreamController = StreamController<Uri>.broadcast();
    when(() => mockAppLinks.uriLinkStream)
        .thenAnswer((_) => uriStreamController.stream);

    editorDeCroqui = EditorDeCroqui();
    datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
    treeController = TreeNavigationController();
    navigatorService = DeepLinkNavigatorService(
      datasetRepo: datasetRepo,
      treeController: treeController,
    );

    // Popula pico no repositório
    final pico = Pico()..nome = 'Pedra Grande';
    final croqui = Croqui()..picos.add(pico);
    datasetRepo.activeDataset.value = TopoDataset(
      picosBaixados: [
        {
          'id': 'br_mg_igarape_pedra_grande',
          'data': {'pico': pico, 'croqui': croqui},
        }
      ],
      picosDisponiveis: [],
    );

    gerenciador = GerenciadorDeepLinks(
      appLinks: mockAppLinks,
      navigatorService: navigatorService,
    );
  });

  tearDown(() {
    gerenciador.dispose();
    uriStreamController.close();
  });

  test('processa link inicial no Cold Start quando disponivel', () async {
    final initialUri = Uri.parse(
      'https://app.arestaclimb.com/br_mg_igarape_pedra_grande',
    );
    when(() => mockAppLinks.getInitialLink())
        .thenAnswer((_) async => initialUri);

    await gerenciador.inicializar();

    expect(treeController.currentNode, isA<PicoNode>());
    final picoNode = treeController.currentNode as PicoNode;
    expect(picoNode.cragId, equals('br_mg_igarape_pedra_grande'));
  });

  test('ignora Cold Start quando initialLink for nulo', () async {
    when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

    await gerenciador.inicializar();

    expect(treeController.currentNode, isA<HomeNode>());
  });

  test('processa links recebidos no Warm Start via stream', () async {
    when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

    await gerenciador.inicializar();
    expect(treeController.currentNode, isA<HomeNode>());

    // Dispara evento na stream
    final warmUri = Uri.parse(
      'https://app.arestaclimb.com/br_mg_igarape_pedra_grande',
    );
    uriStreamController.add(warmUri);

    // Aguarda processamento assíncrono
    await Future.delayed(const Duration(milliseconds: 50));

    expect(treeController.currentNode, isA<PicoNode>());
  });
}
