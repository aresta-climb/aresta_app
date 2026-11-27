// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/widgets/explorar/componentes_marcador_globo.dart';
import 'package:frontend/widgets/explorar/controlador_camera_globo.dart';

void main() {
  group('ComponentesMarcadorGlobo', () {
    testWidgets('CapsulaControlesModoGlobo aciona 3D/2D, reset e estado GPS carregando ou ativo', (
      tester,
    ) async {
      var alternou = 0;
      var resetou = 0;
      var centralizou = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CapsulaControlesModoGlobo(
                  modo3D: true,
                  temLocalizacaoUsuario: false,
                  buscandoLocalizacaoUsuario: false,
                  aoAlternarModo3D: () => alternou++,
                  aoResetarGlobo: () => resetou++,
                ),
                CapsulaControlesModoGlobo(
                  modo3D: false,
                  temLocalizacaoUsuario: true,
                  buscandoLocalizacaoUsuario: false,
                  aoAlternarModo3D: () => alternou++,
                  aoResetarGlobo: () => resetou++,
                  aoCentralizarNoUsuario: () => centralizou++,
                ),
                CapsulaControlesModoGlobo(
                  modo3D: true,
                  temLocalizacaoUsuario: false,
                  buscandoLocalizacaoUsuario: true,
                  aoAlternarModo3D: () {},
                  aoResetarGlobo: () {},
                  aoCentralizarNoUsuario: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('3D'), findsNWidgets(2));
      expect(find.text('2D'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byKey(const Key('botao_alternar_3d_2d')).first);
      await tester.tap(find.byKey(const Key('botao_resetar_globo')).first);
      await tester.tap(find.byKey(const Key('botao_minha_localizacao')).first);
      expect(alternou, equals(1));
      expect(resetou, equals(1));
      expect(centralizou, equals(1));
    });

    testWidgets('BolhaCompactaPicoGlobo e PilulaExpandidaPicoGlobo exibem marca Aresta, umidade e altitude sobre o mar', (
      tester,
    ) async {
      const picoSeco = MarcadorPicoGlobo(
        id: 'p_seco',
        nome: 'Serra do Cipó',
        uf: 'MG',
        latitude: -19.3,
        longitude: -43.6,
        altitudeBaseMetros: 800,
        altitudePicoMetros: 1250,
      );
      final picoMolhado = MarcadorPicoGlobo(
        id: 'p_molhado',
        nome: 'Pedra Grande',
        uf: 'MG',
        latitude: -20.0,
        longitude: -44.3,
        altitudeBaseMetros: 960,
        altitudePicoMetros: 1430,
        umidade: EstadoUmidadePico(
          nivel: NivelUmidadePico.possivelmenteUmido,
          diasParaSecar: 3,
          diasDesdeChuva: 1,
          dataUltimaChuva: DateTime.utc(2026, 11, 25),
        ),
      );
      expect(picoSeco.paraReferenciaRelevo().altitudePicoMetros, equals(1250));

