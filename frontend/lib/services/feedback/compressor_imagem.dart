// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Módulo de compressão de imagens para otimização de capturas de tela no feedback.
/// Reduz o tamanho de transferências em conexões lentas de montanha via formato WebP.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../firebase/app_logger.dart';

/// Encapsula os bytes resultantes e os metadados de formato da compressão de imagem.
class ResultadoCompressao {
  /// Bytes da imagem após o processamento (comprimida ou original caso ocorra fallback).
  final Uint8List bytes;

  /// Formato da imagem resultante: `'webp'` ou `'png'`.
  final String formato;

  const ResultadoCompressao({
    required this.bytes,
    required this.formato,
  });

  /// Extensão de arquivo correspondente ao formato (ex: `'webp'` ou `'png'`).
  String get extensao => formato;

  /// Tipo MIME correspondente para requisições HTTP (ex: `'image/webp'` ou `'image/png'`).
  String get tipoMime => 'image/$formato';
}

/// Serviço responsável por comprimir capturas de tela antes da persistência na fila local.
///
/// Utiliza internamente a biblioteca nativa `flutter_image_compress` para codificar em WebP
/// com alta performance (C++/libwebp) e baixo consumo de memória. Caso a plataforma não
/// suporte ou ocorra qualquer erro de canal de plataforma, aplica fallback gracioso para os
/// bytes originais em PNG.
class CompressorImagem {
  /// Assinatura da função de compressão nativa para permitir injeção de dependência em testes.
  final Future<Uint8List?> Function(
    Uint8List bytes, {
    int quality,
    int minWidth,
    int minHeight,
  })? compressaoNativaOverride;

  /// Cria uma nova instância de [CompressorImagem].
  const CompressorImagem({this.compressaoNativaOverride});

  /// Comprime a lista de [bytesOriginais] (normalmente codificada em PNG pelo BetterFeedback)
  /// para o formato WebP com a qualidade especificada.
  ///
  /// Caso [bytesOriginais] esteja vazio, retorna imediatamente uma lista vazia em formato `'png'`.
  /// Se a compressão nativa falhar, lançar exceção ou retornar bytes vazios, o método
  /// executa **fallback gracioso**, retornando [bytesOriginais] associados ao formato `'png'`.
  Future<ResultadoCompressao> comprimirParaWebp(
    Uint8List bytesOriginais, {
    int qualidade = 80,
    int minWidth = 1080,
    int minHeight = 1920,
  }) async {
    if (bytesOriginais.isEmpty) {
      return ResultadoCompressao(bytes: bytesOriginais, formato: 'png');
    }

    try {
      final Uint8List? bytesComprimidos;
      if (compressaoNativaOverride != null) {
        bytesComprimidos = await compressaoNativaOverride!(
          bytesOriginais,
          quality: qualidade,
          minWidth: minWidth,
          minHeight: minHeight,
        );
      } else {
        bytesComprimidos = await FlutterImageCompress.compressWithList(
          bytesOriginais,
          format: CompressFormat.webp,
          quality: qualidade,
          minWidth: minWidth,
          minHeight: minHeight,
        );
      }

      if (bytesComprimidos != null && bytesComprimidos.isNotEmpty) {
        return ResultadoCompressao(
          bytes: bytesComprimidos,
          formato: 'webp',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Falha ao comprimir imagem para WebP. Aplicando fallback para PNG.',
        error: e,
        stackTrace: stackTrace,
      );
    }

    // Fallback gracioso: preserva a captura original em PNG
    return ResultadoCompressao(
      bytes: bytesOriginais,
      formato: 'png',
    );
  }
}
