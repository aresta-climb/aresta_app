// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workmanager/workmanager.dart';

import 'package:frontend/aresta_api/openapi/generated/dart/catalogo.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/constants/constantes_rede.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:frontend/services/http/sync_rede.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/inicializacao_app.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import '../mocks/mock_app_logger.dart';
import '../mocks/mock_telemetria.dart';

class _MockWorkmanager extends Mock implements Workmanager {}
class _MockAppLinks extends Mock implements AppLinks {}

class _PathProviderInicializacaoFake extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String caminho;
  _PathProviderInicializacaoFake(this.caminho);

  @override
  Future<String?> getApplicationDocumentsPath() async => caminho;

  @override
  Future<String?> getTemporaryPath() async => '$caminho/temp';
}

class _ImageCacheRastreador extends ImageCache {
  int limpezas = 0;

  @override
  void clear() {
    limpezas++;
    super.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dirTemp;

  setUp(() async {
    HttpOverrides.global = null;
    dirTemp = await Directory.systemTemp.createTemp('inicializacao_app_test_');
    PathProviderPlatform.instance = _PathProviderInicializacaoFake(dirTemp.path);
    TelemetryService.instance = MockTelemetryService();
  });

  tearDown(() async {
    SyncService.baseUrlOverride = null;
    if (dirTemp.existsSync()) {
      try {
        dirTemp.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('Gestão de Memória e Vitals (configurarGestaoMemoria)', () {
    test('define teto LRU do imageCache para 100 MB por padrão ou em tier medio', () {
      configurarGestaoMemoria(ramTotalMb: 4096);
      expect(
        PaintingBinding.instance.imageCache.maximumSizeBytes,
        equals(100 * 1024 * 1024),
      );
    });

    test('ajusta teto LRU do imageCache para 50 MB em dispositivos de baixa memória (<= 3 GB RAM)', () {
      configurarGestaoMemoria(ramTotalMb: 3072);
      expect(
        PaintingBinding.instance.imageCache.maximumSizeBytes,
        equals(50 * 1024 * 1024),
      );
    });

    test('ajusta teto LRU do imageCache para 150 MB em dispositivos de alta memória (>= 8 GB RAM)', () {
      configurarGestaoMemoria(ramTotalMb: 8192);
      expect(
        PaintingBinding.instance.imageCache.maximumSizeBytes,
        equals(150 * 1024 * 1024),
      );
      configurarGestaoMemoria();
    });

    test('permite tamanho customizado explícito', () {
      configurarGestaoMemoria(tamanhoMaximoBytes: 50 * 1024 * 1024);
      expect(
        PaintingBinding.instance.imageCache.maximumSizeBytes,
        equals(50 * 1024 * 1024),
      );
      configurarGestaoMemoria();
    });
  });

  group('Migração Silenciosa de Termos Legais (migrarTermosLegais)', () {
    test('migra de chave legada accepted_terms para accepted_legal_version = 1', () async {
      SharedPreferences.setMockInitialValues({
        'accepted_terms': true,
      });
      final prefs = await SharedPreferences.getInstance();

      final versao = await migrarTermosLegais(prefs);

      expect(versao, 1);
      expect(prefs.getInt('accepted_legal_version'), 1);
      expect(prefs.containsKey('accepted_terms'), isFalse);
    });

    test('remove accepted_terms residual se accepted_legal_version já existir', () async {
      SharedPreferences.setMockInitialValues({
        'accepted_legal_version': 2,
        'accepted_terms': true,
      });
      final prefs = await SharedPreferences.getInstance();

      final versao = await migrarTermosLegais(prefs);

      expect(versao, 2);
      expect(prefs.getInt('accepted_legal_version'), 2);
      expect(prefs.containsKey('accepted_terms'), isFalse);
    });

    test('retorna nulo se o usuário for novo e nunca aceitou nada', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final versao = await migrarTermosLegais(prefs);

      expect(versao, isNull);
    });
  });

  group('Serviços e Foreground Takeover (setupAppServices)', () {
    late _MockWorkmanager mockWorkmanager;
    late EditorDeCroqui editor;
    late DatasetRepository datasetRepo;
    late SyncService syncService;
    late HttpServer servidor;
    int chamadasIndice = 0;

    setUp(() async {
      mockWorkmanager = _MockWorkmanager();
      when(() => mockWorkmanager.cancelByUniqueName(any())).thenAnswer((_) async {});

      chamadasIndice = 0;
      servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      servidor.listen((req) async {
        if (req.uri.path.endsWith('/indice.binarypb')) {
          chamadasIndice++;
          req.response.statusCode = 200;
          req.response.add(Indice().writeToBuffer());
          await req.response.close();
        } else {
          req.response.statusCode = 404;
          await req.response.close();
        }
      });

      SyncService.baseUrlOverride = 'http://127.0.0.1:${servidor.port}';
      editor = EditorDeCroqui();
      File(editor.indicePath(dirTemp.path))
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(Indice().writeToBuffer());
      File(editor.catalogoPath(dirTemp.path)).writeAsBytesSync([1, 2, 3, 4]);
      datasetRepo = DatasetRepository(editorDeCroqui: editor);
      final cliente = ClienteHttpAresta.paraTestes(http.Client());
      syncService = SyncService(
        datasetRepository: datasetRepo,
        client: cliente,
        network: SyncNetwork(cliente, Duration.zero),
      );
    });

    tearDown(() async {
      await datasetRepo.repositorioCatalogo.fechar();
      await servidor.close(force: true);
    });

    test('cancela tarefa de segundo plano e sincroniza se não precisa de migração', () async {
      SharedPreferences.setMockInitialValues({
        'cached_data_version': NetworkConstants.kDataVersion,
      });

      final result = await setupAppServices(
        datasetRepo,
        syncService,
        workmanager: mockWorkmanager,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockWorkmanager.cancelByUniqueName('migracao_pos_update')).called(1);
      expect(result, isFalse);
      expect(chamadasIndice, equals(1));
    });

    test('cancela tarefa de segundo plano e não sincroniza se precisa de migração', () async {
      SharedPreferences.setMockInitialValues({
        'cached_data_version': NetworkConstants.kDataVersion - 1,
      });

      final result = await setupAppServices(
        datasetRepo,
        syncService,
        workmanager: mockWorkmanager,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockWorkmanager.cancelByUniqueName('migracao_pos_update')).called(1);
      expect(result, isTrue);
      expect(chamadasIndice, equals(0));
    });
  });

  group('Ouvintes LiveReload (registrarOuvintesLiveReload)', () {
    test(
      'sincroniza índice, atualiza catalogo.db experimental com forceBypassCache, recarrega croquis online e purga cache inativo ao receber evento',
      () async {
        final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => servidor.close(force: true));
        final urlServidor = 'http://127.0.0.1:${servidor.port}';

        // Cria um banco catalogo.db atualizado no servidor
        final caminhoFonte = '${dirTemp.path}/catalogo_servidor_live.db';
        final repoFonte = RepositorioCatalogo(
          provedorCaminhoBanco: () async => caminhoFonte,
          fabricaBanco: databaseFactoryFfi,
        );
        await repoFonte.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoDestino: 'v_live_1',
            upserts: UpsertsSyncCatalogo(
              croquis: [
                CatalogoCroqui(
                  croquiUid: 'uid_croqui_live',
                  idSlug: 'br_mg_ouro_preto',
                  nome: 'Ouro Preto Experimental',
                ),
              ],
              entidades: [
                CatalogoEntidade(
                  uid: 'uid_via_live',
                  tipo: 'escalada',
                  croquiUid: 'uid_croqui_live',
                  nome: 'Via Nova do Live Reload',
                ),
              ],
            ),
          ),
        );
        await repoFonte.fechar();
        final bytesCatalogoNovo = await File(caminhoFonte).readAsBytes();

        final croquiAtualizado = Croqui(
          id: 'br_mg_ouro_preto',
          nome: 'Ouro Preto Atualizado via Live Reload',
        );
        final indiceLive = Indice(
          versaoCatalogo: 'v_live_1',
          croquis: [
            ResumoCroqui(
              id: 'br_mg_ouro_preto',
              nome: 'Ouro Preto Experimental',
              caminhoRelativo: 'br_mg_ouro_preto/compilado.binarypb',
              checksumSha256Croqui: 'hash_live_1',
            ),
          ],
        );

        bool recebeuBypassCacheNoIndice = false;
        servidor.listen((req) async {
          if (req.uri.path.endsWith('/indice.binarypb')) {
            if (req.uri.queryParameters.containsKey('t')) {
              recebeuBypassCacheNoIndice = true;
            }
            req.response.statusCode = 200;
            req.response.add(indiceLive.writeToBuffer());
            await req.response.close();
          } else if (req.uri.path.endsWith('/catalogo.db')) {
            req.response.statusCode = 200;
            req.response.add(bytesCatalogoNovo);
            await req.response.close();
          } else if (req.uri.path.endsWith('/compilado.binarypb')) {
            req.response.statusCode = 200;
            req.response.add(croquiAtualizado.writeToBuffer());
            await req.response.close();
          } else {
            req.response.statusCode = 404;
            await req.response.close();
          }
        });

        final editorLocal = EditorDeCroqui();
        editorLocal.isExperimentalMode.value = true;
        editorLocal.editorUrl.value = urlServidor;

        final datasetRepo = DatasetRepository(editorDeCroqui: editorLocal);
        addTearDown(() => datasetRepo.repositorioCatalogo.fechar());

        // Registra um croqui aberto na sessão online para validar que o Live Reload o recarrega
        datasetRepo.gerenciadorSessaoOnline.registrarCroquiOnline(
          'br_mg_ouro_preto',
          Croqui(id: 'br_mg_ouro_preto', nome: 'Ouro Preto Antigo'),
        );

        final cliente = ClienteHttpAresta.paraTestes(http.Client());
        final syncSvc = SyncService(
          datasetRepository: datasetRepo,
          client: cliente,
          network: SyncNetwork(cliente, Duration.zero),
        );
        final servicoOnline = ServicoCroquiOnline(
          client: cliente,
          sessaoOnline: datasetRepo.gerenciadorSessaoOnline,
        );
        final imageCacheRastreador = _ImageCacheRastreador();

        registrarOuvintesLiveReload(
          editorLocal,
          datasetRepo,
          syncSvc,
          servicoCroquiOnline: servicoOnline,
          imageCache: imageCacheRastreador,
          debounceDuration: const Duration(milliseconds: 20),
        );

        editorLocal.eventoLiveReload.value = LiveReloadEvent(
          setorId: 'setor_1',
          timestamp: DateTime.now(),
        );

        await Future<void>.delayed(const Duration(milliseconds: 250));

        expect(recebeuBypassCacheNoIndice, isTrue);
        expect(imageCacheRastreador.limpezas, equals(1));
        expect(
          await datasetRepo.repositorioCatalogo.obterIdSlugPorUid('uid_via_live'),
          equals('br_mg_ouro_preto'),
        );
        expect(
          datasetRepo.gerenciadorSessaoOnline
              .obterCroquiOnline('br_mg_ouro_preto')
              ?.nome,
          equals('Ouro Preto Atualizado via Live Reload'),
        );
      },
    );

    test('coalesce múltiplos eventos push de LiveReload em rápida sucessão', () async {
      final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => servidor.close(force: true));
      int chamadasIndice = 0;
      servidor.listen((req) async {
        if (req.uri.path.endsWith('/indice.binarypb')) {
          chamadasIndice++;
          req.response.statusCode = 200;
          req.response.add(Indice().writeToBuffer());
          await req.response.close();
        } else {
          req.response.statusCode = 404;
          await req.response.close();
        }
      });

      final editorLocal = EditorDeCroqui();
      editorLocal.isExperimentalMode.value = true;
      editorLocal.editorUrl.value = 'http://127.0.0.1:${servidor.port}';
      final datasetRepo = DatasetRepository(editorDeCroqui: editorLocal);
      addTearDown(() => datasetRepo.repositorioCatalogo.fechar());
      datasetRepo.gerenciadorSessaoOnline.registrarCroquiOnline(
        'pico_ausente_no_indice',
        Croqui(id: 'pico_ausente_no_indice', nome: 'Ausente'),
      );

      final cliente = ClienteHttpAresta.paraTestes(http.Client());
      final syncSvc = SyncService(
        datasetRepository: datasetRepo,
        client: cliente,
        network: SyncNetwork(cliente, Duration.zero),
      );

      registrarOuvintesLiveReload(
        editorLocal,
        datasetRepo,
        syncSvc,
        debounceDuration: const Duration(milliseconds: 40),
      );

      // Emite 3 eventos seguidos quase instantâneos
      editorLocal.eventoLiveReload.value = LiveReloadEvent(
        setorId: 'setor_1',
        timestamp: DateTime.now(),
      );
      editorLocal.eventoLiveReload.value = LiveReloadEvent(
        setorId: 'setor_2',
        timestamp: DateTime.now(),
      );
      editorLocal.eventoLiveReload.value = LiveReloadEvent(
        setorId: 'setor_3',
        timestamp: DateTime.now(),
      );

      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Deve ter chamado syncIndex apenas 1 vez para o lote
      expect(chamadasIndice, equals(1));
    });
  });

