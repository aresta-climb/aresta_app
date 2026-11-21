// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/smoke_ci/configuracao_smoke_ci.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfiguracaoSmokeCi', () {
    test(
      'aceita endereços HTTP de loopback local (127.0.0.1, localhost e 10.0.2.2) e normaliza barra final',
      () {
        final cfg1 = ConfiguracaoSmokeCi.validar(
          servidorUrl: 'http://127.0.0.1:41234/',
          token: ' tok_abc ',
        );
        expect(cfg1.uriBase.toString(), 'http://127.0.0.1:41234');
        expect(cfg1.token, 'tok_abc');
        expect(
          cfg1.construirUriOidcToken().toString(),
          'http://127.0.0.1:41234/__smoke__/oidc-token',
        );
        expect(
          cfg1.construirUriRelatorio().toString(),
          'http://127.0.0.1:41234/__smoke__/relatorio',
        );

        final cfg2 = ConfiguracaoSmokeCi.validar(
          servidorUrl: 'http://LOCALHOST:8080',
          token: 't2',
        );
        expect(cfg2.uriBase.host, 'localhost');

        final cfg3 = ConfiguracaoSmokeCi.validar(
          servidorUrl: 'http://10.0.2.2:55100',
          token: 't3',
        );
        expect(cfg3.uriBase.host, '10.0.2.2');
      },
    );

    test(
      'rejeita token vazio, URL vazia, esquema não-HTTP, ausência de porta ou host externo fora de loopback',
      () {
        expect(
          () => ConfiguracaoSmokeCi.validar(
            servidorUrl: 'http://127.0.0.1:9000',
            token: '   ',
          ),
          throwsFormatException,
        );
        expect(
          () => ConfiguracaoSmokeCi.validar(
            servidorUrl: '   ',
            token: 'tok',
          ),
          throwsFormatException,
        );
        expect(
          () => ConfiguracaoSmokeCi.validar(
            servidorUrl: 'https://127.0.0.1:9000',
            token: 'tok',
          ),
          throwsFormatException,
        );
        expect(
          () => ConfiguracaoSmokeCi.validar(
            servidorUrl: 'http://127.0.0.1',
            token: 'tok',
          ),
          throwsFormatException,
        );
        expect(
          () => ConfiguracaoSmokeCi.validar(
            servidorUrl: 'http://atacante.exemplo.com:9000',
            token: 'tok',
          ),
          throwsFormatException,
        );
      },
    );

    test(
      'exigirDoCanalNativo retorna configuração válida quando o canal responde ativo',
      () async {
        const canal = MethodChannel('teste/smoke_ci_ativo');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(canal, (MethodCall call) async {
          expect(call.method, 'obterConfiguracaoSmoke');
          return <String, dynamic>{
            'ativo': true,
            'servidorUrl': 'http://10.0.2.2:49100',
            'token': 'token_canal_123',
          };
        });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(canal, null);
        });

        final cfg = await ConfiguracaoSmokeCi.exigirDoCanalNativo(canal: canal);
        expect(cfg.uriBase.toString(), 'http://10.0.2.2:49100');
        expect(cfg.token, 'token_canal_123');
      },
    );

    test(
      'exigirDoCanalNativo lança StateError quando o canal está ausente ou inativo',
      () async {
        const canalAusente = MethodChannel('teste/smoke_ci_ausente');
        await expectLater(
          ConfiguracaoSmokeCi.exigirDoCanalNativo(canal: canalAusente),
          throwsStateError,
        );

        const canalInativo = MethodChannel('teste/smoke_ci_inativo');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(canalInativo, (_) async {
          return <String, dynamic>{'ativo': false};
        });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(canalInativo, null);
        });

        await expectLater(
          ConfiguracaoSmokeCi.exigirDoCanalNativo(canal: canalInativo),
          throwsStateError,
        );
      },
    );
  });
}
