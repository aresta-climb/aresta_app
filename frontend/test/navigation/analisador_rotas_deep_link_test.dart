// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/analisador_rotas_deep_link.dart';

void main() {
  group('DeepLinkRouteParser', () {
    test('retorna null para entrada nula, tipo invalido, URL vazia ou de outros dominios', () {
      expect(DeepLinkRouteParser.parse(null), isNull);
      expect(DeepLinkRouteParser.parse(12345), isNull);
      expect(DeepLinkRouteParser.parse('   '), isNull);
      expect(DeepLinkRouteParser.parse('https://:::invalido'), isNull);
      expect(
        DeepLinkRouteParser.parse('https://google.com/sQ7YgEG6ONsPXt'),
        isNull,
      );
      expect(DeepLinkRouteParser.parse('https://aresta.cc/'), isNull);
      expect(DeepLinkRouteParser.parse('https://aresta.cc'), isNull);
      expect(DeepLinkRouteParser.parse('https://app.arestaclimb.com/'), isNull);
    });

    test('faz parsing de link padrao https://aresta.cc/<uid> (sem fonte e sem modo mapa)', () {
      final rota = DeepLinkRouteParser.parse('https://aresta.cc/x8siJek3FiG3aB');
      expect(rota, isNotNull);
      expect(rota!.isPorUid, isTrue);
      expect(rota.uid, equals('x8siJek3FiG3aB'));
      expect(rota.abrirMapa, isFalse);
      expect(rota.origemLink, isNull);
      expect(rota.parametros, isEmpty);
    });

    test('faz parsing de todos os prefixos compactos (/m/, /s/, /sm/, /ms/, /q/, /qm/, /mq/) cabendo em <= 35 caracteres', () {
      const uid = 'sQ7YgEG6ONsPXt';

      final rMapa = DeepLinkRouteParser.parse('https://aresta.cc/m/$uid');
      expect(rMapa, isNotNull);
      expect(rMapa!.uid, equals(uid));
      expect(rMapa.abrirMapa, isTrue);
      expect(rMapa.origemLink, isNull);

      final rShare = DeepLinkRouteParser.parse('https://aresta.cc/s/$uid');
      expect(rShare, isNotNull);
      expect(rShare!.uid, equals(uid));
      expect(rShare.abrirMapa, isFalse);
      expect(rShare.origemLink, equals('compartilhamento'));

      for (final prefixo in ['sm', 'ms']) {
        final url = 'https://aresta.cc/$prefixo/$uid';
        expect(url.length, lessThanOrEqualTo(35));
        final rota = DeepLinkRouteParser.parse(url);
        expect(rota, isNotNull);
        expect(rota!.uid, equals(uid));
        expect(rota.abrirMapa, isTrue);
        expect(rota.origemLink, equals('compartilhamento'));
      }

      final rQr = DeepLinkRouteParser.parse('https://aresta.cc/q/$uid');
      expect(rQr, isNotNull);
      expect(rQr!.uid, equals(uid));
      expect(rQr.abrirMapa, isFalse);
      expect(rQr.origemLink, equals('qrcode'));

      for (final prefixo in ['qm', 'mq']) {
        final url = 'https://aresta.cc/$prefixo/$uid';
        expect(url.length, lessThanOrEqualTo(35));
        final rota = DeepLinkRouteParser.parse(url);
        expect(rota, isNotNull);
        expect(rota!.uid, equals(uid));
        expect(rota.abrirMapa, isTrue);
        expect(rota.origemLink, equals('qrcode'));
      }
    });

    test('preserva parametros UTM opcionais e aceita Uri, www.aresta.cc e string sem scheme', () {
      final rotaUtm = DeepLinkRouteParser.parse(
        'https://aresta.cc/qm/sQ7YgEG6ONsPXt?utm_source=placa_inox&utm_medium=qrcode',
      );
      expect(rotaUtm, isNotNull);
      expect(rotaUtm!.uid, equals('sQ7YgEG6ONsPXt'));
      expect(rotaUtm.abrirMapa, isTrue);
      expect(rotaUtm.origemLink, equals('qrcode'));
      expect(
        rotaUtm.parametros,
        equals({'utm_source': 'placa_inox', 'utm_medium': 'qrcode'}),
      );

      final rotaUri = DeepLinkRouteParser.parse(
        Uri.parse('https://www.aresta.cc/s/sQ7YgEG6ONsPXt'),
      );
      expect(rotaUri, isNotNull);
      expect(rotaUri!.uid, equals('sQ7YgEG6ONsPXt'));
      expect(rotaUri.origemLink, equals('compartilhamento'));

      final rotaSemScheme = DeepLinkRouteParser.parse('aresta.cc/sQ7YgEG6ONsPXt');
      expect(rotaSemScheme, isNotNull);
      expect(rotaSemScheme!.uid, equals('sQ7YgEG6ONsPXt'));
    });

    test('resolve estaticamente as 8 URLs de placas fisicas legadas e rejeita slugs arbitrarios', () {
      const casosLegados = <String, String>{
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/bloco_democracia?utm_source=setor_igarameca&utm_medium=qrcode':
            'sQ7YgEG6ONsPXt',
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/bloco_viva_o_climb?utm_source=setor_igarameca&utm_medium=qrcode':
            'xNOT4evG3tUx7A',
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/grupo_sherpa?utm_source=setor_igarameca&utm_medium=qrcode':
            'cqT5nqQ4pvPub7',
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/setor_estacionamento?utm_source=setor_igarameca&utm_medium=qrcode':
            'hv7YWgTBQGyWOX',
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/setor_familia_i?utm_source=setor_igarameca&utm_medium=qrcode':
            'ZTPu3KeCXIJisV',
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/setor_familia_ii?utm_source=setor_igarameca&utm_medium=qrcode':
            '4GJDAcwWEJb4Ca',
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/bloco_fugitivos_i?utm_source=setor_igarameca&utm_medium=qrcode':
            '7TPrkAyBIkfebu',
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/bloco_fugitivos_ii?utm_source=setor_igarameca&utm_medium=qrcode':
            'jPzv6byW0dO0Gj',
      };

      for (final entrada in casosLegados.entries) {
        final rota = DeepLinkRouteParser.parse(entrada.key);
        expect(rota, isNotNull, reason: 'Falhou para ${entrada.key}');
        expect(rota!.uid, equals(entrada.value));
        expect(rota.abrirMapa, isFalse);
        expect(rota.origemLink, equals('qrcode'));
        expect(rota.parametros['utm_source'], equals('setor_igarameca'));
        expect(rota.parametros['utm_medium'], equals('qrcode'));
      }

      // Slugs arbitrários não listados nas 8 placas físicas devem retornar null
      expect(
        DeepLinkRouteParser.parse(
          'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/setor_inexistente',
        ),
        isNull,
      );
      expect(
        DeepLinkRouteParser.parse(
          'https://aresta.cc/prefixo_invalido/sQ7YgEG6ONsPXt',
        ),
        isNull,
      );
      expect(
        DeepLinkRouteParser.parse('https://aresta.cc/m/uid_curto'),
        isNull,
      );
    });

    test('RotaDeepLink implementa igualdade, hashCode e toString corretamente', () {
      final r1 = RotaDeepLink(
        uid: 'sQ7YgEG6ONsPXt',
        abrirMapa: true,
        origemLink: 'qrcode',
        parametros: {'utm_source': 'placa'},
      );
      final r2 = RotaDeepLink(
        uid: 'sQ7YgEG6ONsPXt',
        abrirMapa: true,
        origemLink: 'qrcode',
        parametros: {'utm_source': 'placa'},
      );
      final r3 = RotaDeepLink(
        uid: 'sQ7YgEG6ONsPXt',
        abrirMapa: false,
        origemLink: 'compartilhamento',
        parametros: {'utm_source': 'outro'},
      );
      final r4 = RotaDeepLink(
        uid: 'sQ7YgEG6ONsPXt',
        abrirMapa: true,
        origemLink: 'qrcode',
        parametros: {'utm_source': 'diferente'},
      );
      final r5 = RotaDeepLink(
        uid: 'sQ7YgEG6ONsPXt',
        abrirMapa: true,
        origemLink: 'qrcode',
        parametros: const {},
      );

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1 == r3, isFalse);
      expect(r1 == r4, isFalse);
      expect(r1 == r5, isFalse);
      expect(r1.toString(), contains('sQ7YgEG6ONsPXt'));
    });
  });
}
