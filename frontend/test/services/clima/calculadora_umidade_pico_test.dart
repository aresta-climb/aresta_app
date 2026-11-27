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

