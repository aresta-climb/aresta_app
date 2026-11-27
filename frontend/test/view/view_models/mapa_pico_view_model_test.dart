// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view/view_models/mapa_pico_view_model.dart';
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
