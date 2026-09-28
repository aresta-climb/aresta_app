// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/view_models/pico_proximo_view_model.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';

void main() {
  group('PicoProximoViewModel Tests', () {
    test('criação direta com dados primitivos e formatação de distância', () {
      const vmMetro = PicoProximoViewModel(
        id: 'pedra_bela',
        nome: 'Pedra Bela',
        localizacao: 'São Paulo',
        distanciaKm: 0.45,
        caminhoMiniatura: 'thumbnails/pedra_bela.webp',
        estaBaixado: true,
        totalSetores: 4,
        totalEscaladas: 30,
      );

      expect(vmMetro.id, equals('pedra_bela'));
      expect(vmMetro.nome, equals('Pedra Bela'));
      expect(vmMetro.localizacao, equals('São Paulo'));
      expect(vmMetro.distanciaKm, equals(0.45));
      expect(vmMetro.distanciaFormatada, equals('450 m'));
      expect(vmMetro.caminhoMiniatura, equals('thumbnails/pedra_bela.webp'));
      expect(vmMetro.estaBaixado, isTrue);
      expect(vmMetro.totalSetores, equals(4));
      expect(vmMetro.totalEscaladas, equals(30));

      final card = vmMetro.paraCardCroquiViewModel();
      expect(card.id, equals('pedra_bela'));
      expect(card.titulo, equals('PEDRA BELA'));
      expect(card.salvoOffline, isTrue);

      const vmKm = PicoProximoViewModel(
        id: 'bau',
        nome: 'Pedra do Baú',
        localizacao: 'São Paulo',
        distanciaKm: 12.34,
        caminhoMiniatura: 'thumbnails/bau.webp',
        estaBaixado: false,
      );

      expect(vmKm.distanciaFormatada, equals('12.3 km'));
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

      final vm = PicoProximoViewModel.deMetadados(
        metadados: metadados,
        distanciaKm: 5.67,
        estaBaixado: true,
      );

      expect(vm.id, equals('cipó'));
      expect(vm.nome, equals('Serra do Cipó'));
      expect(vm.localizacao, equals('Minas Gerais'));
      expect(vm.distanciaKm, equals(5.67));
      expect(vm.distanciaFormatada, equals('5.7 km'));
      expect(vm.caminhoMiniatura, equals('thumbnails/cipó.webp'));
      expect(vm.estaBaixado, isTrue);
      expect(vm.totalSetores, equals(10));
      expect(vm.totalEscaladas, equals(150));

      final card = vm.paraCardCroquiViewModel();
      expect(card.id, equals('cipó'));
      expect(card.titulo, equals('SERRA DO CIPÓ'));
      expect(card.salvoOffline, isTrue);
    });

    test('distanciaFormatada com valor nulo retorna string vazia', () {
      const vm = PicoProximoViewModel(
        id: 'pico_sem_distancia',
        nome: 'Pico Longe',
        localizacao: 'Minas',
        caminhoMiniatura: 'thumbnails/pico_sem_distancia.webp',
      );

      expect(vm.distanciaFormatada, isEmpty);
    });
  });
}
