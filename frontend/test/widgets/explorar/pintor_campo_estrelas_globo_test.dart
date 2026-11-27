// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/pintor_campo_estrelas_globo.dart';

void main() {
  group('PintorCampoEstrelasGlobo', () {
    test('calcula estrelas fora do disco planetário com deriva temporal e oculta quando globo ocupa a tela', () {
      const tela = Size(400, 800);
      const centro = Offset(200, 380);

      final t0 = PintorCampoEstrelasGlobo.calcularEstrelasVisiveis(
        tamanho: tela,
        centroGlobo: centro,
        raioGloboPx: 140.0,
        tempoSegundos: 0.0,
      );
      final t10 = PintorCampoEstrelasGlobo.calcularEstrelasVisiveis(
        tamanho: tela,
        centroGlobo: centro,
        raioGloboPx: 140.0,
        tempoSegundos: 10.0,
        longitudeCameraGraus: -44.0,
        latitudeCameraGraus: -20.0,
      );
      expect(t0, isNotEmpty);
      expect(t0.any((e) => e.possuiHaloSuave), isTrue);
      expect(t0.first.posicao, isNot(equals(t10.first.posicao)));

      final ocultasNoZoom = PintorCampoEstrelasGlobo.calcularEstrelasVisiveis(
        tamanho: tela,
        centroGlobo: centro,
        raioGloboPx: 800.0,
        tempoSegundos: 0.0,
      );
      expect(ocultasNoZoom, isEmpty);
    });

    test('pinta fundo cósmico, estrelas e halo atmosférico em 3D orbital, horizonte e 2D', () {
      final ctrl = ControladorCameraGlobo(lodInicial: 0.2);
      final ctrlOutro = ControladorCameraGlobo(lodInicial: 2.6);
      final tempo = ValueNotifier<double>(1.5);
      final outroTempo = ValueNotifier<double>(3.0);
      addTearDown(() {
        ctrl.dispose();
        ctrlOutro.dispose();
        tempo.dispose();
        outroTempo.dispose();
      });

      final pintorOrbital = PintorCampoEstrelasGlobo(
        controlador: ctrl,
        tempoSegundosListenable: tempo,
      );
      final gravador1 = PictureRecorder();
      pintorOrbital.paint(Canvas(gravador1), const Size(380, 760));
      gravador1.endRecording().dispose();

      final pintorHorizonte = PintorCampoEstrelasGlobo(
        controlador: ctrlOutro,
        tempoSegundosListenable: tempo,
      );
      final gravador2 = PictureRecorder();
      pintorHorizonte.paint(Canvas(gravador2), const Size(380, 760));
      gravador2.endRecording().dispose();

      ctrlOutro.definirModo3D(false);
      final gravador3 = PictureRecorder();
      pintorHorizonte.paint(Canvas(gravador3), const Size(380, 760));
      gravador3.endRecording().dispose();

      expect(pintorOrbital.shouldRepaint(pintorOrbital), isFalse);
      expect(pintorOrbital.shouldRepaint(pintorHorizonte), isTrue);
      expect(
        pintorOrbital.shouldRepaint(
          PintorCampoEstrelasGlobo(
            controlador: ctrl,
            tempoSegundosListenable: outroTempo,
          ),
        ),
        isTrue,
      );
    });
  });
}
