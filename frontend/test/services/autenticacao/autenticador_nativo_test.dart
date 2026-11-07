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

    test('solicitarCredencialGoogle retorna CredencialNativaOAuth preenchida quando o canal nativo responde com idToken', () async {
      MethodCall? chamadaRecebida;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (call) async {
            chamadaRecebida = call;
            return <String, dynamic>{
              'idToken': 'jwt-google-nativo-123',
              'nomeExibicao': 'Eduardo Utsch',
              'fotoUrl': 'https://lh3.googleusercontent.com/a/eduardo.jpg',
              'cancelado': false,
            };
          });

      final autenticador = AutenticadorNativoCanal();
      final credencial = await autenticador.solicitarCredencialGoogle(
        webClientId: 'client-id-web.apps.googleusercontent.com',
      );

      expect(chamadaRecebida?.method, equals('solicitarIdTokenGoogle'));
      expect(
        chamadaRecebida?.arguments,
        equals({'webClientId': 'client-id-web.apps.googleusercontent.com'}),
      );
      expect(credencial, isNotNull);
      expect(credencial!.possuiIdToken, isTrue);
      expect(credencial.idToken, equals('jwt-google-nativo-123'));
      expect(credencial.nomeExibicao, equals('Eduardo Utsch'));
      expect(
        credencial.fotoUrl,
        equals('https://lh3.googleusercontent.com/a/eduardo.jpg'),
      );
      expect(credencial.cancelado, isFalse);
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

    test('retorna null quando o canal nativo devolve null, mapa sem token ou lança PlatformException / MissingPluginException', () async {
      var modo = 'nulo';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (call) async {
            if (modo == 'nulo') return null;
            if (modo == 'vazio') return <String, dynamic>{'idToken': '   '};
            throw PlatformException(code: 'INDISPONIVEL');
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

      modo = 'excecao';
      expect(
        await autenticador.solicitarCredencialGoogle(webClientId: 'id'),
        isNull,
      );
      expect(await autenticador.solicitarCredencialApple(), isNull);
    });
  });
}
