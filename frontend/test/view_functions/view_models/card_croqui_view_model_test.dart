// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/dataset/modelos/metadados_indice.dart';
import 'package:frontend/view_functions/view_models/card_croqui_view_model.dart';

void main() {
  group('CardCroquiViewModel', () {
    test('instanciação com valores obrigatórios e padrões', () {
      const vm = CardCroquiViewModel(
        id: 'pico_1',
        titulo: 'PICO TESTE',
        textoEstatisticas: '2 setores • 10 escaladas',
        caminhoMiniatura: 'thumbnails/pico_1.webp',
      );

      expect(vm.id, equals('pico_1'));
      expect(vm.titulo, equals('PICO TESTE'));
      expect(vm.localizacao, isEmpty);
      expect(vm.textoEstatisticas, equals('2 setores • 10 escaladas'));
      expect(vm.caminhoMiniatura, equals('thumbnails/pico_1.webp'));
      expect(vm.salvoOffline, isFalse);
      expect(vm.textoDistancia, isNull);
    });
  });

  group('mapearMetadadosParaCard', () {
    test('mapeia informações básicas e estatísticas resumidas por padrão', () {
      final metadados = MetadadosIndice(
        id: 'pico_alpha',
        nome: 'Pico Alpha',
        caminhoRelativo: 'brasil/mg/serra_do_cipo/croqui.binarypb',
        precomputados: PrecomputadosResumoCroqui(
          totalSetores: 4,
          totalEscaladas: 20,
        ),
      );

      final vm = mapearMetadadosParaCard(metadados, salvoOffline: true, textoDistancia: '1.5km');

      expect(vm.id, equals('pico_alpha'));
      expect(vm.titulo, equals('PICO ALPHA'));
      expect(vm.localizacao, equals('SERRA DO CIPO'));
      expect(vm.textoEstatisticas, equals('4 setores • 20 escaladas'));
      expect(vm.caminhoMiniatura, equals('thumbnails/pico_alpha.webp'));
      expect(vm.salvoOffline, isTrue);
      expect(vm.textoDistancia, equals('1.5km'));
    });

    test('aplica fallback SEM NOME quando nome estiver vazio', () {
      final metadados = MetadadosIndice(id: 'sem_nome');
      final vm = mapearMetadadosParaCard(metadados);

      expect(vm.titulo, equals('SEM NOME'));
      expect(vm.textoEstatisticas, equals('0 setores • 0 escaladas'));
      expect(vm.salvoOffline, isFalse);
    });

    test('inclui modalidades detalhadas quando estatisticasDetalhadas for true', () {
      final metadados = MetadadosIndice(
        id: 'pico_beta',
        nome: 'Pico Beta',
        precomputados: PrecomputadosResumoCroqui(
          totalSetores: 3,
          totalEscaladas: 15,
          totalBoulders: 10,
          totalEsportivas: 5,
        ),
      );

      final vm = mapearMetadadosParaCard(
        metadados,
        estatisticasDetalhadas: true,
      );

      expect(
        vm.textoEstatisticas,
        equals('3 setores • 15 escaladas (10 boulders, 5 esportivas)'),
      );
    });
  });

  group('mapearCroquiParaCard', () {
    test('mapeia Croqui offline completo com todas as propriedades', () {
      final croqui = Croqui(
        id: 'croqui_1',
        nome: 'Pedra do Baú',
        picos: [
          Pico(
            nome: 'Baú',
            estado: 'São Paulo',
            precomputados: PrecomputadosPico(
              totalSetores: 5,
              totalEscaladas: 42,
            ),
          ),
        ],
      );

      final vm = mapearCroquiParaCard(croqui);

      expect(vm.id, equals('croqui_1'));
      expect(vm.titulo, equals('PEDRA DO BAÚ'));
      expect(vm.localizacao, equals('SÃO PAULO'));
      expect(vm.textoEstatisticas, equals('5 setores • 42 escaladas'));
      expect(vm.caminhoMiniatura, equals('thumbnails/croqui_1.webp'));
      expect(vm.salvoOffline, isTrue);
    });

    test('usa nome do primeiro pico e fallback de localização quando nome for vazio', () {
      final croqui = Croqui(
        id: 'croqui_2',
        picos: [
          Pico(
            nome: 'Pico Secundário',
          ),
        ],
      );

      final vm = mapearCroquiParaCard(croqui);

      expect(vm.titulo, equals('PICO SECUNDÁRIO'));
      expect(vm.localizacao, equals('LOCAL DESCONHECIDO'));
      expect(vm.textoEstatisticas, equals('0 setores • 0 escaladas'));
    });
  });
}
