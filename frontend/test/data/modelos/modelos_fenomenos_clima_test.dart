// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_fenomenos_clima.dart';

void main() {
  const trianguloPadrao = <PontoContornoGeo>[
    PontoContornoGeo(longitude: -44.3, latitude: -20.2),
    PontoContornoGeo(longitude: -43.7, latitude: -20.2),
    PontoContornoGeo(longitude: -44.0, latitude: -19.7),
  ];

  group('NivelUmidadePico, NivelIntensidadeChuva e PontoContornoGeo', () {
    test('expõe pesos, flag estaUmido e rótulos localizados nos estados conservadores de umidade e nos 4 níveis de chuva ao vivo', () {
      expect(NivelUmidadePico.values, hasLength(2));
      expect(NivelUmidadePico.seco.estaUmido, isFalse);
      expect(NivelUmidadePico.possivelmenteUmido.estaUmido, isTrue);
      expect(
        NivelUmidadePico.seco.peso,
        lessThan(NivelUmidadePico.possivelmenteUmido.peso),
      );

      for (final nivel in NivelUmidadePico.values) {
        expect(nivel.rotulo, isNotEmpty);
      }

      expect(NivelIntensidadeChuva.values, hasLength(4));
      for (var i = 0; i < NivelIntensidadeChuva.values.length; i++) {
        final nivelChuva = NivelIntensidadeChuva.values[i];
        expect(nivelChuva.peso, equals(i + 1));
        expect(nivelChuva.rotulo, isNotEmpty);
      }
    });

    test('valida limites geográficos de PontoContornoGeo ao converter de lista', () {
      final ponto = PontoContornoGeo.deLista(const [-44.25, -20.12]);
      expect(ponto.paraLista(), equals([-44.25, -20.12]));

      expect(() => PontoContornoGeo.deLista(const [-44.0]), throwsFormatException);
      expect(() => PontoContornoGeo.deLista(const [190.0, -20.0]), throwsFormatException);
      expect(() => PontoContornoGeo.deLista(const [-44.0, -95.0]), throwsFormatException);
    });
  });

  group('BolhaChuvaRegional e RastroPassadoTempestade', () {
    test('classifica os 4 níveis de intensidade por análise de mm/h e células convectivas internas', () {
      const fraca = BolhaChuvaRegional(
        id: 'c1',
        latitude: -20.0,
        longitude: -44.0,
        intensidadeMmHora: 0.55,
        ventoRumoGraus: 45.0,
        ventoVelocidadeKmh: 12.0,
        contornoExterno: trianguloPadrao,
      );
      const moderada = BolhaChuvaRegional(
        id: 'c2',
        latitude: -20.0,
        longitude: -44.0,
        intensidadeMmHora: 2.1,
        ventoRumoGraus: 45.0,
        ventoVelocidadeKmh: 16.0,
        contornoExterno: trianguloPadrao,
      );
      const fortePorNucleo = BolhaChuvaRegional(
        id: 'c3',
        latitude: -20.0,
        longitude: -44.0,
        intensidadeMmHora: 2.4,
        ventoRumoGraus: 45.0,
        ventoVelocidadeKmh: 22.0,
        contornoExterno: trianguloPadrao,
        nucleosIntensos: [trianguloPadrao],
      );
      const extremaPorMultiplosNucleos = BolhaChuvaRegional(
        id: 'c4',
        latitude: -20.0,
        longitude: -44.0,
        intensidadeMmHora: 4.4,
        ventoRumoGraus: 45.0,
        ventoVelocidadeKmh: 30.0,
        contornoExterno: trianguloPadrao,
        nucleosIntensos: [trianguloPadrao, trianguloPadrao],
      );
      const extremaPorTaxa = BolhaChuvaRegional(
        id: 'c5',
        latitude: -20.0,
        longitude: -44.0,
        intensidadeMmHora: 6.8,
        ventoRumoGraus: 45.0,
        ventoVelocidadeKmh: 34.0,
        contornoExterno: trianguloPadrao,
      );

