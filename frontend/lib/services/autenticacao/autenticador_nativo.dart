// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/services.dart';

/// Credencial retornada pelo seletor nativo de contas do sistema operacional (Android/iOS).
class CredencialNativaOAuth {
  /// Token JWT (`id_token`) assinado pelo provedor nativo (Google ou Apple).
  final String? idToken;

  /// Nonce em texto plano utilizado na solicitação nativa (exigido pelo Sign in with Apple).
  final String? nonce;

  /// Nome de exibição retornado pelo seletor nativo, quando disponível.
  final String? nomeExibicao;

  /// URL da foto de perfil retornada pelo seletor nativo, quando disponível.
  final String? fotoUrl;

  /// Indica se o usuário fechou ou cancelou explicitamente o modal nativo.
  final bool cancelado;

  /// Cria uma instância imutável de [CredencialNativaOAuth].
  const CredencialNativaOAuth({
    this.idToken,
    this.nonce,
    this.nomeExibicao,
    this.fotoUrl,
    this.cancelado = false,
  });

  /// Indica se a credencial contém um `id_token` não vazio pronto para validação no Supabase.
  bool get possuiIdToken => idToken != null && idToken!.trim().isNotEmpty;
}

/// Contrato para acionamento dos modais nativos de autenticação (Google One Tap / Account Picker e Apple Face ID).
abstract class AutenticadorNativo {
  /// Abre o seletor nativo de contas do Google e retorna o `id_token` emitido para [webClientId].
  ///
  /// Retorna `null` caso o seletor nativo não esteja disponível na plataforma atual.
  Future<CredencialNativaOAuth?> solicitarCredencialGoogle({
    required String webClientId,
  });

  /// Abre o modal nativo do Sign in with Apple (Face ID / Touch ID) e retorna o `id_token` e o `nonce`.
  ///
  /// Retorna `null` caso o modal nativo não esteja disponível na plataforma atual.
  Future<CredencialNativaOAuth?> solicitarCredencialApple();
}

/// Implementação de [AutenticadorNativo] integrada ao `MethodChannel` nativo do Android e iOS.
class AutenticadorNativoCanal implements AutenticadorNativo {
  /// Nome do canal de plataforma registrado em `MainActivity.kt` e `AppDelegate.swift`.
  static const String nomeCanal = 'app.escalada.croquis/autenticacao_nativa';

  /// Client ID Web OAuth 2.0 padrão do projeto Aresta Climb no Google Cloud / Supabase.
  static const String idClienteWebGooglePadrao =
      '737982062809-8tsnq2eb3a8c30rsiolfrl75f1u6h8tr.apps.googleusercontent.com';

  static const MethodChannel _canal = MethodChannel(nomeCanal);

  static AutenticadorNativo? _instanciaCompartilhada;

  /// Instância compartilhada padrão do autenticador nativo.
  static AutenticadorNativo get instancia =>
      _instanciaCompartilhada ??= AutenticadorNativoCanal();

  /// Permite substituir a instância compartilhada em testes.
  static set instancia(AutenticadorNativo valor) {
    _instanciaCompartilhada = valor;
  }

  /// Redefine a instância compartilhada para o estado inicial em testes.
  static void redefinirParaTestes() {
    _instanciaCompartilhada = null;
  }

  /// Cria uma instância de [AutenticadorNativoCanal].
  AutenticadorNativoCanal();

  @override
  Future<CredencialNativaOAuth?> solicitarCredencialGoogle({
    required String webClientId,
  }) async {
    try {
      final resposta = await _canal.invokeMapMethod<String, dynamic>(
        'solicitarIdTokenGoogle',
        {'webClientId': webClientId},
      );
      return _interpretarRespostaCanal(resposta);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<CredencialNativaOAuth?> solicitarCredencialApple() async {
    try {
      final resposta = await _canal.invokeMapMethod<String, dynamic>(
        'solicitarIdTokenApple',
      );
      return _interpretarRespostaCanal(resposta);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static CredencialNativaOAuth? _interpretarRespostaCanal(
    Map<String, dynamic>? mapa,
  ) {
    if (mapa == null) {
      return null;
    }
    if (mapa['cancelado'] == true) {
      return const CredencialNativaOAuth(cancelado: true);
    }
    final token = (mapa['idToken'] as String?)?.trim();
    if (token == null || token.isEmpty) {
      return null;
    }
    return CredencialNativaOAuth(
      idToken: token,
      nonce: mapa['nonce'] as String?,
      nomeExibicao: mapa['nomeExibicao'] as String?,
      fotoUrl: mapa['fotoUrl'] as String?,
    );
  }
}
