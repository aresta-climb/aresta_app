// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/caderneta/controles_formulario_cadena.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget envolverComTema(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: filho),
    );
  }

  group('SeletorEstiloAscensao', () {
    testWidgets(
      'renderiza todos os estilos esportivos e notifica apenas ao selecionar novo chip',
      (tester) async {
        final selecionados = <TipoAscensao>[];

        await tester.pumpWidget(
          envolverComTema(
            SeletorEstiloAscensao(
              estiloSelecionado: TipoAscensao.trabalhado,
              aoSelecionar: selecionados.add,
            ),
          ),
        );

        expect(find.text('Estilo Esportivo'), findsOneWidget);
        for (final estilo in TipoAscensao.values) {
          expect(find.text(estilo.rotulo), findsOneWidget);
        }

        // Tocar no chip já selecionado desmarca internamente (ativo == false) e não deve disparar callback
        await tester.tap(find.text(TipoAscensao.trabalhado.rotulo));
        await tester.pump();
        expect(selecionados, isEmpty);

        // Tocar em outro chip dispara callback com o novo estilo
        await tester.tap(find.text(TipoAscensao.flash.rotulo));
        await tester.pump();
        expect(selecionados, equals([TipoAscensao.flash]));
      },
    );
  });

  group('ContadorTentativasAscensao', () {
    testWidgets(
      'desabilita botão de decremento quando podeDecrementar é falso e aciona incremento',
      (tester) async {
        var incrementos = 0;
        var decrementos = 0;

        await tester.pumpWidget(
          envolverComTema(
            ContadorTentativasAscensao(
              tentativas: 1,
              podeDecrementar: false,
              aoIncrementar: () => incrementos++,
              aoDecrementar: () => decrementos++,
            ),
          ),
        );

        expect(find.text('Tentativas / Pegas'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        await tester.tap(find.byKey(const Key('btn_decrementar_tentativas')));
        await tester.pump();
        expect(decrementos, 0);

        await tester.tap(find.byKey(const Key('btn_incrementar_tentativas')));
        await tester.pump();
        expect(incrementos, 1);
      },
    );

    testWidgets(
      'aciona callback aoDecrementar quando podeDecrementar é verdadeiro',
      (tester) async {
        var decrementos = 0;

        await tester.pumpWidget(
          envolverComTema(
            ContadorTentativasAscensao(
              tentativas: 3,
              podeDecrementar: true,
              aoIncrementar: () {},
              aoDecrementar: () => decrementos++,
            ),
          ),
        );

        expect(find.text('3'), findsOneWidget);
        await tester.tap(find.byKey(const Key('btn_decrementar_tentativas')));
        await tester.pump();
        expect(decrementos, 1);
      },
    );
  });

  group('SeletorDataAscensao', () {
    testWidgets(
      'exibe data formatada e aciona callback aoTocar ao tocar no botão',
      (tester) async {
        var tocou = false;

        await tester.pumpWidget(
          envolverComTema(
            SeletorDataAscensao(
              dataTexto: '01/11/2026',
              aoTocar: () => tocou = true,
            ),
          ),
        );

        expect(find.text('Data da Ascensão'), findsOneWidget);
        expect(find.text('01/11/2026'), findsOneWidget);

        await tester.tap(find.byKey(const Key('btn_selecionar_data')));
        await tester.pump();
        expect(tocou, isTrue);
      },
    );
  });

  group('CampoNotasPrivadasAscensao', () {
    testWidgets(
      'vincula controlador de texto, respeita limite de caracteres e destaca contador ao atingir limite',
      (tester) async {
        final controlador = TextEditingController();
        addTearDown(controlador.dispose);

        await tester.pumpWidget(
          envolverComTema(
            CampoNotasPrivadasAscensao(
              controlador: controlador,
              contadorTexto: '0/10',
              atingiuLimite: false,
              limiteCaracteres: 10,
            ),
          ),
        );

        expect(find.text('Notas Privadas (Crux / Métodos)'), findsOneWidget);
        final contadorInicial = tester.widget<Text>(find.text('0/10'));
        expect(contadorInicial.style?.color, equals(AppColors.dark.ashGrey));

        await tester.enterText(
          find.byKey(const Key('campo_notas_privadas')),
          '1234567890EXTRAS',
        );
        await tester.pump();
        expect(controlador.text, equals('1234567890'));

        await tester.pumpWidget(
          envolverComTema(
            CampoNotasPrivadasAscensao(
              controlador: controlador,
              contadorTexto: '10/10',
              atingiuLimite: true,
              limiteCaracteres: 10,
            ),
          ),
        );

        final contadorLimite = tester.widget<Text>(find.text('10/10'));
        expect(contadorLimite.style?.color, equals(AppColors.dark.rustIron));
      },
    );
  });
}
