// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Suíte de testes do ZipInterceptorClient.
/// Testa o protocolo aresta-zip para leitura de arquivos locais.
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:frontend/services/http/zip_interceptor_client.dart';

void main() {
  late Directory tempDir;
  late ZipInterceptorClient client;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('zip_test');
    client = ZipInterceptorClient();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // Protocolo aresta-zip básico
  // ---------------------------------------------------------------------------

  group('Extração de arquivos', () {
    test('deve extrair arquivo de .zip (não ofuscado)', () async {
      final archive = Archive();
      final content = 'Olá ZIP World';
      archive.addFile(
        ArchiveFile('compilado/hello.txt', content.length, content.codeUnits),
      );

      final zipData = ZipEncoder().encode(archive);
      final zipFile = File('${tempDir.path}/test.zip');
      await zipFile.writeAsBytes(zipData);

      final uri = Uri(scheme: 'aresta-zip', path: '${zipFile.path}/hello.txt');
      final response = await client.get(uri);

      expect(response.statusCode, 200);
      expect(response.body, content);
    });

    test('deve extrair arquivo de .croqui (ofuscado com XOR)', () async {
      final archive = Archive();
      final content = 'Dados do Croqui';
      archive.addFile(
        ArchiveFile('compilado/secret.txt', content.length, content.codeUnits),
      );

      final zipData = ZipEncoder().encode(archive);

      // Ofusca o primeiro byte
      if (zipData.isNotEmpty) {
        zipData[0] = zipData[0] ^ 0xFF;
      }

      final croquiFile = File('${tempDir.path}/test.croqui');
      await croquiFile.writeAsBytes(zipData);

      final uri = Uri(
        scheme: 'aresta-zip',
        path: '${croquiFile.path}/secret.txt',
      );
      final response = await client.get(uri);

      expect(response.statusCode, 200);
      expect(response.body, content);
    });

    test(
      'deve adicionar prefixo "compilado/" automaticamente se não fornecido',
      () async {
        final archive = Archive();
        final content = 'Conteúdo sem prefixo';
        archive.addFile(
          ArchiveFile('compilado/dados.txt', content.length, content.codeUnits),
        );

        final zipData = ZipEncoder().encode(archive);
        final zipFile = File('${tempDir.path}/prefixo.zip');
        await zipFile.writeAsBytes(zipData);

        // Solicita sem o prefixo "compilado/"
        final uri = Uri(
          scheme: 'aresta-zip',
          path: '${zipFile.path}/dados.txt',
        );
        final response = await client.get(uri);

        expect(response.statusCode, 200);
        expect(response.body, content);
      },
    );

    test('deve extrair arquivo binário (bytes) corretamente', () async {
      final archive = Archive();
      final binaryContent = [0x50, 0x72, 0x6F, 0x74, 0x6F]; // "Proto"
      archive.addFile(
        ArchiveFile(
          'compilado/data.binarypb',
          binaryContent.length,
          binaryContent,
        ),
      );

      final zipData = ZipEncoder().encode(archive);
      final zipFile = File('${tempDir.path}/binary.zip');
      await zipFile.writeAsBytes(zipData);

      final uri = Uri(
        scheme: 'aresta-zip',
        path: '${zipFile.path}/data.binarypb',
      );
      final response = await client.get(uri);

      expect(response.statusCode, 200);
      expect(response.bodyBytes, binaryContent);
    });
  });

  // ---------------------------------------------------------------------------
  // Casos de erro
  // ---------------------------------------------------------------------------

  group('Tratamento de erros', () {
    test('deve retornar 404 para arquivo ausente dentro do zip', () async {
      final archive = Archive();
      archive.addFile(
        ArchiveFile('compilado/existe.txt', 5, 'hello'.codeUnits),
      );
      final zipData = ZipEncoder().encode(archive);
      final zipFile = File('${tempDir.path}/erro_test.zip');
      await zipFile.writeAsBytes(zipData);

      final uri = Uri(
        scheme: 'aresta-zip',
        path: '${zipFile.path}/nao_existe.txt',
      );
      final response = await client.get(uri);

      expect(response.statusCode, 404);
    });

    test('deve retornar 404 para arquivo zip inexistente no disco', () async {
      final uri = Uri(
        scheme: 'aresta-zip',
        path: '${tempDir.path}/fantasma.zip/algo.txt',
      );
      final response = await client.get(uri);

      expect(response.statusCode, 404);
    });
  });

  // ---------------------------------------------------------------------------
  // Pass-through para requisições normais
  // ---------------------------------------------------------------------------

  group('Pass-through HTTP', () {
    test('deve repassar requisições https sem interceptar', () async {
      final uri = Uri.parse('https://www.google.com');

      // Esperamos que NÃO lance erro sobre o esquema imediatamente.
      // Pode expirar em ambientes restritos, o que é esperado.
      try {
        await client.get(uri).timeout(const Duration(milliseconds: 200));
      } catch (e) {
        // Timeout ou erro de rede é aceitável aqui
        expect(e, isNot(isA<FormatException>()));
      }
    });
  });
}
