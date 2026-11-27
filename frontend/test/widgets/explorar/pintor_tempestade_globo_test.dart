// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';
import 'package:frontend/widgets/explorar/pintor_tempestade_globo.dart';

Future<Uint8List> _renderizarPixels({
  required ControladorCameraGlobo ctrl,
  required List<BolhaAtivaRenderizavel> bolhas,
  required double faseSegundos,
  String? bolhaRealcadaId,
  List<PicoRelevoReferencia> picos = const [],
}) async {
  const tamanho = ui.Size(220, 220);
  final gravador = ui.PictureRecorder();
  final canvas = ui.Canvas(gravador);
  PintorTempestadeGlobo.desenharTempestades(
    canvas: canvas,
    tamanhoTela: tamanho,
    controlador: ctrl,
    bolhasAtivas: bolhas,
    picosReferencia: picos,
    faseSegundos: faseSegundos,
    bolhaRealcadaId: bolhaRealcadaId,
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

  const frenteSudeste = BolhaChuvaRegional(
    id: 'frente_zcas',
    latitude: -20.5,
    longitude: -43.8,
    intensidadeMmHora: 6.5,
    ventoRumoGraus: 55.0,
    ventoVelocidadeKmh: 28.0,
    contornoExterno: [
      PontoContornoGeo(longitude: -46.2, latitude: -22.6),
      PontoContornoGeo(longitude: -41.6, latitude: -22.2),
      PontoContornoGeo(longitude: -41.8, latitude: -18.4),
      PontoContornoGeo(longitude: -46.0, latitude: -18.8),
    ],
    nucleosIntensos: [
      [
        PontoContornoGeo(longitude: -44.6, latitude: -21.2),
        PontoContornoGeo(longitude: -43.0, latitude: -21.0),
        PontoContornoGeo(longitude: -43.2, latitude: -19.8),
        PontoContornoGeo(longitude: -44.5, latitude: -20.0),
      ],
    ],
  );

  group('PintorTempestadeGlobo', () {
    test(
      'deve respeitar o contorno geografico real da tempestade, animar bandas e tracos de vento entre quadros e descartar hemisferio oculto',
      () async {
        expect(
          PintorTempestadeGlobo.contemCoordenadaNoContorno(
            longitude: -43.8,
            latitude: -20.5,
            contorno: frenteSudeste.contornoExterno,
          ),
          isTrue,
        );
        expect(
          PintorTempestadeGlobo.contemCoordenadaNoContorno(
            longitude: -52.0,
            latitude: -12.0,
            contorno: frenteSudeste.contornoExterno,
          ),
          isFalse,
        );

        final ctrl = ControladorCameraGlobo(
          latitudeInicial: -20.5,
          longitudeInicial: -43.8,
          lodInicial: 0.55,
        );
        addTearDown(ctrl.dispose);

