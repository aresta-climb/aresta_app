// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Testes de integração do fluxo completo aresta-zip:
/// desde o arquivo .croqui no disco até a leitura do Croqui em memória,
/// incluindo múltiplos arquivos e imagens externas.
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/http/zip_interceptor_client.dart';

/// Cria um .croqui com múltiplos arquivos internos e retorna o arquivo.
Future<File> _criarCroquiCompleto(Directory tempDir) async {
  const picoId = 'pedra_da_gavea';

  // --- Indice ---
  final resumo = ResumoCroqui()
    ..id = picoId
    ..nome = 'Pedra da Gávea'
    ..caminhoRelativo = 'downloads/$picoId/$picoId.binarypb'
    ..checksumSha256Croqui = 'xyz789';

  final indice = Indice()..croquis.add(resumo);

  // --- Croqui / Pico ---
  final md = ArquivoMarkdown()..conteudo = '![foto](imagens/thumbnail.webp)';
  final botao = Botao()
    ..texto = 'Capa'
    ..destino = (DestinoBotao()..secaoTextual = md);

  final extArquivo = ArquivoExterno()
    ..caminho = 'imagens/thumbnail.webp'
    ..checksumSha256 = 'imgchecksum';

  final croqui = Croqui()
    ..nome = 'Pedra da Gávea'
    ..caminhoThumbnail = 'imagens/thumbnail.webp'
    ..botoes.add(botao)
    ..arquivosExternos.add(extArquivo);

  // --- Imagem fictícia ---
  final fakeImg = [0x89, 0x50, 0x4E, 0x47]; // Cabeçalho PNG fictício

  // --- Monta o ZIP ---
  final archive = Archive();

  final indiceBytes = indice.writeToBuffer();
  final croquiBytes = croqui.writeToBuffer();

  archive.addFile(
    ArchiveFile('compilado/indice.binarypb', indiceBytes.length, indiceBytes),
  );
  archive.addFile(
    ArchiveFile(
      'compilado/$picoId/$picoId.binarypb',
      croquiBytes.length,
      croquiBytes,
    ),
  );
  archive.addFile(
    ArchiveFile(
      'compilado/$picoId/imagens/thumbnail.webp',
      fakeImg.length,
      fakeImg,
    ),
  );

  final zipData = ZipEncoder().encode(archive);

  // Ofusca
  if (zipData.isNotEmpty) zipData[0] = zipData[0] ^ 0xFF;

  final file = File('${tempDir.path}/gavea.croqui');
  await file.writeAsBytes(zipData);
  return file;
}

