// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MalhaGeograficaGlobo e GeradorRelevoLod', () {
    test(
      'deve carregar malha geografica embutida com 27 estados, continentes e textura esferica NASA Blue Marble',
      () async {
        final malha = await MalhaGeograficaGlobo.carregarDoAssetBundle();
        expect(malha.continentes, isNotEmpty);
        expect(malha.brasil.length, greaterThan(10));
        expect(malha.estados.length, equals(27));
        expect(malha.localidadesProximas.length, inInclusiveRange(35, 110));
        expect(malha.rodoviasProximas.length, greaterThanOrEqualTo(120));
        expect(
          malha.localidadesProximas.any(
            (l) => l.nome == 'Belo Horizonte' && l.nivel == 1,
          ),
          isTrue,
        );
        expect(
          malha.localidadesProximas.any(
            (l) => l.nome == 'Igarapé' && l.nivel == 2,
          ),
          isTrue,
        );
        expect(
          malha.localidadesProximas.any((l) => l.nome == 'Ouro Preto'),
          isTrue,
        );
        // Classificacao geografica exata terra vs oceano (impede cortes diagonais azuis no interior de MG!)
        expect(
          malha.contemPontoTerrestre(latitude: -19.92, longitude: -43.94),
          isTrue,
        );
        expect(
          malha.contemPontoTerrestre(latitude: -20.14, longitude: -44.20),
          isTrue,
        );
        expect(
          malha.contemPontoTerrestre(latitude: -19.59, longitude: -46.94),
          isTrue,
        );
        expect(
          malha.contemPontoTerrestre(latitude: -20.00, longitude: -35.00),
          isFalse,
        );

        final concorrentes = await Future.wait([
          TexturaGloboNasa.carregarDoAssetBundle(larguraAlvo: 512),
          TexturaGloboNasa.carregarDoAssetBundle(larguraAlvo: 512),
        ]);
        final textura = concorrentes.first;
        expect(concorrentes.last, same(textura));
        expect(textura.width, equals(512));
        expect(textura.height, greaterThan(200));
        expect(TexturaGloboNasa.cacheMemoria, same(textura));

        final emCache = await TexturaGloboNasa.carregarDoAssetBundle();
        expect(emCache, same(textura));

        final semCache = await TexturaGloboNasa.carregarDoAssetBundle(
          usarCache: false,
          larguraAlvo: 256,
        );
        expect(semCache.width, equals(256));

        final nativa4k = await TexturaGloboNasa.carregarDoAssetBundle(
          usarCache: false,
        );
        expect(nativa4k.width, greaterThanOrEqualTo(2048));
      },
    );

    test(
      'deve interpolar bilinearmente grade DEM real de satelite quando disponivel no pico',
      () {
        // Grade 3x3: sul=700m, centro=900m, norte-leste=1320m
        const picoComDem = PicoRelevoReferencia(
          id: 'dem_real',
          latitude: -19.50,
          longitude: -43.50,
          altitudeBaseMetros: 700,
          altitudePicoMetros: 1320,
          dimensaoGradeDem: 3,
          raioGradeDemGraus: 0.02,
          gradeDemMetros: [
            700, 720, 740, // j=0 (sul: -19.52)
            820, 900, 1080, // j=1 (centro: -19.50)
            950, 1140, 1320, // j=2 (norte: -19.48)
          ],
        );

        final sulOeste = GeradorRelevoLod.amostrarElevacaoMetros(
          latitude: -19.518,
          longitude: -43.518,
          picosReferencia: const [picoComDem],
        );
        final nordeste = GeradorRelevoLod.amostrarElevacaoMetros(
          latitude: -19.482,
          longitude: -43.482,
          picosReferencia: const [picoComDem],
        );

        expect(nordeste, greaterThan(1180));
        expect(sulOeste, lessThan(800));
        expect(nordeste - sulOeste, greaterThan(420));
      },
    );

    test(
      'deve gerar relevo local apenas ao redor dos picos catalogados e retornar 0m no oceano ou regioes sem picos',
      () {
        const picos = [
          PicoRelevoReferencia(
            id: 'igarape',
            latitude: -20.07,
            longitude: -44.32,
            altitudeBaseMetros: 980,
            altitudePicoMetros: 1430,
          ),
          PicoRelevoReferencia(
            id: 'urca',
            latitude: -22.95,
            longitude: -43.16,
            altitudeBaseMetros: 12,
            altitudePicoMetros: 396,
          ),
        ];

        final topoIgarape = GeradorRelevoLod.amostrarElevacaoMetros(
          latitude: -20.07,
          longitude: -44.32,
          picosReferencia: picos,
        );
        final oceanoAtlantico = GeradorRelevoLod.amostrarElevacaoMetros(
          latitude: -20.00,
          longitude: -36.50,
          picosReferencia: picos,
        );
        final costaSulUrca = GeradorRelevoLod.amostrarElevacaoMetros(
          latitude: -23.00,
          longitude: -43.16,
          picosReferencia: picos,
        );

        expect(topoIgarape, greaterThan(1200));
        expect(oceanoAtlantico, equals(0.0));
        expect(costaSulUrca, lessThanOrEqualTo(0.0));

