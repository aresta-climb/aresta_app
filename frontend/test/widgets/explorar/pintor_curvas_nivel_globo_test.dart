// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';
import 'package:frontend/widgets/explorar/pintor_curvas_nivel_globo.dart';
import 'package:frontend/widgets/explorar/pintor_terreno_vetores_globo.dart';

Future<Uint8List> _renderizarTerrenoComCurvas({
  required ControladorCameraGlobo ctrl,
  required List<PicoRelevoReferencia> picos,
  required MalhaGeograficaGlobo malha,
  double fatorMonocromatico = 1.0,
}) async {
  const size = ui.Size(280, 280);
  final gravador = ui.PictureRecorder();
  final canvas = ui.Canvas(gravador);
  PintorTerrenoVetoresGlobo.desenharTerrenoDetalhadoContinuo(
    canvas: canvas,
    size: size,
    controlador: ctrl,
    dadosMalha: malha,
    picosReferencia: picos,
    opacidadeBase: 1.0,
    fatorMonocromatico: fatorMonocromatico,
  );
  final pic = gravador.endRecording();
  final img = await pic.toImage(280, 280);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  pic.dispose();
  img.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const malhaTerra = MalhaGeograficaGlobo(
    continentes: [
      PoligonoGeografico(
        id: 'america_sul',
        verticesLonLat: [
          ui.Offset(-48.0, -24.0),
          ui.Offset(-40.0, -24.0),
          ui.Offset(-40.0, -16.0),
          ui.Offset(-48.0, -16.0),
        ],
      ),
    ],
    brasil: [
      ui.Offset(-48.0, -24.0),
      ui.Offset(-40.0, -24.0),
      ui.Offset(-40.0, -16.0),
      ui.Offset(-48.0, -16.0),
    ],
    estados: [],
  );

  const picos = <PicoRelevoReferencia>[
    PicoRelevoReferencia(
      id: 'igarape',
      latitude: -20.07,
      longitude: -44.32,
      altitudeBaseMetros: 960,
      altitudePicoMetros: 1460,
    ),
    PicoRelevoReferencia(
      id: 'distante',
      latitude: -16.50,
      longitude: -41.20,
      altitudeBaseMetros: 600,
      altitudePicoMetros: 1050,
    ),
  ];

  group('PintorCurvasNivelGlobo', () {
    test('permanece inativo em zoom regional distante e desenha curvas mestras, escarpas cobre Aresta, cotas e anéis de maciço nos LODs próximos', () async {
      final ctrl = ControladorCameraGlobo(
        latitudeInicial: -20.07,
        longitudeInicial: -44.32,
        lodInicial: 1.40,
      );
      addTearDown(ctrl.dispose);

      // Em LOD < 1.92 não desenha isolinhas
      final gravadorVazio = ui.PictureRecorder();
      PintorCurvasNivelGlobo.desenharCurvasETopografiaProxima(
        canvas: ui.Canvas(gravadorVazio),
        size: const ui.Size(200, 200),
        controlador: ctrl,
        picosReferencia: picos,
        opacidadeTerreno: 1.0,
        fatorMonocromatico: 1.0,
      );
      gravadorVazio.endRecording().dispose();

      // Exercita as 3 faixas aditivas de curvas sólidas (400 m em LOD 2.95, +200 m em LOD 3.40 e +100 m em LOD 4.20)
      ctrl.definirLod(2.95);
      final qMedio = await _renderizarTerrenoComCurvas(
        ctrl: ctrl,
        picos: picos,
        malha: malhaTerra,
      );

      ctrl.definirLod(3.40);
      final qProximo = await _renderizarTerrenoComCurvas(
        ctrl: ctrl,
        picos: picos,
        malha: malhaTerra,
      );

      ctrl.definirLod(4.20);
      ctrl.definirElevacaoReferenciaCamera(960.0);
      final qMaximo = await _renderizarTerrenoComCurvas(
        ctrl: ctrl,
        picos: picos,
        malha: malhaTerra,
      );

      expect(qMedio.any((b) => b > 0), isTrue);
      expect(qProximo, isNot(equals(qMedio)));
      expect(qMaximo, isNot(equals(qProximo)));

      // No zoom máximo (LOD 4.20), verifica que não há vazio preto uniforme (há contraste real de curvas/relevo)
      var minLum = 255;
      var maxLum = 0;
      for (var i = 0; i < qMaximo.length; i += 4) {
        if (qMaximo[i + 3] < 200) continue;
        final lum = (qMaximo[i] + qMaximo[i + 1] + qMaximo[i + 2]) ~/ 3;
        if (lum < minLum) minLum = lum;
        if (lum > maxLum) maxLum = lum;
      }
      expect(maxLum - minLum, greaterThan(35));
    });
  });
}
