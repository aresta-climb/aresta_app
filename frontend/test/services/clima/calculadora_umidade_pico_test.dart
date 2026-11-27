// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/services/clima/calculadora_umidade_pico.dart';

void main() {
  const contornoPadrao = <PontoContornoGeo>[
    PontoContornoGeo(longitude: -44.5, latitude: -20.5),
    PontoContornoGeo(longitude: -43.5, latitude: -20.5),
    PontoContornoGeo(longitude: -44.0, latitude: -19.5),
  ];

  group('CalculadoraUmidadePico', () {
    test(
      'aplica janela conservadora de 4 dias para qualquer chuva na região (>= 0.2 mm): 4d -> 3d -> 2d -> 1d -> Seco',
      () {
        final diaChuva = DateTime.utc(2026, 11, 25);

        final d0 = CalculadoraUmidadePico.avaliarEventoUnico(
          milimetros: 0.4,
          dataChuva: diaChuva,
          dataReferencia: DateTime.utc(2026, 11, 25),
          bolhaId: 'b1',
        );
        expect(d0.nivel, equals(NivelUmidadePico.possivelmenteUmido));
        expect(d0.diasParaSecar, equals(4));
        expect(d0.diasDesdeChuva, equals(0));
        expect(d0.bolhaIdAssociada, equals('b1'));

        final d1 = CalculadoraUmidadePico.avaliarEventoUnico(
          milimetros: 0.4,
          dataChuva: diaChuva,
          dataReferencia: DateTime.utc(2026, 11, 26),
        );
        expect(d1.nivel, equals(NivelUmidadePico.possivelmenteUmido));
        expect(d1.diasParaSecar, equals(3));
        expect(d1.diasDesdeChuva, equals(1));

        final d2 = CalculadoraUmidadePico.avaliarEventoUnico(
          milimetros: 0.4,
          dataChuva: diaChuva,
          dataReferencia: DateTime.utc(2026, 11, 27),
        );
        expect(d2.nivel, equals(NivelUmidadePico.possivelmenteUmido));
        expect(d2.diasParaSecar, equals(2));
        expect(d2.diasDesdeChuva, equals(2));

        final d3 = CalculadoraUmidadePico.avaliarEventoUnico(
          milimetros: 0.4,
          dataChuva: diaChuva,
          dataReferencia: DateTime.utc(2026, 11, 28),
        );
        expect(d3.nivel, equals(NivelUmidadePico.possivelmenteUmido));
        expect(d3.diasParaSecar, equals(1));
        expect(d3.diasDesdeChuva, equals(3));

        final d4 = CalculadoraUmidadePico.avaliarEventoUnico(
          milimetros: 0.4,
          dataChuva: diaChuva,
          dataReferencia: DateTime.utc(2026, 11, 29),
        );
        expect(d4.nivel, equals(NivelUmidadePico.seco));
        expect(d4.diasParaSecar, equals(0));
      },
    );

    test(
      'ignora traços abaixo do limiar regional (< 0.2 mm) e datas futuras',
      () {
        final diaChuva = DateTime.utc(2026, 11, 25);

        expect(
          CalculadoraUmidadePico.avaliarEventoUnico(
            milimetros: 0.1,
            dataChuva: diaChuva,
            dataReferencia: DateTime.utc(2026, 11, 25),
          ).nivel,
          equals(NivelUmidadePico.seco),
        );
        expect(
          CalculadoraUmidadePico.avaliarEventoUnico(
            milimetros: 25.0,
            dataChuva: DateTime.utc(2026, 11, 27),
            dataReferencia: DateTime.utc(2026, 11, 25),
          ).nivel,
          equals(NivelUmidadePico.seco),
        );
      },
    );

    test(
      'reinicia o contador de 4 dias e a data da chuva sempre que ocorre nova precipitação na região e filtra bolhas/incêndios vigentes',
      () {
        // Chuva forte há 2 dias (restariam 2d) seguida de chuva leve hoje -> reinicia para 4 dias e data de hoje!
        final estadoReiniciado = CalculadoraUmidadePico.avaliarHistoricoPico(
          eventos: [
            EventoChuvaPico(
              data: DateTime.utc(2026, 11, 23),
              milimetros: 32.0,
              bolhaId: 'chuva_antiga_forte',
            ),
            EventoChuvaPico(
              data: DateTime.utc(2026, 11, 25),
              milimetros: 0.6,
              bolhaId: 'chuva_hoje_leve',
            ),
            EventoChuvaPico(
              data: DateTime.utc(2026, 11, 25),
              milimetros: 1.4,
              bolhaId: 'chuva_hoje_desempate_mm',
            ),
          ],
          dataReferencia: DateTime.utc(2026, 11, 25),
        );

        expect(
          estadoReiniciado.nivel,
          equals(NivelUmidadePico.possivelmenteUmido),
        );
        expect(estadoReiniciado.diasParaSecar, equals(4));
        expect(estadoReiniciado.diasDesdeChuva, equals(0));
        expect(estadoReiniciado.dataChuvaFormatadaCurta, equals('25/11'));
        expect(
          estadoReiniciado.bolhaIdAssociada,
          equals('chuva_hoje_desempate_mm'),
        );

        final geradoEm = DateTime.utc(2026, 11, 25, 18, 0);
        const listaBolhas = <BolhaChuvaRegional>[
          BolhaChuvaRegional(
            id: 'extrema',
            latitude: -20.4,
            longitude: -44.2,
            intensidadeMmHora: 8.6,
            ventoRumoGraus: 40.0,
            ventoVelocidadeKmh: 34.0,
            contornoExterno: contornoPadrao,
          ),
          BolhaChuvaRegional(
            id: 'forte',
            latitude: -20.0,
            longitude: -44.0,
            intensidadeMmHora: 5.2,
            ventoRumoGraus: 45.0,
            ventoVelocidadeKmh: 28.0,
            contornoExterno: contornoPadrao,
          ),
          BolhaChuvaRegional(
            id: 'moderada',
            latitude: -21.0,
            longitude: -43.0,
            intensidadeMmHora: 2.4,
            ventoRumoGraus: 60.0,
            ventoVelocidadeKmh: 18.0,
            contornoExterno: contornoPadrao,
          ),
          BolhaChuvaRegional(
            id: 'leve',
            latitude: -19.2,
            longitude: -43.6,
            intensidadeMmHora: 0.4,
            ventoRumoGraus: 75.0,
            ventoVelocidadeKmh: 12.0,
            contornoExterno: contornoPadrao,
          ),
          BolhaChuvaRegional(
            id: 'sem_chuva_agora',
            latitude: -18.5,
            longitude: -42.0,
            intensidadeMmHora: 0.05,
            ventoRumoGraus: 90.0,
            ventoVelocidadeKmh: 8.0,
            contornoExterno: contornoPadrao,
          ),
        ];

        final bolhasAtivas = CalculadoraUmidadePico.filtrarBolhasAtivas(
          bolhas: listaBolhas,
          geradoEm: geradoEm,
          dataReferencia: DateTime.utc(2026, 11, 25, 19, 30),
        );

