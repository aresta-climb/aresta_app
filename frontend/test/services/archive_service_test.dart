/// Suíte de testes do ArchiveService.
/// Testa extração, ofuscação XOR e geração de índice temporário.
library;
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:frontend/services/archive.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';

/// Cria um arquivo .croqui (ZIP ofuscado) no diretório informado.
/// O ZIP contém um indice.binarypb e opcionalmente um pico binarypb.
Future<File> _criarCroquiOfuscado(
  Directory tempDir,
  String nome, {
  List<int>? indiceBytes,
  String? picoId,
}) async {
  final arquivo = Archive();

  final bytesIndice = indiceBytes ?? [0x0A, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F];
  arquivo.addFile(ArchiveFile('compilado/indice.binarypb', bytesIndice.length, bytesIndice));

  if (picoId != null) {
    final bytesPico = [0x01, 0x02, 0x03];
    arquivo.addFile(ArchiveFile('compilado/$picoId/$picoId.binarypb', bytesPico.length, bytesPico));
  }

  final zipData = ZipEncoder().encode(arquivo);

  // Ofusca o primeiro byte (XOR)
  if (zipData.isNotEmpty) {
    zipData[0] = zipData[0] ^ 0xFF;
  }

  final file = File('${tempDir.path}/$nome');
  await file.writeAsBytes(zipData);
  return file;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('archive_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // extractCroqui
  // ---------------------------------------------------------------------------

  group('extractCroqui', () {
    test('deve extrair o indice.binarypb para rootDir', () async {
      final file = await _criarCroquiOfuscado(tempDir, 'repo.croqui');
      final resultado = await ArchiveService.extractCroqui(file, tempDir.path, onlyIndice: true);

      expect(resultado, isNotNull);
      final indiceFile = File('${tempDir.path}/indice.binarypb');
      expect(await indiceFile.exists(), isTrue);
    });

    test('deve retornar "experimental_pico" quando onlyIndice=true, independente de haver pico', () async {
      // Quando onlyIndice=true, os arquivos de pico são ignorados (continue no loop),
      // então picoFolderName nunca é atribuído e o resultado é sempre 'experimental_pico'
      // quando o indice.binarypb existe.
      final file = await _criarCroquiOfuscado(tempDir, 'repo.croqui', picoId: 'pedra_alta');
      final resultado = await ArchiveService.extractCroqui(file, tempDir.path, onlyIndice: true);

      expect(resultado, 'experimental_pico');
    });

    test('deve retornar "experimental_pico" quando indice existe mas sem pico', () async {
      final file = await _criarCroquiOfuscado(tempDir, 'repo.croqui');
      final resultado = await ArchiveService.extractCroqui(file, tempDir.path, onlyIndice: true);

      expect(resultado, 'experimental_pico');
    });

    test('deve re-ofuscar o arquivo após extração (XOR preservado)', () async {
      final file = await _criarCroquiOfuscado(tempDir, 'repo.croqui');
      final bytesAntes = (await file.readAsBytes()).toList();

      await ArchiveService.extractCroqui(file, tempDir.path);

      final bytesDepois = (await file.readAsBytes()).toList();
      // O primeiro byte deve ser igual ao original (re-ofuscado)
      expect(bytesDepois[0], bytesAntes[0]);
    });

    test('deve retornar null se o ZIP não contiver indice.binarypb', () async {
      // ZIP sem indice
      final arquivo = Archive();
      arquivo.addFile(ArchiveFile('compilado/outro.txt', 3, 'abc'.codeUnits));
      final zipData = ZipEncoder().encode(arquivo);
      if (zipData.isNotEmpty) zipData[0] = zipData[0] ^ 0xFF;
      final file = File('${tempDir.path}/sem_indice.croqui');
      await file.writeAsBytes(zipData);

      final resultado = await ArchiveService.extractCroqui(file, tempDir.path, onlyIndice: true);
      expect(resultado, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // createTemporaryIndice
  // ---------------------------------------------------------------------------

  group('createTemporaryIndice', () {
    test('deve criar indice.binarypb válido e serializável', () async {
      await ArchiveService.createTemporaryIndice(
        tempDir.path,
        'pedra_bonita',
        'Pedra Bonita',
        'pedra_bonita/pedra_bonita.binarypb',
      );

      final file = File('${tempDir.path}/indice.binarypb');
      expect(await file.exists(), isTrue);

      final bytes = await file.readAsBytes();
      final indice = Indice.fromBuffer(bytes);
      expect(indice.croquis.length, 1);
      expect(indice.croquis.first.id, 'pedra_bonita');
      expect(indice.croquis.first.nome, 'Pedra Bonita');
    });

    test('deve definir checksumSha256Croqui como "experimental_mode"', () async {
      await ArchiveService.createTemporaryIndice(
        tempDir.path, 'abc', 'ABC', 'abc/abc.binarypb',
      );
      final bytes = await File('${tempDir.path}/indice.binarypb').readAsBytes();
      final indice = Indice.fromBuffer(bytes);
      expect(indice.croquis.first.checksumSha256Croqui, 'experimental_mode');
    });
  });
}
