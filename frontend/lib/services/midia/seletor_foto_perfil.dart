// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Assinatura para função de conversão de bytes de imagem para formato WebP.
typedef ConversorBytesWebp = Future<Uint8List> Function(Uint8List bytesOriginais);

/// Contrato para seleção, recorte e compressão da foto de perfil do escalador.
abstract class SeletorFotoPerfil {
  /// Abre o seletor nativo de imagens do dispositivo, corrige a orientação EXIF,
  /// recorta/comprime a imagem em formato quadrado (256x256 WebP) e retorna uma
  /// Data URI (`data:image/webp;base64,...`) ou `null` quando cancelado.
  Future<String?> selecionarFotoComoDataUri();
}

/// Implementação nativa de [SeletorFotoPerfil] baseada em [MethodChannel].
class SeletorFotoPerfilNativo implements SeletorFotoPerfil {
  static SeletorFotoPerfil? _instanciaCompartilhada;

  /// Instância compartilhada padrão do seletor de foto de perfil.
  static SeletorFotoPerfil get instancia =>
      _instanciaCompartilhada ??= SeletorFotoPerfilNativo();

  /// Substitui a instância compartilhada em testes.
  static set instancia(SeletorFotoPerfil? valor) {
    _instanciaCompartilhada = valor;
  }

  /// Redefine a instância compartilhada para o estado inicial em testes.
  static void redefinirParaTestes() {
    _instanciaCompartilhada = null;
  }

  static const MethodChannel _canalPadrao = MethodChannel(
    'app.escalada.croquis/seletor_midia',
  );

  final MethodChannel _canal;
  final ConversorBytesWebp _conversorWebp;

  /// Cria uma instância de [SeletorFotoPerfilNativo].
  SeletorFotoPerfilNativo({
    MethodChannel? canal,
    ConversorBytesWebp? conversorWebp,
  }) : _canal = canal ?? _canalPadrao,
       _conversorWebp = conversorWebp ?? _converterParaWebpPadrao;

  static bool _ehFormatoWebp(Uint8List bytes) {
    return bytes.length >= 12 &&
        bytes[0] == 0x52 && // R
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46 && // F
        bytes[3] == 0x46 && // F
        bytes[8] == 0x57 && // W
        bytes[9] == 0x45 && // E
        bytes[10] == 0x42 && // B
        bytes[11] == 0x50; // P
  }

  static Future<Uint8List> _converterParaWebpPadrao(Uint8List bytesOriginais) =>
      FlutterImageCompress.compressWithList(
        bytesOriginais,
        minWidth: 256,
        minHeight: 256,
        quality: 82,
        format: CompressFormat.webp,
        autoCorrectionAngle: true,
      );

  @override
  Future<String?> selecionarFotoComoDataUri() async {
    try {
      final bytes = await _canal.invokeMethod<Uint8List>(
        'selecionarFotoPerfil',
      );
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      var bytesWebp = bytes;
      if (!_ehFormatoWebp(bytes)) {
        try {
          final convertidos = await _conversorWebp(bytes);
          if (convertidos.isNotEmpty) {
            bytesWebp = convertidos;
          }
        } catch (_) {}
      }
      return 'data:image/webp;base64,${base64Encode(bytesWebp)}';
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

