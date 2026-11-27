// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Assinatura de função responsável por capturar os bytes PNG de um cartão montado em um [RepaintBoundary].
typedef CapturadorBytesCartao = Future<Uint8List> Function(
  GlobalKey chaveRepaintBoundary,
);

/// Utilitário responsável por rasterizar um [RepaintBoundary] em memória para PNG de alta nitidez
/// de forma assíncrona sem bloquear o orçamento de meio frame da interface.
abstract final class CapturadorImagemCartao {
  /// Captura o widget associado à [chaveRepaintBoundary] como imagem PNG (`Uint8List`).
  ///
  /// Lança [StateError] imediatamente se a chave não estiver montada em um [RenderRepaintBoundary]
  /// ou se a rasterização não produzir bytes PNG válidos.
  static Future<Uint8List> capturarPng(
    GlobalKey chaveRepaintBoundary, {
    double pixelRatio = 3.0,
  }) async {
    final objetoRenderizacao =
        chaveRepaintBoundary.currentContext?.findRenderObject();
    if (objetoRenderizacao is! RenderRepaintBoundary) {
      throw StateError(
        'Não foi possível capturar o cartão: a chave informada não pertence a um RenderRepaintBoundary ativo.',
      );
    }

    final ui.Image imagem = await objetoRenderizacao.toImage(
      pixelRatio: pixelRatio,
    );
    try {
      final ByteData dados = (await imagem.toByteData(
        format: ui.ImageByteFormat.png,
      ))!;
      return dados.buffer.asUint8List();
    } finally {
      imagem.dispose();
    }
  }
}
