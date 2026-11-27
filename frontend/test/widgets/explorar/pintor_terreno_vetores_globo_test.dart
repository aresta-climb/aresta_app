// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';
import 'package:frontend/widgets/explorar/pintor_terreno_vetores_globo.dart';

void main() {
  const malhaCompleta = MalhaGeograficaGlobo(
    continentes: [
      PoligonoGeografico(
        id: 'america_sul',
        verticesLonLat: [
          Offset(-48.0, -24.0),
          Offset(-40.0, -24.0),
          Offset(-40.0, -16.0),
          Offset(-48.0, -16.0),
        ],
      ),
    ],
    brasil: [
      Offset(-48.0, -24.0),
      Offset(-40.0, -24.0),
      Offset(-40.0, -16.0),
      Offset(-48.0, -16.0),
    ],
    estados: [],
    rodoviasProximas: [
      RodoviaRegionalMapa(
        ehPrincipal: true,
        codigo: 'BR-040',
        verticesLonLat: [
          Offset(-44.1, -20.2),
          Offset(-44.0, -20.0),
          Offset(-43.9, -19.8),
        ],
      ),
      RodoviaRegionalMapa(
        ehPrincipal: false,
        codigo: 'MG-secundaria',
        verticesLonLat: [
          Offset(-44.1, -20.1),
          Offset(-44.0, -20.0),
        ],
      ),
    ],
  );

  const picosVariados = <PicoRelevoReferencia>[
    PicoRelevoReferencia(
      id: 'baixo',
      latitude: -20.05,
      longitude: -44.05,
      altitudeBaseMetros: 200,
      altitudePicoMetros: 580,
    ),
    PicoRelevoReferencia(
      id: 'medio',
      latitude: -20.00,
      longitude: -44.00,
      altitudeBaseMetros: 700,
      altitudePicoMetros: 1200,
    ),
    PicoRelevoReferencia(
      id: 'alto',
      latitude: -19.96,
      longitude: -43.96,
      altitudeBaseMetros: 1250,
      altitudePicoMetros: 1850,
    ),
  ];

  group('PintorTerrenoVetoresGlobo', () {
    test('renderiza terreno contínuo hipsométrico em 3D e 2D e ignora lista vazia', () {
      final ctrl3D = ControladorCameraGlobo(
        latitudeInicial: -20.0,
        longitudeInicial: -44.0,
        lodInicial: 2.6,
      );
      final ctrl2D = ControladorCameraGlobo(
        latitudeInicial: -20.0,
        longitudeInicial: -44.0,
        lodInicial: 3.4,
        modo3DInicial: false,
      );
      addTearDown(() {
        ctrl3D.dispose();
        ctrl2D.dispose();
      });

