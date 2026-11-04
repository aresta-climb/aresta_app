// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter/services.dart';

/// Contrato para seleção, recorte e compressão da foto de perfil do escalador.
abstract class SeletorFotoPerfil {
  /// Abre o seletor nativo de imagens do dispositivo, recorta/comprime a imagem
  /// em formato quadrado (256x256 JPEG) e retorna uma Data URI (`data:image/jpeg;base64,...`)
  /// ou `null` quando a operação for cancelada pelo usuário.
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

  /// Cria uma instância de [SeletorFotoPerfilNativo].
  SeletorFotoPerfilNativo({MethodChannel? canal})
    : _canal = canal ?? _canalPadrao;

  @override
  Future<String?> selecionarFotoComoDataUri() async {
    try {
      final bytes = await _canal.invokeMethod<Uint8List>(
        'selecionarFotoPerfil',
      );
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

