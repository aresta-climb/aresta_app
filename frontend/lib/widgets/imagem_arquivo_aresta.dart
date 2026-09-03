// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/firebase/app_logger.dart';

/// Chave de cache imutável para [ImagemArquivoAresta], incorporando o caminho,
/// escala e o checksum SHA-256 para invalidação reativa no [ImageCache].
@immutable
class ChaveImagemArquivoAresta {
  /// Caminho canônico do arquivo no disco.
  final String caminho;

  /// Fator de escala da imagem.
  final double escala;

  /// Hash SHA-256 do arquivo (autoritativo para cache-busting).
  final String? checksumSha256;

  /// Cria uma nova instância de [ChaveImagemArquivoAresta].
  const ChaveImagemArquivoAresta({
    required this.caminho,
    this.escala = 1.0,
    this.checksumSha256,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is ChaveImagemArquivoAresta &&
        other.caminho == caminho &&
        other.escala == escala &&
        other.checksumSha256 == checksumSha256;
  }

  @override
  int get hashCode => Object.hash(caminho, escala, checksumSha256);

  @override
  String toString() =>
      'ChaveImagemArquivoAresta(caminho: $caminho, escala: $escala, checksumSha256: $checksumSha256)';
}

/// Provedor especializado de imagem local do ecossistema Aresta com invalidação por SHA-256.
///
/// Diferente do [FileImage] padrão do Flutter (que avalia apenas o caminho do arquivo),
/// o [ImagemArquivoAresta] embute o [checksumSha256] em sua chave de cache. Sempre que um novo
/// pacote for sincronizado ou editado, se o hash mudar, o Flutter detecta automaticamente
/// a nova versão e invalida a textura anterior em memória sem piscar imagens inalteradas.
class ImagemArquivoAresta extends ImageProvider<ChaveImagemArquivoAresta> {
  /// O arquivo no sistema de arquivos local.
  final File arquivo;

  /// Escala de renderização da imagem.
  final double escala;

  /// Checksum SHA-256 da imagem (opcional, autoritativo para cache-busting).
  final String? checksumSha256;

  /// Cria um provedor [ImagemArquivoAresta] para o arquivo local informado.
  ///
  /// Caso [checksumSha256] seja nulo ou vazio, emite um registro de erro na telemetria
  /// via [AppLogger] e recorre ao timestamp de modificação ([File.lastModifiedSync])
  /// como chave de diferenciação para manter a reatividade de recarga no Flutter.
  ImagemArquivoAresta(
    this.arquivo, {
    this.escala = 1.0,
    String? checksumSha256,
  }) : checksumSha256 = _resolverChecksum(arquivo, checksumSha256);

  static String _resolverChecksum(File arquivo, String? checksumSha256) {
    if (checksumSha256 != null && checksumSha256.isNotEmpty) {
      return checksumSha256;
    }
    AppLogger.instance.logError(
      'Checksum SHA-256 ausente ou nulo para imagem local (${arquivo.path}). Utilizando fallback de timestamp.',
    );
    try {
      if (arquivo.existsSync()) {
        return arquivo.lastModifiedSync().millisecondsSinceEpoch.toString();
      }
    } catch (_) {}
    return '';
  }

  @override
  Future<ChaveImagemArquivoAresta> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ChaveImagemArquivoAresta>(
      ChaveImagemArquivoAresta(
        caminho: arquivo.path,
        escala: escala,
        checksumSha256: checksumSha256,
      ),
    );
  }

  @override
  ImageStreamCompleter loadImage(
    ChaveImagemArquivoAresta key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _carregarAssincrono(key, decode: decode),
      scale: key.escala,
      debugLabel: key.caminho,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Caminho: ${arquivo.path}'),
        if (checksumSha256 != null)
          ErrorDescription('SHA256: $checksumSha256'),
      ],
    );
  }

  Future<ui.Codec> _carregarAssincrono(
    ChaveImagemArquivoAresta key, {
    required ImageDecoderCallback decode,
  }) async {
    final bytes = await arquivo.readAsBytes();
    if (bytes.isEmpty) {
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError('O arquivo $arquivo está vazio e não pode ser decodificado.');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is ImagemArquivoAresta &&
        other.arquivo.path == arquivo.path &&
        other.escala == escala &&
        other.checksumSha256 == checksumSha256;
  }

  @override
  int get hashCode => Object.hash(arquivo.path, escala, checksumSha256);

  @override
  String toString() =>
      'ImagemArquivoAresta("${arquivo.path}", escala: $escala, sha: $checksumSha256)';
}
