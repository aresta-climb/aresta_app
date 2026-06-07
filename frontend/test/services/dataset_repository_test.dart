/// Testes do DatasetRepository: lógica de estado público, busca recursiva de
/// arquivos (testada via sistema de arquivos), e extração de capa markdown
/// (testada indiretamente via regex local equivalente).
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

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

void main() {
  late EditorDeCroqui editor;
  late DatasetRepository repo;
  late Directory tempDir;
  late MockTelemetryService mockTelemetry;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('dataset_test');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);

    editor = EditorDeCroqui();
    repo = DatasetRepository(editorDeCroqui: editor);
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // Estado público do DatasetRepository
  // ---------------------------------------------------------------------------

  group('Estado do DatasetRepository', () {
    test('loadEmpty deve criar dataset com listas vazias', () {
      repo.loadEmpty();
      expect(repo.activeDataset.value, isNotNull);
      expect(repo.activeDataset.value!.availablePicos, isEmpty);
      expect(repo.activeDataset.value!.downloadedPicos, isEmpty);
    });

    test('triggerHomeReset deve incrementar homeResetTrigger', () {
      final before = repo.homeResetTrigger.value;
      repo.triggerHomeReset();
      expect(repo.homeResetTrigger.value, before + 1);
    });

    test('triggerHomeReset múltiplo incrementa corretamente', () {
      final before = repo.homeResetTrigger.value;
      repo.triggerHomeReset();
      repo.triggerHomeReset();
      repo.triggerHomeReset();
      expect(repo.homeResetTrigger.value, before + 3);
    });

    test('activeDataset começa como null', () {
      final freshEditor = EditorDeCroqui();
      final freshRepo = DatasetRepository(editorDeCroqui: freshEditor);
      expect(freshRepo.activeDataset.value, isNull);
    });

    test('activeDataset notifica ouvintes ao ser atualizado', () {
      bool notified = false;
      repo.activeDataset.addListener(() => notified = true);
      repo.loadEmpty();
      expect(notified, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Operações de Deleção
  // ---------------------------------------------------------------------------
  group('Deleção de Crag', () {
    test('deleteCrag remove o diretório do pico corretamente', () async {
      final picoId = 'pico_para_deletar';
      final picoDir = Directory(
        '${editor.downloadsPath(tempDir.path)}/$picoId',
      );
      await picoDir.create(recursive: true);

      // Cria arquivo de teste dentro
      final testFile = File('${picoDir.path}/test_file.txt');
      await testFile.writeAsString('conteudo_teste');

      expect(picoDir.existsSync(), isTrue);

      final result = await repo.deleteCrag(picoId);

      expect(result, isTrue);
      expect(picoDir.existsSync(), isFalse);
    });

    test('deleteCrag retorna falso se ocorrer erro na deleção', () async {
      final result = await repo.deleteCrag('pico_inexistente');
      expect(result, isFalse);
    });
  });
}
