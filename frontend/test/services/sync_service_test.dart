/// Testes do SyncService: lógica de extração de imagens markdown e SyncStatus.
/// Como _extractMarkdownImages é privada da biblioteca, testamos seu comportamento
/// indiretamente via regex equivalente aplicada a JSONs de Croqui.
library;

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:frontend/constants/network_constants.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:crypto/crypto.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/http/sync_isolate.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks/mock_telemetry_service.dart';

late HttpServer localServer;
Map<String, List<int>> mockServerResponses = {};
List<String> requestedPaths = [];

Future<void> setupLocalServer() async {
  localServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  localServer.listen((HttpRequest request) {
    final path = request.uri.path;
    requestedPaths.add(request.uri.toString());
    print('LOCAL SERVER REQUEST: ');
    for (var entry in mockServerResponses.entries) {
      if (path.endsWith(entry.key)) {
        print('LOCAL SERVER FOUND MATCH: ');
        request.response.add(entry.value);
        request.response.close();
        return;
      }
    }
    print('LOCAL SERVER 404: ');
    request.response.statusCode = 404;
    request.response.close();
  });
}

Future<void> teardownLocalServer() async {
  await localServer.close(force: true);
}

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
}

class _ErrorClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw const SocketException('Failed host lookup');
  }
}

class FakeClient extends http.BaseClient {
  final Indice newIndice;
  final Indice? freshIndiceForBypass;
  final Map<String, List<int>> mockFiles;
  final String? etagToReturn;
  final List<String> requestedUrls = [];
  final List<String> requestedFullUrls = [];
  final Map<String, String> receivedHeaders = {};

