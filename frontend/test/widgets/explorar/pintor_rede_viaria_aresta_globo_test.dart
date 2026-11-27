// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/construtor_rede_viaria_aresta.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';
import 'package:frontend/widgets/explorar/pintor_rede_viaria_aresta_globo.dart';

Future<Uint8List> _renderizarCamadaViaria({
  required ControladorCameraGlobo ctrl,
  required RedeViariaArestaGlobo? redeViaria,
  required List<PicoRelevoReferencia> picos,
  required double fatorModoViario,
  required double progressoLuz,
}) async {
  const size = ui.Size(240, 240);
  final gravador = ui.PictureRecorder();
  final canvas = ui.Canvas(gravador);
  PintorRedeViariaArestaGlobo.desenharRedeViariaECidades(
    canvas: canvas,
    size: size,
    controlador: ctrl,
    redeViaria: redeViaria,
    picosReferencia: picos,
    fatorModoViario: fatorModoViario,
    progressoLuzViaria: progressoLuz,
  );
  final pic = gravador.endRecording();
  final img = await pic.toImage(240, 240);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  pic.dispose();
  img.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const malhaViaria = MalhaGeograficaGlobo(
    continentes: [],
    brasil: [],
    estados: [],
    localidadesProximas: [
      LocalidadeRegionalMapa(
        nome: 'Belo Horizonte',
        ehCidade: true,
        nivel: 1,
        longitude: -43.9386,
        latitude: -19.9191,
      ),
      LocalidadeRegionalMapa(
        nome: 'Lagoa Santa',
        ehCidade: true,
        nivel: 2,
        longitude: -43.8932,
        latitude: -19.6397,
      ),
      LocalidadeRegionalMapa(
        nome: 'Vila Local Corredor',
        ehCidade: false,
        nivel: 3,
        longitude: -43.7500,
        latitude: -19.4800,
      ),
      LocalidadeRegionalMapa(
        nome: 'Cidade Referência Isolada',
        ehCidade: true,
        nivel: 1,
        longitude: -44.6500,
        latitude: -19.9000,
      ),
    ],
    rodoviasProximas: [
      RodoviaRegionalMapa(
        ehPrincipal: true,
        codigo: 'MG-010',
        verticesLonLat: [
          ui.Offset(-43.9386, -19.9191),
          ui.Offset(-43.9100, -19.7800),
          ui.Offset(-43.8932, -19.6397),
          ui.Offset(-43.7500, -19.4800),
          ui.Offset(-43.6135, -19.3156),
        ],
