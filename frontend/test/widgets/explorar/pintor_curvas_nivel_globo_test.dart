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

