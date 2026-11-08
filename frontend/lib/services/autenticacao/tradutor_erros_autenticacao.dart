// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Mapa de traduções amigáveis para mensagens de erro retornadas pelo servidor GoTrue / OAuth.
const Map<String, String> _traducoesErrosServidorAutenticacao = {
  'invalid api key': 'Chave de acesso do servidor inválida. Tente novamente.',
  'no api key': 'Chave de acesso do servidor inválida. Tente novamente.',
  'invalid login credentials': 'E-mail ou senha incorretos.',
  'invalid_credentials': 'E-mail ou senha incorretos.',
  'email not confirmed': 'Confirme seu endereço de e-mail antes de entrar.',
  'email_not_confirmed': 'Confirme seu endereço de e-mail antes de entrar.',
  'already registered': 'Este e-mail já está cadastrado.',
  'user_already_exists': 'Este e-mail já está cadastrado.',
  'password should be at least': 'A senha deve ter pelo menos 6 caracteres.',
  'weak_password': 'A senha deve ter pelo menos 6 caracteres.',
  'unable to validate email': 'Informe um endereço de e-mail válido.',
  'invalid_email': 'Informe um endereço de e-mail válido.',
  'unacceptable audience':
      'Não foi possível validar a credencial nativa no servidor.',
  'bad_jwt': 'Não foi possível validar a credencial nativa no servidor.',
  'invalid_grant': 'Não foi possível validar a credencial nativa no servidor.',
  'nonce': 'Não foi possível validar a credencial nativa no servidor.',
  'rate limit':
      'Muitas tentativas seguidas. Aguarde alguns instantes e tente novamente.',
  'over_email_send_rate_limit':
      'Muitas tentativas seguidas. Aguarde alguns instantes e tente novamente.',
  'for security purposes':
      'Muitas tentativas seguidas. Aguarde alguns instantes e tente novamente.',
  'expired': 'Sua sessão expirou. Faça login novamente.',
  'invalid token': 'Sua sessão expirou. Faça login novamente.',
  'refresh_token_not_found': 'Sua sessão expirou. Faça login novamente.',
  'access_denied': 'Autenticação cancelada pelo escalador.',
  'user_cancelled': 'Autenticação cancelada pelo escalador.',
};

/// Traduz uma mensagem de erro bruta retornada pelo servidor GoTrue/OAuth para português.
String traduzirMensagemServidorAutenticacao(
  String textoBruto,
  String mensagemPadrao,
) {
  final limpo = textoBruto.trim();
  if (limpo.isEmpty) {
    return mensagemPadrao;
  }
  final minusculo = limpo.toLowerCase();
  for (final entrada in _traducoesErrosServidorAutenticacao.entries) {
    if (minusculo.contains(entrada.key)) {
      return entrada.value;
    }
  }
  return limpo;
}

/// Extrai e traduz a mensagem de erro de um payload JSON do GoTrue (`error_description`, `msg`, `message` ou `error`).
String extrairMensagemErroAutenticacao(
  Map<String, dynamic> mapa,
  String mensagemPadrao,
) {
  final msg =
      mapa['error_description'] ??
      mapa['msg'] ??
      mapa['message'] ??
      mapa['error'];
  return msg != null
      ? traduzirMensagemServidorAutenticacao(msg.toString(), mensagemPadrao)
      : mensagemPadrao;
}
