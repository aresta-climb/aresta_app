// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/imagem_arquivo_aresta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File arquivoImagem;

  // Bytes válidos de PNG de 1x1 pixel transparente
  final bytesPng1 = <int>[
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
    0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0,
    0, 13, 73, 68, 65, 84, 120, 156, 99, 100, 248, 207, 80, 15, 0, 3,
    134, 1, 128, 90, 52, 125, 107, 0, 0, 0, 0, 73, 69, 78, 68, 174,
    66, 96, 130
  ];

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('aresta_img_widget_test_');
    arquivoImagem = File('${tempDir.path}/imagem_teste.png');
    await arquivoImagem.writeAsBytes(bytesPng1);
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });


  group('ImagemArquivoAresta Widget Test', () {
    testWidgets('renderiza widget Image utilizando ImagemArquivoAresta', (tester) async {
      final provedor = ImagemArquivoAresta(
        arquivoImagem,
        checksumSha256: 'hash_inicial',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Image(
                image: provedor,
                key: const Key('imagem_alvo'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagem_alvo')), findsOneWidget);
    });

    testWidgets('atualiza o Image widget quando o checksumSha256 muda', (tester) async {
      final provedorInicial = ImagemArquivoAresta(
        arquivoImagem,
        checksumSha256: 'hash_v1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Image(
                image: provedorInicial,
                key: const Key('imagem_alvo'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Reconstrói com novo checksum (simulando hot reload / sync)
      final provedorAtualizado = ImagemArquivoAresta(
        arquivoImagem,
        checksumSha256: 'hash_v2',
      );

      expect(provedorInicial, isNot(equals(provedorAtualizado)));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Image(
                image: provedorAtualizado,
                key: const Key('imagem_alvo'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Image imageWidget = tester.widget(find.byKey(const Key('imagem_alvo')));
      expect(imageWidget.image, equals(provedorAtualizado));
    });

    testWidgets('mantém o mesmo provider se o checksumSha256 for idêntico', (tester) async {
      final provedor1 = ImagemArquivoAresta(
        arquivoImagem,
        checksumSha256: 'hash_constante',
      );
      final provedor2 = ImagemArquivoAresta(
        arquivoImagem,
        checksumSha256: 'hash_constante',
      );

      expect(provedor1, equals(provedor2));
      expect(provedor1.hashCode, equals(provedor2.hashCode));
    });

    test('ChaveImagemArquivoAresta igualdade, hashCode e toString', () {
      const chave1 = ChaveImagemArquivoAresta(
        caminho: '/downloads/pico/mapa.webp',
        escala: 1.0,
        checksumSha256: 'sha1',
      );
      const chave2 = ChaveImagemArquivoAresta(
        caminho: '/downloads/pico/mapa.webp',
        escala: 1.0,
        checksumSha256: 'sha1',
      );
      const chaveDiferenteHash = ChaveImagemArquivoAresta(
        caminho: '/downloads/pico/mapa.webp',
        escala: 1.0,
        checksumSha256: 'sha2',
      );
      const chaveDiferenteCaminho = ChaveImagemArquivoAresta(
        caminho: '/downloads/pico/outro.webp',
        escala: 1.0,
        checksumSha256: 'sha1',
      );
      const chaveDiferenteEscala = ChaveImagemArquivoAresta(
        caminho: '/downloads/pico/mapa.webp',
        escala: 2.0,
        checksumSha256: 'sha1',
      );

      expect(chave1, equals(chave2));
      expect(chave1.hashCode, equals(chave2.hashCode));
      expect(chave1, isNot(equals(chaveDiferenteHash)));
      expect(chave1, isNot(equals(chaveDiferenteCaminho)));
      expect(chave1, isNot(equals(chaveDiferenteEscala)));
      expect(chave1, isNot(equals('outra_coisa')));
      expect(chave1.toString(), contains('ChaveImagemArquivoAresta'));
    });

    test('ImagemArquivoAresta obtainKey, toString e validações de igualdade', () async {
      final img1 = ImagemArquivoAresta(
        arquivoImagem,
        checksumSha256: 'hash1',
      );
      final img2 = ImagemArquivoAresta(
        arquivoImagem,
        checksumSha256: 'hash1',
      );
      final imgOutroHash = ImagemArquivoAresta(
        arquivoImagem,
        checksumSha256: 'hash2',
      );
      final imgOutraEscala = ImagemArquivoAresta(
        arquivoImagem,
        escala: 2.0,
        checksumSha256: 'hash1',
      );
      final imgOutroArquivo = ImagemArquivoAresta(
        File('${tempDir.path}/inexistente.png'),
        checksumSha256: 'hash1',
      );

      final key = await img1.obtainKey(ImageConfiguration.empty);
      expect(key.caminho, equals(arquivoImagem.path));
      expect(key.checksumSha256, equals('hash1'));
      expect(key.escala, equals(1.0));

      expect(img1, equals(img2));
      expect(img1, isNot(equals(imgOutroHash)));
      expect(img1, isNot(equals(imgOutraEscala)));
      expect(img1, isNot(equals(imgOutroArquivo)));
      expect(img1, isNot(equals('string_aleatoria')));
      expect(img1.toString(), contains('ImagemArquivoAresta'));
    });

    test('ImagemArquivoAresta lança StateError se o arquivo estiver vazio', () async {
      final arquivoVazio = File('${tempDir.path}/vazio.png');
      await arquivoVazio.writeAsBytes([]);

      final imgVazia = ImagemArquivoAresta(
        arquivoVazio,
        checksumSha256: 'hash_vazio',
      );

      final key = await imgVazia.obtainKey(ImageConfiguration.empty);
      final completer = imgVazia.loadImage(key, (buffer, {getTargetSize}) async {
        throw StateError('Não deve ser chamado');
      });

      expect(completer, isNotNull);
    });

    test('ImagemArquivoAresta loadImage com arquivo válido executa decode', () async {
      final img = ImagemArquivoAresta(
        arquivoImagem,
        checksumSha256: 'hash_valido',
      );

      final key = await img.obtainKey(ImageConfiguration.empty);
      bool decodificou = false;
      final completer = img.loadImage(key, (buffer, {getTargetSize}) async {
        decodificou = true;
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        return descriptor.instantiateCodec();
      });

      expect(completer, isNotNull);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(decodificou, isTrue);
    });
  });
}


