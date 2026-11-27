// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:frontend/services/clima/servico_tiles_elevacao_terrarium.dart';

/// Biblioteca `test-only` de Fake determinístico em memória para [FonteTilesElevacaoMapa],
/// gerando tiles PNG `256x256` reais na codificação Terrarium sem tráfego de rede externo.
class FonteTilesElevacaoFake implements FonteTilesElevacaoMapa {
  bool simularFalhaRede;
  bool retornarBytesCorrompidos;
  int altitudePadraoMetros;
  int totalChamadas = 0;

  FonteTilesElevacaoFake({
    this.simularFalhaRede = false,
    this.retornarBytesCorrompidos = false,
    this.altitudePadraoMetros = 940,
  });

  /// Gera em memória um PNG `256x256` válido codificando [altitudeMetros] no padrão Terrarium.
  static Future<Uint8List> gerarPngTerrarium256(int altitudeMetros) async {
    final deslocado = (altitudeMetros + 32768).clamp(0, 65535);
    final r = (deslocado >> 8) & 0xFF;
    final g = deslocado & 0xFF;

    final gravador = ui.PictureRecorder();
    final canvas = ui.Canvas(gravador);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 256, 256),
      ui.Paint()..color = ui.Color.fromARGB(255, r, g, 0),
    );
    final pic = gravador.endRecording();
    final img = await pic.toImage(256, 256);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    pic.dispose();
    img.dispose();
    return bd!.buffer.asUint8List();
  }

  @override
  Future<Uint8List?> baixarPngTile({
    required int zoom,
    required int x,
    required int y,
  }) async {
    totalChamadas++;
    if (simularFalhaRede) return null;
    if (retornarBytesCorrompidos) {
      return Uint8List.fromList(const <int>[1, 2, 3, 4, 5]);
    }
    return gerarPngTerrarium256(altitudePadraoMetros);
  }
}
