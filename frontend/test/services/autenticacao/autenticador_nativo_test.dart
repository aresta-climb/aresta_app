// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/autenticacao/autenticador_nativo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canal = MethodChannel(AutenticadorNativoCanal.nomeCanal);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
    AutenticadorNativoCanal.redefinirParaTestes();
  });

  group('AutenticadorNativoCanal', () {
    test('gerencia singleton configurável e redefinição para testes', () {
      final padrao = AutenticadorNativoCanal.instancia;
      final customizado = AutenticadorNativoCanal();

      AutenticadorNativoCanal.instancia = customizado;
      expect(identical(AutenticadorNativoCanal.instancia, customizado), isTrue);

      AutenticadorNativoCanal.redefinirParaTestes();
      expect(identical(AutenticadorNativoCanal.instancia, customizado), isFalse);
      expect(padrao, isA<AutenticadorNativo>());
    });

    test('solicitarCredencialGoogle envia webClientId, urlAutorizacaoPkce e esquemaCallback e interpreta idToken ou callbackUrl', () async {
      MethodCall? chamadaRecebida;
      var modoRetorno = 'id_token';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (call) async {
            chamadaRecebida = call;
            if (modoRetorno == 'id_token') {
              return <String, dynamic>{
                'idToken': 'jwt-google-nativo-123',
                'nomeExibicao': 'Eduardo Utsch',
                'fotoUrl': 'https://lh3.googleusercontent.com/a/eduardo.jpg',
                'cancelado': false,
              };
            }
            return <String, dynamic>{
              'callbackUrl':
                  'aresta://app.arestaclimb.com/auth-callback?code=pkce-ios-999',
              'cancelado': false,
            };
          });

      final autenticador = AutenticadorNativoCanal();
      final uriPkce = Uri.parse(
        'https://yzkhiaoqtxvvcyyuwmqg.supabase.co/auth/v1/authorize?provider=google',
      );
      final credencialAndroid = await autenticador.solicitarCredencialGoogle(
        webClientId: 'client-id-web.apps.googleusercontent.com',
        uriAutorizacaoPkce: uriPkce,
        esquemaCallback: 'aresta',
      );

      expect(chamadaRecebida?.method, equals('solicitarIdTokenGoogle'));
      expect(
        chamadaRecebida?.arguments,
        equals({
          'webClientId': 'client-id-web.apps.googleusercontent.com',
          'urlAutorizacaoPkce': uriPkce.toString(),
          'esquemaCallback': 'aresta',
        }),
      );
      expect(credencialAndroid, isNotNull);
      expect(credencialAndroid!.possuiIdToken, isTrue);
      expect(credencialAndroid.possuiCallbackUri, isFalse);
      expect(credencialAndroid.idToken, equals('jwt-google-nativo-123'));
      expect(credencialAndroid.nomeExibicao, equals('Eduardo Utsch'));
      expect(
        credencialAndroid.fotoUrl,
        equals('https://lh3.googleusercontent.com/a/eduardo.jpg'),
      );
      expect(credencialAndroid.cancelado, isFalse);

      modoRetorno = 'callback_pkce';
      final credencialIos = await autenticador.solicitarCredencialGoogle(
        webClientId: 'client-id-web.apps.googleusercontent.com',
        uriAutorizacaoPkce: uriPkce,
      );
      expect(credencialIos, isNotNull);
      expect(credencialIos!.possuiIdToken, isFalse);
      expect(credencialIos.possuiCallbackUri, isTrue);
      expect(
        credencialIos.callbackUri?.queryParameters['code'],
        equals('pkce-ios-999'),
      );
      expect(credencialIos.cancelado, isFalse);
    });

    test('solicitarCredencialApple retorna CredencialNativaOAuth com nonce quando o canal nativo responde com sucesso ou cancelamento', () async {
      var retornarCancelado = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (call) async {
            if (call.method == 'solicitarIdTokenApple') {
              if (retornarCancelado) {
                return <String, dynamic>{'cancelado': true};
              }
              return <String, dynamic>{
                'idToken': 'jwt-apple-nativo-456',
                'nonce': 'nonce-bruto-123',
                'nomeExibicao': 'Escalador iOS',
                'cancelado': false,
              };
            }
            return null;
          });

      final autenticador = AutenticadorNativoCanal();
      final credencialSucesso = await autenticador.solicitarCredencialApple();
      expect(credencialSucesso, isNotNull);
      expect(credencialSucesso!.possuiIdToken, isTrue);
      expect(credencialSucesso.idToken, equals('jwt-apple-nativo-456'));
      expect(credencialSucesso.nonce, equals('nonce-bruto-123'));
      expect(credencialSucesso.nomeExibicao, equals('Escalador iOS'));
      expect(credencialSucesso.cancelado, isFalse);

      retornarCancelado = true;
      final credencialCancelada = await autenticador.solicitarCredencialApple();
      expect(credencialCancelada, isNotNull);
      expect(credencialCancelada!.possuiIdToken, isFalse);
      expect(credencialCancelada.cancelado, isTrue);
    });

    test('propaga erroNativo quando informado pelo canal ou PlatformException e retorna null em resposta vazia ou MissingPluginException', () async {
      var modo = 'nulo';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (call) async {
            if (modo == 'nulo') return null;
            if (modo == 'vazio') return <String, dynamic>{'idToken': '   '};
            if (modo == 'erro_mapa') {
              return <String, dynamic>{'erro': 'Entitlement Sign in with Apple ausente'};
            }
            if (modo == 'platform_exception') {
              throw PlatformException(
                code: 'FALHA_CREDENTIAL_MANAGER',
                message: 'Play Services desatualizado',
              );
            }
            throw MissingPluginException('Canal não registrado');
          });

      final autenticador = AutenticadorNativoCanal();
      expect(
        await autenticador.solicitarCredencialGoogle(webClientId: 'id'),
        isNull,
      );

      modo = 'vazio';
      expect(
        await autenticador.solicitarCredencialGoogle(webClientId: 'id'),
        isNull,
      );

      modo = 'erro_mapa';
      final comErroMapa = await autenticador.solicitarCredencialApple();
      expect(comErroMapa?.erroNativo, equals('Entitlement Sign in with Apple ausente'));

      modo = 'platform_exception';
      final comErroPlatGoogle = await autenticador.solicitarCredencialGoogle(
        webClientId: 'id',
      );
      expect(comErroPlatGoogle?.erroNativo, contains('Play Services desatualizado'));
      final comErroPlatApple = await autenticador.solicitarCredencialApple();
      expect(comErroPlatApple?.erroNativo, contains('Play Services desatualizado'));

      modo = 'missing';
      expect(
        await autenticador.solicitarCredencialGoogle(webClientId: 'id'),
        isNull,
      );
      expect(await autenticador.solicitarCredencialApple(), isNull);
    });
  });
}
