// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/via/bolha_alerta_seguranca_via.dart';

void main() {
  Widget envolverComTema(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: filho),
    );
  }

  testWidgets('BolhasFlutuantesAlertaVia oculta quando lista vazia e renderiza bolha vermelha com emoji e contador', (tester) async {
    await tester.pumpWidget(
      envolverComTema(
        BolhasFlutuantesAlertaVia(
          alertas: const [],
          aoSelecionarAlerta: (_) {},
        ),
      ),
    );
    expect(find.byType(BolhaEmojiAlertaVia), findsNothing);

    AlertaSegurancaVia? selecionado;
    final alertaInicial = AlertaSegurancaVia.criar(
      uid: 'alertaAbelha01',
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.abelhasInsetos,
      detalhe: 'Colmeia na terceira costura',
      confirmacoesAtivas: 1,
    );

    await tester.pumpWidget(
      envolverComTema(
        BolhasFlutuantesAlertaVia(
          alertas: [alertaInicial],
          aoSelecionarAlerta: (alerta) => selecionado = alerta,
        ),
      ),
    );
    expect(find.text('🐝'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    final alertaAbelhas = alertaInicial.copyWith(confirmacoesAtivas: 3);

    await tester.pumpWidget(
      envolverComTema(
        BolhasFlutuantesAlertaVia(
          alertas: [alertaAbelhas],
          aoSelecionarAlerta: (alerta) => selecionado = alerta,
        ),
      ),
    );

    expect(find.text('🐝'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bolha_alerta_ABELHAS_INSETOS')));
    expect(selecionado?.uid, 'alertaAbelha01');
  });

  testWidgets('exibirModalConfirmacaoAlertaVia exibe detalhes e dispara confirmação positiva ou resolução', (tester) async {
    bool? respostaConfirmada;
    final alerta = AlertaSegurancaVia.criar(
      uid: 'alertaRocha001',
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.rochaAgarraInstavel,
      detalhe: 'Laca oca na saída do teto',
      autorNomePublico: 'Mariana Silva',
      confirmacoesAtivas: 2,
    );

    await tester.pumpWidget(
      envolverComTema(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              exibirModalConfirmacaoAlertaVia(
                context,
                alerta: alerta,
                aoResponder: (aindaEstaLa) async {
                  respostaConfirmada = aindaEstaLa;
                },
              );
            },
            child: const Text('Abrir Alerta'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir Alerta'));
    await tester.pumpAndSettle();

    expect(find.text('🪨'), findsOneWidget);
    expect(find.text('Rocha ou Agarra Instável'), findsOneWidget);
    expect(find.textContaining('Laca oca na saída do teto'), findsOneWidget);
    expect(find.textContaining('Mariana Silva'), findsOneWidget);
    expect(find.text('Ainda está lá?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_confirmar_alerta_ativo')));
    await tester.pumpAndSettle();
    expect(respostaConfirmada, isTrue);

    await tester.tap(find.text('Abrir Alerta'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_confirmar_alerta_resolvido')));
    await tester.pumpAndSettle();
    expect(respostaConfirmada, isFalse);
  });

  testWidgets('exibirModalReportarAlertaVia permite escolher categoria emoji e enviar detalhe opcional', (tester) async {
    CategoriaAlertaSeguranca? categoriaEnviada;
    String? detalheEnviado;

    await tester.pumpWidget(
      envolverComTema(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              exibirModalReportarAlertaVia(
                context,
                aoReportar: (categoria, detalhe) async {
                  categoriaEnviada = categoria;
                  detalheEnviado = detalhe;
                },
              );
            },
            child: const Text('Novo Alerta'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Novo Alerta'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('opcao_alerta_PROTECAO_PRECARIA')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('campo_detalhe_alerta_via')),
      'Chapeleta 2 girando',
    );
    await tester.tap(find.byKey(const Key('btn_enviar_alerta_via')));
    await tester.pumpAndSettle();

    expect(categoriaEnviada, CategoriaAlertaSeguranca.protecaoPrecaria);
    expect(detalheEnviado, 'Chapeleta 2 girando');
  });
}
