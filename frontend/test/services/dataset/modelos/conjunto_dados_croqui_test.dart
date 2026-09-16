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

    test('suporta construtor com aliases availablePicos e downloadedPicos', () {
      final picos = [
        const ResumoPico(id: 'pico_alias', nome: 'Pico Alias', local: 'MG'),
      ];

      final dataset = ConjuntoDadosCroqui(
        availablePicos: picos,
        downloadedPicos: picos,
      );

      expect(dataset.picosDisponiveis.first.id, equals('pico_alias'));
      expect(dataset.picosBaixados.first.nome, equals('Pico Alias'));
      expect(dataset.availablePicos.first.id, equals('pico_alias'));
      expect(dataset.downloadedPicos.first.nome, equals('Pico Alias'));
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

    test('normaliza mapas legados para ResumoPico e rejeita tipos inválidos', () {
      final dataset = ConjuntoDadosCroqui(
        picosDisponiveis: [
          {'id': 'pico_mapa', 'nome': 'Pico do Mapa', 'local': 'MG'}
        ],
      );

      expect(dataset.picosDisponiveis.first, isA<ResumoPico>());
      expect(dataset.picosDisponiveis.first.id, equals('pico_mapa'));

      expect(
        () => ConjuntoDadosCroqui(picosDisponiveis: [123]),
        throwsArgumentError,
      );
    });
  });
}
