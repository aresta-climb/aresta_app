// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/navigation/servico_navegacao_deep_link.dart';
import 'package:frontend/navigation/gerenciador_deep_links.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/services/firebase/performance_telemetria.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';

/// Fake determinístico de [AppLinks] para testes de fronteira sem mocks.
class FakeAppLinks extends Fake implements AppLinks {
  Uri? linkInicial;
  final Stream<Uri> _fluxoLinks;

  FakeAppLinks(this._fluxoLinks);

  @override
  Future<Uri?> getInitialLink() async => linkInicial;

  @override
  Stream<Uri> get uriLinkStream => _fluxoLinks;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAppLinks fakeAppLinks;
  late StreamController<Uri> uriStreamController;
  late EditorDeCroqui editorDeCroqui;
  late DatasetRepository datasetRepo;
  late TreeNavigationController treeController;
  late DeepLinkNavigatorService navigatorService;
  late GerenciadorDeepLinks gerenciador;

  setUp(() {
    ServicoPerformance.resetarParaTestes();
    uriStreamController = StreamController<Uri>.broadcast();
    fakeAppLinks = FakeAppLinks(uriStreamController.stream);

    editorDeCroqui = EditorDeCroqui();
    datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
    treeController = TreeNavigationController();
    navigatorService = DeepLinkNavigatorService(
      datasetRepo: datasetRepo,
      treeController: treeController,
    );

    // Popula pico no repositório
    final pico = Pico()..nome = 'Pedra Grande';
    final croqui = Croqui()
      ..id = 'br_mg_igarape_pedra_grande'
      ..uid = 'pQ9mRt2Kx1Vw8L'
      ..picos.add(pico);
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
      appLinks: fakeAppLinks,
      navigatorService: navigatorService,
    );
  });

  tearDown(() {
    gerenciador.dispose();
    uriStreamController.close();
    ServicoPerformance.resetarParaTestes();
  });

  test('processa link inicial no Cold Start quando disponivel e registra cold_start_deep_link', () async {
    final initialUri = Uri.parse(
      'https://aresta.cc/pQ9mRt2Kx1Vw8L',
    );
    fakeAppLinks.linkInicial = initialUri;

    await gerenciador.inicializar();

    expect(treeController.currentNode, isA<PicoNode>());
    final picoNode = treeController.currentNode as PicoNode;
    expect(picoNode.cragId, equals('br_mg_igarape_pedra_grande'));
    expect(
      ServicoPerformance.instancia.tracesRegistradas
          .any((t) => t.nome == 'cold_start_deep_link'),
      isTrue,
    );
  });

  test('ignora Cold Start quando initialLink for nulo', () async {
    fakeAppLinks.linkInicial = null;

    await gerenciador.inicializar();

    expect(treeController.currentNode, isA<HomeNode>());
  });

  test('processa links recebidos no Warm Start via stream e registra warm_start_deep_link', () async {
    fakeAppLinks.linkInicial = null;

    await gerenciador.inicializar();
    expect(treeController.currentNode, isA<HomeNode>());

    // Dispara evento na stream
    final warmUri = Uri.parse(
      'https://aresta.cc/pQ9mRt2Kx1Vw8L',
    );
    uriStreamController.add(warmUri);

    // Aguarda processamento assíncrono
    await Future.delayed(const Duration(milliseconds: 50));

    expect(treeController.currentNode, isA<PicoNode>());
    expect(
      ServicoPerformance.instancia.tracesRegistradas
          .any((t) => t.nome == 'warm_start_deep_link'),
      isTrue,
    );
  });

  test('ignora disparo duplicado imediato da mesma URI entre Cold Start e stream ou no Warm Start', () async {
    final uri = Uri.parse('https://aresta.cc/pQ9mRt2Kx1Vw8L');
    fakeAppLinks.linkInicial = uri;

    await gerenciador.inicializar();
    expect(treeController.currentNode, isA<PicoNode>());

    // Volta para a Home para observar se o disparo duplicado da mesma URI navegaria novamente
    treeController.navigateTo(const HomeNode());
    expect(treeController.currentNode, isA<HomeNode>());

    // Emite a mesma URI imediatamente na stream (comportamento padrão do app_links no Android)
    uriStreamController.add(uri);
    await Future.delayed(const Duration(milliseconds: 50));

    // Deve ter ignorado a duplicata imediata, permanecendo na HomeNode
    expect(treeController.currentNode, isA<HomeNode>());
  });

  test(
    'registrarLinkInicialJaProcessado evita reprocessar o mesmo link inicial no inicializar() e na stream',
    () async {
      final uri = Uri.parse('https://aresta.cc/pQ9mRt2Kx1Vw8L');
      fakeAppLinks.linkInicial = uri;

      gerenciador.registrarLinkInicialJaProcessado(uri);
      await gerenciador.inicializar();

      // Permanece em HomeNode porque o link inicial já havia sido processado durante o Cold Start
      expect(treeController.currentNode, isA<HomeNode>());

      // Se a stream emitir o mesmo link logo em seguida, também deve ser ignorado
      uriStreamController.add(uri);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(treeController.currentNode, isA<HomeNode>());
    },
  );
}

