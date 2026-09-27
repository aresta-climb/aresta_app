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
