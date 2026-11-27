// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_rede_viaria_aresta.dart';

void main() {
  group('Modelos de domínio da rede viária Aresta', () {
    test('valida contratos imutáveis de polígonos, localidades, rodovias em 3 níveis, DEM de picos e rede viária', () {
      const poligono = PoligonoGeografico(
        id: 'mg',
        verticesLonLat: [Offset(-44.0, -20.0), Offset(-43.5, -19.5)],
      );
      expect(poligono.id, equals('mg'));
      expect(poligono.verticesLonLat, hasLength(2));

      const localidade = LocalidadeRegionalMapa(
        nome: 'Belo Horizonte',
        ehCidade: true,
        longitude: -43.9386,
        latitude: -19.9191,
      );
      expect(localidade.nivel, equals(1));
      expect(localidade.ehCidade, isTrue);

      const rodoviaConst = RodoviaRegionalMapa(
        ehPrincipal: true,
        codigo: 'BR-040',
        verticesLonLat: [Offset(-43.9386, -19.9191), Offset(-43.80, -20.10)],
      );
      expect(rodovia.ehPrincipal, isTrue);
      expect(rodovia.codigo, equals('BR-040'));

      const picoSemDem = PicoRelevoReferencia(
        id: 'cipo',
        latitude: -19.31,
        longitude: -43.61,
        altitudeBaseMetros: 820,
        altitudePicoMetros: 1310,
      );
      expect(picoSemDem.temGradeDemReal, isFalse);

      const picoComDem = PicoRelevoReferencia(
        id: 'igarape',
        latitude: -20.07,
        longitude: -44.32,
        altitudeBaseMetros: 980,
        altitudePicoMetros: 1430,
        dimensaoGradeDem: 2,
        raioGradeDemGraus: 0.024,
        gradeDemMetros: [980, 1120, 1260, 1430],
      );
      expect(picoComDem.temGradeDemReal, isTrue);

      const trecho = TrechoPropagacaoViaria(
        verticesLonLat: [Offset(-43.9386, -19.9191), Offset(-43.80, -20.10)],
        tempoInicio: 0.0,
        tempoFim: 0.45,
      );
      expect(trecho.tempoFim, greaterThan(trecho.tempoInicio));

      const cidade = CidadeClassificadaMapa(
        localidade: localidade,
        ehRelevanteAresta: true,
        tempoAtivacao: 0.0,
        viasUrbanasLonLat: [
          [Offset(-43.95, -19.92), Offset(-43.92, -19.91)],
        ],
      );
      expect(cidade.ehRelevanteAresta, isTrue);

      const rede = RedeViariaArestaGlobo(
        rodoviasFundo: [rodovia],
        trechosCorredorAresta: [trecho],
        cidadesClassificadas: [cidade],
      );
      expect(RedeViariaArestaGlobo.latitudeCentroBeloHorizonte, closeTo(-19.9191, 1e-4));
      expect(RedeViariaArestaGlobo.longitudeCentroBeloHorizonte, closeTo(-43.9386, 1e-4));
      expect(rede.rodoviasFundo, hasLength(1));
      expect(rede.trechosCorredorAresta, hasLength(1));
      expect(rede.cidadesClassificadas, hasLength(1));
    });
  });
}
