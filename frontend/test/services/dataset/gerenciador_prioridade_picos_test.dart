// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset/armazenamento/gerenciador_prioridade_picos.dart';

void main() {
  late Directory tempDir;
  late GerenciadorPrioridadePicos gerenciador;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('prioridade_test_');
    gerenciador = GerenciadorPrioridadePicos();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('GerenciadorPrioridadePicos', () {
    test('retorna lista vazia quando o arquivo não existe', () async {
      final lista = await gerenciador.obterListaPrioridade(tempDir.path);
      expect(lista, isEmpty);
    });

    test('atualiza e persiste a prioridade no arquivo YAML', () async {
      await gerenciador.atualizarPrioridade(tempDir.path, 'pico_1');
      await gerenciador.atualizarPrioridade(tempDir.path, 'pico_2');

      final lista = await gerenciador.obterListaPrioridade(tempDir.path);
      expect(lista, equals(['pico_2', 'pico_1']));
    });

    test('reordena item existente para o topo', () async {
      await gerenciador.atualizarPrioridade(tempDir.path, 'pico_1');
      await gerenciador.atualizarPrioridade(tempDir.path, 'pico_2');
      await gerenciador.atualizarPrioridade(tempDir.path, 'pico_1');

      final lista = await gerenciador.obterListaPrioridade(tempDir.path);
      expect(lista, equals(['pico_1', 'pico_2']));
    });

    test('migra arquivo JSON legado para YAML e remove o JSON', () async {
      final jsonFile = File('${tempDir.path}/recent_picos.json');
      await jsonFile.writeAsString('["pico_a", "pico_b"]');

      final lista = await gerenciador.obterListaPrioridade(tempDir.path);
      expect(lista, equals(['pico_a', 'pico_b']));
      expect(await jsonFile.exists(), isFalse);

      final yamlFile = File('${tempDir.path}/recent_picos.yaml');
      expect(await yamlFile.exists(), isTrue);
    });

    test('ordena lista de picos com base na lista de prioridade', () {
      final picos = [
        {'id': 'pico_3'},
        {'id': 'pico_1'},
        {'id': 'pico_2'},
        {'id': 'pico_invalido'},
      ];

      final ordenados = gerenciador.ordenarPorPrioridade(
        picos,
        ['pico_1', 'pico_2', 'pico_3'],
      );

      expect(ordenados.map((p) => p['id']).toList(), [
        'pico_1',
        'pico_2',
        'pico_3',
        'pico_invalido',
      ]);
    });
  });
}
