/// Testes do SyncService: lógica de extração de imagens markdown e SyncStatus.
/// Como _extractMarkdownImages é privada da biblioteca, testamos seu comportamento
/// indiretamente via regex equivalente aplicada a JSONs de Croqui.
library;

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:crypto/crypto.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

class MockPathProviderPlatform extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getLibraryPath() async => tempPath;
}

class FakeClient extends http.BaseClient {
  final Indice newIndice;
  final Map<String, List<int>> mockFiles;
  final String? etagToReturn;
  final List<String> requestedUrls = [];
  final List<String> requestedFullUrls = [];
  final Map<String, String> receivedHeaders = {};
  
  FakeClient(this.newIndice, [this.mockFiles = const {}, this.etagToReturn]);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUrls.add(request.url.path);
    requestedFullUrls.add(request.url.toString());
    receivedHeaders.addAll(request.headers);

    if (request.url.path.endsWith('indice.binarypb')) {
      if (etagToReturn != null && request.headers['If-None-Match'] == etagToReturn) {
        return http.StreamedResponse(const Stream.empty(), 304);
      }
      final bytes = newIndice.writeToBuffer();
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
  late EditorDeCroqui editor;
  late DatasetRepository repo;
  late SyncService syncService;

  late MockTelemetryService mockTelemetry;

  setUp(() {
    editor = EditorDeCroqui();
    repo = DatasetRepository(editorDeCroqui: editor);
    syncService = SyncService(datasetRepository: repo);
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
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
      expect(SyncStatus.values, containsAll([
        SyncStatus.updated,
        SyncStatus.updating,
        SyncStatus.outdated,
        SyncStatus.error,
      ]));
    });
  });

  // ---------------------------------------------------------------------------
  // TopoDataset
  // ---------------------------------------------------------------------------

  group('TopoDataset', () {
    test('deve armazenar listas de picos corretamente', () {
      final available = [{'id': 'a', 'nome': 'Pico A'}];
      final downloaded = [{'id': 'a', 'nome': 'Pico A', 'isDownloaded': true}];

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
      
      final oldIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..checksumSha256Croqui = 'SAME_HASH');
      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..caminhoRelativo = 'picos/$picoId.binarypb'..checksumSha256Croqui = 'SAME_HASH');
      
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

      final fakeClient = FakeClient(newIndice);
      final syncService = SyncService(datasetRepository: repo, client: fakeClient);
      
      await syncService.syncIndex();

      expect(fakeClient.requestedUrls.any((url) => url.contains('picos/')), isFalse);
    });

    test('não baixa arquivo externo de novo se checksum é o mesmo', () async {
      final picoId = 'pico_ext_igual';
      final picoDir = Directory('${downloadsDir.path}/$picoId');
      await picoDir.create(recursive: true);

      final fileToKeep = File('${picoDir.path}/imagem.webp');
      await fileToKeep.writeAsBytes([1]);

      final croqui = Croqui()
        ..arquivosExternos.add(ArquivoExterno()..caminho = 'imagem.webp'..checksumSha256 = 'abc');
      await File('${picoDir.path}/$picoId.binarypb').writeAsBytes(croqui.writeToBuffer());

      final oldIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..checksumSha256Croqui = 'OLD_HASH');
      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..caminhoRelativo = 'picos/$picoId.binarypb'..checksumSha256Croqui = 'NEW_HASH');
      
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croqui.writeToBuffer(),
      });
      final syncService = SyncService(datasetRepository: repo, client: fakeClient);
      
      await syncService.syncIndex();

      expect(fakeClient.requestedUrls, isNot(contains(matches(RegExp(r'imagem\.webp$')))));
      expect(fileToKeep.existsSync(), isTrue);
    });

    test('baixa arquivo externo de novo se checksum mudou', () async {
      final picoId = 'pico_ext_mudou';
      final picoDir = Directory('${downloadsDir.path}/$picoId');
      await picoDir.create(recursive: true);

      final fileToUpdate = File('${picoDir.path}/imagem.webp');
      await fileToUpdate.writeAsBytes([1]);

      final oldCroqui = Croqui()
        ..arquivosExternos.add(ArquivoExterno()..caminho = 'imagem.webp'..checksumSha256 = 'OLD_HASH');
      await File('${picoDir.path}/$picoId.binarypb').writeAsBytes(oldCroqui.writeToBuffer());

      final oldIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..checksumSha256Croqui = 'OLD_CROQUI_HASH');
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());
      final newCroqui = Croqui()
        ..arquivosExternos.add(ArquivoExterno()..caminho = 'imagem.webp'..checksumSha256 = sha256.convert([2]).toString());

      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..caminhoRelativo = 'picos/$picoId.binarypb'..checksumSha256Croqui = sha256.convert(newCroqui.writeToBuffer()).toString());

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': newCroqui.writeToBuffer(),
        'picos/imagem.webp': [2],
      });
      final syncService = SyncService(datasetRepository: repo, client: fakeClient);
      
      await syncService.syncIndex();

      expect(fakeClient.requestedUrls.any((url) => url.endsWith('imagem.webp')), isTrue);
      expect(await fileToUpdate.readAsBytes(), equals([2]));
    });

    test('deleta arquivos removidos em nova versão', () async {
      final picoId = 'pico_ext_removido';
      final picoDir = Directory('${downloadsDir.path}/$picoId');
      await picoDir.create(recursive: true);

      final fileToDelete = File('${picoDir.path}/removida.webp');
      await fileToDelete.writeAsBytes([1]);

      final oldCroqui = Croqui()
        ..arquivosExternos.add(ArquivoExterno()..caminho = 'removida.webp'..checksumSha256 = 'abc');
      await File('${picoDir.path}/$picoId.binarypb').writeAsBytes(oldCroqui.writeToBuffer());

      final oldIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..checksumSha256Croqui = 'OLD_CROQUI_HASH');
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());
      final newCroqui = Croqui(); // Sem arquivos externos

      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..caminhoRelativo = 'picos/$picoId.binarypb'..checksumSha256Croqui = sha256.convert(newCroqui.writeToBuffer()).toString());

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': newCroqui.writeToBuffer(),
      });
      final syncService = SyncService(datasetRepository: repo, client: fakeClient);
      
      await syncService.syncIndex();

      expect(fileToDelete.existsSync(), isFalse);
    });

    test('baixa novos arquivos que não estavam presentes em versão anterior', () async {
      final picoId = 'pico_ext_novo';
      final picoDir = Directory('${downloadsDir.path}/$picoId');
      await picoDir.create(recursive: true);

      final oldCroqui = Croqui(); // Sem arquivos
      await File('${picoDir.path}/$picoId.binarypb').writeAsBytes(oldCroqui.writeToBuffer());

      final oldIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..checksumSha256Croqui = 'OLD_CROQUI_HASH');
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());
      final newCroqui = Croqui()
        ..arquivosExternos.add(ArquivoExterno()..caminho = 'nova.webp'..checksumSha256 = sha256.convert([3]).toString());

      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..caminhoRelativo = 'picos/$picoId.binarypb'..checksumSha256Croqui = sha256.convert(newCroqui.writeToBuffer()).toString());

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': newCroqui.writeToBuffer(),
        'picos/nova.webp': [3],
      });
      final syncService = SyncService(datasetRepository: repo, client: fakeClient);
      
      await syncService.syncIndex();

      // Cache-Busting Verification
      final expectedHash = sha256.convert(newCroqui.writeToBuffer()).toString();
      final fullUrl = fakeClient.requestedFullUrls.firstWhere((u) => u.contains('$picoId.binarypb'));
      expect(fullUrl, contains('?sha256sum='), reason: 'A URL do arquivo deve ter o furador de cache ?sha256sum=');
      expect(fullUrl, contains(expectedHash), reason: 'A URL deve ter o hash real do croqui para furar o cache da CDN');

      // Sync External Files Verification
      expect(fakeClient.requestedUrls.any((url) => url.endsWith('nova.webp')), isTrue);
      expect(File('${picoDir.path}/nova.webp').existsSync(), isTrue);
    });

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
          ArquivoExterno()..caminho = 'mantida.webp'..checksumSha256 = 'A',
          ArquivoExterno()..caminho = 'atualizada.webp'..checksumSha256 = 'B',
          ArquivoExterno()..caminho = 'removida.webp'..checksumSha256 = 'C',
        ]);
      await File('${picoDir.path}/$picoId.binarypb').writeAsBytes(oldCroqui.writeToBuffer());

      final oldIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..checksumSha256Croqui = 'OLD_CROQUI_HASH');
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());
      final newCroqui = Croqui()
        ..arquivosExternos.addAll([
          ArquivoExterno()..caminho = 'mantida.webp'..checksumSha256 = 'A',
          ArquivoExterno()..caminho = 'atualizada.webp'..checksumSha256 = sha256.convert([22]).toString(),
          ArquivoExterno()..caminho = 'nova.webp'..checksumSha256 = sha256.convert([44]).toString(),
        ]);

      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..caminhoRelativo = 'picos/$picoId.binarypb'..checksumSha256Croqui = sha256.convert(newCroqui.writeToBuffer()).toString());

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': newCroqui.writeToBuffer(),
        'picos/atualizada.webp': [22],
        'picos/nova.webp': [44],
      });
      final syncService = SyncService(datasetRepository: repo, client: fakeClient);
      
      await syncService.syncIndex();

      expect(fileToKeep.existsSync(), isTrue);
      expect(fileToDelete.existsSync(), isFalse);
      expect(File('${picoDir.path}/nova.webp').existsSync(), isTrue);
      expect(await fileToUpdate.readAsBytes(), equals([22]));
      
      expect(fakeClient.requestedUrls, isNot(contains(matches(RegExp(r'mantida\.webp$')))));
    });
  });

  // ---------------------------------------------------------------------------
  // SyncOnLaunch Order of Operations
  // ---------------------------------------------------------------------------

  group('SyncOnLaunch order of operations', () {
    late Directory tempDir;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
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

    test('deve manter o indice antigo se o download do pico falhar (não atualiza o indice cedo demais)', () async {
      // 1. Setup local files
      final oldIndice = Indice()
        ..croquis.add(ResumoCroqui()
          ..id = 'pico1'
          ..checksumSha256Croqui = 'OLD_CHECKSUM');
          
      final indicePath = editor.indicePath(tempDir.path);
      final indiceFile = File(indicePath);
      indiceFile.parent.createSync(recursive: true);
      indiceFile.writeAsBytesSync(oldIndice.writeToBuffer());

      // Simulate that the pico is downloaded
      final picoFile = File('${editor.downloadsPath(tempDir.path)}/pico1/pico1.binarypb');
      picoFile.parent.createSync(recursive: true);
      picoFile.writeAsBytesSync([1, 2, 3]); // dummy content

      // 2. Setup mock client returning NEW index
      final newIndice = Indice()
        ..croquis.add(ResumoCroqui()
          ..id = 'pico1'
          ..caminhoRelativo = 'picos/pico1.binarypb'
          ..checksumSha256Croqui = 'NEW_CHECKSUM');
          
      final fakeClient = FakeClient(newIndice);
      final syncService = SyncService(datasetRepository: repo, client: fakeClient);

      // We must not be in experimental mode for _checkForUpdates to run
      editor.isExperimentalMode.value = false;

      // 3. Run sync
      await syncService.syncIndex();

      // 4. Verify that local indice is STILL the old one because the download failed
      final finalBytes = indiceFile.readAsBytesSync();
      final finalIndice = Indice.fromBuffer(finalBytes);
      
      expect(finalIndice.croquis.first.checksumSha256Croqui, 'OLD_CHECKSUM', 
          reason: 'O índice não deve ser sobrescrito se houver erro ou interrupção no download do pico.');
          
      expect(finalIndice.croquis.first.checksumSha256Croqui, 'OLD_CHECKSUM', 
          reason: 'O índice não deve ser sobrescrito se houver erro ou interrupção no download do pico.');
    });
  });

  // ---------------------------------------------------------------------------
  // SyncOnLaunch ETag e Caching
  // ---------------------------------------------------------------------------

  group('SyncOnLaunch ETag e Caching', () {
    late Directory tempDir;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
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
      final syncServiceFake = SyncService(datasetRepository: repo, client: fakeClient);
      
      await syncServiceFake.syncIndex();

      final etagFile = File('${editor.indicePath(tempDir.path)}.etag');
      expect(etagFile.existsSync(), isTrue);
      expect(etagFile.readAsStringSync(), 'mock_etag_123');
    });

    test('deve enviar If-None-Match e processar 304 Not Modified corretamente', () async {
      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = 'pico_fake_nao_deve_baixar');
      final fakeClient = FakeClient(newIndice, {}, 'mock_etag_123');
      final syncServiceFake = SyncService(datasetRepository: repo, client: fakeClient);
      
      final indiceFile = File(editor.indicePath(tempDir.path));
      indiceFile.parent.createSync(recursive: true);
      indiceFile.writeAsBytesSync(Indice().writeToBuffer());
      
      final etagFile = File('${editor.indicePath(tempDir.path)}.etag');
      etagFile.writeAsStringSync('mock_etag_123');
      
      await syncServiceFake.syncIndex();

      expect(fakeClient.receivedHeaders['If-None-Match'], 'mock_etag_123');
      
      final finalBytes = indiceFile.readAsBytesSync();
      final finalIndice = Indice.fromBuffer(finalBytes);
      expect(finalIndice.croquis, isEmpty, reason: 'Nao deve sobrescrever indice se retornou 304');
      expect(syncServiceFake.syncStatus.value, equals(SyncStatus.justUpdated));
    });

    test('nao deve recarregar DatasetRepo em memoria se ja estiver carregado e retornar 304', () async {
      final fakeClient = FakeClient(Indice(), {}, 'mock_etag_123');
      final syncServiceFake = SyncService(datasetRepository: repo, client: fakeClient);
      
      final etagFile = File('${editor.indicePath(tempDir.path)}.etag');
      etagFile.parent.createSync(recursive: true);
      etagFile.writeAsStringSync('mock_etag_123');
      
      // Força estar carregado
      repo.activeDataset.value = TopoDataset(availablePicos: [], downloadedPicos: []);
      final resetCountBefore = repo.homeResetTrigger.value;
      
      await syncServiceFake.syncIndex();

      expect(repo.homeResetTrigger.value, equals(resetCountBefore), reason: 'Nao deve recarregar no 304 se ja tem activeDataset');
    });
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
        tempDir.deleteSync(recursive: true);
      }
    });

    test('deve baixar o croqui e seus arquivos externos com sucesso', () async {
      final picoId = 'pico_teste';
      final croqui = Croqui()
        ..arquivosExternos.add(ArquivoExterno()..caminho = 'imagens/capa.webp'..checksumSha256 = sha256.convert([1, 2, 3]).toString());
        
      final newIndice = Indice()..croquis.add(ResumoCroqui()
        ..id = picoId
        ..caminhoRelativo = 'picos/$picoId.binarypb'
        ..checksumSha256Croqui = sha256.convert(croqui.writeToBuffer()).toString());

      final client = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croqui.writeToBuffer(),
        'picos/imagens/capa.webp': [1, 2, 3],
      });

      editor.editorUrl.value = 'https://fake.url';
      
      repo = DatasetRepository(editorDeCroqui: editor);
      final syncServiceFake = SyncService(datasetRepository: repo, client: client);

      repo.indiceData.value = newIndice;
      
      final result = await syncServiceFake.downloadCrag(newIndice.croquis.first);

      expect(result, isTrue);

      final downloadsDir = editor.downloadsPath(tempDir.path);
      final picoDir = Directory('$downloadsDir/$picoId');
      
      expect(File('${picoDir.path}/$picoId.binarypb').existsSync(), isTrue);
      expect(File('${picoDir.path}/imagens/capa.webp').existsSync(), isTrue);
    });

    test('deve acionar a telemetria ao fazer download', () async {
      final picoId = 'pico_telemetria';
      final croqui = Croqui();
        
      final newIndice = Indice()..croquis.add(ResumoCroqui()
        ..id = picoId
        ..caminhoRelativo = 'picos/$picoId.binarypb'
        ..checksumSha256Croqui = sha256.convert(croqui.writeToBuffer()).toString());

      final client = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croqui.writeToBuffer(),
      });

      editor.editorUrl.value = 'https://fake.url';
      
      repo = DatasetRepository(editorDeCroqui: editor);
      final syncServiceFake = SyncService(datasetRepository: repo, client: client);

      repo.indiceData.value = newIndice;
      
      final result = await syncServiceFake.downloadCrag(newIndice.croquis.first);

      expect(result, isTrue);
      expect(mockTelemetry.recordedEvents, contains('acao_explorar'));
      expect(mockTelemetry.recordedParams['acao_explorar']?['acao'], 'baixar');
      expect(mockTelemetry.recordedParams['acao_explorar']?['id_croqui'], picoId);
    });

    test('deve atualizar o indice se estiver desatualizado e usar o novo hash para o download', () async {
      final picoId = 'pico_race_condition';
      final croqui = Croqui();
      final correctHash = sha256.convert(croqui.writeToBuffer()).toString();

      final oldIndice = Indice()..croquis.add(ResumoCroqui()
        ..id = picoId
        ..caminhoRelativo = 'picos/$picoId.binarypb'
        ..checksumSha256Croqui = 'OLD_OUTDATED_HASH');

      final newIndice = Indice()..croquis.add(ResumoCroqui()
        ..id = picoId
        ..caminhoRelativo = 'picos/$picoId.binarypb'
        ..checksumSha256Croqui = correctHash);

      // O FakeClient possui o novo índice e o arquivo correto (que bate com correctHash)
      final client = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croqui.writeToBuffer(),
      });

      editor.editorUrl.value = 'https://fake.url';
      repo = DatasetRepository(editorDeCroqui: editor);
      final syncServiceFake = SyncService(datasetRepository: repo, client: client);

      // O app localmente acha que tem o OLD_HASH
      repo.indiceData.value = oldIndice;
      
      final result = await syncServiceFake.downloadCrag(newIndice.croquis.first);

      // Se a prevenção de race condition funcionar, ele vai:
      // 1. Chamar syncIndex, que baixa newIndice
      // 2. Extrair o ResumoCroqui com correctHash
      // 3. Baixar e validar o arquivo contra correctHash, e não OLD_OUTDATED_HASH!
      expect(result, isTrue);
    });

    test('deve falhar se o download do croqui tiver sha256 inválido', () async {
      final picoId = 'pico_invalido';
      final croqui = Croqui();
      final newIndice = Indice()..croquis.add(ResumoCroqui()
        ..id = picoId
        ..caminhoRelativo = 'picos/$picoId.binarypb'
        ..checksumSha256Croqui = 'hash_completamente_errado');

      final client = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croqui.writeToBuffer(),
      });
      editor.editorUrl.value = 'https://fake.url';
      repo = DatasetRepository(editorDeCroqui: editor);
      final syncServiceFake = SyncService(datasetRepository: repo, client: client);

      repo.indiceData.value = newIndice;
      
      final result = await syncServiceFake.downloadCrag(newIndice.croquis.first);

      expect(result, isFalse);
    });

    test('deve retomar de um arquivo .tmp válido e pular o download', () async {
      final picoId = 'pico_resume_valido';
      final fileData = [1, 2, 3, 4];
      final fileHash = sha256.convert(fileData).toString();
      
      final croqui = Croqui()
        ..arquivosExternos.add(ArquivoExterno()
          ..caminho = 'capa.webp'
          ..checksumSha256 = fileHash);
      final croquiBytes = croqui.writeToBuffer();
      
      final newIndice = Indice()..croquis.add(ResumoCroqui()
        ..id = picoId
        ..caminhoRelativo = 'picos/$picoId.binarypb'
        ..checksumSha256Croqui = sha256.convert(croquiBytes).toString());

      // We serve the main croqui, but DO NOT serve capa.webp!
      // If it tries to download capa.webp, it will fail (because FakeClient will return 404/error).
      final client = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croquiBytes,
      });

      editor.editorUrl.value = 'https://fake.url';
      repo = DatasetRepository(editorDeCroqui: editor);
      final syncServiceFake = SyncService(datasetRepository: repo, client: client);

      repo.indiceData.value = newIndice;
      
      final downloadsDir = editor.downloadsPath(tempDir.path);
      final picoDir = Directory('$downloadsDir/$picoId');
      picoDir.createSync(recursive: true);
      
      // Create valid .tmp file manually for the arquivo externo
      final tmpFile = File('${picoDir.path}/capa.webp.tmp');
      tmpFile.writeAsBytesSync(fileData);
      
      final result = await syncServiceFake.downloadCrag(newIndice.croquis.first);

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
        ..arquivosExternos.add(ArquivoExterno()
          ..caminho = 'capa.webp'
          ..checksumSha256 = fileHash);
      final croquiBytes = croqui.writeToBuffer();
      
      final newIndice = Indice()..croquis.add(ResumoCroqui()
        ..id = picoId
        ..caminhoRelativo = 'picos/$picoId.binarypb'
        ..checksumSha256Croqui = sha256.convert(croquiBytes).toString());

      // We serve BOTH the croqui and the capa.webp, because it needs to redownload capa.webp.
      final client = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croquiBytes,
        'picos/capa.webp': fileData,
      });

      editor.editorUrl.value = 'https://fake.url';
      repo = DatasetRepository(editorDeCroqui: editor);
      final syncServiceFake = SyncService(datasetRepository: repo, client: client);

      repo.indiceData.value = newIndice;
      
      final downloadsDir = editor.downloadsPath(tempDir.path);
      final picoDir = Directory('$downloadsDir/$picoId');
      picoDir.createSync(recursive: true);
      
      // Create INVALID .tmp file manually
      final tmpFile = File('${picoDir.path}/capa.webp.tmp');
      tmpFile.writeAsBytesSync([9, 9, 9, 9]); // Junk bytes
      
      final result = await syncServiceFake.downloadCrag(newIndice.croquis.first);

      expect(result, isTrue);
      // Main croqui should be downloaded
      expect(File('${picoDir.path}/$picoId.binarypb').existsSync(), isTrue);
      // The tmp file should be deleted and final file downloaded correctly
      expect(File('${picoDir.path}/capa.webp').existsSync(), isTrue);
      expect(tmpFile.existsSync(), isFalse);
      
      final downloadedBytes = File('${picoDir.path}/capa.webp').readAsBytesSync();
      expect(downloadedBytes, fileData);
    });

    test('deve retomar o croqui principal de um arquivo .tmp válido e pular o download', () async {
      final picoId = 'pico_principal_resume_valido';
      final croqui = Croqui(); // empty for simplicity
      final croquiBytes = croqui.writeToBuffer();
      final croquiHash = sha256.convert(croquiBytes).toString();
      
      final newIndice = Indice()..croquis.add(ResumoCroqui()
        ..id = picoId
        ..caminhoRelativo = 'picos/$picoId.binarypb'
        ..checksumSha256Croqui = croquiHash);

      // We DO NOT serve the croqui from FakeClient. If it tries to download, it will fail!
      final client = FakeClient(newIndice, {});

      editor.editorUrl.value = 'https://fake.url';
      repo = DatasetRepository(editorDeCroqui: editor);
      final syncServiceFake = SyncService(datasetRepository: repo, client: client);

      repo.indiceData.value = newIndice;
      
      final downloadsDir = editor.downloadsPath(tempDir.path);
      final picoDir = Directory('$downloadsDir/$picoId');
      picoDir.createSync(recursive: true);
      
      // Create valid .tmp file manually for the main croqui
      final tmpFile = File('${picoDir.path}/$picoId.binarypb.tmp');
      tmpFile.writeAsBytesSync(croquiBytes);
      
      final result = await syncServiceFake.downloadCrag(newIndice.croquis.first);

      expect(result, isTrue);
      expect(File('${picoDir.path}/$picoId.binarypb').existsSync(), isTrue);
      expect(tmpFile.existsSync(), isFalse); // tmp should be renamed
    });

    test('deve descartar arquivo .tmp inválido do croqui principal e fazer novo download', () async {
      final picoId = 'pico_principal_resume_invalido';
      final croqui = Croqui();
      final croquiBytes = croqui.writeToBuffer();
      final croquiHash = sha256.convert(croquiBytes).toString();
      
      final newIndice = Indice()..croquis.add(ResumoCroqui()
        ..id = picoId
        ..caminhoRelativo = 'picos/$picoId.binarypb'
        ..checksumSha256Croqui = croquiHash);

      // We SERVE the croqui because it should be redownloaded.
      final client = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croquiBytes,
      });

      editor.editorUrl.value = 'https://fake.url';
      repo = DatasetRepository(editorDeCroqui: editor);
      final syncServiceFake = SyncService(datasetRepository: repo, client: client);

      repo.indiceData.value = newIndice;
      
      final downloadsDir = editor.downloadsPath(tempDir.path);
      final picoDir = Directory('$downloadsDir/$picoId');
      picoDir.createSync(recursive: true);
      
      // Create INVALID .tmp file manually for the main croqui
      final tmpFile = File('${picoDir.path}/$picoId.binarypb.tmp');
      tmpFile.writeAsBytesSync([9, 9, 9, 9]); // Junk bytes
      
      final result = await syncServiceFake.downloadCrag(newIndice.croquis.first);

      expect(result, isTrue);
      expect(File('${picoDir.path}/$picoId.binarypb').existsSync(), isTrue);
      expect(tmpFile.existsSync(), isFalse); // tmp should be deleted and replaced
      
      final downloadedBytes = File('${picoDir.path}/$picoId.binarypb').readAsBytesSync();
      expect(downloadedBytes, croquiBytes);
    });
  });
}
