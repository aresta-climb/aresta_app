// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';

void main() {
  group('EventoChuvaPico', () {
    test('serializa e desserializa evento com e sem bolha associada', () {
      final comBolha = EventoChuvaPico.deMapa({
        'data': '2026-11-25',
        'mm': 14.5,
        'bolha_id': 'tempestade_1',
      });
      expect(comBolha.data, equals(DateTime.utc(2026, 11, 25)));
      expect(comBolha.milimetros, closeTo(14.5, 1e-6));
      expect(comBolha.bolhaId, equals('tempestade_1'));
      expect(comBolha.paraMapa(), equals({
        'data': '2026-11-25',
        'mm': 14.5,
        'bolha_id': 'tempestade_1',
      }));

      final semBolha = EventoChuvaPico.deMapa({'data': '2026-03-04', 'mm': 2});
      expect(semBolha.bolhaId, isNull);
      expect(semBolha.paraMapa().containsKey('bolha_id'), isFalse);
    });

    test('rejeita mapa com campos ausentes ou data inválida', () {
      expect(
        () => EventoChuvaPico.deMapa({'data': 123, 'mm': 4.0}),
        throwsFormatException,
      );
      expect(
        () => EventoChuvaPico.deMapa({'data': 'data-invalida', 'mm': 4.0}),
        throwsFormatException,
      );
    });
  });

  group('CotaAltimetricaPico', () {
    test('serializa e desserializa cotas com e sem grade DEM', () {
      final simples = CotaAltimetricaPico.deMapa({
        'altitude_base_m': 820,
        'altitude_pico_m': 1240,
      });
      expect(simples.altitudeBaseMetros, equals(820));
      expect(simples.altitudePicoMetros, equals(1240));
      expect(simples.gradeDemMetros, isEmpty);
      expect(simples.paraMapa().containsKey('grade_dem_m'), isFalse);

      final comGrade = CotaAltimetricaPico.deMapa({
        'altitude_base_m': 900,
        'altitude_pico_m': 1350,
        'altitude_ponto_m': 1120,
        'grade_dem_m': [900, 960, 1100, 1350],
      });
      expect(comGrade.dimensaoGradeDem, equals(2));
      expect(comGrade.altitudePontoMetros, equals(1120));
      expect(comGrade.paraMapa()['dimensao_grade'], equals(2));

      final comRaioExplicito = CotaAltimetricaPico.deMapa({
        'altitude_base_m': 700,
        'altitude_pico_m': 950,
        'dimensao_grade': 2,
        'raio_grade_graus': 0.03,
        'grade_dem_m': [700, 750, 820, 950],
      });
      expect(comRaioExplicito.raioGradeDemGraus, closeTo(0.03, 1e-6));
    });

    test('preservandoGradeSeAusente herda malha DEM anterior apenas quando ausente', () {
      const anteriorComGrade = CotaAltimetricaPico(
        altitudeBaseMetros: 800,
        altitudePicoMetros: 1200,
        altitudePontoMetros: 950,
        dimensaoGradeDem: 2,
        raioGradeDemGraus: 0.025,
        gradeDemMetros: [800, 900, 1000, 1200],
      );
      const novaSemGrade = CotaAltimetricaPico(
        altitudeBaseMetros: 810,
        altitudePicoMetros: 1210,
      );
      final combinada = novaSemGrade.preservandoGradeSeAusente(anteriorComGrade);
      expect(combinada.gradeDemMetros, equals([800, 900, 1000, 1200]));
      expect(combinada.altitudePontoMetros, equals(950));

      expect(novaSemGrade.preservandoGradeSeAusente(null), same(novaSemGrade));
      expect(
        novaSemGrade.preservandoGradeSeAusente(
          const CotaAltimetricaPico(
            altitudeBaseMetros: 800,
            altitudePicoMetros: 900,
          ),
        ),
        same(novaSemGrade),
      );
      expect(
        anteriorComGrade.preservandoGradeSeAusente(novaSemGrade),
        same(anteriorComGrade),
      );
    });

    test('rejeita cotas ou grades DEM fora das invariantes físicas', () {
      expect(
        () => CotaAltimetricaPico.deMapa({
          'altitude_base_m': 1200,
          'altitude_pico_m': 900,
        }),
        throwsFormatException,
      );
      expect(
        () => CotaAltimetricaPico.deMapa({
          'altitude_base_m': 800,
          'altitude_pico_m': 900,
          'grade_dem_m': [800, 900],
        }),
        throwsFormatException,
      );
      expect(
        () => CotaAltimetricaPico.deMapa({
          'altitude_base_m': 800,
          'altitude_pico_m': 900,
          'dimensao_grade': 3,
          'grade_dem_m': [800, 820, 850, 900],
        }),
        throwsFormatException,
      );
      expect(
        () => CotaAltimetricaPico.deMapa({
          'altitude_base_m': 800,
          'altitude_pico_m': 900,
          'raio_grade_graus': 0,
          'grade_dem_m': [800, 820, 850, 900],
        }),
        throwsFormatException,
      );
      expect(
        () => CotaAltimetricaPico.deMapa({
          'altitude_base_m': 800,
          'altitude_pico_m': 900,
          'grade_dem_m': [800, 'invalido', 850, 900],
        }),
        throwsFormatException,
      );
    });
  });

  group('EstadoUmidadePico e SnapshotClimaAltimetria', () {
    test('formata data curta apenas quando há umidade ativa com data conhecida', () {
      const seco = EstadoUmidadePico.seco();
      expect(seco.dataChuvaFormatadaCurta, isNull);
      expect(seco.diasDesdeChuva, equals(0));

      const umidoSemData = EstadoUmidadePico(
        nivel: NivelUmidadePico.possivelmenteUmido,
        diasParaSecar: 2,
        diasDesdeChuva: 2,
      );
      expect(umidoSemData.dataChuvaFormatadaCurta, isNull);

      final umidoComData = EstadoUmidadePico(
        nivel: NivelUmidadePico.possivelmenteUmido,
        diasParaSecar: 4,
        diasDesdeChuva: 0,
        dataUltimaChuva: DateTime.utc(2026, 9, 5),
        milimetrosEvento: 22.0,
      );
      expect(umidoComData.dataChuvaFormatadaCurta, equals('05/09'));
    });

