// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/openapi/generated/dart/catalogo.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/servico_navegacao_deep_link.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/performance_telemetria.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/widgets/bottom_sheets/modal_croqui_sem_conexao.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import '../mocks/mock_telemetria.dart';

class _FakeUrlLauncher extends UrlLauncherPlatform {
  String? ultimaUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    ultimaUrl = url;
    return true;
  }
}

class _FakePathProvider extends PathProviderPlatform {
  final String caminhoBase;
  _FakePathProvider(this.caminhoBase);

  @override
  Future<String?> getApplicationDocumentsPath() async => caminhoBase;

  @override
  Future<String?> getTemporaryPath() async => '$caminhoBase/temp';
}

void main() {
  sqfliteFfiInit();

  late Directory dirTemp;
  late EditorDeCroqui editorDeCroqui;
  late RepositorioCatalogo repositorioCatalogo;
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

  const String uidCroqui = 'pQ9mRt2Kx1Vw8L';
  const String uidSetorDireto = 'sQ7YgEG6ONsPXt'; // UID da placa bloco_democracia
  const String uidGrupo = 'cqT5nqQ4pvPub7'; // UID da placa grupo_sherpa
  const String uidSetorNoGrupo = 'ZTPu3KeCXIJisV'; // UID da placa setor_familia_i
  const String uidViaNoSetor = 'v1siJek3FiG3aB';
  const String uidViaNoGrupoSetor = 'v2siJek3FiG3aB';

  setUp(() {
    dirTemp = Directory.systemTemp.createTempSync('servico_deep_link_test_');
    PathProviderPlatform.instance = _FakePathProvider(dirTemp.path);

    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
    editorDeCroqui = EditorDeCroqui();
    repositorioCatalogo = RepositorioCatalogo(
      provedorCaminhoBanco: () async => '${dirTemp.path}/catalogo.db',
      fabricaBanco: databaseFactoryFfiNoIsolate,
    );
    datasetRepo = DatasetRepository(
      editorDeCroqui: editorDeCroqui,
      repositorioCatalogo: repositorioCatalogo,
    );
    treeController = TreeNavigationController();
    service = DeepLinkNavigatorService(
      datasetRepo: datasetRepo,
      treeController: treeController,
    );

    croquiTeste = Croqui()
      ..id = 'br_mg_igarape_pedra_grande'
      ..uid = uidCroqui;
    picoTeste = Pico()..nome = 'Pedra Grande de Igarapé';

    setorDireto = Setor()
      ..nome = 'Bloco Democracia'
      ..uid = uidSetorDireto
      ..mapas.add(
        Mapa()
          ..caminhoImagemMapa = 'mapas/democracia.webp'
          ..larguraMapa = 1200
          ..alturaMapa = 800
          ..referencias.add(
            Mapa_Referencia()
              ..alvoUid = uidViaNoSetor
              ..pontosUids.add('pt_via_1'),
          ),
      );
    viaNoSetor = Escalada()
      ..uid = uidViaNoSetor
      ..viaEsportiva = (ViaEsportiva()..nome = 'Teto da Savassinha');
    setorDireto.escaladas.add(viaNoSetor);

    picoTeste.setoresOuGrupos.add(
      SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorDireto),
    );

    grupoEstacionamento = Grupo()
      ..nome = 'Grupo Sherpa'
      ..uid = uidGrupo;
    setorNoGrupo = Setor()
      ..nome = 'Setor Família I'
      ..uid = uidSetorNoGrupo;
    viaNoGrupoSetor = Escalada()
      ..uid = uidViaNoGrupoSetor
      ..boulder = (Boulder()..nome = 'Via do Bloco');
    setorNoGrupo.escaladas.add(viaNoGrupoSetor);

    grupoEstacionamento.setores.add(
      ArquivoSetor()..conteudo = setorNoGrupo,
    );

    picoTeste.setoresOuGrupos.add(
      SetorOuGrupo()..grupo = (ArquivoGrupo()..conteudo = grupoEstacionamento),
    );

    croquiTeste.picos.add(picoTeste);

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

  tearDown(() async {
    SyncService.baseUrlOverride = null;
    await repositorioCatalogo.fechar();
    if (dirTemp.existsSync()) {
      try {
        dirTemp.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('DeepLinkNavigatorService - Reconstrução de Linhagem por UID', () {
    test('navega para PicoNode a partir de link https://aresta.cc/<croqui_uid>', () async {
      final sucesso = await service.processarLink(
        'https://aresta.cc/$uidCroqui',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<PicoNode>());
      final picoNode = treeController.currentNode as PicoNode;
      expect(picoNode.cragId, equals('br_mg_igarape_pedra_grande'));
      expect(picoNode.parent, isA<HomeNode>());
    });

    test('navega para SetorNode direto a partir de link https://aresta.cc/<setor_uid>', () async {
      final sucesso = await service.processarLink(
        'https://aresta.cc/$uidSetorDireto',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<SetorNode>());
      final setorNode = treeController.currentNode as SetorNode;
      expect(setorNode.setorNome, equals('Bloco Democracia'));
      expect(setorNode.cragId, equals('br_mg_igarape_pedra_grande'));
      expect(setorNode.parent, isA<PicoNode>());
      expect(setorNode.parent!.parent, isA<HomeNode>());
    });

    test('navega para GrupoNode a partir de link https://aresta.cc/<grupo_uid>', () async {
      final sucesso = await service.processarLink(
        'https://aresta.cc/$uidGrupo',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<GrupoNode>());
      final grupoNode = treeController.currentNode as GrupoNode;
      expect(grupoNode.grupoNome, equals('Grupo Sherpa'));
      expect(grupoNode.parent, isA<PicoNode>());
      expect(grupoNode.parent!.parent, isA<HomeNode>());
    });

    test('navega para SetorNode dentro de Grupo a partir de link https://aresta.cc/<setor_uid>', () async {
      final sucesso = await service.processarLink(
        'https://aresta.cc/$uidSetorNoGrupo',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<SetorNode>());
      final setorNode = treeController.currentNode as SetorNode;
      expect(setorNode.setorNome, equals('Setor Família I'));
      expect(setorNode.grupoNome, equals('Grupo Sherpa'));
      expect(setorNode.parent, isA<GrupoNode>());
      expect(setorNode.parent!.parent, isA<PicoNode>());
      expect(setorNode.parent!.parent!.parent, isA<HomeNode>());
    });

    test('navega para ViaNode dentro de Setor em Grupo e desempilha toda a linhagem no botão voltar', () async {
      final sucesso = await service.processarLink(
        'https://aresta.cc/$uidViaNoGrupoSetor',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<ViaNode>());
      final viaNode = treeController.currentNode as ViaNode;
      expect(viaNode.escaladaNome, equals('Via do Bloco'));
      expect(viaNode.setorNome, equals('Setor Família I'));
      expect(viaNode.grupoNome, equals('Grupo Sherpa'));

      expect(treeController.goBack(), isTrue);
      expect(treeController.currentNode, isA<SetorNode>());

      expect(treeController.goBack(), isTrue);
      expect(treeController.currentNode, isA<GrupoNode>());

      expect(treeController.goBack(), isTrue);
      expect(treeController.currentNode, isA<PicoNode>());

      expect(treeController.goBack(), isTrue);
      expect(treeController.currentNode, isA<HomeNode>());
    });
  });

  group('DeepLinkNavigatorService - Modo Mapa (/m/, /sm/, /qm/) e Placas Legadas', () {
    test('abre MapasCarrosselNode focado na via ao processar https://aresta.cc/sm/<via_uid>', () async {
      final sucesso = await service.processarLink(
        'https://aresta.cc/sm/$uidViaNoSetor',
        tipoStart: 'warm_start',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<MapasCarrosselNode>());
      final carrosselNode = treeController.currentNode as MapasCarrosselNode;
      expect(carrosselNode.parent, isA<ViaNode>());
      expect(carrosselNode.mapas.first.initialSelectedId, equals('pt_via_1'));

      final params = mockTelemetry.recordedParams['deep_link_aberto']!;
      expect(params['id_croqui'], equals('br_mg_igarape_pedra_grande'));
      expect(params['destino'], equals('via'));
      expect(params['origem_link'], equals('compartilhamento'));
      expect(params['abrir_mapa'], equals('true'));
      expect(params['sucesso'], equals('true'));
    });

    test('resolve placa física legada de app.arestaclimb.com mapeando para o UID correspondente', () async {
      final sucesso = await service.processarLink(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/bloco_democracia?utm_source=setor_igarameca&utm_medium=qrcode',
        tipoStart: 'cold_start',
      );

      expect(sucesso, isTrue);
      expect(treeController.currentNode, isA<SetorNode>());
      final setorNode = treeController.currentNode as SetorNode;
      expect(setorNode.setorNome, equals('Bloco Democracia'));

      final params = mockTelemetry.recordedParams['deep_link_aberto']!;
      expect(params['id_croqui'], equals('br_mg_igarape_pedra_grande'));
      expect(params['destino'], equals('setor'));
      expect(params['origem_link'], equals('qrcode'));
      expect(params['utm_source'], equals('setor_igarameca'));
      expect(params['utm_medium'], equals('qrcode'));
    });

    test('retorna false se a URL for inválida, de outro domínio ou rota legada não cadastrada', () async {
      expect(
        await service.processarLink('https://outrodominio.com/teste'),
        isFalse,
      );
      expect(
        await service.processarLink(
          'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/rota_desconhecida',
        ),
        isFalse,
      );
    });
  });

  group('DeepLinkNavigatorService - Erros, Avisos e Telemetria', () {
    test('emite aviso via onMensagemAviso e telemetria de erro quando o UID não for encontrado', () async {
      String? mensagemEmitida;
      service.onMensagemAviso = (msg) => mensagemEmitida = msg;

      final sucesso = await service.processarLink(
        'https://aresta.cc/q/z9zzZzZzZzZzZz?utm_source=placa_danificada',
        tipoStart: 'warm_start',
      );

      expect(sucesso, isFalse);
      expect(mensagemEmitida, contains('z9zzZzZzZzZzZz'));
      expect(mockTelemetry.recordedEvents, contains('deep_link_aberto'));
      final params = mockTelemetry.recordedParams['deep_link_aberto']!;
      expect(params['id_croqui'], equals('z9zzZzZzZzZzZz'));
      expect(params['sucesso'], equals('false'));
      expect(params['origem_link'], equals('qrcode'));
      expect(params['abrir_mapa'], equals('false'));
      expect(params['motivo_erro'], equals('uid_nao_encontrado_no_acervo'));
      expect(params['utm_source'], equals('placa_danificada'));
    });

    testWidgets('exibe SnackBar quando onMensagemAviso é nulo e context montado é fornecido', (tester) async {
      BuildContext? contextoCapturado;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                contextoCapturado = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final sucesso = await service.processarLink(
        'https://aresta.cc/z9zzZzZzZzZzZz',
        context: contextoCapturado,
      );
      await tester.pump();

      expect(sucesso, isFalse);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('z9zzZzZzZzZzZz'), findsOneWidget);
    });

    test('aciona onCroquiSemConexao e registra telemetria croqui_offline_sem_conexao quando o croqui do UID não está baixado e o dispositivo está offline', () async {
      await repositorioCatalogo.aplicarDelta(
        const RespostaSyncCatalogo(
          acao: 'apply_delta',
          versaoDestino: 'v_itacoa',
          upserts: UpsertsSyncCatalogo(
            croquis: [
              CatalogoCroqui(
                croquiUid: 'uidItacoa99',
                idSlug: 'br_rj_itacoa',
                nome: 'Costão de Itacoatiara',
                cidade: 'Niterói',
                estado: 'RJ',
              ),
            ],
            entidades: [
              CatalogoEntidade(
                uid: 'uidViaChamine1',
                tipo: 'escalada',
                croquiUid: 'uidItacoa99',
                nome: 'Chaminé Stop',
                escaladaGrau: '4º V',
              ),
            ],
          ),
        ),
      );

      final socketFechado = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final portaFechada = socketFechado.port;
      await socketFechado.close();
      SyncService.baseUrlOverride = 'http://127.0.0.1:$portaFechada';

      ItemCatalogoBusca? itemRecebido;
      String? avisoInesperado;
      service.onMensagemAviso = (msg) => avisoInesperado = msg;
      service.onCroquiSemConexao = (item, tentarNovamente) {
        itemRecebido = item;
      };

      ServicoPerformance.resetarParaTestes();
      ServicoPerformance.instancia.iniciarCronometroColdStart();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final sucesso = await service.processarLink(
        'https://aresta.cc/uidViaChamine1',
        tipoStart: 'cold_start',
      );

      expect(sucesso, isFalse);
      expect(avisoInesperado, isNull);
      expect(itemRecebido, isNotNull);
      expect(itemRecebido!.nome, equals('Chaminé Stop'));
      expect(itemRecebido!.picoNome, equals('Costão de Itacoatiara'));

      final params = mockTelemetry.recordedParams['deep_link_aberto']!;
      expect(params['id_croqui'], equals('br_rj_itacoa'));
      expect(params['destino'], equals('via'));
      expect(params['sucesso'], equals('false'));
      expect(params['motivo_erro'], equals('croqui_offline_sem_conexao'));
    });

    testWidgets('exibe ModalCroquiSemConexao quando context montado é fornecido e navega ao reconectar e tocar em Tentar novamente', (tester) async {
      await tester.runAsync(() async {
        await repositorioCatalogo.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoDestino: 'v_itacoa',
            upserts: UpsertsSyncCatalogo(
              croquis: [
                CatalogoCroqui(
                  croquiUid: 'uidItacoa99',
                  idSlug: 'br_rj_itacoa',
                  nome: 'Costão de Itacoatiara',
                  cidade: 'Niterói',
                  estado: 'RJ',
                ),
              ],
              entidades: [
                CatalogoEntidade(
                  uid: 'uidViaChamine1',
                  tipo: 'escalada',
                  croquiUid: 'uidItacoa99',
                  nome: 'Chaminé Stop',
                  escaladaGrau: '4º V',
                ),
              ],
            ),
          ),
        );
      });

      BuildContext? contextoCapturado;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                contextoCapturado = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      late Future<bool> futuroProcessamento;
      await tester.runAsync(() async {
        futuroProcessamento = service.processarLink(
          'https://aresta.cc/uidViaChamine1',
          context: contextoCapturado,
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.byType(ModalCroquiSemConexao), findsOneWidget);
      expect(find.textContaining('Chaminé Stop'), findsOneWidget);
      expect(
        find.text('Croqui Costão de Itacoatiara • Niterói, RJ'),
        findsOneWidget,
      );

      // Agora disponibiliza o croqui em memória (simulando que a conexão voltou) e toca em Tentar novamente
      final croquiItacoa = Croqui()
        ..id = 'br_rj_itacoa'
        ..uid = 'uidItacoa99'
        ..picos.add(
          Pico()
            ..nome = 'Costão de Itacoatiara'
            ..setoresOuGrupos.add(
              SetorOuGrupo()
                ..setor = (ArquivoSetor()
                  ..conteudo = (Setor()
                    ..uid = 'uidSetorItacoa1'
                    ..nome = 'Face Sul'
                    ..escaladas.add(
                      Escalada()
                        ..uid = 'uidViaChamine1'
                        ..viaEsportiva =
                            (ViaEsportiva()..nome = 'Chaminé Stop'),
                    ))),
            ),
        );
      datasetRepo.activeDataset.value = TopoDataset(
        picosBaixados: [
          {
            'id': 'br_rj_itacoa',
            'data': {'pico': croquiItacoa.picos.first, 'croqui': croquiItacoa},
          },
        ],
        picosDisponiveis: [],
      );

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        expect(await futuroProcessamento, isFalse);
        await repositorioCatalogo.fechar();
      });
      expect(find.byType(ModalCroquiSemConexao), findsNothing);
      expect(treeController.currentNode, isA<ViaNode>());
      expect(
        (treeController.currentNode as ViaNode).escaladaNome,
        equals('Chaminé Stop'),
      );
    });
  });

  group('DeepLinkNavigatorService - Links de Prévia e Pull Request (previa.arestaclimb.com)', () {
    test('intercepta https://previa.arestaclimb.com/pr00-0042 e aresta://previa/pr12-34567 conectando à prévia', () async {
      final codigosConectados = <String>[];
      final servicoPrevia = DeepLinkNavigatorService(
        datasetRepo: datasetRepo,
        treeController: treeController,
        conectorSessaoPrevia: (codigo) async {
          codigosConectados.add(codigo);
          return 'br_mg_igarape_pedra_grande';
        },
      );

      final okHttps = await servicoPrevia.processarLink(
        'https://previa.arestaclimb.com/pr00-0042',
      );
      expect(okHttps, isTrue);
      expect(codigosConectados, contains('pr000042'));
      expect(treeController.currentNode, isA<PicoNode>());

      final okScheme = await servicoPrevia.processarLink(
        'aresta://previa/pr12-34567',
      );
      expect(okScheme, isTrue);
      expect(codigosConectados, contains('pr1234567'));
    });

    test('desvia https://previa.arestaclimb.com/resumo/pr00-0042 para navegador externo sem tratar como rota interna', () async {
      Uri? urlExternaAberta;
      final servicoPrevia = DeepLinkNavigatorService(
        datasetRepo: datasetRepo,
        treeController: treeController,
        abridorUrlExterna: (uri) async {
          urlExternaAberta = uri;
          return true;
        },
      );

      final resultado = await servicoPrevia.processarLink(
        'https://previa.arestaclimb.com/resumo/pr00-0042',
      );
      expect(resultado, isFalse);
      expect(
        urlExternaAberta?.toString(),
        equals('https://previa.arestaclimb.com/resumo/pr00-0042'),
      );
    });

    test('usa launchUrl padrão para abrir resumo de PR e navega para BrowseNode quando a prévia tem múltiplos croquis ou falha quando retorna null', () async {
      final fakeLauncher = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = fakeLauncher;

      final resResumo = await service.processarLink(
        Uri.parse('https://previa.arestaclimb.com/resumo/pr00-0099'),
      );
      expect(resResumo, isFalse);
      expect(
        fakeLauncher.ultimaUrl,
        equals('https://previa.arestaclimb.com/resumo/pr00-0099'),
      );

      // Múltiplos croquis (retorna string vazia -> BrowseNode)
      final servicoMultiplos = DeepLinkNavigatorService(
        datasetRepo: datasetRepo,
        treeController: treeController,
        conectorSessaoPrevia: (_) async => '',
      );
      expect(
        await servicoMultiplos.processarLink(
          'https://previa.arestaclimb.com/pr00-0042',
        ),
        isTrue,
      );
      expect(treeController.currentNode, isA<BrowseNode>());

      // Falha na sessão de prévia (retorna null -> onMensagemAviso)
      String? msgErroPrevia;
      final servicoFalha = DeepLinkNavigatorService(
        datasetRepo: datasetRepo,
        treeController: treeController,
        conectorSessaoPrevia: (_) async => null,
        onMensagemAviso: (m) => msgErroPrevia = m,
      );
      expect(
        await servicoFalha.processarLink(
          'https://previa.arestaclimb.com/pr00-0042',
        ),
        isFalse,
      );
      expect(msgErroPrevia, contains('pr00-0042'));
    });

    test('executa _conectarSessaoPreviaPadrao com cliente HTTP injetado para prévia de croqui único, múltiplos e erro HTTP', () async {
      final indiceUnico = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = 'br_mg_igarape_pedra_grande'
            ..nome = 'Pedra Grande',
        );
      final clienteUnico = ClienteHttpAresta.paraTestes(
        MockClient((req) async {
          if (req.url.path.endsWith('/info')) {
            return http.Response(jsonEncode({'localUrl': ''}), 200);
          }
          if (req.url.path.endsWith('/indice.binarypb')) {
            return http.Response.bytes(indiceUnico.writeToBuffer(), 200);
          }
          if (req.url.path.endsWith('/compilado.binarypb')) {
            return http.Response.bytes(croquiTeste.writeToBuffer(), 200);
          }
          return http.Response('', 404);
        }),
      );

      final servicoPadraoUnico = DeepLinkNavigatorService(
        datasetRepo: datasetRepo,
        treeController: treeController,
        httpClient: clienteUnico,
      );
      final okUnico = await servicoPadraoUnico.processarLink(
        'https://previa.arestaclimb.com/pr00-0042',
      );
      expect(okUnico, isTrue);
      expect(treeController.currentNode, isA<PicoNode>());

      // Múltiplos croquis no índice
      final indiceMulti = Indice()
        ..croquis.addAll([
          ResumoCroqui()..id = 'c1',
          ResumoCroqui()..id = 'c2',
        ]);
      final clienteMulti = ClienteHttpAresta.paraTestes(
        MockClient((req) async {
          if (req.url.path.endsWith('/indice.binarypb')) {
            return http.Response.bytes(indiceMulti.writeToBuffer(), 200);
          }
          return http.Response('', 404);
        }),
      );
      final servicoPadraoMulti = DeepLinkNavigatorService(
        datasetRepo: datasetRepo,
        treeController: treeController,
        httpClient: clienteMulti,
      );
      final okMulti = await servicoPadraoMulti.processarLink(
        'https://previa.arestaclimb.com/pr00-0043',
      );
      expect(okMulti, isTrue);
      expect(treeController.currentNode, isA<BrowseNode>());

      // Erro 404 no indice.binarypb e exceção de rede
      final cliente404 = ClienteHttpAresta.paraTestes(
        MockClient((_) async => http.Response('', 404)),
      );
      final servicoPadrao404 = DeepLinkNavigatorService(
        datasetRepo: datasetRepo,
        treeController: treeController,
        httpClient: cliente404,
      );
      expect(
        await servicoPadrao404.processarLink(
          'https://previa.arestaclimb.com/pr00-0044',
        ),
        isFalse,
      );

      final clienteExcecao = ClienteHttpAresta.paraTestes(
        MockClient((_) async => throw const SocketException('falha')),
      );
      final servicoPadraoExcecao = DeepLinkNavigatorService(
        datasetRepo: datasetRepo,
        treeController: treeController,
        httpClient: clienteExcecao,
      );
      expect(
        await servicoPadraoExcecao.processarLink(
          'https://previa.arestaclimb.com/pr00-0045',
        ),
        isFalse,
      );
    });

    test('registra traces de performance cold_start_deep_link e warm_start_deep_link com modo_acesso e duracao_ms', () async {
      ServicoPerformance.resetarParaTestes();
      ServicoPerformance.instancia.iniciarCronometroColdStart();

      final okCold = await service.processarLink(
        'https://aresta.cc/$uidSetorDireto',
        tipoStart: 'cold_start',
      );
      expect(okCold, isTrue);

      final traceCold = ServicoPerformance.instancia.tracesRegistradas
          .where((t) => t.nome == 'cold_start_deep_link')
          .last;
      expect(traceCold.atributos['destino'], equals('setor'));
      expect(traceCold.atributos['modo_acesso'], equals('offline'));
      expect(mockTelemetry.recordedParams['deep_link_aberto']!['modo_acesso'], equals('offline'));
      expect(mockTelemetry.recordedParams['deep_link_aberto']!['duracao_ms'], isA<int>());

      final okWarm = await service.processarLink(
        'https://aresta.cc/$uidViaNoSetor',
        tipoStart: 'warm_start',
      );
      expect(okWarm, isTrue);

      final traceWarm = ServicoPerformance.instancia.tracesRegistradas
          .where((t) => t.nome == 'warm_start_deep_link')
          .last;
      expect(traceWarm.atributos['destino'], equals('via'));
      expect(traceWarm.atributos['modo_acesso'], equals('offline'));
    });
  });
}

