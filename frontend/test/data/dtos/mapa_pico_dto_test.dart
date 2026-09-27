// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/dtos/mapa_pico_dto.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  group('MapaPicoDTO Tests', () {
    test('criação direta com dados primitivos', () {
      const dto = MapaPicoDTO(
        id: 'cuscuzeiro',
        nome: 'Morro do Cuscuzeiro',
        latitude: -22.123456,
        longitude: -47.654321,
        estaBaixado: true,
        totalSetores: 3,
        totalEscaladas: 45,
        caminhoMiniatura: 'thumbnails/cuscuzeiro.webp',
        localizacao: 'Analândia',
        descricao: 'Pico clássico em arenito',
      );

      expect(dto.id, equals('cuscuzeiro'));
      expect(dto.nome, equals('Morro do Cuscuzeiro'));
      expect(dto.latitude, equals(-22.123456));
      expect(dto.longitude, equals(-47.654321));
      expect(dto.estaBaixado, isTrue);
      expect(dto.totalSetores, equals(3));
      expect(dto.totalEscaladas, equals(45));
      expect(dto.localizacao, equals('Analândia'));
      expect(dto.descricao, equals('Pico clássico em arenito'));
      expect(dto.temCoordenadasValidas, isTrue);
    });

    test('temCoordenadasValidas retorna false quando coordenadas são nulas ou zero', () {
