// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/idioma/dicionario_en.dart';
import 'package:frontend/idioma/modelo_idioma_app.dart';
import 'package:frontend/widgets/explorar/botao_camada_clima_mapa.dart';
import 'package:frontend/widgets/navegacao/botao_voltar_com_retorno_inicio.dart';

void main() {
  group('BotaoCamadaClimaMapa e DialogoAvisoPrecisaoClima', () {
    testWidgets(
      'inicia desligado, exige confirmação no aviso de precisão (~75%) para ativar e desativa imediatamente ao tocar novamente',
      (tester) async {
        var ativo = false;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Center(
                    child: BotaoCamadaClimaMapa(
                      ativo: ativo,
                      aoAlterarAtivo: (novo) => setState(() => ativo = novo),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        expect(find.byKey(const Key('botao_camada_clima_mapa')), findsOneWidget);
        expect(find.byIcon(Icons.thunderstorm_outlined), findsOneWidget);
        expect(ativo, isFalse);

        // 1. Primeiro clique com o botão desligado abre o aviso de ~75% de precisão
        await tester.tap(find.byKey(const Key('botao_camada_clima_mapa')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('dialogo_aviso_precisao_clima')),
          findsOneWidget,
        );
        expect(find.text('~85%'), findsOneWidget);
        expect(find.textContaining('Open-Meteo'), findsOneWidget);
        expect(find.textContaining('RainViewer'), findsOneWidget);
        expect(find.textContaining('INPE BDQueimadas'), findsOneWidget);
        expect(find.textContaining('FIRMS'), findsOneWidget);
        expect(find.textContaining('SRTM'), findsOneWidget);
        expect(find.textContaining('Blue Marble'), findsOneWidget);
        expect(
          dicionarioIngles[ChaveTexto.explorarAvisoClimaCorpo],
          allOf(
            contains('~85%'),
            contains('Open-Meteo'),
            contains('RainViewer'),
            contains('INPE BDQueimadas'),
            contains('public NASA mission resources'),
            contains('reference tool instead of absolute truth'),
          ),
        );

        // 1b. Tocar em "Ver estatísticas" fecha o diálogo sem ativar a camada e abre a página dedicada de estatísticas
        expect(
          find.byKey(const Key('botao_ver_estatisticas_clima')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('botao_ver_estatisticas_clima')));
        await tester.pumpAndSettle();
        expect(ativo, isFalse);
        expect(
          find.byKey(const Key('pagina_estatisticas_clima')),
          findsOneWidget,
        );
        await tester.tap(find.byType(BotaoVoltarComRetornoInicio));
        await tester.pumpAndSettle();

        // Reabre o diálogo para testar o botão Cancelar
        await tester.tap(find.byKey(const Key('botao_camada_clima_mapa')));
        await tester.pumpAndSettle();

        // 2. Cancelar mantém o botão desligado
        await tester.tap(find.byKey(const Key('botao_cancelar_aviso_clima')));
        await tester.pumpAndSettle();
        expect(ativo, isFalse);
        expect(find.byIcon(Icons.thunderstorm_outlined), findsOneWidget);

        // 3. Tocar novamente e pressionar OK ativa a camada
        await tester.tap(find.byKey(const Key('botao_camada_clima_mapa')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('botao_confirmar_aviso_clima')));
        await tester.pumpAndSettle();

        expect(ativo, isTrue);
        expect(find.byIcon(Icons.thunderstorm_rounded), findsOneWidget);

        // 4. Tocar no botão já ligado desliga imediatamente sem abrir diálogo
        await tester.tap(find.byKey(const Key('botao_camada_clima_mapa')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('dialogo_aviso_precisao_clima')),
          findsNothing,
        );
        expect(ativo, isFalse);
        expect(find.byIcon(Icons.thunderstorm_outlined), findsOneWidget);
      },
    );
  });
}
