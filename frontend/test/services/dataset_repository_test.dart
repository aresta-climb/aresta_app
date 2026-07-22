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
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import '../mocks/mock_telemetry_service.dart';
import '../mocks/mock_app_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/constants/network_constants.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/firebase/app_logger.dart';

class MockAssetBundle extends Mock implements AssetBundle {}

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

    test(
      'init deve descompactar indice.binarypb e thumbnails do preload quando o indice local nao existe',
      () async {
        final mockBundle = MockAssetBundle();

        final fakeIndice = Indice(
          croquis: [
            ResumoCroqui(
              id: 'crag1',
              caminhoRelativo: 'crag1/compilado.binarypb',
            ),
          ],
        );
        final indiceBytes = fakeIndice.writeToBuffer();

        // Mock para indice.binarypb
        when(
          () => mockBundle.load('assets/preload/indice.binarypb'),
        ).thenAnswer((_) async => ByteData.view(indiceBytes.buffer));

        // Mock para thumbnail
        when(
          () => mockBundle.load('assets/preload/thumbnails/crag1.webp'),
        ).thenAnswer(
          (_) async => ByteData.view(Uint8List.fromList([1, 2, 3]).buffer),
        );

        // Injeta o mockBundle (adicionaremos no DatasetRepository depois)
        repo.assetBundle = mockBundle;
        SharedPreferences.setMockInitialValues({});
        await repo.init();

        final docsPath = tempDir.path;
        final localIndiceFile = File(editor.indicePath(docsPath));
        expect(localIndiceFile.existsSync(), isTrue);

        final thumbFile = File('$docsPath/thumbnails/crag1.webp');
        expect(thumbFile.existsSync(), isTrue);

        // Deve ter carregado na memoria
        expect(repo.activeDataset.value!.availablePicos.length, 1);
      },
    );

    test(
      'updateDatasetAfterDownload deve atualizar isDownloaded flag no availablePicos e preencher data',
      () async {
        repo.activeDataset.value = TopoDataset(
          availablePicos: [
            {'id': 'pico_1', 'isDownloaded': false},
          ],
          downloadedPicos: [],
        );

        final picoDir = Directory(
          '${editor.downloadsPath(tempDir.path)}/pico_1',
        );
        await picoDir.create(recursive: true);
        final picoFile = File('${picoDir.path}/pico_1.binarypb');

        final dummyPico = Pico()..nome = 'Pico Teste';
        final dummyCroqui = Croqui()..picos.add(dummyPico);
        await picoFile.writeAsBytes(dummyCroqui.writeToBuffer());

        await repo.updateDatasetAfterDownload('pico_1');

        final updatedAvailable = repo.activeDataset.value!.availablePicos;
        expect(updatedAvailable.first['isDownloaded'], isTrue);

        final downloaded = repo.activeDataset.value!.downloadedPicos;
        expect(downloaded.length, 1);
        expect(downloaded.first['data'], isNotNull);
        expect((downloaded.first['data'] as Map)['pico'], isA<Pico>());
        expect((downloaded.first['data'] as Map)['croqui'], isA<Croqui>());
      },
    );

    test(
      'loadIndiceToMemory mapeia o campo descricao do ResumoCroqui',
      () async {
        final indice = Indice(
          croquis: [
            ResumoCroqui(
              id: 'pico_desc',
              nome: 'Nome',
              descricao: 'Uma descrição curta muito legal',
              caminhoRelativo: 'pico_desc.zip',
            ),
          ],
        );
        repo.indiceData.value = indice;
        await repo.loadIndiceToMemory(indice);

        final available = repo.activeDataset.value!.availablePicos;
        expect(available.length, 1);
        expect(available.first['descricao'], 'Uma descrição curta muito legal');
      },
    );

    test(
      'loadIndiceToMemory deve preencher a chave [data] na inicializacao se o pico ja estiver baixado',
      () async {
        // Simula um pico já baixado no disco antes de carregar o índice
        final picoDir = Directory(
          '${editor.downloadsPath(tempDir.path)}/pico_boot',
        );
        await picoDir.create(recursive: true);
        final picoFile = File('${picoDir.path}/pico_boot.binarypb');

        final dummyPico = Pico()..nome = 'Pico de Boot Teste';
        final dummyCroqui = Croqui()..picos.add(dummyPico);
        await picoFile.writeAsBytes(dummyCroqui.writeToBuffer());

        final indice = Indice(
          croquis: [
            ResumoCroqui(
              id: 'pico_boot',
              nome: 'Nome',
              caminhoRelativo: 'pico_boot.zip',
            ),
          ],
        );

        await repo.loadIndiceToMemory(indice);

        final downloaded = repo.activeDataset.value!.downloadedPicos;
        expect(downloaded.length, 1);
        expect(downloaded.first['isDownloaded'], isTrue);
        expect(downloaded.first['data'], isNotNull);
        expect((downloaded.first['data'] as Map)['pico'], isA<Pico>());
        expect((downloaded.first['data'] as Map)['croqui'], isA<Croqui>());
      },
    );
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

  // ---------------------------------------------------------------------------
  // Pré-bundling (Unpack Assets)
  // ---------------------------------------------------------------------------
  group('_unpackPreloadedAssets', () {
    late MockAppLogger mockLogger;

    setUp(() {
      mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;
    });

    test(
      'deve logar erro se falhar ao carregar o indice do bundle (ex: pasta não existe)',
      () async {
        final mockBundle = MockAssetBundle();
        when(
          () => mockBundle.load('assets/preload/indice.binarypb'),
        ).thenThrow(Exception('Bundle não encontrado'));

        repo.assetBundle = mockBundle;

        // Chamamos init que por sua vez chama _unpackPreloadedAssets na ausência de diretórios
        await repo.init();

        expect(mockLogger.recordedErrors.isNotEmpty, isTrue);
        expect(
          mockLogger.recordedErrors.any(
            (e) => e['contextMessage'].contains('Preload de indice.binarypb'),
          ),
          isTrue,
        );
      },
    );

    test(
      'deve logar erro se falhar ao carregar uma thumbnail específica',
      () async {
        final mockBundle = MockAssetBundle();

        final mockIndice = Indice()
          ..croquis.add(
            ResumoCroqui()
              ..id = 'pico_sem_thumb'
              ..caminhoRelativo = 'picos/pico_sem_thumb.binarypb',
          );
        final indiceBytes = mockIndice.writeToBuffer();

        when(
          () => mockBundle.load('assets/preload/indice.binarypb'),
        ).thenAnswer((_) async => ByteData.view(indiceBytes.buffer));

        when(
          () =>
              mockBundle.load('assets/preload/thumbnails/pico_sem_thumb.webp'),
        ).thenThrow(Exception('Thumbnail missing in bundle'));

        repo.assetBundle = mockBundle;

        await repo.init();

        // O índice foi carregado com sucesso, mas a thumbnail falhou
        expect(mockLogger.recordedErrors.isNotEmpty, isTrue);
        expect(
          mockLogger.recordedErrors.any(
            (e) => e['contextMessage'].contains(
              'Erro ao carregar thumbnail pico_sem_thumb',
            ),
          ),
          isTrue,
        );
      },
    );

    test(
      'deve definir a cached_data_version para evitar tela de migração na primeira instalação',
      () async {
        SharedPreferences.setMockInitialValues({});
        final mockBundle = MockAssetBundle();
        final mockIndice = Indice();
        final indiceBytes = mockIndice.writeToBuffer();

        when(
          () => mockBundle.load('assets/preload/indice.binarypb'),
        ).thenAnswer((_) async => ByteData.view(indiceBytes.buffer));

        repo.assetBundle = mockBundle;

        await repo.init();

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getInt('cached_data_version'),
          equals(NetworkConstants.kDataVersion),
        );
      },
    );
  });
}
