// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/utils/construtor_rede_viaria_aresta.dart';
import 'package:frontend/widgets/explorar/componentes_marcador_globo.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';
import 'package:frontend/widgets/explorar/pintor_planeta_globo.dart';

Future<ui.Image> _criarTexturaTeste16x8() async {
  final pixels = Uint8List(16 * 8 * 4);
  for (var i = 0; i < pixels.length; i += 4) {
    pixels[i] = 40;
    pixels[i + 1] = 110;
    pixels[i + 2] = 180;
    pixels[i + 3] = 255;
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
  final descritor = ui.ImageDescriptor.raw(
    buffer,
    width: 16,
    height: 8,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descritor.instantiateCodec();
  final quadro = await codec.getNextFrame();
  codec.dispose();
  descritor.dispose();
  buffer.dispose();
  return quadro.image;
}

void main() {
  const malhaTeste = MalhaGeograficaGlobo(
    continentes: [
      PoligonoGeografico(
        id: 'america_sul',
        verticesLonLat: [
          ui.Offset(-50.0, -25.0),
          ui.Offset(-38.0, -25.0),
          ui.Offset(-38.0, -14.0),
          ui.Offset(-50.0, -14.0),
        ],
      ),
    ],
    brasil: [
      ui.Offset(-50.0, -25.0),
      ui.Offset(-38.0, -25.0),
      ui.Offset(-38.0, -14.0),
      ui.Offset(-50.0, -14.0),
    ],
    estados: [
      PoligonoGeografico(
        id: 'MG',
        verticesLonLat: [
          ui.Offset(-46.0, -22.0),
          ui.Offset(-41.0, -22.0),
          ui.Offset(-41.0, -16.0),
          ui.Offset(-46.0, -16.0),
        ],
      ),
    ],
    rodoviasProximas: [
      RodoviaRegionalMapa(
        ehPrincipal: true,
        codigo: 'BR-381',
        verticesLonLat: [
          ui.Offset(-44.2, -20.1),
          ui.Offset(-43.9, -19.9),
        ],
      ),
    ],
  );

  group('PintorPlanetaGlobo e PintorFenomenosAtmosfericosGlobo', () {
    test('compõe esfera texturizada NASA em 3D e 2D e fallback vetorial quando textura está ausente', () async {
      final textura = await _criarTexturaTeste16x8();
      final ctrl3D = ControladorCameraGlobo(lodInicial: 0.45);
      final ctrl2D = ControladorCameraGlobo(
        lodInicial: 0.45,
        modo3DInicial: false,
      );
      addTearDown(() {
        textura.dispose();
        ctrl3D.dispose();
        ctrl2D.dispose();
      });

