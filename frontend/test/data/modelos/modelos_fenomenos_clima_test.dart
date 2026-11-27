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

      expect(fraca.nivelIntensidade, equals(NivelIntensidadeChuva.fraca));
      expect(moderada.nivelIntensidade, equals(NivelIntensidadeChuva.moderada));
      expect(fortePorNucleo.nivelIntensidade, equals(NivelIntensidadeChuva.forte));
      expect(
        extremaPorMultiplosNucleos.nivelIntensidade,
        equals(NivelIntensidadeChuva.extrema),
      );
      expect(extremaPorTaxa.nivelIntensidade, equals(NivelIntensidadeChuva.extrema));
    });

    test('serializa núcleos intensos, ordena rastros passados e calcula limites', () {
      final bolha = BolhaChuvaRegional.deMapa({
        'id': 'chuva_mg',
        'lat': -20.0,
        'lon': -44.0,
        'intensidade_mm_h': 4.5,
        'vento_rumo_graus': -45.0,
        'vento_kmh': 24.0,
        'contorno_externo': [
          [-44.3, -20.2],
          [-43.7, -20.2],
          [-44.0, -19.7],
        ],
        'nucleos_intensos': [
          [
            [-44.1, -20.1],
            [-43.9, -20.1],
            [-44.0, -19.9],
          ],
        ],
        'rastros_passados': [
          {
            'horas_atras': 3,
            'contorno': [
              [-44.5, -20.4],
              [-44.2, -20.4],
              [-44.3, -20.1],
            ],
          },
          {
            'horas_atras': 6,
            'contorno': [
              [-44.8, -20.6],
              [-44.5, -20.6],
              [-44.6, -20.3],
            ],
          },
        ],
      });

      expect(bolha.ventoRumoGraus, closeTo(315.0, 1e-6));
      expect(bolha.minLon, closeTo(-44.3, 1e-6));
      expect(bolha.maxLon, closeTo(-43.7, 1e-6));
      expect(bolha.minLat, closeTo(-20.2, 1e-6));
      expect(bolha.maxLat, closeTo(-19.7, 1e-6));
      expect(bolha.nivelIntensidade, equals(NivelIntensidadeChuva.forte));
      expect(
        bolha.obterPegadasTrajetoria().map((r) => r.horasAtras).toList(),
        equals([6, 3]),
      );

      final restaurada = BolhaChuvaRegional.deMapa(bolha.paraMapa());
      expect(restaurada.nucleosIntensos, hasLength(1));
      expect(restaurada.rastrosPassados, hasLength(2));

      final renderizavel = BolhaAtivaRenderizavel(
        bolha: restaurada,
        nivelIntensidade: restaurada.nivelIntensidade,
      );
      expect(renderizavel.bolha.id, equals('chuva_mg'));
      expect(renderizavel.nivelIntensidade, equals(NivelIntensidadeChuva.forte));
    });

    test('retroprojeta pegadas cinemáticas pelo vento inclusive cruzando o antimeridiano', () {
      const bolhaOeste = BolhaChuvaRegional(
        id: 'antimeridiano_oeste',
        latitude: 0.0,
        longitude: 179.9,
        intensidadeMmHora: 2.0,
        ventoRumoGraus: 270.0,
        ventoVelocidadeKmh: 60.0,
        contornoExterno: [
          PontoContornoGeo(longitude: 179.8, latitude: -0.2),
          PontoContornoGeo(longitude: 180.0, latitude: -0.2),
          PontoContornoGeo(longitude: 179.9, latitude: 0.2),
        ],
      );
      final pegadasOeste = bolhaOeste.obterPegadasTrajetoria();
      expect(pegadasOeste.map((p) => p.horasAtras).toList(), equals([6, 3]));
      expect(
        pegadasOeste.first.contorno.every(
          (p) => p.longitude >= -180.0 && p.longitude <= 180.0,
        ),
        isTrue,
      );

      const bolhaLeste = BolhaChuvaRegional(
        id: 'antimeridiano_leste',
        latitude: 0.0,
        longitude: -179.9,
        intensidadeMmHora: 2.0,
        ventoRumoGraus: 90.0,
        ventoVelocidadeKmh: 60.0,
        contornoExterno: [
          PontoContornoGeo(longitude: -180.0, latitude: -0.2),
          PontoContornoGeo(longitude: -179.8, latitude: -0.2),
          PontoContornoGeo(longitude: -179.9, latitude: 0.2),
        ],
      );
      expect(
        bolhaLeste.obterPegadasTrajetoria().first.contorno.every(
          (p) => p.longitude >= -180.0 && p.longitude <= 180.0,
        ),
        isTrue,
      );
    });

    test('rejeita payloads inválidos em BolhaChuvaRegional e RastroPassadoTempestade', () {
      expect(
        () => RastroPassadoTempestade.deMapa({'horas_atras': 0, 'contorno': []}),
        throwsFormatException,
      );
      expect(
        () => BolhaChuvaRegional.deMapa({'id': '', 'lat': 0, 'lon': 0}),
        throwsFormatException,
      );
      expect(
        () => BolhaChuvaRegional.deMapa({
          'id': 'b',
          'lat': -20.0,
          'lon': -44.0,
          'intensidade_mm_h': 1.0,
          'vento_rumo_graus': 90.0,
          'vento_kmh': 10.0,
          'contorno_externo': [
            [-44.1, -20.1],
            [-43.9, -20.1],
            [-44.0, -19.9],
          ],
          'nucleos_intensos': 'invalido',
        }),
        throwsFormatException,
      );
      expect(
        () => BolhaChuvaRegional.deMapa({
          'id': 'b',
          'lat': -20.0,
          'lon': -44.0,
          'intensidade_mm_h': 1.0,
          'vento_rumo_graus': 90.0,
          'vento_kmh': 10.0,
          'contorno_externo': [
            [-44.1, -20.1],
            [-43.9, -20.1],
            [-44.0, -19.9],
          ],
          'nucleos_intensos': [
            [
              [-44.0, -20.0],
            ],
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => BolhaChuvaRegional.deMapa({
          'id': 'b',
          'lat': -20.0,
          'lon': -44.0,
          'intensidade_mm_h': 1.0,
          'vento_rumo_graus': 90.0,
          'vento_kmh': 10.0,
          'contorno_externo': [
            [-44.1, -20.1],
            [-43.9, -20.1],
            [-44.0, -19.9],
          ],
          'rastros_passados': 'invalido',
        }),
        throwsFormatException,
      );
      expect(
        () => BolhaChuvaRegional.deMapa({
          'id': 'b',
          'lat': -20.0,
          'lon': -44.0,
          'intensidade_mm_h': 1.0,
          'vento_rumo_graus': 90.0,
          'vento_kmh': 10.0,
          'contorno_externo': [
            [-44.1, -20.1],
            [-43.9, -20.1],
            [-44.0, -19.9],
          ],
          'rastros_passados': ['nao_mapa'],
        }),
        throwsFormatException,
      );
    });
  });

  group('BolhaIncendioRegional e NivelSeveridadeIncendio', () {
    test('classifica os 4 níveis de severidade combinando FRP, focos e núcleos intensos', () {
      expect(NivelSeveridadeIncendio.values, hasLength(4));
      for (var i = 0; i < NivelSeveridadeIncendio.values.length; i++) {
        final s = NivelSeveridadeIncendio.values[i];
        expect(s.peso, equals(i + 1));
        expect(s.rotulo, isNotEmpty);
      }

      final baixo = BolhaIncendioRegional.deMapa({
        'id': 'f_baixo',
        'lat': -19.0,
        'lon': -43.0,
        'potencia_frp_mw': 9.5,
        'total_focos': 2,
        'vento_rumo_graus': 180.0,
        'vento_kmh': 10.0,
        'contorno_externo': [
          [-43.1, -19.1],
          [-42.9, -19.1],
          [-43.0, -18.9],
        ],
      });
      expect(baixo.nivelSeveridade, equals(NivelSeveridadeIncendio.baixo));
      expect(baixo.fonteSatelite, equals('INPE_BDQUEIMADAS_NASA_VIIRS_MODIS'));

      const moderado = BolhaIncendioRegional(
        id: 'f_moderado',
        latitude: -19.0,
        longitude: -43.0,
        potenciaFrpMw: 22.0,
        totalFocos: 3,
        ventoRumoGraus: 90.0,
        ventoVelocidadeKmh: 12.0,
        contornoExterno: trianguloPadrao,
      );
      expect(moderado.nivelSeveridade, equals(NivelSeveridadeIncendio.moderado));