  group('Resolução de Destino Inicial no Cold Start (resolverDestinoInicialColdStart)', () {
    test('retorna HomeNode quando getInitialLink retorna null', () async {
      final mockAppLinks = _MockAppLinks();
      when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

      final editor = EditorDeCroqui();
      final repo = DatasetRepository(editorDeCroqui: editor);
      addTearDown(() => repo.repositorioCatalogo.fechar());

      final resultado = await resolverDestinoInicialColdStart(
        repo,
        appLinks: mockAppLinks,
      );

      expect(resultado.treeController.currentNode, isA<HomeNode>());
      expect(resultado.linkInicialProcessado, isNull);
      expect(resultado.mensagemAvisoInicial, isNull);
    });

    test('resolve link inicial de Cold Start posicionando o controlador diretamente no nó alvo', () async {
      final mockAppLinks = _MockAppLinks();
      final uri = Uri.parse('https://aresta.cc/pQ9mRt2Kx1Vw8L');
      when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => uri);

      final editor = EditorDeCroqui();
      final repo = DatasetRepository(editorDeCroqui: editor);
      addTearDown(() => repo.repositorioCatalogo.fechar());

      final pico = Pico()..nome = 'Pedra Grande';
      final croqui = Croqui()
        ..id = 'br_mg_igarape_pedra_grande'
        ..uid = 'pQ9mRt2Kx1Vw8L'
        ..picos.add(pico);
      repo.activeDataset.value = TopoDataset(
        picosBaixados: [
          {
            'id': 'br_mg_igarape_pedra_grande',
            'data': {'pico': pico, 'croqui': croqui},
          },
        ],
        picosDisponiveis: [],
      );

      final resultado = await resolverDestinoInicialColdStart(
        repo,
        appLinks: mockAppLinks,
      );

      expect(resultado.treeController.currentNode, isA<PicoNode>());
      expect(
        (resultado.treeController.currentNode as PicoNode).cragId,
        equals('br_mg_igarape_pedra_grande'),
      );
      expect(resultado.linkInicialProcessado, equals(uri));
      expect(resultado.mensagemAvisoInicial, isNull);
    });

    test('captura mensagemAvisoInicial quando o UID do link inicial não for encontrado e trata exceção de getInitialLink graciosamente', () async {
      final mockAppLinks = _MockAppLinks();
      final uri = Uri.parse('https://aresta.cc/z9zzZzZzZzZzZz');
      when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => uri);

      final editor = EditorDeCroqui();
      final repo = DatasetRepository(editorDeCroqui: editor);
      addTearDown(() => repo.repositorioCatalogo.fechar());
      repo.activeDataset.value = TopoDataset(
        picosBaixados: [],
        picosDisponiveis: [],
      );

      final resultado = await resolverDestinoInicialColdStart(
        repo,
        appLinks: mockAppLinks,
      );

      expect(resultado.treeController.currentNode, isA<HomeNode>());
      expect(resultado.linkInicialProcessado, equals(uri));
      expect(resultado.mensagemAvisoInicial, contains('z9zzZzZzZzZzZz'));

      // Também trata exceção de getInitialLink retornando HomeNode sem falhar
      when(() => mockAppLinks.getInitialLink()).thenThrow(Exception('Falha canal nativo'));
      final resultadoErro = await resolverDestinoInicialColdStart(
        repo,
        appLinks: mockAppLinks,
      );
      expect(resultadoErro.treeController.currentNode, isA<HomeNode>());
      expect(resultadoErro.linkInicialProcessado, isNull);
    });

