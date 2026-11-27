// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/data/modelos/modelos_rede_viaria_aresta.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/pintor_atmosfera_clima_globo.dart';

void main() {
  group('PintorFenomenosAtmosfericosGlobo', () {
    test('renderiza filtro atmosférico superior de tempestades e incêndios em órbita 3D e em zoom local', () async {
      final ctrlOrbital = ControladorCameraGlobo(
        latitudeInicial: -20.0,
        longitudeInicial: -44.0,
        lodInicial: 0.45,
      );
      final ctrlLocal = ControladorCameraGlobo(
        latitudeInicial: -20.0,
        longitudeInicial: -44.0,
        lodInicial: 2.95,
      );
      addTearDown(() {
        ctrlOrbital.dispose();
        ctrlLocal.dispose();
      });

      const picosReferencia = <PicoRelevoReferencia>[
        PicoRelevoReferencia(
          id: 'p1',
          latitude: -20.0,
          longitude: -44.0,
          altitudeBaseMetros: 900,
          altitudePicoMetros: 1420,
        ),
      ];

      const bolhas = <BolhaAtivaRenderizavel>[
        BolhaAtivaRenderizavel(
          nivelIntensidade: NivelIntensidadeChuva.extrema,
          bolha: BolhaChuvaRegional(
            id: 'b1',
            latitude: -20.0,
            longitude: -44.0,
            intensidadeMmHora: 9.5,
            ventoRumoGraus: 120.0,
            ventoVelocidadeKmh: 28.0,
            contornoExterno: [
              PontoContornoGeo(longitude: -46.2, latitude: -22.2),
              PontoContornoGeo(longitude: -41.8, latitude: -22.2),
              PontoContornoGeo(longitude: -44.0, latitude: -17.8),
            ],
          ),
        ),
        BolhaAtivaRenderizavel(
          nivelIntensidade: NivelIntensidadeChuva.fraca,
          bolha: BolhaChuvaRegional(
            id: 'b_fora_frustum',
            latitude: -12.0,
            longitude: -48.0,
            intensidadeMmHora: 1.2,
            ventoRumoGraus: 90.0,
            ventoVelocidadeKmh: 12.0,
            contornoExterno: [
              PontoContornoGeo(longitude: -48.2, latitude: -12.2),
              PontoContornoGeo(longitude: -47.8, latitude: -12.2),
              PontoContornoGeo(longitude: -48.0, latitude: -11.8),
            ],
          ),
        ),
      ];

      const incendios = <BolhaIncendioAtivaRenderizavel>[
        BolhaIncendioAtivaRenderizavel(
          incendio: BolhaIncendioRegional(
            id: 'f1',
            latitude: -20.0,
            longitude: -44.0,
            potenciaFrpMw: 92.0,
            totalFocos: 7,
            ventoRumoGraus: 260.0,
            ventoVelocidadeKmh: 22.0,
            contornoExterno: [
              PontoContornoGeo(longitude: -45.5, latitude: -21.5),
              PontoContornoGeo(longitude: -42.5, latitude: -21.5),
              PontoContornoGeo(longitude: -44.0, latitude: -18.5),
            ],
