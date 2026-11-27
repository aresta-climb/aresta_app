// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_relevo_topografico.dart';
import 'package:frontend/services/clima/servico_tiles_elevacao_terrarium.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:http/http.dart' as http;

import '../../fakes/fonte_tiles_elevacao_fake.dart';

class _AssetBundleFalho extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => Future.error(StateError('Ausente'));

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      Future.error(StateError('JSON inválido'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  tearDown(ServicoTilesElevacaoTerrarium.redefinirParaTestes);

  group('ServicoTilesElevacaoTerrarium e ClienteTilesTerrariumAws', () {
    test('carrega grade regional SRTM offline real, mantém zoom canônico invariante ao LOD e aplica LRU', () async {
      final fake = FonteTilesElevacaoFake(altitudePadraoMetros: 1280);
      final servico = ServicoTilesElevacaoTerrarium(fonteRemota: fake);
      addTearDown(servico.dispose);

      expect(servico.inicializado, isFalse);
      await servico.inicializar();
      await servico.inicializar();
      expect(servico.inicializado, isTrue);
      expect(servico.gradeRegionalOffline, isNotNull);

      final cotaUberlandia = servico.amostrarElevacaoReal(
        latitude: -18.9186,
        longitude: -48.2772,
      );
      expect(cotaUberlandia, isNotNull);
      expect(cotaUberlandia, inInclusiveRange(720.0, 960.0));

      // Zoom canônico único (z=9) em todos os LODs impede trocas/saltos de DEM ao aproximar o zoom
      expect(
        ServicoTilesElevacaoTerrarium.escolherZoomTerrarium(2.1),
        equals(ServicoTilesElevacaoTerrarium.zoomCanonicoTerrarium),
      );
      expect(
        ServicoTilesElevacaoTerrarium.escolherZoomTerrarium(3.0),
        equals(ServicoTilesElevacaoTerrarium.zoomCanonicoTerrarium),
      );
      expect(
        ServicoTilesElevacaoTerrarium.escolherZoomTerrarium(4.0),
        equals(ServicoTilesElevacaoTerrarium.zoomCanonicoTerrarium),
      );

      // Abaixo de LOD 1.85 não requisita tiles
      servico.solicitarTilesVisiveis(
        minLat: -20.0,
        maxLat: -19.9,
        minLon: -44.0,
        maxLon: -43.9,
        lod: 1.2,
      );
      expect(fake.totalChamadas, equals(0));

      // Em LOD >= 1.85 requisita tiles z=9 e mantém a mesma cota exata em qualquer zoom subsequente
      servico.solicitarTilesVisiveis(
        minLat: -19.93,
        maxLat: -19.91,
        minLon: -43.95,
        maxLon: -43.93,
        lod: 2.2,
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(servico.totalTilesEmCache, greaterThan(0));
      expect(
        servico.amostrarElevacaoReal(latitude: -19.92, longitude: -43.94),
        closeTo(1280.0, 2.0),
      );

      final chamadasAntes = fake.totalChamadas;
      servico.solicitarTilesVisiveis(
        minLat: -19.93,
        maxLat: -19.91,
        minLon: -43.95,
        maxLon: -43.93,
        lod: 4.1,
      );
      expect(fake.totalChamadas, equals(chamadasAntes));

      // Evicção LRU acima de limiteCacheTiles (64)
      final rgbaDummy = Uint8List(256 * 256 * 4);
      for (var x = 0; x < 72; x++) {
        servico.registrarTileEmMemoria(
          TileElevacaoTerrarium.deRgba256(
            zoom: 9,
            x: x,
            y: 100,
            rgba: rgbaDummy,
          ),
        );
      }
      expect(
        servico.totalTilesEmCache,
        equals(ServicoTilesElevacaoTerrarium.limiteCacheTiles),
      );

      // Tolerância a falha de rede, PNG corrompido e AssetBundle falho
      final fakeFalho = FonteTilesElevacaoFake(retornarBytesCorrompidos: true);
      final srvFalho = ServicoTilesElevacaoTerrarium(
        fonteRemota: fakeFalho,
        assetBundle: _AssetBundleFalho(),
      );
      addTearDown(srvFalho.dispose);
      await srvFalho.inicializar();
      srvFalho.solicitarTilesVisiveis(
        minLat: -25.0,
        maxLat: -15.0,
        minLon: -50.0,
        maxLon: -40.0,
        lod: 2.2,
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
      fakeFalho.simularFalhaRede = true;
      srvFalho.solicitarTilesVisiveis(
        minLat: -14.0,
        maxLat: -13.0,
        minLon: -45.0,
        maxLon: -44.0,
        lod: 2.2,
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(srvFalho.totalTilesEmCache, equals(0));

      expect(ServicoTilesElevacaoTerrarium.instancia, isNotNull);
    });

    test('ClienteTilesTerrariumAws busca PNG via HTTP local e retorna null em 404 ou falha de socket', () async {
      final pngValido = await FonteTilesElevacaoFake.gerarPngTerrarium256(850);
      var statusCode = 200;
      final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => servidor.close(force: true));

      servidor.listen((req) async {
        req.response.statusCode = statusCode;
        if (statusCode == 200) {
          req.response.add(pngValido);
        }
        await req.response.close();
      });

      final cliente = ClienteTilesTerrariumAws(
        urlBase: 'http://127.0.0.1:${servidor.port}',
        clienteHttp: ClienteHttpAresta.paraTestes(http.Client()),
      );

      final recebido = await cliente.baixarPngTile(zoom: 9, x: 186, y: 286);
      expect(recebido, isNotNull);
      expect(recebido!.length, equals(pngValido.length));

      statusCode = 404;
      expect(await cliente.baixarPngTile(zoom: 9, x: 186, y: 286), isNull);

      await servidor.close(force: true);
      expect(await cliente.baixarPngTile(zoom: 9, x: 186, y: 286), isNull);
    });
  });
}
