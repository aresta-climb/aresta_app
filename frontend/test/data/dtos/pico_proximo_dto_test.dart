// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/dtos/pico_proximo_dto.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';

void main() {
  group('PicoProximoDTO Tests', () {
    test('criação direta com dados primitivos e formatação de distância', () {
      const dtoMetro = PicoProximoDTO(
        id: 'pedra_bela',
        nome: 'Pedra Bela',
        localizacao: 'São Paulo',
        distanciaKm: 0.45,
        caminhoMiniatura: 'thumbnails/pedra_bela.webp',
        estaBaixado: true,
        totalSetores: 4,
        totalEscaladas: 30,
      );

      expect(dtoMetro.id, equals('pedra_bela'));
      expect(dtoMetro.nome, equals('Pedra Bela'));
      expect(dtoMetro.localizacao, equals('São Paulo'));
      expect(dtoMetro.distanciaKm, equals(0.45));
      expect(dtoMetro.distanciaFormatada, equals('450 m'));
      expect(dtoMetro.caminhoMiniatura, equals('thumbnails/pedra_bela.webp'));
      expect(dtoMetro.estaBaixado, isTrue);
      expect(dtoMetro.totalSetores, equals(4));
      expect(dtoMetro.totalEscaladas, equals(30));

      const dtoKm = PicoProximoDTO(
        id: 'bau',
        nome: 'Pedra do Baú',
        localizacao: 'São Paulo',
        distanciaKm: 12.34,
        caminhoMiniatura: 'thumbnails/bau.webp',
        estaBaixado: false,
      );

      expect(dtoKm.distanciaFormatada, equals('12.3 km'));
    });

    test('deMetadados converte ResumoCroqui e calcula distância formatada', () {
      final metadados = ResumoCroqui(
        id: 'cipó',
        nome: 'Serra do Cipó',
        caminhoRelativo: 'minas_gerais/serra_do_cipo',
        precomputados: PrecomputadosResumoCroqui(
          totalSetores: 10,
          totalEscaladas: 150,
        ),
      );

      final dto = PicoProximoDTO.deMetadados(
        metadados: metadados,
        distanciaKm: 5.67,
        estaBaixado: true,
      );

      expect(dto.id, equals('cipó'));
      expect(dto.nome, equals('Serra do Cipó'));
      expect(dto.localizacao, equals('Minas Gerais'));
      expect(dto.distanciaKm, equals(5.67));
      expect(dto.distanciaFormatada, equals('5.7 km'));
      expect(dto.caminhoMiniatura, equals('thumbnails/cipó.webp'));
      expect(dto.estaBaixado, isTrue);
      expect(dto.totalSetores, equals(10));
      expect(dto.totalEscaladas, equals(150));
    });

    test('distanciaFormatada com valor nulo retorna string vazia', () {
      const dto = PicoProximoDTO(
        id: 'pico_sem_distancia',
        nome: 'Pico Longe',
        localizacao: 'Minas',
        caminhoMiniatura: 'thumbnails/pico_sem_distancia.webp',
      );

      expect(dto.distanciaFormatada, isEmpty);
    });
  });
}
