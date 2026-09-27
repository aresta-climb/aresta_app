// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/dtos/card_croqui_dto.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';

void main() {
  group('CardCroquiDTO Tests', () {
    test('criação direta com dados primitivos', () {
      const dto = CardCroquiDTO(
        id: 'pedra_bela',
        titulo: 'PEDRA BELA',
        localizacao: 'SÃO PAULO',
        textoEstatisticas: '5 setores • 20 escaladas',
        caminhoMiniatura: 'thumbnails/pedra_bela.webp',
        salvoOffline: true,
        textoDistancia: '15 km',
        caminhoCapa: 'capas/pedra_bela.jpg',
        checksumSha256: 'abc123hash',
      );

      expect(dto.id, equals('pedra_bela'));
      expect(dto.titulo, equals('PEDRA BELA'));
      expect(dto.localizacao, equals('SÃO PAULO'));
      expect(dto.textoEstatisticas, equals('5 setores • 20 escaladas'));
      expect(dto.caminhoMiniatura, equals('thumbnails/pedra_bela.webp'));
      expect(dto.salvoOffline, isTrue);
      expect(dto.textoDistancia, equals('15 km'));
      expect(dto.caminhoCapa, equals('capas/pedra_bela.jpg'));
      expect(dto.checksumSha256, equals('abc123hash'));
    });

