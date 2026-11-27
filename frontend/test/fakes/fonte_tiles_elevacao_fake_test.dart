// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_relevo_topografico.dart';
import 'package:frontend/services/clima/servico_tiles_elevacao_terrarium.dart';

import 'fonte_tiles_elevacao_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FonteTilesElevacaoFake', () {
    test('gera PNG Terrarium 256x256 decodificável com altitude exata e simula falhas determinísticas', () async {
      final fake = FonteTilesElevacaoFake(altitudePadraoMetros: 1125);
      final png = await fake.baixarPngTile(zoom: 10, x: 374, y: 575);
      expect(png, isNotNull);
      expect(fake.totalChamadas, equals(1));

      final rgba = await ServicoTilesElevacaoTerrarium.decodificarPngParaRgba256(png!);
      final tile = TileElevacaoTerrarium.deRgba256(
        zoom: 10,
        x: 374,
        y: 575,
        rgba: rgba,
      );
      expect(tile.amostrarLocal(128.0, 128.0), closeTo(1125.0, 1.0));

      fake.retornarBytesCorrompidos = true;
      final corrompido = await fake.baixarPngTile(zoom: 10, x: 0, y: 0);
      expect(corrompido, hasLength(5));

      fake.simularFalhaRede = true;
      expect(await fake.baixarPngTile(zoom: 10, x: 0, y: 0), isNull);
    });
  });
}
