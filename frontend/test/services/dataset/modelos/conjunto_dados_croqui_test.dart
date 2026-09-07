// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset/modelos/conjunto_dados_croqui.dart';
import 'package:frontend/services/dataset/modelos/resumo_pico.dart';

void main() {
  group('ConjuntoDadosCroqui', () {
    test('instancia vazio com listas imutáveis', () {
      final dataset = ConjuntoDadosCroqui.vazio();
      expect(dataset.picosDisponiveis, isEmpty);
      expect(dataset.picosBaixados, isEmpty);
      expect(dataset.availablePicos, isEmpty);
      expect(dataset.downloadedPicos, isEmpty);
    });

    test('aceita e normaliza List<ResumoPico>', () {
      final picos = [
        const ResumoPico(id: 'p1', nome: 'Pico 1', local: 'Local 1'),
      ];

      final dataset = ConjuntoDadosCroqui(
        picosDisponiveis: picos,
        picosBaixados: picos,
      );

      expect(dataset.picosDisponiveis.first.id, equals('p1'));
      expect(dataset.picosBaixados.first.nome, equals('Pico 1'));
    });

    test('normaliza mapas legados para List<ResumoPico>', () {
      final mapas = [
        {
          'id': 'pico_mapa',
          'nome': 'Pico do Mapa',
          'local': 'MG',
        }
      ];

      final dataset = ConjuntoDadosCroqui(
        picosDisponiveis: mapas,
      );

      expect(dataset.picosDisponiveis.first, isA<ResumoPico>());
      expect(dataset.picosDisponiveis.first.id, equals('pico_mapa'));
      expect(dataset.picosDisponiveis.first.nome, equals('Pico do Mapa'));
    });

    test('suporta copyWith mantendo tipagem', () {
      final dataset = ConjuntoDadosCroqui(
        picosDisponiveis: [
          const ResumoPico(id: 'p1', nome: 'Pico 1', local: 'L1'),
        ],
      );

      final atualizado = dataset.copyWith(
        picosBaixados: [
          const ResumoPico(id: 'p1', nome: 'Pico 1', local: 'L1', isDownloaded: true),
        ],
      );

      expect(atualizado.picosDisponiveis.length, equals(1));
      expect(atualizado.picosBaixados.first.isDownloaded, isTrue);
    });
  });
}
