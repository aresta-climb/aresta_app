// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/clima/selo_umidade_pico.dart';

void main() {
  Widget envolver(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: Center(child: filho)),
    );
  }

  test(
    'PaletaUmidadePico define cores e ícones distintos para os estados conservadores (Possivelmente úmido e Seco)',
    () {
      final coresDestaque = {
        for (final nivel in NivelUmidadePico.values)
          PaletaUmidadePico.corDestaque(nivel),
      };
      final coresFundo = {
        for (final nivel in NivelUmidadePico.values)
          PaletaUmidadePico.corFundo(nivel),
      };
      final coresBorda = {
        for (final nivel in NivelUmidadePico.values)
          PaletaUmidadePico.corBorda(nivel),
      };
      final coresTexto = {
        for (final nivel in NivelUmidadePico.values)
          PaletaUmidadePico.corTexto(nivel),
      };
      final icones = {
        for (final nivel in NivelUmidadePico.values)
          PaletaUmidadePico.icone(nivel),
      };

      expect(coresDestaque, hasLength(2));
      expect(coresFundo, hasLength(2));
      expect(coresBorda, hasLength(2));
      expect(coresTexto, hasLength(2));
      expect(icones, hasLength(2));
      expect(PaletaUmidadePico.corPontoArestaPadrao, const Color(0xFFE27D60));
    },
  );

  testWidgets(
    'TarjaUmidadePico e CartaoCondicaoHidricaPico formatam janela conservadora de 4 dias (hoje, 1 dia, N dias e sem data) e estado seco',
    (tester) async {
      await tester.pumpWidget(
        envolver(
          const TarjaUmidadePico(
            umidade: EstadoUmidadePico.seco(),
            exibirQuandoSeco: false,
          ),
        ),
      );
      expect(find.textContaining('Provavelmente seco'), findsNothing);

      await tester.pumpWidget(
        envolver(
          const TarjaUmidadePico(
            umidade: EstadoUmidadePico.seco(),
            exibirQuandoSeco: true,
          ),
        ),
      );
      expect(
        find.text('Provavelmente seco · Sem chuva próxima (4 dias)'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);

      await tester.pumpWidget(
        envolver(
          TarjaUmidadePico(
            umidade: EstadoUmidadePico(
              nivel: NivelUmidadePico.possivelmenteUmido,
              diasParaSecar: 4,
              diasDesdeChuva: 0,
              dataUltimaChuva: DateTime.utc(2026, 11, 25),
              milimetrosEvento: 6.0,
            ),
          ),
        ),
      );
      expect(
        find.text('Possivelmente úmido (4 dias) - chuva próxima hoje (25/11)'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);