    test('captura itemSemConexaoInicial quando o croqui do link inicial não está baixado e o dispositivo está sem conexão', () async {
      final mockAppLinks = _MockAppLinks();
      final uri = Uri.parse('https://aresta.cc/uidViaColdOff1');
      when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => uri);

      final editor = EditorDeCroqui();
      final catalogo = RepositorioCatalogo(
        provedorCaminhoBanco: () async => '${dirTemp.path}/catalogo_cold_offline.db',
        fabricaBanco: databaseFactoryFfi,
      );
      addTearDown(catalogo.fechar);
      await catalogo.aplicarDelta(
        const RespostaSyncCatalogo(
          acao: 'apply_delta',
          versaoDestino: 'v_cold_offline',
          upserts: UpsertsSyncCatalogo(
            croquis: [
              CatalogoCroqui(
                croquiUid: 'uidCroquiCold1',
                idSlug: 'br_mg_serra_cipo',
                nome: 'Serra do Cipó',
                cidade: 'Santana do Riacho',
                estado: 'MG',
              ),
            ],
            entidades: [
              CatalogoEntidade(
                uid: 'uidViaColdOff1',
                tipo: 'escalada',
                croquiUid: 'uidCroquiCold1',
                nome: 'Via do Sol',
                escaladaGrau: '6º',
              ),
            ],
          ),
        ),
      );

      final repo = DatasetRepository(
        editorDeCroqui: editor,
        repositorioCatalogo: catalogo,
      );
      repo.activeDataset.value = TopoDataset(
        picosBaixados: [],
        picosDisponiveis: [],
      );

      final resultado = await resolverDestinoInicialColdStart(
        repo,
        appLinks: mockAppLinks,
      );

      expect(resultado.treeController.currentNode, isA<HomeNode>());
      expect(resultado.linkInicialProcessado, equals(uri));
      expect(resultado.mensagemAvisoInicial, isNull);
      expect(resultado.itemSemConexaoInicial, isNotNull);
      expect(resultado.itemSemConexaoInicial!.nome, equals('Via do Sol'));
      expect(resultado.itemSemConexaoInicial!.picoNome, equals('Serra do Cipó'));
    });

    test('retorna HomeNode e registra aviso quando a resolução do link inicial exceder o timeoutResolucao', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;
      addTearDown(AppLogger.resetForTesting);

      final mockAppLinks = _MockAppLinks();
      final completerInfinito = Completer<Uri?>();
      when(() => mockAppLinks.getInitialLink()).thenAnswer((_) => completerInfinito.future);

      final editor = EditorDeCroqui();
      final repo = DatasetRepository(editorDeCroqui: editor);
      addTearDown(() => repo.repositorioCatalogo.fechar());

      final resultado = await resolverDestinoInicialColdStart(
        repo,
        appLinks: mockAppLinks,
        timeoutResolucao: const Duration(milliseconds: 40),
      );

      expect(resultado.treeController.currentNode, isA<HomeNode>());
      expect(resultado.linkInicialProcessado, isNull);
      expect(
        mockLogger.recordedWarnings.any(
          (w) => w.contains('Tempo limite excedido ao resolver destino inicial no Cold Start'),
        ),
        isTrue,
      );
    });

    test('executarEtapaPreBootComTimeout conclui normalmente no sucesso e degrada com aviso em timeout ou erro sem propagar exceção', () async {
      final mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;
      addTearDown(AppLogger.resetForTesting);

      bool executou = false;
      await executarEtapaPreBootComTimeout(
        'etapa_rapida',
        () async {
          executou = true;
        },
      );
      expect(executou, isTrue);
      expect(mockLogger.recordedWarnings, isEmpty);

      // Caso de timeout em canal nativo pendurado
      final completerInfinito = Completer<void>();
      await executarEtapaPreBootComTimeout(
        'canal_pendurado',
        () => completerInfinito.future,
        timeout: const Duration(milliseconds: 30),
      );
      expect(
        mockLogger.recordedWarnings.any((w) => w.contains('canal_pendurado')),
        isTrue,
      );
    });
  });
}
