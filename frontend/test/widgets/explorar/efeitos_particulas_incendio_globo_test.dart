// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/efeitos_particulas_incendio_globo.dart';

Future<Uint8List> _capturarQuadro(void Function(ui.Canvas) desenhar) async {
  final gravador = ui.PictureRecorder();
  final canvas = ui.Canvas(gravador);
  desenhar(canvas);
  final picture = gravador.endRecording();
  final imagem = await picture.toImage(140, 140);
  final bytes = await imagem.toByteData(format: ui.ImageByteFormat.rawRgba);
  picture.dispose();
  imagem.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EfeitosParticulasIncendioGlobo', () {
    test('calcula 4 paletas termais progressivas do âmbar isolado ao carmim incandescente', () {
      final baixo = EfeitosParticulasIncendioGlobo.paletaPorSeveridade(
        NivelSeveridadeIncendio.baixo,
        1.0,
      );
      final moderado = EfeitosParticulasIncendioGlobo.paletaPorSeveridade(
        NivelSeveridadeIncendio.moderado,
        1.0,
      );
      final alto = EfeitosParticulasIncendioGlobo.paletaPorSeveridade(
        NivelSeveridadeIncendio.alto,
        1.0,
      );
      final extremo = EfeitosParticulasIncendioGlobo.paletaPorSeveridade(
        NivelSeveridadeIncendio.extremo,
        1.0,
      );

      expect(moderado.haloTermal.a, greaterThan(baixo.haloTermal.a));
      expect(alto.haloTermal.a, greaterThan(moderado.haloTermal.a));
      expect(extremo.haloTermal.a, greaterThan(alto.haloTermal.a));
      expect(extremo.fumacaDensa.a, greaterThan(baixo.fumacaDensa.a));
    });

    test('diferencia fumaça, ondas de calor, chamas/fagulhas e emblema nos 4 níveis de severidade', () async {
      const centro = ui.Offset(70, 70);
      final ctrl = ControladorCameraGlobo(
        latitudeInicial: -20.0,
        longitudeInicial: -44.0,
        lodInicial: 2.0,
        modo3DInicial: false,
      );
      addTearDown(ctrl.dispose);

      const incendioTeste = BolhaIncendioRegional(
        id: 'fogo_teste',
        latitude: -20.0,
        longitude: -44.0,
        potenciaFrpMw: 80.0,
        totalFocos: 6,
        ventoRumoGraus: 90.0,
        ventoVelocidadeKmh: 18.0,
        contornoExterno: [
          PontoContornoGeo(longitude: -44.2, latitude: -20.2),
          PontoContornoGeo(longitude: -43.8, latitude: -20.2),
          PontoContornoGeo(longitude: -44.0, latitude: -19.8),
        ],
      );

      // Níveis baixo/moderado não emitem anel de choque térmico externo; alto e extremo emitem
      final ondasBaixo = await _capturarQuadro((canvas) {
        final p = EfeitosParticulasIncendioGlobo.paletaPorSeveridade(
          NivelSeveridadeIncendio.baixo,
          1.0,
        );
        EfeitosParticulasIncendioGlobo.desenharOndaCalorRadiante(
          canvas: canvas,
          centro: centro,
          menorLadoPx: 60.0,
          faseSegundos: 0.4,
          severidade: NivelSeveridadeIncendio.baixo,
          paleta: p,
        );
