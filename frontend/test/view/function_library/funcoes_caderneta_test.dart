// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/function_library/funcoes_caderneta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final cadeiaExemplo = Cadena(
    id: 'cadena-123',
    escaladaUid: 'via-abc',
    dataAscensao: DateTime(2026, 10, 24, 15, 30),
    tipoAscensao: TipoAscensao.aVista,
    tipoEscalada: TipoEscalada.guiado,
    tentativas: 1,
    notasPrivadas: 'Aderência perfeita no entardecer',
  );

  Widget montarComTema(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('Biblioteca de Funções da Caderneta (funcoes_caderneta.dart)', () {
    testWidgets('buildSecaoHistoricoCadenas exibe estado informativo vazio quando não há registros', (tester) async {
      await tester.pumpWidget(
        montarComTema(
          Builder(
            builder: (context) => buildSecaoHistoricoCadenas(
              context,
              historico: const [],
              obterNomeVia: (_) => 'Via Desconhecida',
              obterGrauVia: (_) => null,
              formatarData: (_) => '24/10/2026',
              onExcluirCadena: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Histórico de Ascensões (0)'), findsOneWidget);
      expect(find.text('Nenhuma ascensão registrada ainda'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    });

    testWidgets('buildSecaoHistoricoCadenas renderiza lista de ascensões esportivas com detalhes', (tester) async {
      Cadena? cadenaExcluida;

      await tester.pumpWidget(
        montarComTema(
          Builder(
            builder: (context) => buildSecaoHistoricoCadenas(
              context,
              historico: [cadeiaExemplo],
              obterNomeVia: (_) => 'Fenda do Crepúsculo',
              obterGrauVia: (_) => '7b',
              formatarData: (_) => '24/10/2026',
              onExcluirCadena: (c) => cadenaExcluida = c,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Histórico de Ascensões (1)'), findsOneWidget);
      expect(find.text('Fenda do Crepúsculo'), findsOneWidget);
      expect(find.text('7b'), findsOneWidget);
      expect(find.text('À Vista'), findsOneWidget);
      expect(find.textContaining('24/10/2026 • Guiado • 1 tentativa'), findsOneWidget);
      expect(find.text('“Aderência perfeita no entardecer”'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_excluir_cadena_cadena-123')));
      await tester.pump();
      expect(cadenaExcluida, equals(cadeiaExemplo));
    });

    testWidgets('exibirDialogoConfirmarExclusao retorna false ao clicar em Cancelar', (tester) async {
      bool? resultado;

      await tester.pumpWidget(
        montarComTema(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                resultado = await exibirDialogoConfirmarExclusao(context);
              },
              child: const Text('Abrir Diálogo'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Diálogo'));
      await tester.pumpAndSettle();

      expect(find.text('Excluir Ascensão?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(resultado, isFalse);
    });

    testWidgets('exibirDialogoConfirmarExclusao retorna true ao clicar em Excluir', (tester) async {
      bool? resultado;

      await tester.pumpWidget(
        montarComTema(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                resultado = await exibirDialogoConfirmarExclusao(context);
              },
              child: const Text('Abrir Diálogo'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Diálogo'));
      await tester.pumpAndSettle();

      expect(find.text('Excluir Ascensão?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_confirmar_exclusao')));
      await tester.pumpAndSettle();

      expect(resultado, isTrue);
    });
  });
}