  FakeClient(
    this.newIndice, [
    this.mockFiles = const {},
    this.etagToReturn,
    this.freshIndiceForBypass,
  ]) {
    mockServerResponses.clear();
    mockServerResponses.addAll(mockFiles);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUrls.add(request.url.path);
    requestedFullUrls.add(request.url.toString());
    receivedHeaders.addAll(request.headers);

    if (request.url.path.endsWith('indice.binarypb')) {
      if (etagToReturn != null &&
          request.headers['If-None-Match'] == etagToReturn &&
          !request.url.query.contains('t=')) {
        return http.StreamedResponse(const Stream.empty(), 304);
      }

      final indiceToReturn =
          (freshIndiceForBypass != null && request.url.query.contains('t='))
          ? freshIndiceForBypass!
          : newIndice;

      final bytes = indiceToReturn.writeToBuffer();
      return http.StreamedResponse(
        Stream.value(bytes),
        200,
        headers: etagToReturn != null ? {'etag': etagToReturn!} : {},
      );
    }

    for (var entry in mockFiles.entries) {
      if (request.url.path.endsWith(entry.key)) {
        return http.StreamedResponse(Stream.value(entry.value), 200);
      }
    }

    // Simulate network drop during pico download
    throw const SocketException('Network dropped');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  setUpAll(() async {
    await setupLocalServer();
  });
  tearDownAll(() async {
    await teardownLocalServer();
  });
  late EditorDeCroqui editor;
  late DatasetRepository repo;
  late SyncService syncService;

  late MockTelemetryService mockTelemetry;

  setUp(() {
    editor = EditorDeCroqui();
    editor.editorUrl.value =
        'http://${localServer.address.address}:${localServer.port}/v3';
    SyncService.baseUrlOverride =
        'http://${localServer.address.address}:${localServer.port}/v3';
    repo = DatasetRepository(editorDeCroqui: editor);
    syncService = SyncService(datasetRepository: repo)
      ..mockIsolateSpawn = (mainFunc, args) async {
        await downloadIsolateMain(args);
      };
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
    SharedPreferences.setMockInitialValues({});
    requestedPaths.clear();
  });

  // ---------------------------------------------------------------------------
  // SyncStatus
  // ---------------------------------------------------------------------------

  group('SyncStatus', () {
    test('deve começar como SyncStatus.updating', () {
      expect(syncService.syncStatus.value, SyncStatus.updating);
    });

    test('deve notificar ouvintes quando status muda', () {
      bool notified = false;
      syncService.syncStatus.addListener(() => notified = true);
      syncService.syncStatus.value = SyncStatus.updated;
      expect(notified, isTrue);
      expect(syncService.syncStatus.value, SyncStatus.updated);
    });

    test('deve cobrir todos os valores do enum', () {
      expect(
        SyncStatus.values,
        containsAll([
          SyncStatus.updated,
          SyncStatus.updating,
          SyncStatus.outdated,
          SyncStatus.error,
          SyncStatus.offline,
          SyncStatus.justUpdated,
          SyncStatus.noNewUpdates,
        ]),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // TopoDataset
  // ---------------------------------------------------------------------------

  group('TopoDataset', () {
    test('deve armazenar listas de picos corretamente', () {
      final available = [
        {'id': 'a', 'nome': 'Pico A'},
      ];
      final downloaded = [
        {'id': 'a', 'nome': 'Pico A', 'isDownloaded': true},
      ];

      final dataset = TopoDataset(
        availablePicos: available,
        downloadedPicos: downloaded,
      );

      expect(dataset.availablePicos.length, 1);
      expect(dataset.downloadedPicos.length, 1);
      expect(dataset.availablePicos.first['id'], 'a');
    });

    test('availablePicos e downloadedPicos são listas independentes', () {
      final dataset = TopoDataset(availablePicos: [], downloadedPicos: []);
      dataset.availablePicos.add({'id': 'novo'});
      expect(dataset.downloadedPicos, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Sincronização Delta (_updatePico indiretamente via syncIndex)
  // ---------------------------------------------------------------------------

  group('Sincronização Delta (_updatePico)', () {
    late Directory tempDir;
    late Directory downloadsDir;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      HttpOverrides.global = null;
      tempDir = await Directory.systemTemp.createTemp('sync_delta_test');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);

      // Setup EditorDeCroqui downloadsPath for tempDir
      downloadsDir = Directory(editor.downloadsPath(tempDir.path));
    });

    tearDown(() async {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('não baixa o croqui de novo se sha256sum é o mesmo', () async {
      final picoId = 'pico_hash_igual';

      final oldIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..checksumSha256Croqui = 'SAME_HASH',
        );
      final newIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..caminhoRelativo = 'picos/$picoId.binarypb'
            ..checksumSha256Croqui = 'SAME_HASH',
        );

      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

      final fakeClient = FakeClient(newIndice);
      final syncService =
          SyncService(datasetRepository: repo, client: fakeClient)
            ..mockIsolateSpawn = (mainFunc, args) async {
              await downloadIsolateMain(args);
            };

      await syncService.syncIndex();

      expect(requestedPaths.any((url) => url.contains('picos/')), isFalse);
    });

    test(
      'deve remover id de downloadingCrags mesmo se Isolate lançar exceção severa',
      () async {
        final picoId = 'pico_falho';
        final newIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..caminhoRelativo = 'picos/$picoId.binarypb'
              ..checksumSha256Croqui = 'HASH',
          );

        final fakeClient = FakeClient(newIndice);
        final syncService = SyncService(
          datasetRepository: repo,
          client: fakeClient,
        );

        syncService.mockIsolateSpawn = (mainFunc, args) async {
          args.sendPort.send(0.5);
          args.sendPort.send(Exception('Isolate crashed'));
        };

        await syncService.syncIndex();

        expect(syncService.downloadingCrags.value.containsKey(picoId), isFalse);
      },
    );

    test(
      'deve bloquear a aplicação atômica e gerar pendência se o pico_aberto_id for igual ao pico atualizado',
      () async {
        final picoId = 'pico_aberto_bloqueado';
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

        final picoDir = Directory('${downloadsDir.path}/$picoId');
        await picoDir.create(recursive: true);
        final oldPicoFile = File('${picoDir.path}/$picoId.binarypb');
        await oldPicoFile.writeAsBytes(Croqui().writeToBuffer());

        final fakeClient = FakeClient(newIndice);
        final syncService = SyncService(
          datasetRepository: repo,
          client: fakeClient,
        );

        syncService.mockIsolateSpawn = (mainFunc, args) async {
          // Mocking a successful download isolate result!
          File(
            '${picoDir.path}/$picoId.binarypb.tmp',
          ).createSync(recursive: true);
          args.sendPort.send(
            DownloadIsolateResult(
              filesToDelete: [],
              filesToRename: {
                '${picoDir.path}/$picoId.binarypb.tmp':
                    '${picoDir.path}/$picoId.binarypb',
              },
              newPicoDataBytes: Croqui().writeToBuffer(),
            ),
          );
        };

        // Simulamos que a interface tem esse pico aberto!
        syncService.pico_aberto_id.value = picoId;

        await syncService.syncIndex();

        // Verificamos que o pendente engatilhou
        expect(syncService.recarga_pendente_pico_id.value, picoId);

        // E garantimos que o .tmp NÂO foi renomeado atomaticamente para sobreescrever o real
        expect(
          File('${picoDir.path}/$picoId.binarypb.tmp').existsSync(),
          isTrue,
        );

        // Ao comitar a pendência, o arquivo é movido
        await syncService.commitPendenciasAtomaticas(picoId);
        expect(syncService.recarga_pendente_pico_id.value, isNull);
        expect(
          File('${picoDir.path}/$picoId.binarypb.tmp').existsSync(),
          isFalse,
        );
      },
    );

    test('não baixa arquivo externo de novo se checksum é o mesmo', () async {
      final picoId = 'pico_ext_igual';
      final picoDir = Directory('${downloadsDir.path}/$picoId');
      await picoDir.create(recursive: true);

      final fileToKeep = File('${picoDir.path}/imagem.webp');
      await fileToKeep.writeAsBytes([1]);

      final croqui = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno()
            ..caminho = 'imagem.webp'
            ..checksumSha256 = 'abc',
        );
      await File(
        '${picoDir.path}/$picoId.binarypb',
      ).writeAsBytes(croqui.writeToBuffer());

      final oldIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..checksumSha256Croqui = 'OLD_HASH',
        );
      final newIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..caminhoRelativo = 'picos/$picoId.binarypb'
            ..checksumSha256Croqui = 'NEW_HASH',
        );

      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croqui.writeToBuffer(),
      });
      final syncService =
          SyncService(datasetRepository: repo, client: fakeClient)
            ..mockIsolateSpawn = (mainFunc, args) async {
              await downloadIsolateMain(args);
            };

      await syncService.syncIndex();

      expect(
        requestedPaths,
        isNot(contains(matches(RegExp(r'imagem\.webp$')))),
      );
      expect(fileToKeep.existsSync(), isTrue);
    });

    test('baixa arquivo externo de novo se checksum mudou', () async {
      final picoId = 'pico_ext_mudou';
      final picoDir = Directory('${downloadsDir.path}/$picoId');
      await picoDir.create(recursive: true);

      final fileToUpdate = File('${picoDir.path}/imagem.webp');
      await fileToUpdate.writeAsBytes([1]);

      final oldCroqui = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno()
            ..caminho = 'imagem.webp'
            ..checksumSha256 = 'OLD_HASH',
        );
      await File(
        '${picoDir.path}/$picoId.binarypb',
      ).writeAsBytes(oldCroqui.writeToBuffer());

      final oldIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..checksumSha256Croqui = 'OLD_CROQUI_HASH',
        );
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());
      final newCroqui = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno()
            ..caminho = 'imagem.webp'
            ..checksumSha256 = sha256.convert([2]).toString(),
        );

      final newIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..caminhoRelativo = 'picos/$picoId.binarypb'
            ..checksumSha256Croqui = sha256
                .convert(newCroqui.writeToBuffer())
                .toString(),
        );

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': newCroqui.writeToBuffer(),
        'picos/imagem.webp': [2],
      });
      final syncService =
          SyncService(datasetRepository: repo, client: fakeClient)
            ..mockIsolateSpawn = (mainFunc, args) async {
              await downloadIsolateMain(args);
            };

      await syncService.syncIndex();

      expect(requestedPaths.any((url) => url.contains('imagem.webp')), isTrue);
      expect(await fileToUpdate.readAsBytes(), equals([2]));
    });

    test('deleta arquivos removidos em nova versão', () async {
      final picoId = 'pico_ext_removido';
      final picoDir = Directory('${downloadsDir.path}/$picoId');
      await picoDir.create(recursive: true);

      final fileToDelete = File('${picoDir.path}/removida.webp');
      await fileToDelete.writeAsBytes([1]);

      final oldCroqui = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno()
            ..caminho = 'removida.webp'
            ..checksumSha256 = 'abc',
        );
      await File(
        '${picoDir.path}/$picoId.binarypb',
      ).writeAsBytes(oldCroqui.writeToBuffer());

      final oldIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..checksumSha256Croqui = 'OLD_CROQUI_HASH',
        );
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());
      final newCroqui = Croqui(); // Sem arquivos externos

      final newIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..caminhoRelativo = 'picos/$picoId.binarypb'
            ..checksumSha256Croqui = sha256
                .convert(newCroqui.writeToBuffer())
                .toString(),
        );

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': newCroqui.writeToBuffer(),
      });
      final syncService =
          SyncService(datasetRepository: repo, client: fakeClient)
            ..mockIsolateSpawn = (mainFunc, args) async {
              await downloadIsolateMain(args);
            };

      await syncService.syncIndex();

      expect(fileToDelete.existsSync(), isFalse);
    });

    test(
      'baixa novos arquivos que não estavam presentes em versão anterior',
      () async {
        final picoId = 'pico_ext_novo';
        final picoDir = Directory('${downloadsDir.path}/$picoId');
        await picoDir.create(recursive: true);

        final oldCroqui = Croqui(); // Sem arquivos
        await File(
          '${picoDir.path}/$picoId.binarypb',
        ).writeAsBytes(oldCroqui.writeToBuffer());

        final oldIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..checksumSha256Croqui = 'OLD_CROQUI_HASH',
          );
        final indiceFile = File(editor.indicePath(tempDir.path));
        await indiceFile.parent.create(recursive: true);
        await indiceFile.writeAsBytes(oldIndice.writeToBuffer());
        final newCroqui = Croqui()
          ..arquivosExternos.add(
            ArquivoExterno()
              ..caminho = 'nova.webp'
              ..checksumSha256 = sha256.convert([3]).toString(),
          );

        final newIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..caminhoRelativo = 'picos/$picoId.binarypb'
              ..checksumSha256Croqui = sha256
                  .convert(newCroqui.writeToBuffer())
                  .toString(),
          );

        final fakeClient = FakeClient(newIndice, {
          'picos/$picoId.binarypb': newCroqui.writeToBuffer(),
          'picos/nova.webp': [3],
        });
        final syncService =
            SyncService(datasetRepository: repo, client: fakeClient)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        await syncService.syncIndex();

        // Cache-Busting Verification
        final expectedHash = sha256
            .convert(newCroqui.writeToBuffer())
            .toString();
        print('requestedPaths: $requestedPaths');
        final fullUrl = requestedPaths.firstWhere(
          (u) => u.contains('$picoId.binarypb'),
        );
        expect(
          fullUrl,
          contains('?v='),
          reason: 'A URL do arquivo deve ter o furador de cache ?v=',
        );
        expect(
          fullUrl,
          contains(expectedHash),
          reason:
              'A URL deve ter o hash real do croqui para furar o cache da CDN',
        );

        // Sync External Files Verification
        expect(requestedPaths.any((url) => url.contains('nova.webp')), isTrue);
        expect(File('${picoDir.path}/nova.webp').existsSync(), isTrue);
      },
    );

    test('tudo ao mesmo tempo (atualiza, deleta, insere e mantem)', () async {
      final picoId = 'pico_tudo';
      final picoDir = Directory('${downloadsDir.path}/$picoId');
      await picoDir.create(recursive: true);

      final fileToKeep = File('${picoDir.path}/mantida.webp');
      final fileToUpdate = File('${picoDir.path}/atualizada.webp');
      final fileToDelete = File('${picoDir.path}/removida.webp');
      await fileToKeep.writeAsBytes([1]);
      await fileToUpdate.writeAsBytes([2]);
      await fileToDelete.writeAsBytes([3]);

      final oldCroqui = Croqui()
        ..arquivosExternos.addAll([
          ArquivoExterno()
            ..caminho = 'mantida.webp'
            ..checksumSha256 = 'A',
          ArquivoExterno()
            ..caminho = 'atualizada.webp'
            ..checksumSha256 = 'B',
          ArquivoExterno()
            ..caminho = 'removida.webp'
            ..checksumSha256 = 'C',
        ]);
      await File(
        '${picoDir.path}/$picoId.binarypb',
      ).writeAsBytes(oldCroqui.writeToBuffer());

      final oldIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..checksumSha256Croqui = 'OLD_CROQUI_HASH',
        );
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());
      final newCroqui = Croqui()
        ..arquivosExternos.addAll([
          ArquivoExterno()
            ..caminho = 'mantida.webp'
            ..checksumSha256 = 'A',
          ArquivoExterno()
            ..caminho = 'atualizada.webp'
            ..checksumSha256 = sha256.convert([22]).toString(),
          ArquivoExterno()
            ..caminho = 'nova.webp'
            ..checksumSha256 = sha256.convert([44]).toString(),
        ]);

      final newIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..caminhoRelativo = 'picos/$picoId.binarypb'
            ..checksumSha256Croqui = sha256
                .convert(newCroqui.writeToBuffer())
                .toString(),
        );

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': newCroqui.writeToBuffer(),
        'picos/atualizada.webp': [22],
        'picos/nova.webp': [44],
      });
      final syncService =
          SyncService(datasetRepository: repo, client: fakeClient)
            ..mockIsolateSpawn = (mainFunc, args) async {
              await downloadIsolateMain(args);
            };

      await syncService.syncIndex();

      expect(fileToKeep.existsSync(), isTrue);
      expect(fileToDelete.existsSync(), isFalse);
      expect(File('${picoDir.path}/nova.webp').existsSync(), isTrue);
      expect(await fileToUpdate.readAsBytes(), equals([22]));

      expect(
        requestedPaths,
        isNot(contains(matches(RegExp(r'mantida\.webp$')))),
      );
    });

    test(
      'sobrevive a breaking changes (oldPicoData corrompido) varrendo a pasta para deletar orfaos e validando hash local',
      () async {
        final picoId = 'pico_breaking_change';
        final picoDir = Directory('${downloadsDir.path}/$picoId');
        await picoDir.create(recursive: true);

        // Simula uma foto órfã que DEVE ser deletada (pois não está no novo croqui)
        final orfanFile = File('${picoDir.path}/orfan.webp');
        await orfanFile.writeAsBytes([9, 9]);

        // Simula uma foto válida que JÁ ESTÁ no disco e o hash bate
        final validFile = File('${picoDir.path}/valida.webp');
        await validFile.writeAsBytes([7, 7]);

        // Escreve um arquivo binário corrompido (simulando um protobuf incompatível antigo)
        await File(
          '${picoDir.path}/$picoId.binarypb',
        ).writeAsBytes([255, 255, 255, 255]);

        final oldIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..checksumSha256Croqui = 'OLD_CROQUI_HASH',
          );
        final indiceFile = File(editor.indicePath(tempDir.path));
        await indiceFile.parent.create(recursive: true);
        await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

        final newCroqui = Croqui()
          ..arquivosExternos.addAll([
            ArquivoExterno()
              ..caminho = 'valida.webp'
              ..checksumSha256 = sha256.convert([7, 7]).toString(),
            ArquivoExterno()
              ..caminho = 'nova.webp'
              ..checksumSha256 = sha256.convert([44]).toString(),
          ]);

        final newIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..caminhoRelativo = 'picos/$picoId.binarypb'
              ..checksumSha256Croqui = sha256
                  .convert(newCroqui.writeToBuffer())
                  .toString(),
          );

        // Note que a "valida.webp" NÃO está no FakeClient, para garantir que não vamos tentar baixá-la!
        // Se tentarmos baixar e der erro, o sync vai falhar, provando que o hash check local não funcionou.
        final fakeClient = FakeClient(newIndice, {
          'picos/$picoId.binarypb': newCroqui.writeToBuffer(),
          'picos/nova.webp': [44],
        });
        final syncServiceFake =
            SyncService(datasetRepository: repo, client: fakeClient)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        await syncServiceFake.syncIndex();

        // Arquivo órfão não está na nova estrutura e o oldPicoData não foi lido, então a rotina nova deve ter feito o scan.
        expect(
          orfanFile.existsSync(),
          isFalse,
          reason: 'Arquivo orfao deveria ter sido deletado via directory scan',
        );

        // Arquivo válido deve ter sido mantido sem download.
        expect(
          validFile.existsSync(),
          isTrue,
          reason: 'Arquivo valido deveria ter sido mantido',
        );
        expect(
          requestedPaths.any((url) => url.contains('valida.webp')),
          isFalse,
          reason: 'O arquivo valido NAO deve ter sido baixado',
        );

        // Novo arquivo deve ser baixado
        expect(
          File('${picoDir.path}/nova.webp').existsSync(),
          isTrue,
          reason: 'Arquivo novo deve ter sido baixado',
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Sincronização de Thumbnails Globais (Explorar)
  // ---------------------------------------------------------------------------

  group('Sincronização de Thumbnails Globais', () {
    late Directory tempDir;
    late Directory thumbnailsDir;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      HttpOverrides.global = null;
      tempDir = await Directory.systemTemp.createTemp('sync_thumbnails_test');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
      thumbnailsDir = Directory('${tempDir.path}/thumbnails');
    });

    tearDown(() async {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test(
      'deve baixar thumbnails novas para picos listados no indice, mesmo se o pico nao estiver baixado',
      () async {
        final oldIndice = Indice(); // Indice vazio antigo
        final newIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = 'pico_thumb'
              ..checksumSha256Thumbnail = sha256.convert([10]).toString(),
          );

        final fakeClient = FakeClient(newIndice, {
          'thumbnails/pico_thumb.webp': [10],
        });
        final syncService =
            SyncService(datasetRepository: repo, client: fakeClient)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        await syncService.syncIndex();

        // Verifica que a URL da thumbnail foi requisitada com ?v=
        final expectedHash = sha256.convert([10]).toString();
        final thumbUrl = fakeClient.requestedFullUrls.firstWhere(
          (u) => u.contains('pico_thumb.webp'),
          orElse: () => '',
        );
        expect(
          thumbUrl,
          isNotEmpty,
          reason: 'A thumbnail deveria ter sido baixada',
        );
        expect(thumbUrl, contains('?v=$expectedHash'));

        // Verifica que o arquivo foi salvo no disco
        final thumbFile = File('${thumbnailsDir.path}/pico_thumb.webp');
        expect(
          thumbFile.existsSync(),
          isTrue,
          reason: 'O arquivo da thumbnail deve existir no cache local',
        );
        expect(await thumbFile.readAsBytes(), equals([10]));
      },
    );

    test('deve ignorar thumbnails que não mudaram de hash', () async {
      final picoId = 'pico_thumb_same';
      final fileHash = sha256.convert([11]).toString();

      // Cria a thumbnail antiga
      await thumbnailsDir.create(recursive: true);
      await File('${thumbnailsDir.path}/$picoId.webp').writeAsBytes([11]);

      final oldIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..checksumSha256Thumbnail = fileHash,
        );

      final newIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..checksumSha256Thumbnail = fileHash,
        );

      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

      final fakeClient = FakeClient(newIndice, {
        'thumbnails/$picoId.webp': [11], // Mock pra caso tente baixar
      });
      final syncService =
          SyncService(datasetRepository: repo, client: fakeClient)
            ..mockIsolateSpawn = (mainFunc, args) async {
              await downloadIsolateMain(args);
            };

      await syncService.syncIndex();

      // Nenhuma thumbnail deveria ser requisitada
      expect(requestedPaths.any((url) => url.contains('.webp')), isFalse);
    });

    test(
      'deve deletar thumbnails órfãs que estavam no índice antigo mas não no novo',
      () async {
        final picoIdRemovido = 'pico_removido';
        final picoIdMantido = 'pico_mantido';

        // Cria thumbnails locais para simular cache existente
        await thumbnailsDir.create(recursive: true);
        final thumbRemovida = File(
          '${thumbnailsDir.path}/$picoIdRemovido.webp',
        );
        final thumbMantida = File('${thumbnailsDir.path}/$picoIdMantido.webp');

        await thumbRemovida.writeAsBytes([1]);
        await thumbMantida.writeAsBytes([2]);

        // Índice antigo possuía os dois picos
        final oldIndice = Indice(
          croquis: [
            ResumoCroqui(id: picoIdRemovido, checksumSha256Thumbnail: 'hash1'),
            ResumoCroqui(id: picoIdMantido, checksumSha256Thumbnail: 'hash2'),
          ],
        );

        // Novo índice não possui o pico removido
        final newIndice = Indice(
          croquis: [
            ResumoCroqui(id: picoIdMantido, checksumSha256Thumbnail: 'hash2'),
          ],
        );

        final indiceFile = File(editor.indicePath(tempDir.path));
        await indiceFile.parent.create(recursive: true);
        await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

        final fakeClient = FakeClient(newIndice, {});
        final syncService =
            SyncService(datasetRepository: repo, client: fakeClient)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        await syncService.syncIndex();

        // Thumbnail removida deve ter sido apagada do disco
        expect(
          thumbRemovida.existsSync(),
          isFalse,
          reason: 'Thumbnail do pico removido deveria ser apagada',
        );
        // Thumbnail mantida deve continuar no disco
        expect(
          thumbMantida.existsSync(),
          isTrue,
          reason: 'Thumbnail do pico mantido deve permanecer no disco',
        );
      },
    );

    test(
      'não deve deletar thumbnails órfãs nem efetivar updates atômicos se houver falha parcial no download',
      () async {
        final picoIdRemovido = 'pico_removido';
        final picoIdComErro = 'pico_com_erro';

        // Cria thumbnail local para simular arquivo que DEVERIA ser apagado
        await thumbnailsDir.create(recursive: true);
        final thumbRemovida = File(
          '${thumbnailsDir.path}/$picoIdRemovido.webp',
        );
        await thumbRemovida.writeAsBytes([1]);

        // Índice antigo possuía o pico a ser removido
        final oldIndice = Indice(
          croquis: [
            ResumoCroqui(id: picoIdRemovido, checksumSha256Thumbnail: 'hash1'),
          ],
        );

        // Novo índice não possui o pico removido, mas adiciona um que dará erro no download
        final newIndice = Indice(
          croquis: [
            ResumoCroqui(
              id: picoIdComErro,
              checksumSha256Thumbnail: 'hash2_erro',
            ),
          ],
        );

        final indiceFile = File(editor.indicePath(tempDir.path));
        await indiceFile.parent.create(recursive: true);
        await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

        final mockClient = FakeClient(newIndice, {});

        final syncService =
            SyncService(datasetRepository: repo, client: mockClient)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        await syncService.syncIndex();

        expect(
          thumbRemovida.existsSync(),
          isTrue,
          reason:
              'Thumbnail órfã NÃO deve ser apagada devido à falha de download no SyncUpdates',
        );
        expect(
          syncService.syncStatus.value,
          SyncStatus.error,
          reason: 'Status deve refletir o erro do syncIndex',
        );
        expect(
          mockTelemetry.recordedEvents,
          contains('resultado_sincronizacao'),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // SyncOnLaunch Order of Operations
  // ---------------------------------------------------------------------------

  group('SyncOnLaunch order of operations', () {
    late Directory tempDir;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      HttpOverrides.global = null;
      tempDir = Directory.systemTemp.createTempSync('sync_test');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (e) {
        // Ignora erros de deleção no Windows (arquivos em uso, etc)
      }
    });

    test(
      'deve forcar o update de picos armazenados localmente se o indice antigo estiver corrompido (breaking change)',
      () async {
        // 1. Setup local files: um indice corrompido
        final indicePath = editor.indicePath(tempDir.path);
        final indiceFile = File(indicePath);
        indiceFile.parent.createSync(recursive: true);
        // Escreve bytes corrompidos
        indiceFile.writeAsBytesSync([255, 255, 255]);

        // 2. Simula que o usuário JÁ TEM o pico baixado no celular
        final picoFile = File(
          '${editor.downloadsPath(tempDir.path)}/pico_orfao/pico_orfao.binarypb',
        );
        picoFile.parent.createSync(recursive: true);
        picoFile.writeAsBytesSync([
          1,
          2,
          3,
        ]); // dummy content, só pra existir no disco

        // 3. Setup mock client returning NEW index com o tal pico
        final newCroqui = Croqui(); // vazio
        final newIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = 'pico_orfao'
              ..caminhoRelativo = 'picos/pico_orfao.binarypb'
              ..checksumSha256Croqui = 'NEW_CHECKSUM',
          );

        final fakeClient = FakeClient(newIndice, {
          'picos/pico_orfao.binarypb': newCroqui.writeToBuffer(),
        });
        final syncService =
            SyncService(datasetRepository: repo, client: fakeClient)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        // We must not be in experimental mode for _checkForUpdates to run
        editor.isExperimentalMode.value = false;

        // 4. Run sync
        await syncService.syncIndex();

        // 5. Verifica se o FakeClient foi acionado para tentar baixar o `pico_orfao.binarypb`
        // Isso prova que mesmo com o Indice antigo sendo ilegível, ele forçou a atualização do pico local!
        expect(
          requestedPaths.any((url) => url.contains('pico_orfao.binarypb')),
          isTrue,
          reason:
              'O pico deve ser atualizado compulsoriamente se o indice local for ilegível/ausente',
        );
      },
    );

    test(
      'deve manter o indice antigo se o download do pico falhar (não atualiza o indice cedo demais)',
      () async {
        // 1. Setup local files
        final oldIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = 'pico1'
              ..checksumSha256Croqui = 'OLD_CHECKSUM',
          );

        final indicePath = editor.indicePath(tempDir.path);
        final indiceFile = File(indicePath);
        indiceFile.parent.createSync(recursive: true);
        indiceFile.writeAsBytesSync(oldIndice.writeToBuffer());

        // Simulate that the pico is downloaded
        final picoFile = File(
          '${editor.downloadsPath(tempDir.path)}/pico1/pico1.binarypb',
        );
        picoFile.parent.createSync(recursive: true);
        picoFile.writeAsBytesSync([1, 2, 3]); // dummy content

        // 2. Setup mock client returning NEW index
        final newIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = 'pico1'
              ..caminhoRelativo = 'picos/pico1.binarypb'
              ..checksumSha256Croqui = 'NEW_CHECKSUM',
          );

        final fakeClient = FakeClient(newIndice);
        final syncService =
            SyncService(datasetRepository: repo, client: fakeClient)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        // We must not be in experimental mode for _checkForUpdates to run
        editor.isExperimentalMode.value = false;

        // 3. Run sync
        await syncService.syncIndex();

        // 4. Verify that local indice is STILL the old one because the download failed
        final finalBytes = indiceFile.readAsBytesSync();
        final finalIndice = Indice.fromBuffer(finalBytes);

        expect(
          finalIndice.croquis.first.checksumSha256Croqui,
          'OLD_CHECKSUM',
          reason:
              'O índice não deve ser sobrescrito se houver erro ou interrupção no download do pico.',
        );
      },
    );

    test(
      'deve definir syncStatus para offline se falhar ao buscar o indice.binarypb na nuvem',
      () async {
        // Simula uma falha de rede completa para fetchIndiceWithRetries retornar null
        final errorClient = _ErrorClient();
        final syncService =
            SyncService(datasetRepository: repo, client: errorClient)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        await syncService.syncIndex();

        expect(
          syncService.syncStatus.value,
          SyncStatus.offline,
          reason:
              'Se o fetch falhar, o status final deve ser offline, em vez de erro.',
        );
        expect(
          mockTelemetry.recordedEvents,
          contains('resultado_sincronizacao'),
        );
      },
    );

    test(
      'deve tentar bypass de cache se a atualizacao de picos falhar (failedPicos.isNotEmpty) e forceBypassCache for falso',
      () async {
        // 1. Setup local files: um indice velho
        final picoId = 'pico_stale';
        final croqui = Croqui();
        final croquiBytes = croqui.writeToBuffer();
        final correctHash = sha256.convert(croquiBytes).toString();
        final staleHash = 'STALE_OUTDATED_HASH';

        final oldIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..checksumSha256Croqui = 'OLD_LOCAL_HASH',
          );

        final indicePath = editor.indicePath(tempDir.path);
        final indiceFile = File(indicePath);
        indiceFile.parent.createSync(recursive: true);
        indiceFile.writeAsBytesSync(oldIndice.writeToBuffer());

        final picoFile = File(
          '${editor.downloadsPath(tempDir.path)}/$picoId/$picoId.binarypb',
        );
        picoFile.parent.createSync(recursive: true);
        picoFile.writeAsBytesSync([1, 2, 3]);

        // 2. Setup mock client:
        // - Sem ?t=, ele retorna o staleIndice (onde o pico tem staleHash). O download vai falhar pois servimos correctHash.
        // - Com ?t=, ele retorna o freshIndice (onde o pico tem correctHash). O download vai ter sucesso.
        final staleIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..caminhoRelativo = 'picos/$picoId.binarypb'
              ..checksumSha256Croqui = staleHash,
          );

        final freshIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..caminhoRelativo = 'picos/$picoId.binarypb'
              ..checksumSha256Croqui = correctHash,
          );

        final fakeClient = FakeClient(
          staleIndice,
          {'picos/$picoId.binarypb': croquiBytes},
          null,
          freshIndice,
        );

        final syncServiceFake =
            SyncService(datasetRepository: repo, client: fakeClient)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        // We must not be in experimental mode for _checkForUpdates to run
        editor.isExperimentalMode.value = false;

        // 3. Run sync
        final failed = await syncServiceFake.syncIndex();

        // 4. Verify that failedPicos is ultimately empty because the bypass succeeded!
        expect(
          failed,
          isEmpty,
          reason:
              'O fallback com bypass de cache deve resolver a falha e retornar lista vazia.',
        );

        // Verify that local indice is NOW the fresh one
        final finalBytes = indiceFile.readAsBytesSync();
        final finalIndice = Indice.fromBuffer(finalBytes);

        expect(
          finalIndice.croquis.first.checksumSha256Croqui,
          correctHash,
          reason:
              'O índice deve ser sobrescrito pelo freshIndice após o sucesso do fallback.',
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // SyncOnLaunch ETag e Caching
  // ---------------------------------------------------------------------------

  group('SyncOnLaunch ETag e Caching', () {
    late Directory tempDir;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      HttpOverrides.global = null;
      tempDir = Directory.systemTemp.createTempSync('sync_etag_test');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('deve salvar etag ao baixar indice.binarypb com sucesso', () async {
      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = 'pico1');
      final fakeClient = FakeClient(newIndice, {}, 'mock_etag_123');
      final syncServiceFake =
          SyncService(datasetRepository: repo, client: fakeClient)
            ..mockIsolateSpawn = (mainFunc, args) async {
              await downloadIsolateMain(args);
            };

      await syncServiceFake.syncIndex();

      final etagFile = File('${editor.indicePath(tempDir.path)}.etag');
      expect(etagFile.existsSync(), isTrue);
      expect(etagFile.readAsStringSync(), 'mock_etag_123');
    });

    test(
      'deve enviar If-None-Match e processar 304 Not Modified corretamente',
      () async {
        final newIndice = Indice()
          ..croquis.add(ResumoCroqui()..id = 'pico_fake_nao_deve_baixar');
        final fakeClient = FakeClient(newIndice, {}, 'mock_etag_123');
        final syncServiceFake =
            SyncService(datasetRepository: repo, client: fakeClient)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        final indiceFile = File(editor.indicePath(tempDir.path));
        indiceFile.parent.createSync(recursive: true);
        indiceFile.writeAsBytesSync(Indice().writeToBuffer());

        final etagFile = File('${editor.indicePath(tempDir.path)}.etag');
        etagFile.writeAsStringSync('mock_etag_123');

        await syncServiceFake.syncIndex();

        expect(fakeClient.receivedHeaders['If-None-Match'], 'mock_etag_123');

        final finalBytes = indiceFile.readAsBytesSync();
        final finalIndice = Indice.fromBuffer(finalBytes);
        expect(
          finalIndice.croquis,
          isEmpty,
          reason: 'Nao deve sobrescrever indice se retornou 304',
        );
        expect(
          syncServiceFake.syncStatus.value,
          equals(SyncStatus.noNewUpdates),
        );
        expect(
          mockTelemetry.recordedEvents,
          contains('resultado_sincronizacao'),
        );
      },
    );

    test(
      'nao deve recarregar DatasetRepo em memoria se ja estiver carregado e retornar 304',
      () async {
        final fakeClient = FakeClient(Indice(), {}, 'mock_etag_123');
        final syncServiceFake =
            SyncService(datasetRepository: repo, client: fakeClient)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        final etagFile = File('${editor.indicePath(tempDir.path)}.etag');
        etagFile.parent.createSync(recursive: true);
        etagFile.writeAsStringSync('mock_etag_123');

        // Força estar carregado
        repo.activeDataset.value = TopoDataset(
          availablePicos: [],
          downloadedPicos: [],
        );
        final resetCountBefore = repo.homeResetTrigger.value;

        await syncServiceFake.syncIndex();

        expect(
          repo.homeResetTrigger.value,
          equals(resetCountBefore),
          reason: 'Nao deve recarregar no 304 se ja tem activeDataset',
        );
      },
    );
  });

  group('downloadingCrags', () {
    test('começa vazio', () {
      expect(syncService.downloadingCrags.value, isEmpty);
    });
  });

  group('downloadCrag', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('sync_download_test');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('deve baixar o croqui e seus arquivos externos com sucesso', () async {
      final picoId = 'pico_teste';
      final croqui = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno()
            ..caminho = 'imagens/capa.webp'
            ..checksumSha256 = sha256.convert([1, 2, 3]).toString(),
        );

      final newIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..caminhoRelativo = 'picos/$picoId.binarypb'
            ..checksumSha256Croqui = sha256
                .convert(croqui.writeToBuffer())
                .toString(),
        );

      final client = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croqui.writeToBuffer(),
        'picos/imagens/capa.webp': [1, 2, 3],
      });

      editor.editorUrl.value =
          'http://${localServer.address.address}:${localServer.port}/v3';

      repo = DatasetRepository(editorDeCroqui: editor);
      final syncServiceFake =
          SyncService(datasetRepository: repo, client: client)
            ..mockIsolateSpawn = (mainFunc, args) async {
              await downloadIsolateMain(args);
            };

      repo.indiceData.value = newIndice;

      final result = await syncServiceFake.downloadCrag(
        newIndice.croquis.first,
      );

      expect(result, isTrue);

      final downloadsDir = editor.downloadsPath(tempDir.path);
      final picoDir = Directory('$downloadsDir/$picoId');

      expect(File('${picoDir.path}/$picoId.binarypb').existsSync(), isTrue);
      expect(File('${picoDir.path}/imagens/capa.webp').existsSync(), isTrue);
    });

    test('deve acionar a telemetria ao fazer download', () async {
      final picoId = 'pico_telemetria';
      final croqui = Croqui();

      final newIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..caminhoRelativo = 'picos/$picoId.binarypb'
            ..checksumSha256Croqui = sha256
                .convert(croqui.writeToBuffer())
                .toString(),
        );

      final client = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croqui.writeToBuffer(),
      });

      editor.editorUrl.value =
          'http://${localServer.address.address}:${localServer.port}/v3';

      repo = DatasetRepository(editorDeCroqui: editor);
      final syncServiceFake =
          SyncService(datasetRepository: repo, client: client)
            ..mockIsolateSpawn = (mainFunc, args) async {
              await downloadIsolateMain(args);
            };

      repo.indiceData.value = newIndice;

      final result = await syncServiceFake.downloadCrag(
        newIndice.croquis.first,
      );

      expect(result, isTrue);
      expect(mockTelemetry.recordedEvents, contains('acao_explorar'));
      expect(mockTelemetry.recordedParams['acao_explorar']?['acao'], 'baixar');
      expect(
        mockTelemetry.recordedParams['acao_explorar']?['id_croqui'],
        picoId,
      );
    });

    test(
      'deve atualizar o indice se estiver desatualizado e usar o novo hash para o download',
      () async {
        final picoId = 'pico_race_condition';
        final croqui = Croqui();
        final correctHash = sha256.convert(croqui.writeToBuffer()).toString();

        final oldIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..caminhoRelativo = 'picos/$picoId.binarypb'
              ..checksumSha256Croqui = 'OLD_OUTDATED_HASH',
          );

        final newIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..caminhoRelativo = 'picos/$picoId.binarypb'
              ..checksumSha256Croqui = correctHash,
          );

        // O FakeClient possui o novo índice e o arquivo correto (que bate com correctHash)
        final client = FakeClient(newIndice, {
          'picos/$picoId.binarypb': croqui.writeToBuffer(),
        });

        editor.editorUrl.value =
            'http://${localServer.address.address}:${localServer.port}/v3';
        repo = DatasetRepository(editorDeCroqui: editor);
        final syncServiceFake =
            SyncService(datasetRepository: repo, client: client)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        // O app localmente acha que tem o OLD_HASH
        repo.indiceData.value = oldIndice;

        final result = await syncServiceFake.downloadCrag(
          newIndice.croquis.first,
        );

        // Se a prevenção de race condition funcionar, ele vai:
        // 1. Chamar syncIndex, que baixa newIndice
        // 2. Extrair o ResumoCroqui com correctHash
        // 3. Baixar e validar o arquivo contra correctHash, e não OLD_OUTDATED_HASH!
        expect(result, isTrue);
      },
    );

    test('deve falhar se o download do croqui tiver sha256 inválido', () async {
      final picoId = 'pico_invalido';
      final croqui = Croqui();
      final newIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..caminhoRelativo = 'picos/$picoId.binarypb'
            ..checksumSha256Croqui = 'hash_completamente_errado',
        );

      final client = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croqui.writeToBuffer(),
      });
      editor.editorUrl.value =
          'http://${localServer.address.address}:${localServer.port}/v3';
      repo = DatasetRepository(editorDeCroqui: editor);
      final syncServiceFake =
          SyncService(datasetRepository: repo, client: client)
            ..mockIsolateSpawn = (mainFunc, args) async {
              await downloadIsolateMain(args);
            };

      repo.indiceData.value = newIndice;

      final result = await syncServiceFake.downloadCrag(
        newIndice.croquis.first,
      );

      expect(result, isFalse);
    });

    test('deve retomar de um arquivo .tmp válido e pular o download', () async {
      final picoId = 'pico_resume_valido';
      final fileData = [1, 2, 3, 4];
      final fileHash = sha256.convert(fileData).toString();

      final croqui = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno()
            ..caminho = 'capa.webp'
            ..checksumSha256 = fileHash,
        );
      final croquiBytes = croqui.writeToBuffer();

      final newIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..caminhoRelativo = 'picos/$picoId.binarypb'
            ..checksumSha256Croqui = sha256.convert(croquiBytes).toString(),
        );

      // We serve the main croqui, but DO NOT serve capa.webp!
      // If it tries to download capa.webp, it will fail (because FakeClient will return 404/error).
      final client = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croquiBytes,
      });

      editor.editorUrl.value =
          'http://${localServer.address.address}:${localServer.port}/v3';
      repo = DatasetRepository(editorDeCroqui: editor);
      final syncServiceFake =
          SyncService(datasetRepository: repo, client: client)
            ..mockIsolateSpawn = (mainFunc, args) async {
              await downloadIsolateMain(args);
            };

      repo.indiceData.value = newIndice;

      final downloadsDir = editor.downloadsPath(tempDir.path);
      final picoDir = Directory('$downloadsDir/$picoId');
      picoDir.createSync(recursive: true);

      // Create valid .tmp file manually for the arquivo externo
      final tmpFile = File('${picoDir.path}/capa.webp.tmp');
      tmpFile.writeAsBytesSync(fileData);

      final result = await syncServiceFake.downloadCrag(
        newIndice.croquis.first,
      );

      expect(result, isTrue);
      // Main croqui should be downloaded
      expect(File('${picoDir.path}/$picoId.binarypb').existsSync(), isTrue);
      // The tmp file should have been renamed to final file
      expect(File('${picoDir.path}/capa.webp').existsSync(), isTrue);
      expect(tmpFile.existsSync(), isFalse);
    });

    test('deve descartar arquivo .tmp inválido e fazer novo download', () async {
      final picoId = 'pico_resume_invalido';
      final fileData = [1, 2, 3, 4];
      final fileHash = sha256.convert(fileData).toString();

      final croqui = Croqui()
        ..arquivosExternos.add(
          ArquivoExterno()
            ..caminho = 'capa.webp'
            ..checksumSha256 = fileHash,
        );
      final croquiBytes = croqui.writeToBuffer();

      final newIndice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = picoId
            ..caminhoRelativo = 'picos/$picoId.binarypb'
            ..checksumSha256Croqui = sha256.convert(croquiBytes).toString(),
        );

      // We serve BOTH the croqui and the capa.webp, because it needs to redownload capa.webp.
      final client = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croquiBytes,
        'picos/capa.webp': fileData,
      });

      editor.editorUrl.value =
          'http://${localServer.address.address}:${localServer.port}/v3';
      repo = DatasetRepository(editorDeCroqui: editor);
      final syncServiceFake =
          SyncService(datasetRepository: repo, client: client)
            ..mockIsolateSpawn = (mainFunc, args) async {
              await downloadIsolateMain(args);
            };

      repo.indiceData.value = newIndice;

      final downloadsDir = editor.downloadsPath(tempDir.path);
      final picoDir = Directory('$downloadsDir/$picoId');
      picoDir.createSync(recursive: true);

      // Create INVALID .tmp file manually
      final tmpFile = File('${picoDir.path}/capa.webp.tmp');
      tmpFile.writeAsBytesSync([9, 9, 9, 9]); // Junk bytes

      final result = await syncServiceFake.downloadCrag(
        newIndice.croquis.first,
      );

      expect(result, isTrue);
      // Main croqui should be downloaded
      expect(File('${picoDir.path}/$picoId.binarypb').existsSync(), isTrue);
      // The tmp file should be deleted and final file downloaded correctly
      expect(File('${picoDir.path}/capa.webp').existsSync(), isTrue);
      expect(tmpFile.existsSync(), isFalse);

      final downloadedBytes = File(
        '${picoDir.path}/capa.webp',
      ).readAsBytesSync();
      expect(downloadedBytes, fileData);
    });

    test(
      'deve retomar o croqui principal de um arquivo .tmp válido e pular o download',
      () async {
        final picoId = 'pico_principal_resume_valido';
        final croqui = Croqui(); // empty for simplicity
        final croquiBytes = croqui.writeToBuffer();
        final croquiHash = sha256.convert(croquiBytes).toString();

        final newIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..caminhoRelativo = 'picos/$picoId.binarypb'
              ..checksumSha256Croqui = croquiHash,
          );

        // We DO NOT serve the croqui from FakeClient. If it tries to download, it will fail!
        final client = FakeClient(newIndice, {});

        editor.editorUrl.value =
            'http://${localServer.address.address}:${localServer.port}/v3';
        repo = DatasetRepository(editorDeCroqui: editor);
        final syncServiceFake =
            SyncService(datasetRepository: repo, client: client)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        repo.indiceData.value = newIndice;

        final downloadsDir = editor.downloadsPath(tempDir.path);
        final picoDir = Directory('$downloadsDir/$picoId');
        picoDir.createSync(recursive: true);

        // Create valid .tmp file manually for the main croqui
        final tmpFile = File('${picoDir.path}/$picoId.binarypb.tmp');
        tmpFile.writeAsBytesSync(croquiBytes);

        final result = await syncServiceFake.downloadCrag(
          newIndice.croquis.first,
        );

        expect(result, isTrue);
        expect(File('${picoDir.path}/$picoId.binarypb').existsSync(), isTrue);
        expect(tmpFile.existsSync(), isFalse); // tmp should be renamed
      },
    );

    test(
      'deve descartar arquivo .tmp inválido do croqui principal e fazer novo download',
      () async {
        final picoId = 'pico_principal_resume_invalido';
        final croqui = Croqui();
        final croquiBytes = croqui.writeToBuffer();
        final croquiHash = sha256.convert(croquiBytes).toString();

        final newIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..caminhoRelativo = 'picos/$picoId.binarypb'
              ..checksumSha256Croqui = croquiHash,
          );

        // We SERVE the croqui because it should be redownloaded.
        final client = FakeClient(newIndice, {
          'picos/$picoId.binarypb': croquiBytes,
        });

        editor.editorUrl.value =
            'http://${localServer.address.address}:${localServer.port}/v3';
        repo = DatasetRepository(editorDeCroqui: editor);
        final syncServiceFake =
            SyncService(datasetRepository: repo, client: client)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        repo.indiceData.value = newIndice;

        final downloadsDir = editor.downloadsPath(tempDir.path);
        final picoDir = Directory('$downloadsDir/$picoId');
        picoDir.createSync(recursive: true);

        // Create INVALID .tmp file manually for the main croqui
        final tmpFile = File('${picoDir.path}/$picoId.binarypb.tmp');
        tmpFile.writeAsBytesSync([9, 9, 9, 9]); // Junk bytes

        final result = await syncServiceFake.downloadCrag(
          newIndice.croquis.first,
        );

        expect(result, isTrue);
        expect(File('${picoDir.path}/$picoId.binarypb').existsSync(), isTrue);
        expect(
          tmpFile.existsSync(),
          isFalse,
        ); // tmp should be deleted and replaced

        final downloadedBytes = File(
          '${picoDir.path}/$picoId.binarypb',
        ).readAsBytesSync();
        expect(downloadedBytes, croquiBytes);
      },
    );

    test(
      'deve recuperar descompasso forçando atualização do índice se download falhar (hash mismatch)',
      () async {
        final picoId = 'pico_descompasso';
        final croqui = Croqui(); // empty for simplicity
        final croquiBytes = croqui.writeToBuffer();
        final correctHash = sha256.convert(croquiBytes).toString();
        final oldHash = 'OLD_OUTDATED_HASH';

        final oldIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..caminhoRelativo = 'picos/$picoId.binarypb'
              ..checksumSha256Croqui = oldHash,
          );

        final newIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = picoId
              ..caminhoRelativo = 'picos/$picoId.binarypb'
              ..checksumSha256Croqui = correctHash,
          );

        // O FakeClient possui o novo índice e o arquivo correto (que bate com correctHash)
        // Definimos etagToReturn = 'old_etag' para simular que a CDN tem um cache preso e retornará 304
        // se não houver o bypass '?t='.
        final client = FakeClient(newIndice, {
          'picos/$picoId.binarypb': croquiBytes,
        }, 'old_etag');

        editor.editorUrl.value =
            'http://${localServer.address.address}:${localServer.port}/v3';
        repo = DatasetRepository(editorDeCroqui: editor);
        final syncServiceFake =
            SyncService(datasetRepository: repo, client: client)
              ..mockIsolateSpawn = (mainFunc, args) async {
                await downloadIsolateMain(args);
              };

        // Preparamos o ambiente local como se o app tivesse o índice velho e a etag velha salvos
        final indicePath = editor.indicePath(tempDir.path);
        final indiceFile = File(indicePath);
        indiceFile.parent.createSync(recursive: true);
        indiceFile.writeAsBytesSync(oldIndice.writeToBuffer());

        final etagFile = File('$indicePath.etag');
        etagFile.writeAsStringSync('old_etag');

        repo.indiceData.value = oldIndice; // Carregado em memória

        final result = await syncServiceFake.downloadCrag(
          oldIndice.croquis.first,
        );

        // 1. O primeiro syncIndex retornará 304 Not Modified.
        // 2. O app tentará baixar o pico com OLD_OUTDATED_HASH, o FakeClient retornará o pico correto, mas o hash mismatch falhará.
        // 3. O app disparará o syncIndex com forceBypassCache: true (o FakeClient vai ignorar o if-none-match e retornar 200 OK com o newIndice).
        // 4. O app tentará baixar de novo, agora com o correctHash, e terá sucesso.
        expect(result, isTrue);

        final downloadsDir = editor.downloadsPath(tempDir.path);
        final picoDir = Directory('$downloadsDir/$picoId');
        expect(File('${picoDir.path}/$picoId.binarypb').existsSync(), isTrue);

        // O índice em memória também deve ter sido atualizado com o hash correto
        expect(
          repo.indiceData.value?.croquis.first.checksumSha256Croqui,
          correctHash,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Migração de Dados (checkNeedsMigration, confirmMigrationComplete, executarMigracao)
  // ---------------------------------------------------------------------------

  group('Migração de Dados no SyncService', () {
    late Directory tempDir;
    late EditorDeCroqui editor;
    late DatasetRepository repo;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      tempDir = await Directory.systemTemp.createTemp('sync_migracao_test_');
      PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
      SharedPreferences.setMockInitialValues({});

      editor = EditorDeCroqui();
      repo = DatasetRepository(editorDeCroqui: editor);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('checkNeedsMigration deve retornar true se cached_data_version for menor que kDataVersion', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cached_data_version', 0);

      final syncService = SyncService(datasetRepository: repo);
      final result = await syncService.checkNeedsMigration();
      expect(result, isTrue);
    });

    test('checkNeedsMigration deve retornar false se cached_data_version for igual ou maior que kDataVersion', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cached_data_version', NetworkConstants.kDataVersion);

      final syncService = SyncService(datasetRepository: repo);
      final result = await syncService.checkNeedsMigration();
      expect(result, isFalse);
    });

    test('confirmMigrationComplete deve persistir kDataVersion no SharedPreferences', () async {
      final syncService = SyncService(datasetRepository: repo);
      await syncService.confirmMigrationComplete();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('cached_data_version'), NetworkConstants.kDataVersion);
    });

    test('executarMigracao deve sincronizar índice, rebaixar picos salvos e confirmar versão com sucesso', () async {
      final indice = Indice();
      final picoId = 'pico_salvo_migracao';
      final croquiBytes = utf8.encode('croqui_salvo_content');
      final correctHash = sha256.convert(croquiBytes).toString();

      indice.croquis.add(
        ResumoCroqui()
          ..id = picoId
          ..nome = 'Pico Salvo Migração'
          ..caminhoRelativo = 'picos/$picoId.binarypb'
          ..checksumSha256Croqui = correctHash,
      );

      final client = FakeClient(indice, {
        'picos/$picoId.binarypb': croquiBytes,
      });

      final syncService = SyncService(datasetRepository: repo, client: client)
        ..mockIsolateSpawn = (mainFunc, args) async {
          await downloadIsolateMain(args);
        };

      repo.indiceData.value = indice;
      repo.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': picoId, 'nome': 'Pico Salvo Migração', 'isDownloaded': true},
        ],
        downloadedPicos: [
          {'id': picoId, 'nome': 'Pico Salvo Migração', 'isDownloaded': true},
        ],
      );

      final result = await syncService.executarMigracao();

      expect(result, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('cached_data_version'), NetworkConstants.kDataVersion);
    });

    test('executarMigracao deve retornar false se syncIndex encontrar erros', () async {
      final syncService = SyncService(datasetRepository: repo);
      // Sem mock client ou servidor ativo, syncIndex falhará e mudará status para offline ou error
      final result = await syncService.executarMigracao();
      expect(result, isFalse);
    });
  });
}

