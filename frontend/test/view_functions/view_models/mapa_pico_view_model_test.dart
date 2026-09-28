// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/view_models/mapa_pico_view_model.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';

void main() {
  group('MapaPicoViewModel Tests', () {
    test('criação direta com dados primitivos', () {
      const vm = MapaPicoViewModel(
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

      expect(vm.id, equals('cuscuzeiro'));
      expect(vm.nome, equals('Morro do Cuscuzeiro'));
      expect(vm.latitude, equals(-22.123456));
      expect(vm.longitude, equals(-47.654321));
      expect(vm.estaBaixado, isTrue);
      expect(vm.totalSetores, equals(3));
      expect(vm.totalEscaladas, equals(45));
      expect(vm.localizacao, equals('Analândia'));
      expect(vm.descricao, equals('Pico clássico em arenito'));
      expect(vm.temCoordenadasValidas, isTrue);

      final card = vm.paraCardCroquiViewModel();
      expect(card.id, equals('cuscuzeiro'));
      expect(card.titulo, equals('MORRO DO CUSCUZEIRO'));
      expect(card.salvoOffline, isTrue);
    });

    test('temCoordenadasValidas retorna false quando coordenadas são nulas ou zero', () {
      const vmInvalido = MapaPicoViewModel(
        id: 'invalido',
        nome: 'Pico Sem Coordenadas',
      );

      expect(vmInvalido.temCoordenadasValidas, isFalse);
    });

    test('deMetadados converte ResumoCroqui com micrograus para graus decimais', () {
      final metadados = ResumoCroqui(
        id: 'bau',
        nome: 'Pedra do Baú',
        localizacao: Coordenada(
          latitude: -226844440,
          longitude: -456633330,
        ),
        precomputados: PrecomputadosResumoCroqui(
          totalSetores: 6,
          totalEscaladas: 80,
        ),
      );

      final vm = MapaPicoViewModel.deMetadados(
        metadados: metadados,
        estaBaixado: false,
      );

      expect(vm.id, equals('bau'));
      expect(vm.nome, equals('Pedra do Baú'));
      expect(vm.latitude, closeTo(-22.684444, 0.00001));
      expect(vm.longitude, closeTo(-45.663333, 0.00001));
      expect(vm.estaBaixado, isFalse);
      expect(vm.totalSetores, equals(6));
      expect(vm.totalEscaladas, equals(80));
      expect(vm.temCoordenadasValidas, isTrue);

      final card = vm.paraCardCroquiViewModel();
      expect(card.id, equals('bau'));
      expect(card.titulo, equals('PEDRA DO BAÚ'));
      expect(card.salvoOffline, isFalse);
    });

    test('deMapa instancia corretamente a partir de mapa legado', () {
      final mapa = {
        'id': 'mapa_teste',
        'nome': 'Pico do Mapa',
        'latitude': -20.0,
        'longitude': -40.0,
        'isDownloaded': true,
        'totalSetores': 2,
        'totalEscaladas': 12,
      };

      final vm = MapaPicoViewModel.deMapa(mapa);
      expect(vm.id, equals('mapa_teste'));
      expect(vm.estaBaixado, isTrue);
      expect(vm.temCoordenadasValidas, isTrue);

      final card = vm.paraCardCroquiViewModel();
      expect(card.id, equals('mapa_teste'));
      expect(card.salvoOffline, isTrue);
    });
  });
}
