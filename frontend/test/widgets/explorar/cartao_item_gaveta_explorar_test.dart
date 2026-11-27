// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:frontend/view/view_models/card_croqui_view_model.dart';
import 'package:frontend/widgets/explorar/cartao_item_gaveta_explorar.dart';

void main() {
  group('CartaoItemGavetaExplorar', () {
    testWidgets('exibe selo altimétrico, botão de foco no globo e tarja de umidade apenas quando úmido', (
      tester,
    ) async {
      final progressoDownload = ValueNotifier<Map<String, double>>(const {});
      addTearDown(progressoDownload.dispose);

      const cardUmido = CardCroquiViewModel.deValores(
        id: 'p_umido',
        titulo: 'SERRA DO CIPÓ',
        localizacao: 'SANTANA DO RIACHO - MG',
        textoEstatisticas: '3 setores • 45 escaladas',
        caminhoMiniatura: '',
        salvoOffline: true,
      );
      const cardSeco = CardCroquiViewModel.deValores(
        id: 'p_seco',
        titulo: 'PÃO DE AÇÚCAR',
        localizacao: 'URCA - RJ',
        textoEstatisticas: '5 setores • 90 escaladas',
        caminhoMiniatura: '',
        salvoOffline: false,
      );

      var focouGlobo = 0;
      var abriuCard = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  CartaoItemGavetaExplorar(
                    card: cardUmido,
                    altitudeMetros: 1240,
                    umidade: EstadoUmidadePico(
                      nivel: NivelUmidadePico.possivelmenteUmido,
                      diasParaSecar: 4,
                      diasDesdeChuva: 0,
                      dataUltimaChuva: DateTime.utc(2026, 11, 25),
                    ),
                    selecionado: false,
                    emPulsoDestaque: true,
                    downloadingCrags: progressoDownload,
                    aoAbrir: () => abriuCard++,
                    aoFocarNoGlobo: () => focouGlobo++,
                  ),
                  CartaoItemGavetaExplorar(
                    card: cardSeco,
                    altitudeMetros: null,
                    umidade: const EstadoUmidadePico.seco(),
                    selecionado: true,
                    emPulsoDestaque: false,
                    downloadingCrags: progressoDownload,
                    aoAbrir: () => abriuCard++,
                    aoFocarNoGlobo: () => focouGlobo++,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('badge_altitude_p_umido')), findsOneWidget);
      expect(find.text('Alt. 1240m'), findsOneWidget);
      expect(find.byKey(const Key('alerta_umidade_p_umido')), findsOneWidget);

      expect(find.byKey(const Key('badge_altitude_p_seco')), findsNothing);
      expect(find.byKey(const Key('alerta_umidade_p_seco')), findsNothing);

      await tester.tap(find.byKey(const Key('botao_ver_no_globo_p_umido')));
      await tester.tap(find.text('SERRA DO CIPÓ'));
      expect(focouGlobo, equals(1));
      expect(abriuCard, equals(1));
    });
  });
}
