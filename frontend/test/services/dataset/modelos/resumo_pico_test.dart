// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset/modelos/estatisticas_pico.dart';
import 'package:frontend/services/dataset/modelos/resumo_pico.dart';

void main() {
  group('ResumoPico', () {
    test('instancia corretamente com campos obrigatórios e padrões', () {
      final pico = ResumoPico(
        id: 'pico_1',
        nome: 'Pedra Bela',
        local: 'São Paulo, SP',
      );

      expect(pico.id, equals('pico_1'));
      expect(pico.nome, equals('Pedra Bela'));
      expect(pico.local, equals('São Paulo, SP'));
      expect(pico.descricao, isEmpty);
      expect(pico.url, isEmpty);
      expect(pico.checksum, isEmpty);
      expect(pico.thumbnailUrl, isEmpty);
      expect(pico.isDownloaded, isFalse);
      expect(pico.tamanhoBytes, isNull);
      expect(pico.tamanhoFormatado, equals('Offline'));
      expect(pico.dataUpdate, isNull);
      expect(pico.latitude, isNull);
      expect(pico.longitude, isNull);
      expect(pico.estatisticas, isNull);
      expect(pico.capaPath, isNull);
      expect(pico.croqui, isNull);
      expect(pico.pico, isNull);
      expect(pico.distanciaKm, isNull);
    });

    test('permite acesso retrocompatível via operador indexador []', () {
      final pico = ResumoPico(
        id: 'pico_1',
        nome: 'Pedra Bela',
        local: 'São Paulo, SP',
        latitude: -23.5,
        longitude: -46.6,
        distanciaKm: 12.5,
        isDownloaded: true,
        estatisticas: const EstatisticasPico(totalVias: 42),
      );

      expect(pico['id'], equals('pico_1'));
      expect(pico['nome'], equals('Pedra Bela'));
      expect(pico['local'], equals('São Paulo, SP'));
      expect(pico['latitude'], equals(-23.5));
      expect(pico['longitude'], equals(-46.6));
      expect(pico['distance'], equals(12.5));
      expect(pico['isDownloaded'], isTrue);
      expect(pico['estatisticas']?['totalVias'], equals(42));
      expect(pico.containsKey('id'), isTrue);
      expect(pico.containsKey('chave_inexistente'), isFalse);
    });

    test('suporta copyWith para atualização imutável', () {
      final pico = ResumoPico(
        id: 'pico_1',
        nome: 'Pedra Bela',
        local: 'SP',
      );

      final atualizado = pico.copyWith(
        isDownloaded: true,
        capaPath: '/caminho/capa.jpg',
        distanciaKm: 5.0,
      );

      expect(atualizado.id, equals('pico_1'));
      expect(atualizado.isDownloaded, isTrue);
      expect(atualizado.capaPath, equals('/caminho/capa.jpg'));
      expect(atualizado.distanciaKm, equals(5.0));
      expect(pico.isDownloaded, isFalse);
    });

    test('serializa e desserializa de mapa com fidelidade', () {
      final mapa = {
        'id': 'pico_2',
        'nome': 'Cipó',
        'local': 'Santana do Riacho, MG',
        'descricao': 'Calcário espetacular',
        'url': 'https://aresta.app/cipo',
        'checksum': 'abc123sha',
        'thumbnailUrl': 'https://aresta.app/cipo/thumb.webp',
        'isDownloaded': true,
        'tamanhoBytes': 1048576,
        'tamanhoFormatado': '1.0 MB',
        'dataUpdate': '2026-09-01T12:00:00Z',
        'latitude': -19.3,
        'longitude': -43.6,
        'capaPath': '/downloads/cipo/capa.jpg',
        'distance': 15.2,
        'estatisticas': {
          'totalVias': 350,
          'totalSetores': 25,
        },
      };

      final pico = ResumoPico.deMapa(mapa);
      expect(pico.id, equals('pico_2'));
      expect(pico.nome, equals('Cipó'));
      expect(pico.latitude, equals(-19.3));
      expect(pico.distanciaKm, equals(15.2));
      expect(pico.estatisticas?.totalVias, equals(350));

      final mapaExportado = pico.paraMapa();
      expect(mapaExportado['id'], equals('pico_2'));
      expect(mapaExportado['nome'], equals('Cipó'));
      expect(mapaExportado['isDownloaded'], isTrue);
    });
  });
}
