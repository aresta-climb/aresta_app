// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/navigation/deep_link_navigator_service.dart';
import 'package:frontend/navigation/navigation_tree.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  late EditorDeCroqui editorDeCroqui;
  late DatasetRepository datasetRepo;
  late TreeNavigationController treeController;
  late DeepLinkNavigatorService service;
  late MockTelemetryService mockTelemetry;

  late Pico picoTeste;
  late Croqui croquiTeste;
  late Setor setorDireto;
  late Grupo grupoEstacionamento;
  late Setor setorNoGrupo;
  late Escalada viaNoSetor;
  late Escalada viaNoGrupoSetor;

  setUp(() {
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
    editorDeCroqui = EditorDeCroqui();
    datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
    treeController = TreeNavigationController();
    service = DeepLinkNavigatorService(
      datasetRepo: datasetRepo,
      treeController: treeController,
    );

    // Constrói a árvore de dados de teste:
    // Pico: "Pedra Grande de Igarapé" (id: "br_mg_igarape_pedra_grande")
    //   - Setor direto: "Savassinha"
    //       - Via: "Teto da Savassinha"
    //   - Grupo: "Grupo Estacionamento"
    //       - Setor filho: "Setor do Bloco"
    //           - Via: "Via do Bloco"
    croquiTeste = Croqui()..id = 'br_mg_igarape_pedra_grande';
    picoTeste = Pico()..nome = 'Pedra Grande de Igarapé';

    setorDireto = Setor()..nome = 'Savassinha';
    viaNoSetor = Escalada()
      ..viaEsportiva = (ViaEsportiva()..nome = 'Teto da Savassinha');
    setorDireto.escaladas.add(viaNoSetor);

    picoTeste.setoresOuGrupos.add(
      SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorDireto),
    );

    grupoEstacionamento = Grupo()..nome = 'Grupo Estacionamento';
    setorNoGrupo = Setor()..nome = 'Setor do Bloco';
    viaNoGrupoSetor = Escalada()
      ..boulder = (Boulder()..nome = 'Via do Bloco');
    setorNoGrupo.escaladas.add(viaNoGrupoSetor);

    grupoEstacionamento.setores.add(
      ArquivoSetor()..conteudo = setorNoGrupo,
    );

    picoTeste.setoresOuGrupos.add(
      SetorOuGrupo()..grupo = (ArquivoGrupo()..conteudo = grupoEstacionamento),
    );

    croquiTeste.picos.add(picoTeste);

    // Popula o repositório como pico baixado em cache local
    datasetRepo.activeDataset.value = TopoDataset(
      picosBaixados: [
        {
          'id': 'br_mg_igarape_pedra_grande',
          'data': {'pico': picoTeste, 'croqui': croquiTeste},
        },
      ],
      picosDisponiveis: [],
    );
  });

  group('DeepLinkNavigatorService - Reconstrução de Linhagem', () {
    test('navega para PicoNode a partir de link nivel 1', () async {
      final sucesso = await service.processarLink(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<PicoNode>());
      final picoNode = treeController.currentNode as PicoNode;
      expect(picoNode.cragId, equals('br_mg_igarape_pedra_grande'));
      expect(picoNode.parent, isA<HomeNode>());
    });

    test('navega para SetorNode direto a partir de link nivel 2', () async {
      final sucesso = await service.processarLink(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/savassinha',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<SetorNode>());
      final setorNode = treeController.currentNode as SetorNode;
      expect(setorNode.setorNome, equals('Savassinha'));
      expect(setorNode.cragId, equals('br_mg_igarape_pedra_grande'));

      // Verifica linhagem ascendente: Setor -> Pico -> Home
      expect(setorNode.parent, isA<PicoNode>());
      expect(setorNode.parent!.parent, isA<HomeNode>());
    });

    test('navega para GrupoNode a partir de link nivel 2', () async {
      final sucesso = await service.processarLink(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/grupo_estacionamento',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<GrupoNode>());
      final grupoNode = treeController.currentNode as GrupoNode;
      expect(grupoNode.grupoNome, equals('Grupo Estacionamento'));
      expect(grupoNode.parent, isA<PicoNode>());
      expect(grupoNode.parent!.parent, isA<HomeNode>());
    });

    test('navega para SetorNode dentro de Grupo a partir de link nivel 3', () async {
      final sucesso = await service.processarLink(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/grupo_estacionamento/setor_do_bloco',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<SetorNode>());
      final setorNode = treeController.currentNode as SetorNode;
      expect(setorNode.setorNome, equals('Setor do Bloco'));
      expect(setorNode.grupoNome, equals('Grupo Estacionamento'));

      // Linhagem: Setor -> Grupo -> Pico -> Home
      expect(setorNode.parent, isA<GrupoNode>());
      final grupoNode = setorNode.parent as GrupoNode;
      expect(grupoNode.grupoNome, equals('Grupo Estacionamento'));
      expect(grupoNode.parent, isA<PicoNode>());
      expect(grupoNode.parent!.parent, isA<HomeNode>());
    });

    test('navega para ViaNode dentro de Setor direto a partir de link nivel 3', () async {
      final sucesso = await service.processarLink(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/savassinha/teto_da_savassinha',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<ViaNode>());
      final viaNode = treeController.currentNode as ViaNode;
      expect(viaNode.escaladaNome, equals('Teto da Savassinha'));
      expect(viaNode.setorNome, equals('Savassinha'));

      // Linhagem: Via -> Setor -> Pico -> Home
      expect(viaNode.parent, isA<SetorNode>());
      expect(viaNode.parent!.parent, isA<PicoNode>());
      expect(viaNode.parent!.parent!.parent, isA<HomeNode>());
    });

    test('navega para ViaNode dentro de Setor em Grupo a partir de link nivel 4', () async {
      final sucesso = await service.processarLink(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/grupo_estacionamento/setor_do_bloco/via_do_bloco',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<ViaNode>());
      final viaNode = treeController.currentNode as ViaNode;
      expect(viaNode.escaladaNome, equals('Via do Bloco'));
      expect(viaNode.setorNome, equals('Setor do Bloco'));
      expect(viaNode.grupoNome, equals('Grupo Estacionamento'));

      // Linhagem completa: Via -> Setor -> Grupo -> Pico -> Home
      expect(viaNode.parent, isA<SetorNode>());
      final setorNode = viaNode.parent as SetorNode;
      expect(setorNode.parent, isA<GrupoNode>());
      final grupoNode = setorNode.parent as GrupoNode;
      expect(grupoNode.parent, isA<PicoNode>());
      expect(grupoNode.parent!.parent, isA<HomeNode>());
    });

    test('o botao voltar desempilha retroativamente toda a linhagem montada pelo deep link', () async {
      await service.processarLink(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/grupo_estacionamento/setor_do_bloco/via_do_bloco',
      );

      expect(treeController.currentNode, isA<ViaNode>());

      // Voltar 1: Setor
      expect(treeController.goBack(), isTrue);
      expect(treeController.currentNode, isA<SetorNode>());

      // Voltar 2: Grupo
      expect(treeController.goBack(), isTrue);
      expect(treeController.currentNode, isA<GrupoNode>());

      // Voltar 3: Pico
      expect(treeController.goBack(), isTrue);
      expect(treeController.currentNode, isA<PicoNode>());

      // Voltar 4: Home
      expect(treeController.goBack(), isTrue);
      expect(treeController.currentNode, isA<HomeNode>());
    });
  });

  group('DeepLinkNavigatorService - Resolução de Dados Online/Offline', () {
    test('abre croqui atraves de sessao online se nao estiver baixado localmente', () async {
      // Adiciona o croqui na sessão online simulando que foi pré-carregado
      datasetRepo.gerenciadorSessaoOnline.registrarCroquiOnline(
        'br_mg_cipov2',
        Croqui()..picos.add(Pico()..nome = 'Serra do Cipó'),
      );

      final sucesso = await service.processarLink(
        'https://app.arestaclimb.com/br_mg_cipov2',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<PicoNode>());
      final picoNode = treeController.currentNode as PicoNode;
      expect(picoNode.cragId, equals('br_mg_cipov2'));
    });

    test('retorna false e emite aviso se o croqui nao existir nem local nem online', () async {
      String? mensagemErro;
      service.onMensagemAviso = (msg) => mensagemErro = msg;

      final sucesso = await service.processarLink(
        'https://app.arestaclimb.com/pico_inexistente',
      );

      expect(sucesso, isFalse);
      expect(mensagemErro, isNotNull);
      expect(mensagemErro, contains('Não foi possível abrir o croqui'));
    });

    test('retorna false se a URL for invalida ou de outro dominio', () async {
      final sucesso = await service.processarLink('https://outrodominio.com/teste');
      expect(sucesso, isFalse);
    });
  });

  group('DeepLinkNavigatorService - Telemetria', () {
    test('dispara logDeepLinkAberto com sucesso, destino via, cold_start e parametros UTM', () async {
      final sucesso = await service.processarLink(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/grupo_estacionamento/setor_do_bloco/via_do_bloco?utm_source=placa_pedra&utm_medium=qrcode',
        tipoStart: 'cold_start',
      );

      expect(sucesso, isTrue);
      expect(mockTelemetry.recordedEvents, contains('deep_link_aberto'));
      final params = mockTelemetry.recordedParams['deep_link_aberto']!;
      expect(params['id_croqui'], equals('br_mg_igarape_pedra_grande'));
      expect(params['destino'], equals('via'));
      expect(params['sucesso'], equals('true'));
      expect(params['tipo_start'], equals('cold_start'));
      expect(params['utm_source'], equals('placa_pedra'));
      expect(params['utm_medium'], equals('qrcode'));
    });

    test('dispara logDeepLinkAberto com falha e motivo do erro quando croqui nao for encontrado', () async {
      final sucesso = await service.processarLink(
        'https://app.arestaclimb.com/pico_inexistente?utm_source=teste',
        tipoStart: 'warm_start',
      );

      expect(sucesso, isFalse);
      expect(mockTelemetry.recordedEvents, contains('deep_link_aberto'));
      final params = mockTelemetry.recordedParams['deep_link_aberto']!;
      expect(params['id_croqui'], equals('pico_inexistente'));
      expect(params['sucesso'], equals('false'));
      expect(params['tipo_start'], equals('warm_start'));
      expect(params['motivo_erro'], isNotNull);
      expect(params['utm_source'], equals('teste'));
    });
  });
}
