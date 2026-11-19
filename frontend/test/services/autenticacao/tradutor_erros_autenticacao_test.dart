// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/autenticacao/tradutor_erros_autenticacao.dart';

void main() {
  group('tradutor_erros_autenticacao', () {
    test('traduz mensagens de OTP, cooldown em segundos, provedor desabilitado e OAuth para português', () {
      expect(
        traduzirMensagemServidorAutenticacao(
          'For security purposes, you can only request this after 1 second.',
          'Padrão',
        ),
        equals(
          'Por motivos de segurança, você só pode solicitar um novo código após 1 segundo.',
        ),
      );
      expect(
        traduzirMensagemServidorAutenticacao(
          'For security purposes, you can only request this after 45 seconds.',
          'Padrão',
        ),
        equals(
          'Por motivos de segurança, você só pode solicitar um novo código após 45 segundos.',
        ),
      );
      expect(
        traduzirMensagemServidorAutenticacao(
          'For security purposes, you can only request this once every 1 second.',
          'Padrão',
        ),
        equals(
          'Por motivos de segurança, você só pode solicitar um novo código a cada 1 segundo.',
        ),
      );
      expect(
        traduzirMensagemServidorAutenticacao(
          'For security purposes, you can only request this once every 60 seconds.',
          'Padrão',
        ),
        equals(
          'Por motivos de segurança, você só pode solicitar um novo código a cada 60 segundos.',
        ),
      );
      expect(
        traduzirMensagemServidorAutenticacao(
          'Token has expired or is invalid',
          'Padrão',
        ),
        equals('O código de acesso expirou ou é inválido.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('otp_expired', 'Padrão'),
        equals('O código de acesso expirou ou é inválido.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao(
          'Unable to validate email address',
          'Padrão',
        ),
        equals('Informe um endereço de e-mail válido.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('invalid_email', 'Padrão'),
        equals('Informe um endereço de e-mail válido.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao(
          'Email rate limit exceeded',
          'Padrão',
        ),
        equals(
          'Limite de envio de códigos atingido. Aguarde alguns instantes e tente novamente.',
        ),
      );
      expect(
        traduzirMensagemServidorAutenticacao(
          'OVER_EMAIL_SEND_RATE_LIMIT',
          'Padrão',
        ),
        equals(
          'Limite de envio de códigos atingido. Aguarde alguns instantes e tente novamente.',
        ),
      );
      expect(
        traduzirMensagemServidorAutenticacao(
          'Unsupported provider: provider is not enabled',
          'Padrão',
        ),
        equals('Provedor de autenticação não está habilitado no servidor.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('provider_disabled', 'Padrão'),
        equals('Provedor de autenticação não está habilitado no servidor.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('refresh_token_not_found', 'Padrão'),
        equals('Sua sessão expirou. Faça login novamente.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao('access_denied', 'Padrão'),
        equals('Autenticação cancelada pelo escalador.'),
      );
      expect(
        traduzirMensagemServidorAutenticacao(
          '  Erro customizado em português  ',
          'Padrão',
        ),
        equals('Erro customizado em português'),
      );
    });

    test('extrairMensagemErroAutenticacao prioriza error_description, msg, message, error_code e error ou usa mensagem padrão', () {
      expect(
        extrairMensagemErroAutenticacao(
          {'error_description': 'Token has expired or is invalid'},
          'Falha padrão',
        ),
        equals('O código de acesso expirou ou é inválido.'),
      );
      expect(
        extrairMensagemErroAutenticacao(
          {'error_code': 'provider_disabled', 'msg': 'Provider is not enabled'},
          'Falha padrão',
        ),
        equals('Provedor de autenticação não está habilitado no servidor.'),
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

    test('ehErroEntradaUsuarioServidor distingue erros de digitação/cooldown OTP de erros de configuração/servidor', () {
      expect(
        ehErroEntradaUsuarioServidor({
          'error_code': 'otp_expired',
          'msg': 'Token has expired or is invalid',
        }),
        isTrue,
      );
      expect(
        ehErroEntradaUsuarioServidor({
          'msg': 'For security purposes, you can only request this after 30 seconds.',
        }),
        isTrue,
      );
      expect(
        ehErroEntradaUsuarioServidor({'error_code': 'invalid_email'}),
        isTrue,
      );
      expect(
        ehErroEntradaUsuarioServidor({'error_code': 'over_email_send_rate_limit'}),
        isTrue,
      );

      // Erros de servidor / configuração DEVEM retornar false para acionar Sentry
      expect(
        ehErroEntradaUsuarioServidor({
          'error_code': 'provider_disabled',
          'msg': 'Provider (issuer "https://appleid.apple.com") is not enabled',
        }),
        isFalse,
      );
      expect(
        ehErroEntradaUsuarioServidor({'msg': 'Invalid API key'}),
        isFalse,
      );
      expect(
        ehErroEntradaUsuarioServidor({'error': 'unacceptable audience'}),
        isFalse,
      );
      expect(ehErroEntradaUsuarioServidor(<String, dynamic>{}), isFalse);
    });

    test('gera code_verifier PKCE de 56 caracteres, calcula code_challenge S256 (vetor RFC 7636) e extrai parâmetros de callback OAuth', () {
      final verifier1 = gerarCodeVerifierPkce();
      final verifier2 = gerarCodeVerifierPkce();
      expect(verifier1.length, equals(56));
      expect(verifier2.length, equals(56));
      expect(verifier1, isNot(equals(verifier2)));
      expect(RegExp(r'^[A-Za-z0-9._~-]+$').hasMatch(verifier1), isTrue);

      expect(
        calcularCodeChallengeS256('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
        equals('E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM'),
      );

      final uriCallback = Uri.parse(
        'aresta://app.arestaclimb.com/auth-callback?code=abc123#access_token=jwt999&token_type=bearer',
      );
      final params = extrairParametrosCallbackOAuth(uriCallback);
      expect(params['code'], equals('abc123'));
      expect(params['access_token'], equals('jwt999'));
      expect(params['token_type'], equals('bearer'));

      final uriSemParFragmento = Uri.parse(
        'aresta://app.arestaclimb.com/auth-callback?error=access_denied#ancora',
      );
      final paramsSemFragmento = extrairParametrosCallbackOAuth(uriSemParFragmento);
      expect(paramsSemFragmento['error'], equals('access_denied'));
      expect(paramsSemFragmento.containsKey('ancora'), isFalse);
    });
  });
}
