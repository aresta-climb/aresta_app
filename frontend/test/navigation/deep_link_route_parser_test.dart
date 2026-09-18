// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/navigation/deep_link_route_parser.dart';

void main() {
  group('DeepLinkRouteParser', () {
    test('retorna null para URLs de outros dominios', () {
      final rota = DeepLinkRouteParser.parse(
        'https://google.com/br_mg_igarape_pedra_grande',
      );
      expect(rota, isNull);
    });

    test('retorna null para URL vazia ou sem segmentos de caminho', () {
      expect(DeepLinkRouteParser.parse(''), isNull);
      expect(DeepLinkRouteParser.parse('https://app.arestaclimb.com/'), isNull);
      expect(DeepLinkRouteParser.parse('https://app.arestaclimb.com'), isNull);
    });

    test('faz parsing de rota nivel 1 (apenas Pico)', () {
      final rota = DeepLinkRouteParser.parse(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande',
      );
      expect(rota, isNotNull);
      expect(rota!.picoId, equals('br_mg_igarape_pedra_grande'));
      expect(rota.profundidade, equals(0));
      expect(rota.primeiroSegmento, isNull);
    });

    test('faz parsing de rota nivel 2 (Pico + Setor ou Grupo)', () {
      final rota = DeepLinkRouteParser.parse(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/grupo_estacionamento',
      );
      expect(rota, isNotNull);
      expect(rota!.picoId, equals('br_mg_igarape_pedra_grande'));
      expect(rota.profundidade, equals(1));
      expect(rota.primeiroSegmento, equals('grupo_estacionamento'));
      expect(rota.segundoSegmento, isNull);
    });

    test('faz parsing de rota nivel 3 (Pico + Grupo + Setor OU Pico + Setor + Via)', () {
      final rota = DeepLinkRouteParser.parse(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/grupo_estacionamento/setor_b',
      );
      expect(rota, isNotNull);
      expect(rota!.picoId, equals('br_mg_igarape_pedra_grande'));
      expect(rota.profundidade, equals(2));
      expect(rota.primeiroSegmento, equals('grupo_estacionamento'));
      expect(rota.segundoSegmento, equals('setor_b'));
      expect(rota.terceiroSegmento, isNull);
    });

    test('faz parsing de rota nivel 4 (Pico + Grupo + Setor + Via)', () {
      final rota = DeepLinkRouteParser.parse(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/grupo_estacionamento/savassinha/teto_da_aresta',
      );
      expect(rota, isNotNull);
      expect(rota!.picoId, equals('br_mg_igarape_pedra_grande'));
      expect(rota.profundidade, equals(3));
      expect(rota.primeiroSegmento, equals('grupo_estacionamento'));
      expect(rota.segundoSegmento, equals('savassinha'));
      expect(rota.terceiroSegmento, equals('teto_da_aresta'));
    });

    test('suporta objetos Uri diretamente', () {
      final uri = Uri.parse(
        'https://app.arestaclimb.com/br_mg_cipov2/vale_da_lapinha',
      );
      final rota = DeepLinkRouteParser.parse(uri);
      expect(rota, isNotNull);
      expect(rota!.picoId, equals('br_mg_cipov2'));
      expect(rota.primeiroSegmento, equals('vale_da_lapinha'));
    });

    test('normaliza caracteres acentuados e maiusculos nos segmentos da URL', () {
      final rota = DeepLinkRouteParser.parse(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/Fal%C3%A9sia%20Esperan%C3%A7a/P%C3%A9-de-Cabra',
      );
      expect(rota, isNotNull);
      expect(rota!.primeiroSegmento, equals('falesia_esperanca'));
      expect(rota.segundoSegmento, equals('pe_de_cabra'));
    });

    test('suporta custom scheme aresta://app.arestaclimb.com/...', () {
      final rota = DeepLinkRouteParser.parse(
        'aresta://app.arestaclimb.com/br_mg_igarape_pedra_grande/savassinha',
      );
      expect(rota, isNotNull);
      expect(rota!.picoId, equals('br_mg_igarape_pedra_grande'));
      expect(rota.primeiroSegmento, equals('savassinha'));
    });

    test('suporta URLs com parametros de consulta UTM sem interferir na rota', () {
      final rota = DeepLinkRouteParser.parse(
        'https://app.arestaclimb.com/br_mg_igarape_pedra_grande/setor_estacionamento?utm_source=setor_igarameca&utm_medium=qrcode',
      );
      expect(rota, isNotNull);
      expect(rota!.picoId, equals('br_mg_igarape_pedra_grande'));
      expect(rota.primeiroSegmento, equals('setor_estacionamento'));
      expect(rota.profundidade, equals(1));
    });
  });
}
