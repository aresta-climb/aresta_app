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
    test('carrega grade regional SRTM offline real (Uberlândia e BH), baixa tiles Terrarium sob demanda e aplica LRU', () async {
      final fake = FonteTilesElevacaoFake(altitudePadraoMetros: 1280);
      final servico = ServicoTilesElevacaoTerrarium(fonteRemota: fake);
      addTearDown(servico.dispose);

      expect(servico.inicializado, isFalse);
      await servico.inicializar();
      await servico.inicializar();
      expect(servico.inicializado, isTrue);
      expect(servico.gradeRegionalOffline, isNotNull);

      // Uberlândia (-18.9186, -48.2772) possui cota real de chapada (~800..920 m) na grade SRTM offline!
      final cotaUberlandia = servico.amostrarElevacaoReal(
        latitude: -18.9186,
        longitude: -48.2772,
      );
      expect(cotaUberlandia, isNotNull);
      expect(cotaUberlandia, inInclusiveRange(720.0, 960.0));

      expect(ServicoTilesElevacaoTerrarium.escolherZoomTerrarium(2.1), equals(8));
      expect(ServicoTilesElevacaoTerrarium.escolherZoomTerrarium(3.0), equals(10));
      expect(ServicoTilesElevacaoTerrarium.escolherZoomTerrarium(4.0), equals(12));

      // Abaixo de LOD 1.85 não requisita tiles
      servico.solicitarTilesVisiveis(
        minLat: -20.0,
        maxLat: -19.9,
        minLon: -44.0,
        maxLon: -43.9,
        lod: 1.2,
      );
      expect(fake.totalChamadas, equals(0));

      // Em LOD 3.8 requisita tiles z=12 e atualiza a cota local quando chegam
      servico.solicitarTilesVisiveis(
        minLat: -19.93,
        maxLat: -19.91,
        minLon: -43.95,
        maxLon: -43.93,
        lod: 3.8,
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(servico.totalTilesEmCache, greaterThan(0));
      expect(
        servico.amostrarElevacaoReal(latitude: -19.92, longitude: -43.94),
        closeTo(1280.0, 2.0),
      );

      // Nova solicitação para os mesmos tiles usa cache sem refazer download
      final chamadasAntes = fake.totalChamadas;
      servico.solicitarTilesVisiveis(
        minLat: -19.93,
        maxLat: -19.91,
        minLon: -43.95,
        maxLon: -43.93,
        lod: 3.8,
      );
      expect(fake.totalChamadas, equals(chamadasAntes));

