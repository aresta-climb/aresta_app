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
      });
      final ondasExtremo = await _capturarQuadro((canvas) {
        final p = EfeitosParticulasIncendioGlobo.paletaPorSeveridade(
          NivelSeveridadeIncendio.extremo,
          1.0,
        );
        EfeitosParticulasIncendioGlobo.desenharOndaCalorRadiante(
          canvas: canvas,
          centro: centro,
          menorLadoPx: 60.0,
          faseSegundos: 0.4,
          severidade: NivelSeveridadeIncendio.extremo,
          paleta: p,
        );
      });
      expect(ondasBaixo.every((b) => b == 0), isTrue);
      expect(ondasExtremo.any((b) => b > 0), isTrue);

      final quadrosPorSeveridade = <NivelSeveridadeIncendio, Uint8List>{};
      for (final sev in NivelSeveridadeIncendio.values) {
        final paleta =
            EfeitosParticulasIncendioGlobo.paletaPorSeveridade(sev, 1.0);
        quadrosPorSeveridade[sev] = await _capturarQuadro((canvas) {
          EfeitosParticulasIncendioGlobo.desenharColunaFumacaExterna(
            canvas: canvas,
            origemFogo: centro,
            menorLadoPx: 54.0,
            dirVentoTela: const ui.Offset(0.8, -0.6),
            fatorVel: 1.2,
            faseSegundos: 0.7,
            severidade: sev,
            paleta: paleta,
          );
          EfeitosParticulasIncendioGlobo.desenharOndaCalorRadiante(
            canvas: canvas,
            centro: centro,
            menorLadoPx: sev == NivelSeveridadeIncendio.alto ? 48.0 : 12.0,
            faseSegundos: 0.7,
            severidade: sev,
            paleta: paleta,
          );
          EfeitosParticulasIncendioGlobo.desenharChamasEFagulhasAscendentes(
            canvas: canvas,
            incendio: incendioTeste,
            pxPorGrau: 240.0,
            menorLadoMundoPx: sev == NivelSeveridadeIncendio.baixo ? 18.0 : 54.0,
            dirVentoTela: const ui.Offset(0.8, -0.6),
            faseSegundos: 0.7,
            fatorVel: 1.2,
            tamanhoTela: const ui.Size(140, 140),
            controlador: ctrl,
            picosReferencia: const [],
            sobreRelevo: sev.peso >= 3,
            severidade: sev,
            paleta: paleta,
          );
          EfeitosParticulasIncendioGlobo.desenharEmblemaChamaViva(
            canvas: canvas,
            centro: centro,
            escalaPx: 11.0,
            faseSegundos: 0.7,
            inclinacaoVentoX: 0.15,
            severidade: sev,
            opacidade: 1.0,
          );
        });
      }

      expect(
        quadrosPorSeveridade[NivelSeveridadeIncendio.baixo],
        isNot(equals(quadrosPorSeveridade[NivelSeveridadeIncendio.moderado])),
      );
      expect(
        quadrosPorSeveridade[NivelSeveridadeIncendio.moderado],
        isNot(equals(quadrosPorSeveridade[NivelSeveridadeIncendio.alto])),
      );
      expect(
        quadrosPorSeveridade[NivelSeveridadeIncendio.alto],
        isNot(equals(quadrosPorSeveridade[NivelSeveridadeIncendio.extremo])),
      );
    });
  });
}
