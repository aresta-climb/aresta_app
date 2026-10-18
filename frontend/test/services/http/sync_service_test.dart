// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:frontend/aresta_api/openapi/generated/dart/catalogo.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:frontend/services/http/sync_rede.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/constants/constantes_rede.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/http/sync_armazenamento.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/http/sync_isolate.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import '../../mocks/mock_app_logger.dart';
import '../../mocks/mock_telemetria.dart';
import 'package:frontend/services/firebase/remote_config.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class FakeRemoteConfigService extends ChangeNotifier implements RemoteConfigService {
  final int _hard = 0;
  int _soft = 0;
  final int _rec = 0;

  @override
  int get hardMinVersion => _hard;
  @override
  int get softMinVersion => _soft;
  @override
  int get recommendedVersion => _rec;
  @override
  int getInt(String key) => 0;
  @override
  bool getBool(String key) => false;
  @override
  String getString(String key) => "";

  final String _iosUrl = "";
  @override
  String get storeUrlIos => _iosUrl;
  @override
  String get feedbackEdgeFunctionUrl => "";
  @override
  String get whatsappCommunityUrl => "";
  @override
  String get discordCommunityUrl => "";
  @override
  String get servingBaseUrl => "";
  @override
  String get officialServerUrl => "";
  @override
  Future<void> initialize() async {}
  @override
  FirebaseRemoteConfig? debugRemoteConfig;
  @override
  void clearInitFuture() {}
}

// Mock simple PathProviderPlatform
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;
  MockPathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    return path;
  }
}

