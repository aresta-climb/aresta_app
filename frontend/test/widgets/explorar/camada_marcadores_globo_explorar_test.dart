// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/construtor_rede_viaria_aresta.dart';
import 'package:frontend/widgets/explorar/camada_marcadores_globo_explorar.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';

void main() {
  const malhaTeste = MalhaGeograficaGlobo(
    continentes: [
      PoligonoGeografico(
        id: 'america_sul',
        verticesLonLat: [
          Offset(-50.0, -25.0),
          Offset(-38.0, -25.0),
          Offset(-38.0, -14.0),
          Offset(-50.0, -14.0),
        ],
      ),
    ],
    brasil: [
      Offset(-50.0, -25.0),
      Offset(-38.0, -25.0),
      Offset(-38.0, -14.0),
      Offset(-50.0, -14.0),
    ],
    estados: [],
    localidadesProximas: [
      LocalidadeRegionalMapa(
        nome: 'Belo Horizonte',
        ehCidade: true,
        nivel: 1,
        longitude: -44.08,
        latitude: -19.72,
      ),
      LocalidadeRegionalMapa(
        nome: 'Lagoa Santa',
        ehCidade: true,
        nivel: 2,
        longitude: -43.89,
        latitude: -19.63,
      ),
      LocalidadeRegionalMapa(
        nome: 'Lapinha da Serra',
        ehCidade: false,
        nivel: 3,
        longitude: -43.68,
        latitude: -19.12,
      ),
      LocalidadeRegionalMapa(
        nome: 'Polo Referência',
        ehCidade: true,
        nivel: 1,
        longitude: -44.00,
        latitude: -20.32,
      ),
    ],
    rodoviasProximas: [
      RodoviaRegionalMapa(
        ehPrincipal: true,
        codigo: 'BR-381',
        verticesLonLat: [
          Offset(-44.08, -19.72),
          Offset(-44.20, -20.05),
        ],
      ),
    ],
  );

  const picosTeste = <MarcadorPicoGlobo>[
    MarcadorPicoGlobo(
      id: 'p_mg',
      nome: 'Pedra Grande',
      uf: 'MG',
      latitude: -20.05,
      longitude: -44.20,
      altitudeBaseMetros: 900,
      altitudePicoMetros: 1420,
    ),
    MarcadorPicoGlobo(
      id: 'p_rj',
      nome: 'Urca',
      uf: 'RJ',
      latitude: -20.12,
      longitude: -44.18,
      altitudeBaseMetros: 5,
      altitudePicoMetros: 396,
    ),
  ];

