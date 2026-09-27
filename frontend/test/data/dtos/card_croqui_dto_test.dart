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

    test('mapearMetadadosParaCard mapeia ResumoCroqui corretamente', () {
      final metadados = ResumoCroqui(
        id: 'bau',
        nome: 'Pedra do Baú',
        caminhoRelativo: 'sao_paulo/bau',
        checksumSha256Thumbnail: 'thumbhash123',
        precomputados: PrecomputadosResumoCroqui(
          totalSetores: 4,
          totalEscaladas: 50,
          totalEsportivas: 30,
          totalMoveis: 20,
        ),
      );

      final dto = mapearMetadadosParaCard(
        metadados,
        salvoOffline: false,
        textoDistancia: '2.5 km',
        estatisticasDetalhadas: true,
      );

      expect(dto.id, equals('bau'));
      expect(dto.titulo, equals('PEDRA DO BAÚ'));
      expect(dto.salvoOffline, isFalse);
      expect(dto.textoDistancia, equals('2.5 km'));
      expect(dto.checksumSha256, equals('thumbhash123'));
      expect(dto.textoEstatisticas, contains('4 setores • 50 escaladas'));
      expect(dto.textoEstatisticas, contains('30 esportivas, 20 móveis'));
    });

    test('mapearCroquiParaCard mapeia Croqui completo corretamente', () {
      final croqui = Croqui(
        id: 'cipó',
        nome: 'Serra do Cipó',
        picos: [
          Pico(
            nome: 'Serra do Cipó',
            estado: 'Minas Gerais',
            precomputados: PrecomputadosPico(
              totalSetores: 8,
              totalEscaladas: 120,
            ),
          ),
        ],
      );

      final dto = mapearCroquiParaCard(croqui, textoDistancia: '500 m');

      expect(dto.id, equals('cipó'));
      expect(dto.titulo, equals('SERRA DO CIPÓ'));
      expect(dto.localizacao, equals('MINAS GERAIS'));
      expect(dto.textoEstatisticas, equals('8 setores • 120 escaladas'));
      expect(dto.salvoOffline, isTrue);
      expect(dto.textoDistancia, equals('500 m'));
    });

    test('trata nomes e locais vazios com valores amigáveis padrão', () {
      final metadadosVazios = ResumoCroqui(id: 'sem_nome');
      final dtoVazio = mapearMetadadosParaCard(metadadosVazios);

      expect(dtoVazio.titulo, equals('SEM NOME'));
      expect(dtoVazio.textoEstatisticas, equals('0 setores • 0 escaladas'));

      final croquiVazio = Croqui(id: 'croqui_vazio');
      final dtoCroquiVazio = mapearCroquiParaCard(croquiVazio);
      expect(dtoCroquiVazio.titulo, equals('SEM NOME'));
      expect(dtoCroquiVazio.localizacao, equals('LOCAL DESCONHECIDO'));
    });
  });
}
