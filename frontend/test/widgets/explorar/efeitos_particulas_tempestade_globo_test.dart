// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/efeitos_particulas_tempestade_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';

void main() {
  group('EfeitosParticulasTempestadeGlobo', () {
    test('calcula 4 paletas progressivas distintas para os níveis de chuva ao vivo', () {
      final fraca = EfeitosParticulasTempestadeGlobo.paletaPorIntensidade(
        NivelIntensidadeChuva.fraca,
        1.0,
      );
      final moderada = EfeitosParticulasTempestadeGlobo.paletaPorIntensidade(
        NivelIntensidadeChuva.moderada,
        1.0,
      );
      final forte = EfeitosParticulasTempestadeGlobo.paletaPorIntensidade(
        NivelIntensidadeChuva.forte,
        1.0,
      );
      final extrema = EfeitosParticulasTempestadeGlobo.paletaPorIntensidade(
        NivelIntensidadeChuva.extrema,
        1.0,
      );

      expect(fraca.preenchimento, isNot(equals(moderada.preenchimento)));
      expect(moderada.preenchimento, isNot(equals(forte.preenchimento)));
      expect(forte.nucleo, isNot(equals(extrema.nucleo)));
      expect(moderada.tracoChuva.a, greaterThan(fraca.tracoChuva.a));
      expect(forte.tracoChuva.a, greaterThan(moderada.tracoChuva.a));
      expect(extrema.tracoChuva.a, greaterThan(forte.tracoChuva.a));
    });

    test('renderiza os 4 níveis de células convectivas, emblemas e pitter-patter sobre relevo e mar', () {
      final ctrl = ControladorCameraGlobo(
        latitudeInicial: -20.0,
        longitudeInicial: -44.0,
        lodInicial: 2.2,
      );
      addTearDown(ctrl.dispose);

      const bolha = BolhaChuvaRegional(
        id: 't_severa',
        latitude: -20.0,
        longitude: -44.0,
        intensidadeMmHora: 8.5,
        ventoRumoGraus: 135.0,
        ventoVelocidadeKmh: 28.0,
        contornoExterno: [
          PontoContornoGeo(longitude: -44.2, latitude: -20.2),
          PontoContornoGeo(longitude: -43.8, latitude: -20.2),
          PontoContornoGeo(longitude: -44.0, latitude: -19.8),
        ],
      );
      const limites = Rect.fromLTWH(80, 120, 180, 160);
      const tela = Size(400, 800);
      final faseClarao = (math.pi * 0.5) / 2.8;

      final gravador = PictureRecorder();
      final canvas = Canvas(gravador);

      for (final nivel in NivelIntensidadeChuva.values) {
        final paleta = EfeitosParticulasTempestadeGlobo.paletaPorIntensidade(
          nivel,
          1.0,
        );
        EfeitosParticulasTempestadeGlobo.desenharIluminacaoVolumetricaTempestade(
          canvas: canvas,
          limitesRecorteTela: limites,
          centroMundoTela: limites.center,
          maiorLadoMundoPx: 180.0,
          menorLadoMundoPx: 160.0,
          nivel: nivel,
          paleta: paleta,
          faseSegundos: faseClarao,
        );
        EfeitosParticulasTempestadeGlobo.desenharBandasAdveccaoVento(
          canvas: canvas,
          limitesRecorteTela: limites,
          ancoraMundoTela: limites.center,
          menorLadoMundoPx: 160.0,
          dirTela: const Offset(0.7, 0.7),
          faseSegundos: faseClarao,
          fatorVel: 1.3,
          corCrista: paleta.bandaVento,
        );
        EfeitosParticulasTempestadeGlobo.desenharCelulasNuvemTempestade(
          canvas: canvas,
          bolha: bolha,
          menorLadoMundoPx: 160.0,
          uLon: 0.7,
          uLat: -0.7,
          faseSegundos: faseClarao,
          fatorVel: 1.3,
          tamanhoTela: tela,
          controlador: ctrl,
          picosReferencia: const [],
          sobreRelevo: nivel.peso >= 3,
          nivel: nivel,
          corNuvem: paleta.nucleo,
        );
        EfeitosParticulasTempestadeGlobo.desenharEmblemaNuvemChuva(
          canvas: canvas,
          centro: limites.center,
          escalaPx: 11.0,
          faseSegundos: 1.2,
          nivel: nivel,
          corBorda: paleta.tracoChuva,
        );
        EfeitosParticulasTempestadeGlobo.desenharPingoPatterChuva(
          canvas: canvas,
          bolha: bolha,
          nivel: nivel,
          pxPorGrau: 320.0,
          menorLadoMundoPx: nivel == NivelIntensidadeChuva.fraca ? 10.0 : 120.0,
          tamanhoTela: tela,
          controlador: ctrl,
          picosReferencia: const [
            PicoRelevoReferencia(
              id: 'p1',
              latitude: -20.0,
              longitude: -44.0,
              altitudeBaseMetros: 850,
              altitudePicoMetros: 1320,
            ),
          ],
          sobreRelevo: nivel.peso >= 3,
          faseSegundos: 0.4 + nivel.peso * 0.25,
          corGota: paleta.tracoChuva,
        );
      }

      // Bolsão compacto visível em zoom orbital (menor que a malha grossa de 1°) ancora 1 gota no próprio centro geográfico
      final ctrlOrbitalLocal = ControladorCameraGlobo(
        latitudeInicial: -20.0,
        longitudeInicial: -44.0,
        lodInicial: 0.25,
      );
      addTearDown(ctrlOrbitalLocal.dispose);
      const bolsaoMicro = BolhaChuvaRegional(
        id: 'bolsao_micro',
        latitude: -20.01,
        longitude: -44.01,
        intensidadeMmHora: 3.0,
        ventoRumoGraus: 90.0,
        ventoVelocidadeKmh: 12.0,
        contornoExterno: [
          PontoContornoGeo(longitude: -44.03, latitude: -20.03),
          PontoContornoGeo(longitude: -43.99, latitude: -20.03),
          PontoContornoGeo(longitude: -44.01, latitude: -19.99),
        ],
      );
      EfeitosParticulasTempestadeGlobo.desenharPingoPatterChuva(
        canvas: canvas,
        bolha: bolsaoMicro,
        nivel: NivelIntensidadeChuva.moderada,
        pxPorGrau: 3.5,
        menorLadoMundoPx: 12.0,
        tamanhoTela: tela,
        controlador: ctrlOrbitalLocal,
        picosReferencia: const [],
        sobreRelevo: false,
        faseSegundos: 0.2,
        corGota: const Color(0xFFBAE6FD),
      );

      // Culling limpo quando o contorno está no hemisfério oculto
      final ctrlOposto = ControladorCameraGlobo(
        latitudeInicial: 35.0,
        longitudeInicial: 138.0,
        lodInicial: 0.25,
      );
      addTearDown(ctrlOposto.dispose);
      EfeitosParticulasTempestadeGlobo.desenharPingoPatterChuva(
        canvas: canvas,
        bolha: bolha,
        nivel: NivelIntensidadeChuva.moderada,
        pxPorGrau: 12.0,
        menorLadoMundoPx: 26.0,
        tamanhoTela: tela,
        controlador: ctrlOposto,
        picosReferencia: const [],
        sobreRelevo: false,
        faseSegundos: 0.3,
        corGota: const Color(0xFFBAE6FD),
      );

      final picture = gravador.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });
  });
}
