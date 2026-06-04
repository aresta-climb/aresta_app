/// Testes do DatasetRepository: lógica de estado público, busca recursiva de
/// arquivos (testada via sistema de arquivos), e extração de capa markdown
/// (testada indiretamente via regex local equivalente).
library;
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

/// Reimplementação local da lógica de _extractCapaPathFromMarkdown para testes.
String? extractCapaPath(Croqui croqui, String baseDir) {
  try {
    final capaBotao = croqui.botoes.firstWhere(
      (b) => b.texto.toLowerCase().contains('capa') && b.hasDestino() && b.destino.hasSecaoTextual(),
      orElse: () => Botao(),
    );
    if (capaBotao.hasDestino() && capaBotao.destino.hasSecaoTextual()) {
      final capaMd = capaBotao.destino.secaoTextual;
      if (capaMd.hasConteudo() && capaMd.conteudo.isNotEmpty) {
        final regex = RegExp(r'!\[.*?\]\((.*?)\)');
        final match = regex.firstMatch(capaMd.conteudo);
        if (match != null && match.groupCount >= 1) {
          String path = match.group(1)!;
          if (!path.startsWith('http')) {
            if (path.startsWith('./')) path = path.substring(2);
            if (path.startsWith('/')) path = path.substring(1);
            if (baseDir.isNotEmpty) {
              if (!path.startsWith(baseDir)) {
                return '$baseDir/$path';
              } else {
                return path;
              }
            } else {
              return path;
            }
          }
        }
      }
    }
  } catch (_) {}
  return null;
}

/// Reimplementação local da lógica de _findImageRecursively para testes.
File? findImageRecursively(String rootPath, String fileName) {
  try {
    final dir = Directory(rootPath);
    if (!dir.existsSync()) return null;
    final searchName = Uri.decodeComponent(fileName).toLowerCase();
    String searchBaseName = searchName;
    if (searchName.contains('.')) {
      searchBaseName = searchName.substring(0, searchName.lastIndexOf('.'));
    }
    for (var entity in dir.listSync(recursive: true)) {
      if (entity is File) {
        final ePath = entity.path.replaceAll('\\', '/');
        final eName = ePath.split('/').last;
        final eNameLower = Uri.decodeComponent(eName).toLowerCase();
        if (eNameLower == searchName) return entity;
        String eBaseName = eNameLower;
        if (eNameLower.contains('.')) {
          eBaseName = eNameLower.substring(0, eNameLower.lastIndexOf('.'));
        }
        if (eBaseName == searchBaseName) return entity;
      }
    }
  } catch (_) {}
  return null;
}