void main() {
  late SyncService syncService;
  late SyncStorage storage;
  late DatasetRepository datasetRepository;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    TelemetryService.instance = MockTelemetryService();

    tempDir = await Directory.systemTemp.createTemp('sync_service_test');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);

    storage = SyncStorage();
    // Inicia a instancia para n dar erro
    final editor = EditorDeCroqui();
    datasetRepository = DatasetRepository(editorDeCroqui: editor);

    syncService = SyncService(
      datasetRepository: datasetRepository,
      storage: storage,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'checkNeedsMigration deve retornar true se a versão salva for menor',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'cached_data_version',
        NetworkConstants.kDataVersion - 1,
      );

      final result = await syncService.checkNeedsMigration();
      expect(result, isTrue);
    },
  );

  test(
    'checkNeedsMigration deve retornar false se a versão for igual',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cached_data_version', NetworkConstants.kDataVersion);

      final result = await syncService.checkNeedsMigration();
      expect(result, isFalse);
    },
  );

  test('confirmMigrationComplete grava a versão correta', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'cached_data_version',
      NetworkConstants.kDataVersion - 1,
    );

    await syncService.confirmMigrationComplete();

    final updatedVersion = prefs.getInt('cached_data_version');
    expect(updatedVersion, NetworkConstants.kDataVersion);
  });

  test('syncIndex set outdated status if isNetworkDisabled is true', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Aresta',
      packageName: 'com.aresta.climb',
      version: '1.0.0',
      buildNumber: '10',
      buildSignature: '',
    );

    final fakeRemote = FakeRemoteConfigService();
    fakeRemote._soft = 11;

    final tempSyncService = SyncService(
      datasetRepository: datasetRepository,
      storage: storage,
      remoteConfigService: fakeRemote,
    );

    await tempSyncService.syncIndex(auto: true);

    expect(tempSyncService.syncStatus.value, SyncStatus.outdated);
  });

  test(
    'syncIndex emite logs estruturados de depuração com arquivos atualizados/renomeados e removidos',
    () async {
      final editor = EditorDeCroqui();
      final picoId = 'pico_debug_logs';
      final newIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..caminhoRelativo = 'picos/$picoId.binarypb'
            ..checksumSha256Croqui = 'NEW_HASH',
        );

      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(
        (Indice()
              ..croquis.add(
                ResumoCroqui()
                  ..id = picoId
                  ..checksumSha256Croqui = 'OLD_HASH',
              ))
            .writeToBuffer(),
      );

      final picoDir = Directory('${editor.downloadsPath(tempDir.path)}/$picoId');
      await picoDir.create(recursive: true);
      final oldPicoFile = File('${picoDir.path}/$picoId.binarypb');
      await oldPicoFile.writeAsBytes(Croqui().writeToBuffer());

      final logs = <String>[];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      try {
        final fakeClient = _SyncTestFakeClient(newIndice);
        final testSyncService = SyncService(
          datasetRepository: datasetRepository,
          storage: storage,
          client: ClienteHttpAresta.paraTestes(fakeClient),
        );

        testSyncService.mockIsolateSpawn = (mainFunc, args) async {
          File('${picoDir.path}/compilado.binarypb.tmp')
              .createSync(recursive: true);
          args.sendPort.send(
            DownloadIsolateResult(
              filesToDelete: [
                '${picoDir.path}/foto_antiga.jpg',
                '${picoDir.path}/$picoId.binarypb',
              ],
              filesToRename: {
                '${picoDir.path}/compilado.binarypb.tmp':
                    '${picoDir.path}/compilado.binarypb',
              },
            ),
          );
        };

        await testSyncService.syncIndex(auto: true);

        expect(
          logs.any(
            (l) => l.contains(
              '🔄 [SyncService] Arquivos atualizados/renomeados no syncIndex (1):',
            ),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (l) => l.contains(
              '${picoDir.path}/compilado.binarypb.tmp -> ${picoDir.path}/compilado.binarypb',
            ),
          ),
          isTrue,
        );
        expect(
          logs.any(
            (l) => l.contains(
              '🗑️ [SyncService] Arquivos removidos no syncIndex (2):',
            ),
          ),
          isTrue,
        );
        expect(
          logs.any((l) => l.contains('${picoDir.path}/foto_antiga.jpg')),
          isTrue,
        );
      } finally {
        debugPrint = originalDebugPrint;
      }
    },
  );

  group('Tratamento de Erros de Isolate com Rastreamento de Pilha', () {
    test(
      'tratarErroDownloadIsolate com erro transitório (HTTP 504) deve repassar como logAviso',
      () {
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        const fakeStack = 'sync_isolate.dart:98\nsync_isolate.dart:234';
        final resultado = DownloadIsolateResult(
          filesToDelete: [],
          filesToRename: {},
          error: 'HTTP 504 ao baixar crag_sector_13.webp',
          rastreamentoPilha: fakeStack,
        );

        syncService.tratarErroDownloadIsolate('pico_teste', resultado);

        expect(mockLogger.recordedWarnings.length, 1);
        final recorded = mockLogger.recordedWarnings.first;
        expect(recorded, contains('HTTP 504 ao baixar crag_sector_13.webp'));
        expect(recorded, contains('pico_teste'));
      },
    );

    test(
      'tratarErroDownloadIsolate com erro permanente (Checksum mismatch) deve gerar logCrash e usar StackTrace.current de fallback quando rastreamentoPilha for nulo',
      () {
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        final resultado = DownloadIsolateResult(
          filesToDelete: [],
          filesToRename: {},
          error: 'Checksum SHA-256 inválido para crag_sector_13.webp',
          rastreamentoPilha: null,
        );

        syncService.tratarErroDownloadIsolate('pico_teste_2', resultado);

        expect(mockLogger.recordedErrors.length, 1);
        final recorded = mockLogger.recordedErrors.first;
        expect(recorded['fatal'], isTrue);
        expect(recorded['stackTrace'], isNotNull);
      },
    );

    test(
      'downloadCrag quando isolate falha por queda de conexão registra apenas logAviso e não dispara logCrash fatal',
      () async {
        final mockLogger = MockAppLogger();
        AppLogger.instance = mockLogger;

        final resumo = ResumoCroqui(
          id: 'pico_sem_rede',
          nome: 'Pedra Grande',
          caminhoRelativo: 'br_mg_igarape_pedra_grande/compilado.binarypb',
          checksumSha256Croqui: 'hash123',
        );
        final indice = Indice(croquis: [resumo]);
        datasetRepository.indiceData.value = indice;

        final fakeClient = _SyncTestFakeClient(indice);
        final testSyncService = SyncService(
          datasetRepository: datasetRepository,
          storage: storage,
          client: ClienteHttpAresta.paraTestes(fakeClient),
        );

        testSyncService.mockIsolateSpawn = (mainFunc, args) async {
          args.sendPort.send(
            DownloadIsolateResult(
              filesToDelete: [],
              filesToRename: {},
              error: "ClientException with SocketException: Failed host lookup: 'serving.arestaclimb.com'",
              rastreamentoPilha: 'sync_isolate.dart:90',
            ),
          );
        };

        final sucesso = await testSyncService.downloadCrag(resumo);

        expect(sucesso, isFalse);
        expect(mockLogger.recordedErrors, isEmpty);
        expect(
          mockLogger.recordedWarnings.any((w) => w.contains('pico_sem_rede')),
          isTrue,
        );
      },
    );
  });

  group('Sincronização Assíncrona do Catálogo SQLite (catalogo.db)', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      HttpOverrides.global = null;
      final clienteLocal = ClienteHttpAresta.paraTestes(http.Client());
      syncService = SyncService(
        datasetRepository: datasetRepository,
        storage: storage,
        client: clienteLocal,
        network: SyncNetwork(clienteLocal, Duration.zero),
      );
    });

    tearDown(() async {
      SyncService.baseUrlOverride = null;
      SyncService.catalogoUrlOverride = null;
      await datasetRepository.repositorioCatalogo.fechar();
    });

    test(
      'syncIndex em IndiceUpdated deve sincronizar catalogo.db via apply_delta sem bloquear atualizacao de croquis',
      () async {
        // Prepara um catalogo.db local na versao v1
        await datasetRepository.repositorioCatalogo.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoDestino: 'v1',
            upserts: UpsertsSyncCatalogo(
              croquis: [
                CatalogoCroqui(
                  croquiUid: 'uid_pico_1',
                  idSlug: 'br_mg_igarape',
                  nome: 'Igarapé V1',
                ),
              ],
              entidades: [],
            ),
          ),
        );
        expect(
          await datasetRepository.repositorioCatalogo.obterVersaoCatalogo(),
          equals('v1'),
        );

        final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => servidor.close(force: true));
        final urlServidor = 'http://127.0.0.1:${servidor.port}';
        SyncService.baseUrlOverride = urlServidor;
        SyncService.catalogoUrlOverride = urlServidor;

        final novoIndice = Indice(versaoCatalogo: 'v2');

        servidor.listen((request) async {
          if (request.uri.path.endsWith('/indice.binarypb')) {
            request.response.statusCode = 200;
            request.response.headers.set('etag', '"etag-v2"');
            request.response.add(novoIndice.writeToBuffer());
            await request.response.close();
          } else if (request.uri.path == '/sync') {
            expect(request.uri.queryParameters['versao_local'], equals('v1'));
            expect(request.uri.queryParameters['versao_destino'], equals('v2'));
            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode({
                'acao': 'apply_delta',
                'versao_local': 'v1',
                'versao_destino': 'v2',
                'upserts': {
                  'croquis': [
                    {
                      'croqui_uid': 'uid_pico_1',
                      'id_slug': 'br_mg_igarape',
                      'nome': 'Igarapé V2 Atualizado',
                    },
                  ],
                  'entidades': [
                    {
                      'uid': 'sQ7YgEG6ONsPXt',
                      'tipo': 'escalada',
                      'croqui_uid': 'uid_pico_1',
                      'nome': 'Bloco Democracia',
                    },
                  ],
                },
                'deletes': {'croquis': [], 'entidades': []},
              }),
            );
            await request.response.close();
          } else {
            request.response.statusCode = 404;
            await request.response.close();
          }
        });

        final falhas = await syncService.syncIndex(auto: false);
        expect(falhas, isEmpty);
        expect(
          await datasetRepository.repositorioCatalogo.obterVersaoCatalogo(),
          equals('v2'),
        );
        expect(
          await datasetRepository.repositorioCatalogo.obterIdSlugPorUid(
            'sQ7YgEG6ONsPXt',
          ),
          equals('br_mg_igarape'),
        );
      },
    );

    test(
      'syncIndex deve baixar catalogo.db completo quando /sync retornar full_download ou em modo experimental',
      () async {
        // Cria um banco SQLite em memória/arquivo para servir como bytes de full_download
        final caminhoFonte = '${tempDir.path}/fonte_remota.db';
        final repoFonte = RepositorioCatalogo(
          provedorCaminhoBanco: () async => caminhoFonte,
        );
        await repoFonte.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoDestino: 'v_full_10',
            upserts: UpsertsSyncCatalogo(
              croquis: [
                CatalogoCroqui(
                  croquiUid: 'uid_c_full',
                  idSlug: 'br_sp_sao_bento',
                  nome: 'São Bento',
                ),
              ],
              entidades: [],
            ),
          ),
        );
        await repoFonte.fechar();
        final bytesBancoRemoto = await File(caminhoFonte).readAsBytes();

        final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => servidor.close(force: true));
        final urlServidor = 'http://127.0.0.1:${servidor.port}';
        SyncService.baseUrlOverride = urlServidor;
        SyncService.catalogoUrlOverride = urlServidor;

        final novoIndice = Indice(versaoCatalogo: 'v_full_10');
        int chamadasSyncEndpoint = 0;

        servidor.listen((request) async {
          if (request.uri.path.endsWith('/indice.binarypb')) {
            request.response.statusCode = 200;
            request.response.add(novoIndice.writeToBuffer());
            await request.response.close();
          } else if (request.uri.path == '/sync') {
            chamadasSyncEndpoint++;
            final versaoLocalParam =
                request.uri.queryParameters['versao_local'] ?? '';
            if (versaoLocalParam.isEmpty) {
              request.response.statusCode = 400;
              request.response.write(
                jsonEncode({
                  'erro':
                      'Parâmetros versao_local e versao_destino são obrigatórios',
                }),
              );
              await request.response.close();
              return;
            }
            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode({
                'acao': 'full_download',
                'versao_destino': 'v_full_10',
                'motivo': 'versao_muito_antiga',
              }),
            );
            await request.response.close();
          } else if (request.uri.path.endsWith('/catalogo.db')) {
            request.response.statusCode = 200;
            request.response.add(bytesBancoRemoto);
            await request.response.close();
          } else {
            request.response.statusCode = 404;
            await request.response.close();
          }
        });

        // 1. Quando catalogo.db local ainda não existe, copia primeiro do preload e depois chama /sync
        await syncService.syncIndex(auto: false);
        expect(chamadasSyncEndpoint, equals(1));
        expect(
          await datasetRepository.repositorioCatalogo.obterVersaoCatalogo(),
          equals('v_full_10'),
        );

        // 2. Se catalogo.db local não existir e preload também falhar, faz fallback para baixarCatalogoCompleto direto da CDN
        await datasetRepository.repositorioCatalogo.fechar();
        final arqCatalogo = File(
          datasetRepository.editorDeCroqui.catalogoPath(tempDir.path),
        );
        if (arqCatalogo.existsSync()) {
          arqCatalogo.deleteSync();
        }
        datasetRepository.assetBundle = _EmptyAssetBundle();
        await syncService.syncIndex(auto: false);
        expect(chamadasSyncEndpoint, equals(1));
        expect(
          await datasetRepository.repositorioCatalogo.obterVersaoCatalogo(),
          equals('v_full_10'),
        );
        datasetRepository.assetBundle = null;

        // 3. Em modo experimental (baixa direto $baseUrl/catalogo.db sem chamar /sync)
        await datasetRepository.repositorioCatalogo.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoDestino: 'v_exp_antiga',
          ),
        );
        datasetRepository.editorDeCroqui.isExperimentalMode.value = true;
        await syncService.syncIndex(auto: false);
        expect(
          await datasetRepository.repositorioCatalogo.obterVersaoCatalogo(),
          equals('v_full_10'),
        );
      },
    );

    test(
      'syncIndex em IndiceUnchanged (304 Not Modified) deve verificar versao_catalogo e sincronizar se estiver defasada',
      () async {
        final indiceLocal = Indice(versaoCatalogo: 'v_304_alvo');
        final indiceFile = File(
          datasetRepository.editorDeCroqui.indicePath(tempDir.path),
        );
        await indiceFile.parent.create(recursive: true);
        await indiceFile.writeAsBytes(indiceLocal.writeToBuffer());
        await File('${indiceFile.path}.etag').writeAsString('"etag-304"');

        // Catálogo local está em versão antiga 'v_antiga'
        await datasetRepository.repositorioCatalogo.aplicarDelta(
          const RespostaSyncCatalogo(
            acao: 'apply_delta',
            versaoDestino: 'v_antiga',
          ),
        );

        final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => servidor.close(force: true));
        final urlServidor = 'http://127.0.0.1:${servidor.port}';
        SyncService.baseUrlOverride = urlServidor;
        SyncService.catalogoUrlOverride = urlServidor;

        servidor.listen((request) async {
          if (request.uri.path.endsWith('/indice.binarypb')) {
            request.response.statusCode = 304;
            await request.response.close();
          } else if (request.uri.path == '/sync') {
            if (request.uri.queryParameters['versao_destino'] ==
                'v_indisponivel') {
              request.response.statusCode = 500;
              await request.response.close();
              return;
            }
            request.response.statusCode = 200;
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode({
                'acao': 'apply_delta',
                'versao_local': 'v_antiga',
                'versao_destino': 'v_304_alvo',
                'upserts': {'croquis': [], 'entidades': []},
                'deletes': {'croquis': [], 'entidades': []},
              }),
            );
            await request.response.close();
          } else {
            request.response.statusCode = 404;
            await request.response.close();
          }
        });

        await syncService.syncIndex(auto: true);
        expect(
          await datasetRepository.repositorioCatalogo.obterVersaoCatalogo(),
          equals('v_304_alvo'),
        );

        // Segunda chamada com mesma versão não deve precisar atualizar
        await syncService.syncIndex(auto: true);
        expect(
          await datasetRepository.repositorioCatalogo.obterVersaoCatalogo(),
          equals('v_304_alvo'),
        );

        // Quando /sync falha (ex: 404/500), mantém a versão local sem falhar o syncIndex
        await syncService.sincronizarCatalogoSeNecessario(
          Indice(versaoCatalogo: 'v_indisponivel'),
          '$urlServidor/inexistente',
        );
        expect(
          await datasetRepository.repositorioCatalogo.obterVersaoCatalogo(),
          equals('v_304_alvo'),
        );
      },
    );
  });
}

class _SyncTestFakeClient extends http.BaseClient {
  final Indice indice;
  _SyncTestFakeClient(this.indice);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path.endsWith('indice.binarypb')) {
      final bytes = indice.writeToBuffer();
      return http.StreamedResponse(
        Stream.value(bytes),
        200,
        headers: {'etag': 'TEST_ETAG'},
      );
    }
    return http.StreamedResponse(Stream.value([]), 404);
  }
}

class _EmptyAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Asset ausente: $key');
  }
}


