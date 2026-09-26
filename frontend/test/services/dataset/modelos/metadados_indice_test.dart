// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/dataset/modelos/metadados_indice.dart';

void main() {
  group('MetadadosIndice', () {
    test('instancia corretamente como alias de ResumoCroqui com campos preenchidos', () {
      final metadados = MetadadosIndice(
        id: 'pedra_bela',
        nome: 'Pedra Bela',
        descricao: 'Pico tradicional de escalada',
        caminhoRelativo: 'br_sp_pedra_bela/compilado.binarypb',
        checksumSha256Croqui: 'sha256_mock_123',
        precomputados: PrecomputadosResumoCroqui(
          totalEscaladas: 42,
          totalSetores: 5,
        ),
      );

      expect(metadados.id, equals('pedra_bela'));
      expect(metadados.nome, equals('Pedra Bela'));
      expect(metadados.descricao, equals('Pico tradicional de escalada'));
      expect(metadados.caminhoRelativo, equals('br_sp_pedra_bela/compilado.binarypb'));
      expect(metadados.checksumSha256Croqui, equals('sha256_mock_123'));
      expect(metadados.hasPrecomputados(), isTrue);
      expect(metadados.precomputados.totalEscaladas, equals(42));
      expect(metadados.precomputados.totalSetores, equals(5));
    });

    test('permite criar instância do Indice contendo lista de MetadadosIndice', () {
      final item = MetadadosIndice(id: 'cipo', nome: 'Serra do Cipó');
      final indice = Indice(croquis: [item]);

      expect(indice.croquis.length, equals(1));
      expect(indice.croquis.first.id, equals('cipo'));
      expect(indice.croquis.first, isA<MetadadosIndice>());
    });

    test('extensao extrai coordenadas, localizacaoFormatada e converte para ResumoPico', () {
      final metadados = MetadadosIndice(
        id: 'pedra_bela',
        nome: 'Pedra Bela',
        descricao: 'Pico incrível',
        caminhoRelativo: 'pedra_bela/compilado.binarypb',
        checksumSha256Croqui: 'hash_croqui_123',
        localizacao: Coordenada(
          latitude: -227000000,
          longitude: -465000000,
        ),
        precomputados: PrecomputadosResumoCroqui(
          totalEscaladas: 50,
          totalSetores: 4,
          totalEsportivas: 40,
          totalMoveis: 10,
          tamanhoDownloadBytes: Int64(1048576),
        ),
      );

      expect(metadados.latitude, closeTo(-22.7, 0.0001));
      expect(metadados.longitude, closeTo(-46.5, 0.0001));
      expect(metadados.localizacaoFormatada, equals('Pedra Bela'));
      expect(metadados.totalEscaladas, equals(50));
      expect(metadados.totalSetores, equals(4));
      expect(metadados.tamanhoDownloadBytes, equals(1048576));

      final resumo = metadados.paraResumoPico(
        baseUrl: 'https://cdn.aresta.app',
        isDownloaded: true,
      );
      expect(resumo.id, equals('pedra_bela'));
      expect(resumo.nome, equals('Pedra Bela'));
      expect(resumo.local, equals('Pedra Bela'));
      expect(resumo.isDownloaded, isTrue);
      expect(resumo.url, contains('hash_croqui_123'));
      expect(resumo.thumbnailUrl, equals('https://cdn.aresta.app/thumbnails/pedra_bela.webp'));
      expect(resumo.latitude, closeTo(-22.7, 0.0001));
      expect(resumo.estatisticas?.totalVias, equals(50));
    });

    test('extensao em Croqui converte para ResumoPico com segurança', () {
      final croqui = Croqui(
        id: 'itacolomi',
        nome: 'Pico do Itacolomi',
        descricao: 'Parque estadual',
        picos: [
          Pico(
            nome: 'Itacolomi Principal',
            estado: 'Minas Gerais',
            localizacao: Coordenada(latitude: -204000000, longitude: -435000000),
          ),
        ],
      );

      final resumo = croqui.paraResumoPico(capaPath: '/caminho/capa.jpg');
      expect(resumo.id, equals('itacolomi'));
      expect(resumo.nome, equals('Pico do Itacolomi'));
      expect(resumo.local, equals('Minas Gerais'));
      expect(resumo.isDownloaded, isTrue);
      expect(resumo.capaPath, equals('/caminho/capa.jpg'));
      expect(resumo.croqui, equals(croqui));
      expect(resumo.pico?.nome, equals('Itacolomi Principal'));
      expect(resumo.latitude, closeTo(-20.4, 0.0001));
    });
  });
}