void main() {
  late Directory tempDir;
  late ZipInterceptorClient client;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('integration_test');
    client = ZipInterceptorClient();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // Fluxo de leitura completa: indice → pico → imagem
  // ---------------------------------------------------------------------------

  group('Fluxo completo de leitura via aresta-zip', () {
    test(
      'deve ler indice, extrair id do pico e buscar o binarypb dele',
      () async {
        final croquiFile = await _criarCroquiCompleto(tempDir);

        // 1. Lê o índice
        final uriIndice = Uri(
          scheme: 'aresta-zip',
          path: '${croquiFile.path}/indice.binarypb',
        );
        final resIndice = await client.get(uriIndice);
        expect(resIndice.statusCode, 200);

        final indice = Indice.fromBuffer(resIndice.bodyBytes);
        expect(indice.croquis.length, 1);
        final picoId = indice.croquis.first.id;
        expect(picoId, 'pedra_da_gavea');

        // 2. Usa a URL do índice para buscar o pico
        final picoBinaryUrl = indice
            .croquis
            .first
            .caminhoRelativo; // downloads/pedra_da_gavea/pedra_da_gavea.binarypb
        final picoRelPath = picoBinaryUrl.replaceFirst('downloads/', '');

        final uriPico = Uri(
          scheme: 'aresta-zip',
          path: '${croquiFile.path}/$picoRelPath',
        );
        final resPico = await client.get(uriPico);
        expect(resPico.statusCode, 200);

        final croqui = Croqui.fromBuffer(resPico.bodyBytes);
        expect(croqui.nome, 'Pedra da Gávea');
      },
    );

    test('deve ler o arquivo de imagem thumbnail do .croqui', () async {
      final croquiFile = await _criarCroquiCompleto(tempDir);

      final uriImg = Uri(
        scheme: 'aresta-zip',
        path: '${croquiFile.path}/pedra_da_gavea/imagens/thumbnail.webp',
      );
      final resImg = await client.get(uriImg);
      expect(resImg.statusCode, 200);
      // Verifica cabeçalho PNG fictício
      expect(resImg.bodyBytes, [0x89, 0x50, 0x4E, 0x47]);
    });

    test('deve retornar campos corretos do ArquivoMarkdown', () async {
      final croquiFile = await _criarCroquiCompleto(tempDir);

      final uriPico = Uri(
        scheme: 'aresta-zip',
        path: '${croquiFile.path}/pedra_da_gavea/pedra_da_gavea.binarypb',
      );
      final resPico = await client.get(uriPico);
      final croqui = Croqui.fromBuffer(resPico.bodyBytes);

      expect(croqui.botoes.length, 1);
      expect(croqui.botoes.first.texto, 'Capa');
      expect(
        croqui.botoes.first.destino.secaoTextual.conteudo,
        contains('thumbnail.webp'),
      );
    });

    test('deve retornar ArquivoExterno com checksum correto', () async {
      final croquiFile = await _criarCroquiCompleto(tempDir);

      final uriPico = Uri(
        scheme: 'aresta-zip',
        path: '${croquiFile.path}/pedra_da_gavea/pedra_da_gavea.binarypb',
      );
      final resPico = await client.get(uriPico);
      final croqui = Croqui.fromBuffer(resPico.bodyBytes);

      expect(croqui.arquivosExternos.length, 1);
      expect(croqui.arquivosExternos.first.caminho, 'imagens/thumbnail.webp');
      expect(croqui.arquivosExternos.first.checksumSha256, 'imgchecksum');
    });
  });

  // ---------------------------------------------------------------------------
  // Cenários de múltiplos picos
  // ---------------------------------------------------------------------------

  group('Fluxo com múltiplos picos no índice', () {
    test('deve listar todos os picos do índice corretamente', () async {
      final archive = Archive();

      final indice = Indice();
      for (int i = 0; i < 3; i++) {
        indice.croquis.add(
          ResumoCroqui()
            ..id = 'pico_$i'
            ..nome = 'Pico $i'
            ..caminhoRelativo = 'downloads/pico_$i/pico_$i.binarypb'
            ..checksumSha256Croqui = 'check_$i',
        );
      }

      final indiceBytes = indice.writeToBuffer();
      archive.addFile(
        ArchiveFile(
          'compilado/indice.binarypb',
          indiceBytes.length,
          indiceBytes,
        ),
      );

      final zipData = ZipEncoder().encode(archive);
      if (zipData.isNotEmpty) zipData[0] = zipData[0] ^ 0xFF;

      final file = File('${tempDir.path}/multi.croqui');
      await file.writeAsBytes(zipData);

      final uri = Uri(
        scheme: 'aresta-zip',
        path: '${file.path}/indice.binarypb',
      );
      final response = await client.get(uri);

      final restored = Indice.fromBuffer(response.bodyBytes);
      expect(restored.croquis.length, 3);
      expect(
        restored.croquis.map((r) => r.id),
        containsAll(['pico_0', 'pico_1', 'pico_2']),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Verificação de que arquivos de .zip padrão (sem ofuscação) também funcionam
  // ---------------------------------------------------------------------------

  group('Compatibilidade com .zip padrão', () {
    test('deve ler .zip padrão sem precisar de de-ofuscação', () async {
      final indice = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = 'zip_pico'
            ..nome = 'Pico ZIP',
        );

      final archive = Archive();
      final bytes = indice.writeToBuffer();
      archive.addFile(
        ArchiveFile('compilado/indice.binarypb', bytes.length, bytes),
      );

      final zipData = ZipEncoder().encode(archive);
      // NÃO ofusca

      final file = File('${tempDir.path}/repo.zip');
      await file.writeAsBytes(zipData);

      final uri = Uri(
        scheme: 'aresta-zip',
        path: '${file.path}/indice.binarypb',
      );
      final response = await client.get(uri);

      expect(response.statusCode, 200);
      final restored = Indice.fromBuffer(response.bodyBytes);
      expect(restored.croquis.first.id, 'zip_pico');
    });
  });
}