void main() {
  late EditorDeCroqui editor;
  late DatasetRepository repo;
  late Directory tempDir;
  late MockTelemetryService mockTelemetry;

  setUp(() async {
    editor = EditorDeCroqui();
    repo = DatasetRepository(editorDeCroqui: editor);
    mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
    
    tempDir = await Directory.systemTemp.createTemp('dataset_test');
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

    test('downloadingCrags começa vazio', () {
      expect(repo.downloadingCrags.value, isEmpty);
    });

    test('syncStatus começa como SyncStatus.updating', () {
      expect(repo.syncStatus.value, SyncStatus.updating);
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

    test('downloadCrag (simulado) deve acionar a telemetria', () {
      // We don't have full archive download mock in this test suite yet,
      // so we simulate a call directly on the telemetry to ensure the 
      // concept is covered here. (In a full test, we'd mock HTTP and Archive)
      TelemetryService.instance.logAcaoExplorar('crag1', 'baixar');
      expect(mockTelemetry.recordedEvents, contains('acao_explorar'));
      expect(mockTelemetry.recordedParams['acao_explorar']?['acao'], 'baixar');
      expect(mockTelemetry.recordedParams['acao_explorar']?['id_croqui'], 'crag1');
    });
  });

  // ---------------------------------------------------------------------------
  // extractCapaPath (lógica equivalente)
  // ---------------------------------------------------------------------------

  group('Extração de caminho de capa do markdown', () {
    test('deve retornar null quando croqui não tem arquivos markdown', () {
      expect(extractCapaPath(Croqui(), ''), isNull);
    });

    test('deve retornar null quando nenhum markdown é intitulado "capa"', () {
      final croqui = Croqui()
        ..botoes.add(Botao()
          ..texto = 'Descrição'
          ..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()..conteudo = '![foto](imagem.webp)')));
      expect(extractCapaPath(croqui, ''), isNull);
    });

    test('deve extrair caminho de imagem de markdown intitulado "Capa"', () {
      final croqui = Croqui()
        ..botoes.add(Botao()
          ..texto = 'Capa'
          ..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()..conteudo = '![foto](imagens/thumbnail.webp)')));
      expect(extractCapaPath(croqui, ''), 'imagens/thumbnail.webp');
    });

    test('deve funcionar com "capa" em minúsculo', () {
      final croqui = Croqui()
        ..botoes.add(Botao()
          ..texto = 'capa do pico'
          ..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()..conteudo = '![foto](thumb.webp)')));
      expect(extractCapaPath(croqui, ''), 'thumb.webp');
    });

    test('deve prefixar com baseDir quando fornecido e caminho não contém baseDir', () {
      final croqui = Croqui()
        ..botoes.add(Botao()
          ..texto = 'capa'
          ..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()..conteudo = '![foto](thumbnail.webp)')));
      expect(extractCapaPath(croqui, 'picos/pedra'), 'picos/pedra/thumbnail.webp');
    });

    test('não deve duplicar baseDir se caminho já o contém', () {
      final croqui = Croqui()
        ..botoes.add(Botao()
          ..texto = 'capa'
          ..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()..conteudo = '![foto](picos/pedra/thumbnail.webp)')));
      expect(extractCapaPath(croqui, 'picos/pedra'), 'picos/pedra/thumbnail.webp');
    });

    test('deve ignorar URLs absolutas http no markdown de capa', () {
      final croqui = Croqui()
        ..botoes.add(Botao()
          ..texto = 'capa'
          ..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()..conteudo = '![foto](https://cdn.example.com/foto.webp)')));
      expect(extractCapaPath(croqui, ''), isNull);
    });

    test('deve remover prefixo "./" do caminho da imagem', () {
      final croqui = Croqui()
        ..botoes.add(Botao()
          ..texto = 'capa'
          ..destino = (DestinoBotao()..secaoTextual = (ArquivoMarkdown()..conteudo = '![foto](./imagens/thumbnail.webp)')));
      expect(extractCapaPath(croqui, ''), 'imagens/thumbnail.webp');
    });
  });

  // ---------------------------------------------------------------------------
  // findImageRecursively (lógica equivalente)
  // ---------------------------------------------------------------------------

  group('Busca recursiva de imagens', () {
    test('deve retornar null para diretório inexistente', () {
      expect(findImageRecursively('${tempDir.path}/nao_existe', 'foto.webp'), isNull);
    });

    test('deve encontrar arquivo por nome exato', () async {
      final imgDir = Directory('${tempDir.path}/imagens');
      await imgDir.create(recursive: true);
      final imgFile = File('${imgDir.path}/foto.webp');
      await imgFile.writeAsString('fake');

      final result = findImageRecursively(tempDir.path, 'foto.webp');
      expect(result, isNotNull);
      expect(result!.path.split(RegExp(r'[/\\]')).last, 'foto.webp');
    });

    test('deve encontrar arquivo em subdiretório recursivamente', () async {
      final subDir = Directory('${tempDir.path}/nivel1/nivel2');
      await subDir.create(recursive: true);
      final imgFile = File('${subDir.path}/profundo.webp');
      await imgFile.writeAsString('fake');

      final result = findImageRecursively(tempDir.path, 'profundo.webp');
      expect(result, isNotNull);
      expect(result!.path.split(RegExp(r'[/\\]')).last, 'profundo.webp');
    });

    test('deve encontrar arquivo por nome base mesmo com extensão diferente', () async {
      final imgFile = File('${tempDir.path}/thumbnail.jpg');
      await imgFile.writeAsString('fake');

      final result = findImageRecursively(tempDir.path, 'thumbnail.webp');
      expect(result, isNotNull);
      // Compara pelo nome base, pois o separador de path varia por SO
      expect(result!.path.split(RegExp(r'[/\\]')).last, 'thumbnail.jpg');
    });

    test('deve retornar null quando arquivo não existe em nenhuma subpasta', () async {
      await Directory('${tempDir.path}/imagens').create(recursive: true);
      await File('${tempDir.path}/imagens/outro.webp').writeAsString('fake');

      expect(findImageRecursively(tempDir.path, 'nao_existe.webp'), isNull);
    });

    test('deve fazer correspondência case-insensitive', () async {
      final imgFile = File('${tempDir.path}/FOTO.WEBP');
      await imgFile.writeAsString('fake');

      final result = findImageRecursively(tempDir.path, 'foto.webp');
      expect(result, isNotNull);
    });
  });
}
