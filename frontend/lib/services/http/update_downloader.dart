import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

/// Um modelo representando uma entrada de arquivo do índice mestre.
class IndexEntry {
  final String filename;
  final String expectedSha256;
  final String downloadUrl;

  IndexEntry({
    required this.filename,
    required this.expectedSha256,
    required this.downloadUrl,
  });
}

/// Uma classe utilitária para baixar e verificar arquivos.
///
/// Ela garante que os arquivos baixados correspondam aos seus checksums esperados
/// antes de serem considerados válidos e armazenados no diretório de preparação (staging).
class UpdateDownloader {
  /// Um cliente HTTP reutilizável para baixar arquivos.
  final http.Client _client = http.Client();

  /// Baixa atualizações, verifica-as e as coloca no diretório de preparação.
  ///
  /// Lança uma [Exception] se um download falhar ou se uma incompatibilidade de checksum for detectada.
  Future<void> downloadAndVerifyUpdates({
    required List<IndexEntry> filesToUpdate,
    required Directory stagingDir,
  }) async {
    for (final fileEntry in filesToUpdate) {
      final targetFile = File('${stagingDir.path}/${fileEntry.filename}');

      print('Downloading ${fileEntry.filename}...');

      // 1. Baixa o arquivo diretamente para o diretório de preparação
      final response = await _client.get(Uri.parse(fileEntry.downloadUrl));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download ${fileEntry.filename}: HTTP ${response.statusCode}',
        );
      }

      await targetFile.writeAsBytes(response.bodyBytes);

      // 2. Verifica o Checksum via Streaming
      print('Verifying checksum for ${fileEntry.filename}...');

      final bool isChecksumValid = await _verifyFileChecksum(
        file: targetFile,
        expectedHexHash: fileEntry.expectedSha256,
      );

      if (!isChecksumValid) {
        // Se estiver corrompido ou adulterado, exclua o arquivo ruim
        await targetFile.delete();
        throw Exception(
          'Checksum mismatch for ${fileEntry.filename}. Download corrupted.',
        );
      }

      print('Verified ${fileEntry.filename} successfully.');
    }
  }

  /// Calcula o hash SHA-256 lendo o arquivo em pedaços (streams).
  Future<bool> _verifyFileChecksum({
    required File file,
    required String expectedHexHash,
  }) async {
    // Abre um fluxo de leitura (read stream) do arquivo
    final stream = file.openRead();

    // Passa o fluxo para a calculadora SHA-256 da biblioteca de criptografia
    final Digest hashResult = await sha256.bind(stream).first;

    // Compara a string hexadecimal resultante com o hash esperado
    return hashResult.toString() == expectedHexHash;
  }

  /// Fecha o cliente HTTP.
  void dispose() {
    _client.close();
  }
}
