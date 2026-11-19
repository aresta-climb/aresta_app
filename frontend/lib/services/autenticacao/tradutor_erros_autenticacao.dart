// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

final RegExp _regexCooldownAposSegundos = RegExp(
  r'for security purposes,\s*you can only request this after (\d+) seconds?',
  caseSensitive: false,
);

final RegExp _regexCooldownCadaSegundos = RegExp(
  r'for security purposes,\s*you can only request this once every (\d+) seconds?',
  caseSensitive: false,
);

/// Mapa de traduções amigáveis para mensagens de erro retornadas pelo servidor GoTrue / OAuth / OTP.
const Map<String, String> _traducoesErrosServidorAutenticacao = {
  'invalid api key': 'Chave de acesso do servidor inválida. Tente novamente.',
  'no api key': 'Chave de acesso do servidor inválida. Tente novamente.',
  'token has expired or is invalid':
      'O código de acesso expirou ou é inválido.',
  'otp_expired': 'O código de acesso expirou ou é inválido.',
  'unable to validate email': 'Informe um endereço de e-mail válido.',
  'invalid_email': 'Informe um endereço de e-mail válido.',
  'provider_disabled':
      'Provedor de autenticação não está habilitado no servidor.',
  'provider is not enabled':
      'Provedor de autenticação não está habilitado no servidor.',
  'otp_disabled': 'Provedor de autenticação não está habilitado no servidor.',
  'unacceptable audience':
      'Não foi possível validar a credencial nativa no servidor.',
  'bad_jwt': 'Não foi possível validar a credencial nativa no servidor.',
  'invalid_grant': 'Não foi possível validar a credencial nativa no servidor.',
  'nonce': 'Não foi possível validar a credencial nativa no servidor.',
  'email rate limit exceeded':
      'Limite de envio de códigos atingido. Aguarde alguns instantes e tente novamente.',
  'over_email_send_rate_limit':
      'Limite de envio de códigos atingido. Aguarde alguns instantes e tente novamente.',
  'rate limit':
      'Limite de envio de códigos atingido. Aguarde alguns instantes e tente novamente.',
  'for security purposes':
      'Limite de envio de códigos atingido. Aguarde alguns instantes e tente novamente.',
  'expired': 'Sua sessão expirou. Faça login novamente.',
  'invalid token': 'Sua sessão expirou. Faça login novamente.',
  'refresh_token_not_found': 'Sua sessão expirou. Faça login novamente.',
  'access_denied': 'Autenticação cancelada pelo escalador.',
  'user_cancelled': 'Autenticação cancelada pelo escalador.',
};

const List<String> _padroesErroEntradaUsuario = [
  'token has expired or is invalid',
  'otp_expired',
  'unable to validate email',
  'invalid_email',
  'validation_failed',
  'for security purposes',
  'over_email_send_rate_limit',
  'email rate limit exceeded',
  'over_request_rate_limit',
];

/// Traduz uma mensagem de erro bruta retornada pelo servidor GoTrue/OAuth/OTP para português.
String traduzirMensagemServidorAutenticacao(
  String textoBruto,
  String mensagemPadrao,
) {
  final limpo = textoBruto.trim();
  if (limpo.isEmpty) {
    return mensagemPadrao;
  }

  final matchApos = _regexCooldownAposSegundos.firstMatch(limpo);
  if (matchApos != null) {
    final segundos = int.parse(matchApos.group(1)!);
    final unidade = segundos == 1 ? 'segundo' : 'segundos';
    return 'Por motivos de segurança, você só pode solicitar um novo código após $segundos $unidade.';
  }

  final matchCada = _regexCooldownCadaSegundos.firstMatch(limpo);
  if (matchCada != null) {
    final segundos = int.parse(matchCada.group(1)!);
    final unidade = segundos == 1 ? 'segundo' : 'segundos';
    return 'Por motivos de segurança, você só pode solicitar um novo código a cada $segundos $unidade.';
  }

  final minusculo = limpo.toLowerCase();
  for (final entrada in _traducoesErrosServidorAutenticacao.entries) {
    if (minusculo.contains(entrada.key)) {
      return entrada.value;
    }
  }
  return limpo;
}

/// Extrai e traduz a mensagem de erro de um payload JSON do GoTrue (`error_description`, `msg`, `message`, `error_code` ou `error`).
String extrairMensagemErroAutenticacao(
  Map<String, dynamic> mapa,
  String mensagemPadrao,
) {
  final candidatos = [
    mapa['error_description'],
    mapa['msg'],
    mapa['message'],
    mapa['error_code'],
    mapa['error'],
  ];
  for (final candidato in candidatos) {
    final texto = candidato?.toString().trim() ?? '';
    if (texto.isNotEmpty) {
      return traduzirMensagemServidorAutenticacao(texto, mensagemPadrao);
    }
  }
  return mensagemPadrao;
}

/// Indica se o payload JSON de erro retornado pelo GoTrue decorre de entrada inválida do usuário
/// (e-mail inválido, código OTP expirado/incorreto ou limite de reenvio OTP) em vez de falha operacional/configuração.
bool ehErroEntradaUsuarioServidor(Map<String, dynamic> mapa) {
  final consolidado = [
    mapa['error_code'],
    mapa['error'],
    mapa['error_description'],
    mapa['msg'],
    mapa['message'],
  ].where((v) => v != null).map((v) => v.toString().toLowerCase()).join(' | ');

  if (consolidado.isEmpty) {
    return false;
  }
  for (final padrao in _padroesErroEntradaUsuario) {
    if (consolidado.contains(padrao)) {
      return true;
    }
  }
  return false;
}

/// Gera um `code_verifier` criptograficamente seguro de 56 caracteres para o fluxo OAuth 2.0 PKCE.
String gerarCodeVerifierPkce() {
  const caracteres =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  final random = Random.secure();
  return List.generate(
    56,
    (_) => caracteres[random.nextInt(caracteres.length)],
  ).join();
}

/// Calcula o `code_challenge` SHA-256 em Base64URL sem padding (`S256`) a partir do [codeVerifier].
String calcularCodeChallengeS256(String codeVerifier) {
  final digest = sha256.convert(utf8.encode(codeVerifier));
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}

/// Extrai parâmetros combinados de query string (`?code=...`) e fragmento (`#access_token=...`) de uma URI de retorno OAuth.
Map<String, String> extrairParametrosCallbackOAuth(Uri uri) {
  final resultado = <String, String>{...uri.queryParameters};
  if (uri.fragment.contains('=')) {
    resultado.addAll(Uri.splitQueryString(uri.fragment));
  }
  return resultado;
}
