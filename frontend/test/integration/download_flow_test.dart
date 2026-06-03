/// Suíte de testes do protocolo aresta-zip via ZipInterceptorClient.
/// Simula downloads completos (indice + pico) a partir de um arquivo .croqui local.
library;
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:frontend/services/zip_interceptor_client.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

/// Cria um .croqui com um [Indice] protobuf e um pico [Croqui] protobuf dentro.
Future<File> _criarCroquiComDados(Directory tempDir, String picoId) async {
  // Cria o índice apontando para o pico
  final resumo = ResumoCroqui()
    ..id = picoId
    ..nome = 'Pedra Teste'
    ..url = 'downloads/$picoId/$picoId.binarypb'
    ..checksumSha256Croqui = 'abc123';

  final indice = Indice()..croquis.add(resumo);

  // Cria o pico
  final croqui = Croqui()..nome = 'Pedra Teste';

  // Monta o ZIP
  final archive = Archive();
  final indiceBytes = indice.writeToBuffer();
  final croquiBytes = croqui.writeToBuffer();

  archive.addFile(ArchiveFile('compilado/indice.binarypb', indiceBytes.length, indiceBytes));
  archive.addFile(ArchiveFile('compilado/$picoId/$picoId.binarypb', croquiBytes.length, croquiBytes));

  final zipData = ZipEncoder().encode(archive);

  // Ofusca o primeiro byte
  if (zipData.isNotEmpty) {
    zipData[0] = zipData[0] ^ 0xFF;
  }

  final file = File('${tempDir.path}/$picoId.croqui');
  await file.writeAsBytes(zipData);
  return file;
}

void main() {
  late Directory tempDir;
  late ZipInterceptorClient client;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('download_test');
    client = ZipInterceptorClient();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // Simulação de download de índice
  // ---------------------------------------------------------------------------

  group('Download do índice', () {
    test('deve baixar e parsear indice.binarypb do .croqui', () async {
      const picoId = 'pedra_alta';
      final croquiFile = await _criarCroquiComDados(tempDir, picoId);

      final uri = Uri(
        scheme: 'aresta-zip',
        path: '${croquiFile.path}/indice.binarypb',
      );

      final response = await client.get(uri);

      expect(response.statusCode, 200);

      final indice = Indice.fromBuffer(response.bodyBytes);
      expect(indice.croquis.length, 1);
      expect(indice.croquis.first.id, picoId);
      expect(indice.croquis.first.nome, 'Pedra Teste');
    });
  });

  // ---------------------------------------------------------------------------
  // Simulação de download de pico
  // ---------------------------------------------------------------------------

  group('Download de pico (binarypb)', () {
    test('deve baixar e parsear croqui de um pico específico', () async {
      const picoId = 'pedra_bonita';
      final croquiFile = await _criarCroquiComDados(tempDir, picoId);

      // URL completa como o DatasetRepository construiria
      final uri = Uri(
        scheme: 'aresta-zip',
        path: '${croquiFile.path}/$picoId/$picoId.binarypb',
      );

      final response = await client.get(uri);

      expect(response.statusCode, 200);

      final croqui = Croqui.fromBuffer(response.bodyBytes);
      expect(croqui.nome, 'Pedra Teste');
    });

    test('deve retornar 404 para pico inexistente no .croqui', () async {
      const picoId = 'pedra_bonita';
      final croquiFile = await _criarCroquiComDados(tempDir, picoId);

      final uri = Uri(
        scheme: 'aresta-zip',
        path: '${croquiFile.path}/pico_fantasma/pico_fantasma.binarypb',
      );

      final response = await client.get(uri);
      expect(response.statusCode, 404);
    });
  });

  // ---------------------------------------------------------------------------
  // Verificação de conteúdo salvo localmente
  // ---------------------------------------------------------------------------

  group('Persistência de downloads', () {
    test('deve ser possível salvar os bytes recebidos em um arquivo local', () async {
      const picoId = 'pedra_vermelha';
      final croquiFile = await _criarCroquiComDados(tempDir, picoId);

      final uri = Uri(
        scheme: 'aresta-zip',
        path: '${croquiFile.path}/indice.binarypb',
      );

      final response = await client.get(uri);
      expect(response.statusCode, 200);

      // Salva os bytes em disco (como o DatasetRepository faz)
      final savedFile = File('${tempDir.path}/indice_salvo.binarypb');
      await savedFile.writeAsBytes(response.bodyBytes);

      // Verifica que o arquivo salvo pode ser re-lido como Indice
      final bytes = await savedFile.readAsBytes();
      final indice = Indice.fromBuffer(bytes);
      expect(indice.croquis.isNotEmpty, isTrue);
    });
  });
}
