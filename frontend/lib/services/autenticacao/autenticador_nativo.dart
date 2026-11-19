// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/services.dart';

/// Credencial ou retorno in-app emitido pelo canal nativo de autenticação do sistema operacional (Android/iOS).
class CredencialNativaOAuth {
  /// Token JWT (`id_token`) assinado pelo provedor nativo (`CredentialManager` Google ou Apple ID).
  final String? idToken;

  /// URI de callback retornada por sessão OAuth PKCE in-app (`ASWebAuthenticationSession` no iOS).
  final Uri? callbackUri;

  /// Nonce em texto plano utilizado na solicitação nativa (exigido pelo Sign in with Apple).
  final String? nonce;

  /// Nome de exibição retornado pelo seletor nativo, quando disponível.
  final String? nomeExibicao;

  /// URL da foto de perfil retornada pelo seletor nativo, quando disponível.
  final String? fotoUrl;

  /// Diagnóstico técnico retornado pelo sistema operacional quando a chamada nativa falha sem cancelamento.
  final String? erroNativo;

  /// Indica se o escalador fechou ou cancelou voluntariamente o modal nativo.
  final bool cancelado;

  /// Cria uma instância imutável de [CredencialNativaOAuth].
  const CredencialNativaOAuth({
    this.idToken,
    this.callbackUri,
    this.nonce,
    this.nomeExibicao,
    this.fotoUrl,
    this.erroNativo,
    this.cancelado = false,
  });

  /// Indica se a credencial contém um `id_token` não vazio pronto para validação no Supabase.
  bool get possuiIdToken => idToken != null && idToken!.trim().isNotEmpty;

  /// Indica se a credencial contém uma URI de callback PKCE in-app pronta para troca de código.
  bool get possuiCallbackUri => callbackUri != null;
}

/// Contrato para acionamento dos modais in-app de autenticação (`CredentialManager`, `ASWebAuthenticationSession` e Apple Face ID).
abstract class AutenticadorNativo {
  /// Abre o seletor in-app do Google (`CredentialManager` no Android ou `ASWebAuthenticationSession` PKCE no iOS).
  ///
  /// Retorna `null` apenas caso o canal nativo não esteja disponível na plataforma atual.
  Future<CredencialNativaOAuth?> solicitarCredencialGoogle({
    required String webClientId,
    Uri? uriAutorizacaoPkce,
    String esquemaCallback = 'aresta',
  });

  /// Abre o modal nativo do Sign in with Apple (Face ID / Touch ID) e retorna o `id_token` e o `nonce`.
  ///
  /// Retorna `null` apenas caso o canal nativo não esteja disponível na plataforma atual.
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
    Uri? uriAutorizacaoPkce,
    String esquemaCallback = 'aresta',
  }) async {
    try {
      final argumentos = <String, dynamic>{
        'webClientId': webClientId,
        if (uriAutorizacaoPkce != null)
          'urlAutorizacaoPkce': uriAutorizacaoPkce.toString(),
        'esquemaCallback': esquemaCallback,
      };
      final resposta = await _canal.invokeMapMethod<String, dynamic>(
        'solicitarIdTokenGoogle',
        argumentos,
      );
      return _interpretarRespostaCanal(resposta);
    } on PlatformException catch (e) {
      return CredencialNativaOAuth(erroNativo: e.message ?? e.code);
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
    } on PlatformException catch (e) {
      return CredencialNativaOAuth(erroNativo: e.message ?? e.code);
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
    final erro = (mapa['erro'] as String?)?.trim();
    if (erro != null && erro.isNotEmpty) {
      return CredencialNativaOAuth(erroNativo: erro);
    }
    final callbackBruto = (mapa['callbackUrl'] as String?)?.trim();
    if (callbackBruto != null && callbackBruto.isNotEmpty) {
      final uri = Uri.tryParse(callbackBruto);
      if (uri != null) {
        return CredencialNativaOAuth(callbackUri: uri);
      }
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
