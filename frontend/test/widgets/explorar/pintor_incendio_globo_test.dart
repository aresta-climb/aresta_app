// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';
import 'package:frontend/widgets/explorar/pintor_incendio_globo.dart';

Future<Uint8List> _renderizarIncendios({
  required ControladorCameraGlobo ctrl,
  required List<BolhaIncendioAtivaRenderizavel> incendios,
  required double faseSegundos,
  List<PicoRelevoReferencia> picos = const [],
  List<BolhaAtivaRenderizavel> bolhasChuva = const [],
}) async {
  const tamanho = ui.Size(220, 220);
  final gravador = ui.PictureRecorder();
  final canvas = ui.Canvas(gravador);
  PintorIncendioGlobo.desenharIncendios(
    canvas: canvas,
    tamanhoTela: tamanho,
    controlador: ctrl,
    incendiosAtivos: incendios,
    bolhasChuvaAtivas: bolhasChuva,
    picosReferencia: picos,
    faseSegundos: faseSegundos,
  );
  final picture = gravador.endRecording();
  final imagem = await picture.toImage(220, 220);
  final bytes = await imagem.toByteData(format: ui.ImageByteFormat.rawRgba);
  picture.dispose();
  imagem.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const incendioCipo = BolhaIncendioRegional(
    id: 'incendio_cipo',
    latitude: -19.35,
    longitude: -43.60,
    potenciaFrpMw: 92.0,
    totalFocos: 9,
    ventoRumoGraus: 280.0,
    ventoVelocidadeKmh: 24.0,
    fonteSatelite: 'NASA_FIRMS_VIIRS_375M',
    contornoExterno: [
      PontoContornoGeo(longitude: -44.2, latitude: -20.0),
      PontoContornoGeo(longitude: -43.0, latitude: -19.9),
      PontoContornoGeo(longitude: -43.1, latitude: -18.7),
      PontoContornoGeo(longitude: -44.1, latitude: -18.8),
    ],
    nucleosIntensos: [
      [
        PontoContornoGeo(longitude: -43.8, latitude: -19.6),
        PontoContornoGeo(longitude: -43.4, latitude: -19.5),
        PontoContornoGeo(longitude: -43.5, latitude: -19.1),
      ],
    ],
  );

  group('PintorIncendioGlobo', () {
    test(
      'renderiza perimetro termal ambar/carmim, nucleos em brasa e pluma de fumaca orientada pelo vento em 3D e 2D, descartando face oculta',
      () async {
        final ctrl = ControladorCameraGlobo(
          latitudeInicial: -19.35,
          longitudeInicial: -43.60,
          lodInicial: 0.75,
        );
        addTearDown(ctrl.dispose);

