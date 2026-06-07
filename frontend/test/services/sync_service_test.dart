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
import 'package:frontend/services/sync_service.dart';
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
  final List<String> requestedUrls = [];
  
  FakeClient(this.newIndice, [this.mockFiles = const {}]);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUrls.add(request.url.path);
    if (request.url.path.endsWith('indice.binarypb')) {
      final bytes = newIndice.writeToBuffer();
      return http.StreamedResponse(Stream.value(bytes), 200);
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

  late MockTelemetryService mockTelemetry;

  setUp(() {
    editor = EditorDeCroqui();
    repo = DatasetRepository(editorDeCroqui: editor);
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
  });



  // ---------------------------------------------------------------------------
  // SyncStatus
  // ---------------------------------------------------------------------------

  group('SyncStatus', () {
    test('deve começar como SyncStatus.updating', () {
      expect(repo.syncStatus.value, SyncStatus.updating);
    });

    test('deve notificar ouvintes quando status muda', () {
      bool notified = false;
      repo.syncStatus.addListener(() => notified = true);
      repo.syncStatus.value = SyncStatus.updated;
      expect(notified, isTrue);
      expect(repo.syncStatus.value, SyncStatus.updated);
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
  // Sincronização Delta (_updatePico indiretamente via syncOnLaunch)
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
      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..url = 'picos/$picoId.binarypb'..checksumSha256Croqui = 'SAME_HASH');
      
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

      final fakeClient = FakeClient(newIndice);
      final syncService = SyncService(repo, client: fakeClient);
      
      await syncService.syncOnLaunch();

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
      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..url = 'picos/$picoId.binarypb'..checksumSha256Croqui = 'NEW_HASH');
      
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': croqui.writeToBuffer(),
      });
      final syncService = SyncService(repo, client: fakeClient);
      
      await syncService.syncOnLaunch();

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
      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..url = 'picos/$picoId.binarypb'..checksumSha256Croqui = 'NEW_CROQUI_HASH');
      
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

      final newCroqui = Croqui()
        ..arquivosExternos.add(ArquivoExterno()..caminho = 'imagem.webp'..checksumSha256 = 'NEW_HASH');

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': newCroqui.writeToBuffer(),
        'picos/imagem.webp': [2],
      });
      final syncService = SyncService(repo, client: fakeClient);
      
      await syncService.syncOnLaunch();

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
      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..url = 'picos/$picoId.binarypb'..checksumSha256Croqui = 'NEW_CROQUI_HASH');
      
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

      final newCroqui = Croqui(); // Sem arquivos externos

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': newCroqui.writeToBuffer(),
      });
      final syncService = SyncService(repo, client: fakeClient);
      
      await syncService.syncOnLaunch();

      expect(fileToDelete.existsSync(), isFalse);
    });

    test('baixa novos arquivos que não estavam presentes em versão anterior', () async {
      final picoId = 'pico_ext_novo';
      final picoDir = Directory('${downloadsDir.path}/$picoId');
      await picoDir.create(recursive: true);

      final oldCroqui = Croqui(); // Sem arquivos
      await File('${picoDir.path}/$picoId.binarypb').writeAsBytes(oldCroqui.writeToBuffer());

      final oldIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..checksumSha256Croqui = 'OLD_CROQUI_HASH');
      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..url = 'picos/$picoId.binarypb'..checksumSha256Croqui = 'NEW_CROQUI_HASH');
      
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

      final newCroqui = Croqui()
        ..arquivosExternos.add(ArquivoExterno()..caminho = 'nova.webp'..checksumSha256 = 'abc');

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': newCroqui.writeToBuffer(),
        'picos/nova.webp': [3],
      });
      final syncService = SyncService(repo, client: fakeClient);
      
      await syncService.syncOnLaunch();

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
      final newIndice = Indice()..croquis.add(ResumoCroqui()..id = picoId..url = 'picos/$picoId.binarypb'..checksumSha256Croqui = 'NEW_CROQUI_HASH');
      
      final indiceFile = File(editor.indicePath(tempDir.path));
      await indiceFile.parent.create(recursive: true);
      await indiceFile.writeAsBytes(oldIndice.writeToBuffer());

      final newCroqui = Croqui()
        ..arquivosExternos.addAll([
          ArquivoExterno()..caminho = 'mantida.webp'..checksumSha256 = 'A',
          ArquivoExterno()..caminho = 'atualizada.webp'..checksumSha256 = 'B_NEW',
          ArquivoExterno()..caminho = 'nova.webp'..checksumSha256 = 'D',
        ]);

      final fakeClient = FakeClient(newIndice, {
        'picos/$picoId.binarypb': newCroqui.writeToBuffer(),
        'picos/atualizada.webp': [22],
        'picos/nova.webp': [44],
      });
      final syncService = SyncService(repo, client: fakeClient);
      
      await syncService.syncOnLaunch();

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
          ..url = 'picos/pico1.binarypb'
          ..checksumSha256Croqui = 'NEW_CHECKSUM');
          
      final fakeClient = FakeClient(newIndice);
      final syncService = SyncService(repo, client: fakeClient);

      // We must not be in experimental mode for _checkForUpdates to run
      editor.isExperimentalMode.value = false;

      // 3. Run sync
      await syncService.syncOnLaunch();

      // 4. Verify that local indice is STILL the old one because the download failed
      final finalBytes = indiceFile.readAsBytesSync();
      final finalIndice = Indice.fromBuffer(finalBytes);
      
      expect(finalIndice.croquis.first.checksumSha256Croqui, 'OLD_CHECKSUM', 
          reason: 'O índice não deve ser sobrescrito se houver erro ou interrupção no download do pico.');
          
      expect(finalIndice.croquis.first.checksumSha256Croqui, 'OLD_CHECKSUM', 
          reason: 'O índice não deve ser sobrescrito se houver erro ou interrupção no download do pico.');
    });
  });
}
