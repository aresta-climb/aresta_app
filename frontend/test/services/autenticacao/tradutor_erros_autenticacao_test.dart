// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/autenticacao/tradutor_erros_autenticacao.dart';

void main() {
  group('tradutor_erros_autenticacao', () {
    test('traduz mensagens de erro conhecidas do servidor GoTrue para português e preserva mensagens desconhecidas', () {
      expect(
        traduzirMensagemServidorAutenticacao('Invalid login credentials', 'Padrão'),
        equals('E-mail ou senha incorretos.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('Email not confirmed', 'Padrão'),
        equals('Confirme seu endereço de e-mail antes de entrar.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('email_not_confirmed', 'Padrão'),
        equals('Confirme seu endereço de e-mail antes de entrar.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('User already registered', 'Padrão'),
        equals('Este e-mail já está cadastrado.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('Password should be at least 6 characters', 'Padrão'),
        equals('A senha deve ter pelo menos 6 caracteres.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('Unable to validate email address', 'Padrão'),
        equals('Informe um endereço de e-mail válido.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('Email rate limit exceeded', 'Padrão'),
        equals('Muitas tentativas seguidas. Aguarde alguns instantes e tente novamente.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('Token has expired', 'Padrão'),
        equals('Sua sessão expirou. Faça login novamente.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('access_denied', 'Padrão'),
        equals('Autenticação cancelada pelo escalador.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('  Erro customizado em português  ', 'Padrão'),
        equals('Erro customizado em português'),
      );
    });

    test('traduz códigos alternativos do GoTrue ignorando caixa alta/baixa', () {
      expect(
        traduzirMensagemServidorAutenticacao('INVALID_CREDENTIALS', 'Padrão'),
        equals('E-mail ou senha incorretos.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('OVER_EMAIL_SEND_RATE_LIMIT', 'Padrão'),
        equals('Muitas tentativas seguidas. Aguarde alguns instantes e tente novamente.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('refresh_token_not_found', 'Padrão'),
        equals('Sua sessão expirou. Faça login novamente.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('USER_CANCELLED', 'Padrão'),
        equals('Autenticação cancelada pelo escalador.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('invalid_email', 'Padrão'),
        equals('Informe um endereço de e-mail válido.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('weak_password', 'Padrão'),
        equals('A senha deve ter pelo menos 6 caracteres.'),
      );
    });

    test('extrairMensagemErroAutenticacao prioriza error_description, msg, message e error ou usa mensagem padrão', () {
      expect(
        extrairMensagemErroAutenticacao(
          {'error_description': 'invalid login credentials'},
          'Falha padrão',
        ),
        equals('E-mail ou senha incorretos.'),
      );
      expect(
        extrairMensagemErroAutenticacao(
          {'msg': 'user_already_exists'},
          'Falha padrão',
        ),
        equals('Este e-mail já está cadastrado.'),
      );
      expect(
        extrairMensagemErroAutenticacao(
          {'message': 'Invalid API key'},
          'Falha padrão',
        ),
        equals('Chave de acesso do servidor inválida. Tente novamente.'),
      );
      expect(
        extrairMensagemErroAutenticacao(
          {'error': 'invalid_grant'},
          'Falha padrão',
        ),
        equals('Não foi possível validar a credencial nativa no servidor.'),
      );
      expect(
        extrairMensagemErroAutenticacao(
          {'error_description': '   ', 'msg': ''},
          'Falha padrão',
        ),
        equals('Falha padrão'),
      );
      expect(
        extrairMensagemErroAutenticacao(<String, dynamic>{}, 'Falha padrão'),
        equals('Falha padrão'),
      );
    });
  });
}
