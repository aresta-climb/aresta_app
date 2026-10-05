// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/feedback/compressor_imagem.dart';

void main() {
  group('CompressorImagem', () {
    test('comprime para WebP com sucesso quando o compressor nativo responde', () async {
      final bytesEntrada = Uint8List.fromList([1, 2, 3, 4, 5]);
      final bytesWebpEsperados = Uint8List.fromList([82, 73, 70, 70, 87, 69, 66, 80]); // RIFF...WEBP

      final compressor = CompressorImagem(
        compressaoNativaOverride: (bytes, {minHeight = 1920, minWidth = 1080, quality = 80}) async {
          expect(bytes, equals(bytesEntrada));
          expect(quality, equals(80));
          return bytesWebpEsperados;
        },
      );

      final resultado = await compressor.comprimirParaWebp(bytesEntrada);

      expect(resultado.bytes, equals(bytesWebpEsperados));
      expect(resultado.formato, equals('webp'));
      expect(resultado.extensao, equals('webp'));
      expect(resultado.tipoMime, equals('image/webp'));
    });

    test('aplica fallback gracioso para PNG caso a compressão retorne nulo', () async {
      final bytesOriginais = Uint8List.fromList([137, 80, 78, 71]); // PNG magic bytes

      final compressor = CompressorImagem(
        compressaoNativaOverride: (bytes, {minHeight = 1920, minWidth = 1080, quality = 80}) async {
          return null;
        },
      );

      final resultado = await compressor.comprimirParaWebp(bytesOriginais);

      expect(resultado.bytes, equals(bytesOriginais));
      expect(resultado.formato, equals('png'));
      expect(resultado.extensao, equals('png'));
      expect(resultado.tipoMime, equals('image/png'));
    });

    test('aplica fallback gracioso para PNG caso a compressão lance exceção de plataforma', () async {
      final bytesOriginais = Uint8List.fromList([10, 20, 30]);

      final compressor = CompressorImagem(
        compressaoNativaOverride: (bytes, {minHeight = 1920, minWidth = 1080, quality = 80}) async {
          throw Exception('MissingPluginException: No implementation found for method compressWithList');
        },
      );

      final resultado = await compressor.comprimirParaWebp(bytesOriginais);

      expect(resultado.bytes, equals(bytesOriginais));
      expect(resultado.formato, equals('png'));
      expect(resultado.extensao, equals('png'));
      expect(resultado.tipoMime, equals('image/png'));
    });

    test('aplica fallback para PNG se a compressão nativa retornar lista de bytes vazia', () async {
      final bytesOriginais = Uint8List.fromList([10, 20, 30]);

      final compressor = CompressorImagem(
        compressaoNativaOverride: (bytes, {minHeight = 1920, minWidth = 1080, quality = 80}) async {
          return Uint8List(0);
        },
      );

      final resultado = await compressor.comprimirParaWebp(bytesOriginais);

      expect(resultado.bytes, equals(bytesOriginais));
      expect(resultado.formato, equals('png'));
      expect(resultado.extensao, equals('png'));
      expect(resultado.tipoMime, equals('image/png'));
    });

    test('retorna bytes vazios se a entrada for vazia sem acionar compressor', () async {
      bool chamado = false;
      final compressor = CompressorImagem(
        compressaoNativaOverride: (bytes, {minHeight = 1920, minWidth = 1080, quality = 80}) async {
          chamado = true;
          return Uint8List.fromList([1]);
        },
      );

      final resultado = await compressor.comprimirParaWebp(Uint8List(0));

      expect(chamado, isFalse);
      expect(resultado.bytes, isEmpty);
      expect(resultado.formato, equals('png'));
    });
  });
}
