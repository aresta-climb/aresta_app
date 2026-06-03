/// Testes do SyncService: lógica de extração de imagens markdown e SyncStatus.
/// Como _extractMarkdownImages é privada da biblioteca, testamos seu comportamento
/// indiretamente via regex equivalente aplicada a JSONs de Croqui.
library;
import 'dart:convert';
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
  
  FakeClient(this.newIndice);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path.endsWith('indice.binarypb')) {
      final bytes = newIndice.writeToBuffer();
      return http.StreamedResponse(Stream.value(bytes), 200);
    }
    // Simulate network drop during pico download
    throw const SocketException('Network dropped');
  }
}

/// Implementação local da lógica de _extractMarkdownImages para testes
/// (equivalente ao que existe em SyncService).
Set<String> extractMarkdownImages(Croqui croqui, String baseDir) {
  final Set<String> images = {};
  final jsonStr = jsonEncode(croqui.toProto3Json());
  final regex = RegExp(r'!\[.*?\]\((.*?)\)');
  for (final match in regex.allMatches(jsonStr)) {
    if (match.groupCount >= 1) {
      String path = match.group(1)!;
      if (!path.startsWith('http://') && !path.startsWith('https://')) {
        if (path.startsWith('./')) path = path.substring(2);
        if (path.startsWith('/')) path = path.substring(1);
        if (baseDir.isNotEmpty) {
          images.add('$baseDir/$path');
        } else {
          images.add(path);
        }
      }
    }
  }
  return images;
}

void main() {
  late EditorDeCroqui editor;
  late DatasetRepository repo;

  setUp(() {
    editor = EditorDeCroqui();
    repo = DatasetRepository(editorDeCroqui: editor);
  });

  // ---------------------------------------------------------------------------
  // Lógica de extração de imagens markdown (equivalente ao SyncService)
  // ---------------------------------------------------------------------------

  group('Extração de imagens markdown', () {
    test('deve retornar conjunto vazio para croqui sem markdown', () {
      final croqui = Croqui();
      expect(extractMarkdownImages(croqui, ''), isEmpty);
    });

    test('deve extrair caminho de imagem relativa de um markdown', () {
      final croqui = Croqui()
        ..botoes.add(Botao()
          ..texto = 'Beta'
          ..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()
            ..conteudo = 'Texto ![foto](imagens/foto1.webp) aqui.')));

      expect(extractMarkdownImages(croqui, ''), contains('imagens/foto1.webp'));
    });

    test('deve ignorar URLs absolutas http/https', () {
      final croqui = Croqui()
        ..botoes.add(Botao()
          ..texto = 'Beta'
          ..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()
            ..conteudo = '![foto](https://cdn.example.com/foto.webp)')));

      expect(extractMarkdownImages(croqui, ''), isEmpty);
    });

    test('deve prefixar com baseDir quando fornecido', () {
      final croqui = Croqui()
        ..botoes.add(Botao()
          ..texto = 'Beta'
          ..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()
            ..conteudo = '![foto](thumbnail.webp)')));

      expect(
        extractMarkdownImages(croqui, 'picos/pedra_bonita'),
        contains('picos/pedra_bonita/thumbnail.webp'),
      );
    });

    test('deve remover prefixo "./" de caminhos de imagem', () {
      final croqui = Croqui()
        ..botoes.add(Botao()
          ..texto = 'Beta'
          ..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()
            ..conteudo = '![foto](./imagens/foto.webp)')));

      expect(extractMarkdownImages(croqui, ''), contains('imagens/foto.webp'));
    });

    test('deve extrair múltiplas imagens de um mesmo markdown', () {
      final croqui = Croqui()
        ..botoes.add(Botao()
          ..texto = 'Beta'
          ..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()
            ..conteudo = '![a](foto1.webp) e ![b](foto2.webp) e ![c](foto3.jpg)')));

      final resultado = extractMarkdownImages(croqui, '');
      expect(resultado.length, 3);
      expect(resultado, containsAll(['foto1.webp', 'foto2.webp', 'foto3.jpg']));
    });

    test('deve extrair imagens de múltiplos arquivos markdown', () {
      final croqui = Croqui()
        ..botoes.addAll([
          Botao()..texto = 'Beta 1'..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()..conteudo = '![a](img1.webp)')),
          Botao()..texto = 'Beta 2'..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()..conteudo = '![b](img2.webp)')),
        ]);

      expect(extractMarkdownImages(croqui, ''), containsAll(['img1.webp', 'img2.webp']));
    });

    test('não deve duplicar imagens que aparecem mais de uma vez (é um Set)', () {
      final croqui = Croqui()
        ..botoes.add(Botao()
          ..texto = 'Beta'
          ..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()
            ..conteudo = '![a](foto.webp) e ![b](foto.webp)')));

      final resultado = extractMarkdownImages(croqui, '');
      expect(resultado.where((p) => p == 'foto.webp').length, 1);
    });
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
    });
  });
}
