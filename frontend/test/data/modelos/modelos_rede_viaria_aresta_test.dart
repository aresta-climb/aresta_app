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
      expect(rodoviaConst.ehPrincipal, isTrue);
      expect(rodoviaConst.nivelViario, equals(1));
      expect(rodoviaConst.codigo, equals('BR-040'));

      const rodoviaSecConst = RodoviaRegionalMapa(
        ehPrincipal: false,
        codigo: 'MG-010',
        verticesLonLat: [Offset(-43.93, -19.90), Offset(-43.61, -19.31)],
      );
      expect(rodoviaSecConst.nivelViario, equals(2));

      final rodoviaVazia = RodoviaRegionalMapa.comLimites(
        ehPrincipal: false,
        codigo: '',
        verticesLonLat: const [],
      );
      expect(rodoviaVazia.minLon, equals(0.0));
      expect(rodoviaVazia.maxLat, equals(0.0));

      final rodoviaComLimites = RodoviaRegionalMapa.comLimites(
        ehPrincipal: false,
        nivelViario: 3,
        codigo: 'LMG-800',
        verticesLonLat: const [
          Offset(-43.95, -19.62),
          Offset(-44.02, -19.55),
          Offset(-43.88, -19.70),
        ],
      );
      expect(rodoviaComLimites.nivelViario, equals(3));
      expect(rodoviaComLimites.minLon, closeTo(-44.02, 1e-6));
      expect(rodoviaComLimites.maxLon, closeTo(-43.88, 1e-6));
      expect(rodoviaComLimites.minLat, closeTo(-19.70, 1e-6));
      expect(rodoviaComLimites.maxLat, closeTo(-19.55, 1e-6));
      expect(
        rodoviaComLimites.interceptaJanela(
          janelaMinLon: -44.00,
          janelaMaxLon: -43.90,
          janelaMinLat: -19.65,
          janelaMaxLat: -19.58,
        ),
        isTrue,
      );
      expect(
        rodoviaComLimites.interceptaJanela(
          janelaMinLon: -42.00,
          janelaMaxLon: -41.00,
          janelaMinLat: -19.65,
          janelaMaxLat: -19.58,
        ),
        isFalse,
      );

      final reconstituida = RodoviaRegionalMapa.deMapa(rodoviaComLimites.paraMapa());
      expect(reconstituida.nivelViario, equals(3));
      expect(reconstituida.ehPrincipal, isFalse);
      expect(reconstituida.codigo, equals('LMG-800'));
      expect(reconstituida.verticesLonLat, equals(rodoviaComLimites.verticesLonLat));

      final reconstituidaPrincipal = RodoviaRegionalMapa.deMapa(<String, dynamic>{
        'classe': 'principal',
        'poligono': const [
          [-43.9386, -19.9191],
          [-43.8000, -20.1000],
        ],
      });
      expect(reconstituidaPrincipal.ehPrincipal, isTrue);
      expect(reconstituidaPrincipal.nivelViario, equals(1));

      final snapshot = SnapshotMalhaViariaOffline(
        geradoEm: DateTime.utc(2026, 11, 27, 15, 0),
        versaoHash: 'osm-v1-teste',
        rodovias: [reconstituidaPrincipal, rodoviaComLimites],
      );
      final snapshotLido = SnapshotMalhaViariaOffline.deMapa(snapshot.paraMapa());
      expect(snapshotLido.versaoHash, equals('osm-v1-teste'));
      expect(snapshotLido.geradoEm, equals(DateTime.utc(2026, 11, 27, 15, 0)));
      expect(snapshotLido.rodovias, hasLength(2));

      final snapshotSemData = SnapshotMalhaViariaOffline.deMapa(<String, dynamic>{
        'versao_hash': 'osm-v1-sem-data',
        'rodovias': [reconstituidaPrincipal.paraMapa()],
      });
      expect(
        snapshotSemData.geradoEm,
        equals(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)),
      );

      expect(
        () => SnapshotMalhaViariaOffline.deMapa(const {'versao_hash': ''}),
        throwsFormatException,
      );
      expect(
        () => SnapshotMalhaViariaOffline.deMapa(const {
          'versao_hash': 'v1',
          'rodovias': <dynamic>[],
        }),
        throwsFormatException,
      );

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
      );
      expect(cidade.ehRelevanteAresta, isTrue);

      const rede = RedeViariaArestaGlobo(
        rodoviasFundo: [rodoviaConst],
        trechosCorredorAresta: [trecho],
        cidadesClassificadas: [cidade],
      );
      expect(
        RedeViariaArestaGlobo.latitudeCentroBeloHorizonte,
        closeTo(-19.9191, 1e-4),
      );
      expect(
        RedeViariaArestaGlobo.longitudeCentroBeloHorizonte,
        closeTo(-43.9386, 1e-4),
      );
      expect(rede.rodoviasFundo, hasLength(1));
      expect(rede.trechosCorredorAresta, hasLength(1));
      expect(rede.cidadesClassificadas, hasLength(1));
    });
  });
}
