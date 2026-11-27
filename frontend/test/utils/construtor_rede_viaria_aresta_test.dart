// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/construtor_rede_viaria_aresta.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConstrutorRedeViariaAresta', () {
    test('classifica todas as cidades como referência quando não há rodovias válidas ou picos', () {
      const localidades = [
        LocalidadeRegionalMapa(
          nome: 'Vitória',
          ehCidade: true,
          nivel: 1,
          longitude: -40.3128,
          latitude: -20.3155,
        ),
      ];
      const picos = [
        PicoRelevoReferencia(
          id: 'p1',
          latitude: -20.0,
          longitude: -44.0,
          altitudeBaseMetros: 800,
          altitudePicoMetros: 1200,
        ),
      ];

      final semRodovias = ConstrutorRedeViariaAresta.construir(
        rodovias: const [],
        localidades: localidades,
        picos: picos,
      );
      expect(semRodovias.trechosCorredorAresta, isEmpty);
      expect(semRodovias.cidadesClassificadas.single.ehRelevanteAresta, isFalse);
      expect(semRodovias.cidadesClassificadas.single.viasUrbanasLonLat, isEmpty);

      final apenasPolilinhaCurta = ConstrutorRedeViariaAresta.construir(
        rodovias: const [
          RodoviaRegionalMapa(
            ehPrincipal: true,
            codigo: 'CURTA',
            verticesLonLat: [Offset(-43.9386, -19.9191)],
          ),
        ],
        localidades: localidades,
        picos: picos,
      );
      expect(apenasPolilinhaCurta.trechosCorredorAresta, isEmpty);
      expect(
        apenasPolilinhaCurta.cidadesClassificadas.single.ehRelevanteAresta,
        isFalse,
      );
    });

    test('propaga caminhos mínimos de Belo Horizonte até cada pico Aresta, extrai contornos urbanos nos 3 níveis e gera assinatura determinística', () async {
      final malhaReal = await MalhaGeograficaGlobo.carregarDoAssetBundle();
      const picosAresta = <PicoRelevoReferencia>[
        PicoRelevoReferencia(
          id: 'cipo',
          latitude: -19.3156,
          longitude: -43.6135,
          altitudeBaseMetros: 820,
          altitudePicoMetros: 1310,
        ),
        PicoRelevoReferencia(
          id: 'ouro_preto',
          latitude: -20.3677,
          longitude: -43.5075,
          altitudeBaseMetros: 1120,
          altitudePicoMetros: 1560,
        ),
        PicoRelevoReferencia(
          id: 'araxa',
          latitude: -19.7151,
          longitude: -46.7975,
          altitudeBaseMetros: 940,
          altitudePicoMetros: 1280,
        ),
        PicoRelevoReferencia(
          id: 'januaria',
          latitude: -15.4711,
          longitude: -44.4449,
          altitudeBaseMetros: 480,
          altitudePicoMetros: 760,
        ),
        PicoRelevoReferencia(
          id: 'friburgo',
          latitude: -22.2286,
          longitude: -42.4250,
          altitudeBaseMetros: 860,
          altitudePicoMetros: 1410,
        ),
      ];

