// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/services/caderneta/estatisticas_caderneta.dart';
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

  final cadeiaMultiplasTentativas = Cadena(
    id: 'cadena-456',
    escaladaUid: 'via-def',
    dataAscensao: DateTime(2026, 10, 25, 10, 0),
    tipoAscensao: TipoAscensao.tentativa,
    tipoEscalada: TipoEscalada.boulder,
    tentativas: 3,
    notasPrivadas: '',
  );

  Widget montarComTema(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('Biblioteca de Funções da Caderneta (funcoes_caderneta.dart)', () {
    testWidgets('buildPainelResumoEstatisticas renderiza os 4 cartões de estatística esportiva com valores e fallbacks', (tester) async {
      await tester.pumpWidget(
        montarComTema(
          Builder(
            builder: (context) => buildPainelResumoEstatisticas(
              EstatisticasCaderneta.vazia(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total de Cadenas'), findsOneWidget);
      expect(find.text('Taxa À Vista/Flash'), findsOneWidget);
      expect(find.text('Maior Grau (Vias)'), findsOneWidget);
      expect(find.text('Maior Grau (Boulders)'), findsOneWidget);
    });

    testWidgets('buildSecaoHistoricoCadenas exibe estado informativo vazio quando não há registros', (tester) async {
      await tester.pumpWidget(
        montarComTema(
          Builder(
            builder: (context) => Column(
              children: [
                buildSecaoHistoricoCadenas(
                  context,
                  historico: const [],
                  obterNomeVia: (_) => 'Via Desconhecida',
                  obterGrauVia: (_) => null,
                  formatarData: (_) => '24/10/2026',
                  onExcluirCadena: (_) {},
                ),
                buildEstadoVazioHistorico(context),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Histórico de Ascensões (0)'), findsOneWidget);
      expect(find.text('Nenhuma ascensão registrada ainda'), findsNWidgets(2));
      expect(find.byIcon(Icons.menu_book_outlined), findsNWidgets(2));
    });

    testWidgets('buildSecaoHistoricoCadenas renderiza lista de ascensões esportivas com detalhes', (tester) async {
      Cadena? cadenaExcluida;
      Cadena? cadenaEditada;
      Cadena? cadenaViaTocada;

      await tester.pumpWidget(
        montarComTema(
          Builder(
            builder: (context) => Column(
              children: [
                buildSecaoHistoricoCadenas(
                  context,
                  historico: [cadeiaExemplo, cadeiaMultiplasTentativas],
                  obterNomeVia: (_) => 'Fenda do Crepúsculo',
                  obterGrauVia: (_) => '7b',
                  formatarData: (_) => '24/10/2026',
                  onExcluirCadena: (c) => cadenaExcluida = c,
                  onEditarCadena: (c) => cadenaEditada = c,
                  onTocarVia: (c) => cadenaViaTocada = c,
                ),
                buildItemHistoricoCadena(
                  context,
                  cadena: cadeiaExemplo,
                  nomeVia: 'Via Direta',
                  grauVia: '6ºsup',
                  dataFormatada: '24/10/2026',
                  onExcluir: () {},
                ),
                buildItemHistoricoCadena(
                  context,
                  cadena: cadeiaMultiplasTentativas,
                  nomeVia: 'Boulder Sem Notas',
                  dataFormatada: '25/10/2026',
                  onExcluir: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Histórico de Ascensões (2)'), findsOneWidget);
      expect(find.text('Fenda do Crepúsculo'), findsNWidgets(2));
      expect(find.text('7b'), findsNWidgets(2));
      expect(find.text('À Vista'), findsNWidgets(2));
      expect(find.textContaining('24/10/2026 • Guiado • 1 tentativa'), findsNWidgets(2));
      expect(find.textContaining('24/10/2026 • Boulder • 3 tentativas'), findsOneWidget);
      expect(find.text('“Aderência perfeita no entardecer”'), findsNWidgets(2));

      await tester.tap(find.byKey(const Key('item_historico_cadena_cadena-123')).first);
      await tester.pump();
      expect(cadenaViaTocada, equals(cadeiaExemplo));

      await tester.tap(find.byKey(const Key('btn_editar_cadena_cadena-123')).first);
      await tester.pump();
      expect(cadenaEditada, equals(cadeiaExemplo));

      await tester.tap(find.byKey(const Key('btn_excluir_cadena_cadena-123')).first);
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
