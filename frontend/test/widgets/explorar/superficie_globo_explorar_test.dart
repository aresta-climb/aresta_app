// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/view/view_models/cena_globo_explorar_view_model.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';
import 'package:frontend/widgets/explorar/malha_relevo_lod.dart';
import 'package:frontend/widgets/explorar/superficie_globo_explorar.dart';

void main() {
  final picosTeste = <MarcadorPicoGlobo>[
    MarcadorPicoGlobo(
      id: 'igarape',
      nome: 'Pedra Grande',
      uf: 'MG',
      setorPrincipal: 'Parede Principal',
      latitude: -20.07,
      longitude: -44.32,
      altitudeBaseMetros: 980,
      altitudePicoMetros: 1430,
      dimensaoGradeDem: 3,
      raioGradeDemGraus: 0.024,
      gradeDemMetros: const [
        980, 1020, 1060,
        1120, 1280, 1390,
        1180, 1340, 1430,
      ],
      umidade: EstadoUmidadePico(
        nivel: NivelUmidadePico.possivelmenteUmido,
        diasParaSecar: 4,
        diasDesdeChuva: 0,
        dataUltimaChuva: DateTime.utc(2026, 11, 25),
        milimetrosEvento: 22.0,
        bolhaIdAssociada: 'bolha_mg',
      ),
    ),
    MarcadorPicoGlobo(
      id: 'ouro_preto',
      nome: 'Parque das Andorinhas',
      uf: 'MG',
      setorPrincipal: 'Cachoeira',
      latitude: -20.35,
      longitude: -43.50,
      altitudeBaseMetros: 1120,
      altitudePicoMetros: 1580,
      umidade: EstadoUmidadePico(
        nivel: NivelUmidadePico.possivelmenteUmido,
        diasParaSecar: 3,
        diasDesdeChuva: 1,
        dataUltimaChuva: DateTime.utc(2026, 11, 24),
        milimetrosEvento: 10.0,
        bolhaIdAssociada: 'bolha_op',
      ),
    ),
    MarcadorPicoGlobo(
      id: 'cipo',
      nome: 'Serra do Cipó',
      uf: 'MG',
      setorPrincipal: 'Grupo 1',
      latitude: -19.34,
      longitude: -43.62,
      altitudeBaseMetros: 820,
      altitudePicoMetros: 1290,
      umidade: EstadoUmidadePico(
        nivel: NivelUmidadePico.possivelmenteUmido,
        diasParaSecar: 4,
        diasDesdeChuva: 0,
        dataUltimaChuva: DateTime.utc(2026, 11, 25),
        milimetrosEvento: 3.0,
        bolhaIdAssociada: 'bolha_cipo',
      ),
    ),
    const MarcadorPicoGlobo(
      id: 'urca',
      nome: 'Pão de Açúcar',
      uf: 'RJ',
      setorPrincipal: 'Costão',
      latitude: -22.95,
      longitude: -43.16,
      altitudeBaseMetros: 12,
      altitudePicoMetros: 396,
      umidade: EstadoUmidadePico.seco(),
    ),
  ];

