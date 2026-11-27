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
      categoria: CategoriaAlertaSeguranca.fauna,
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

    await tester.tap(find.byKey(const Key('bolha_alerta_FAUNA')));
    expect(selecionado?.uid, 'alertaAbelha01');

    // A silhueta da bolha de alerta é um contorno único contínuo (sem costura interna cilindro+triângulo)
    // mantendo a ponta da cauda ancorada exatamente em (0.24 * largura, altura).
    const tamanhoBolha = Size(54, 40);
    final caminhoSilhueta = construirCaminhoBolhaAlerta(tamanhoBolha);
    final metricas = caminhoSilhueta.computeMetrics().toList();
    expect(metricas, hasLength(1));
    final limites = caminhoSilhueta.getBounds();
    expect(limites.bottom, closeTo(tamanhoBolha.height, 0.5));
    expect(
      caminhoSilhueta.contains(Offset(tamanhoBolha.width * 0.24, tamanhoBolha.height - 1.5)),
      isTrue,
    );
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

    // Quando criado ou já confirmado pelo usuário, bloqueia novo +1 mas mantém resolução ativa
    for (final estado in [
      EstadoInteracaoAlertaUsuario.criadoPorMim,
      EstadoInteracaoAlertaUsuario.jaConfirmadoPorMim,
    ]) {
      await tester.pumpWidget(
        envolverComTema(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                exibirModalConfirmacaoAlertaVia(
                  context,
                  alerta: alerta,
                  estadoUsuario: estado,
                  aoResponder: (_) async {},
                );
              },
              child: const Text('Abrir Bloqueado'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir Bloqueado'));
      await tester.pumpAndSettle();
      final btnAtivo = tester.widget<ElevatedButton>(
        find.byKey(const Key('btn_confirmar_alerta_ativo')),
      );
      expect(btnAtivo.onPressed, isNull);
      expect(
        find.text(
          estado == EstadoInteracaoAlertaUsuario.criadoPorMim
              ? '✓ Reportado por você'
              : '✓ Confirmado por você',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('btn_confirmar_alerta_resolvido')));
      await tester.pumpAndSettle();
    }

    // Quando não autenticado, exibe orientação de login sem botões mutáveis
    await tester.pumpWidget(
      envolverComTema(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              exibirModalConfirmacaoAlertaVia(
                context,
                alerta: alerta,
                estadoUsuario: EstadoInteracaoAlertaUsuario.requerAutenticacao,
                aoResponder: (_) async {},
              );
            },
            child: const Text('Abrir Sem Conta'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir Sem Conta'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aviso_login_alerta_via')), findsOneWidget);
    expect(find.byKey(const Key('btn_confirmar_alerta_ativo')), findsNothing);
    Navigator.of(
      tester.element(find.byKey(const Key('aviso_login_alerta_via'))),
    ).pop();
    await tester.pumpAndSettle();

    // Quando criado pelo próprio autor com callbacks de edição/exclusão, exibe ações dedicadas e fecha o modal ao acioná-las
    var solicitouEdicao = false;
    var solicitouExclusao = false;
    await tester.pumpWidget(
      envolverComTema(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              exibirModalConfirmacaoAlertaVia(
                context,
                alerta: alerta,
                estadoUsuario: EstadoInteracaoAlertaUsuario.criadoPorMim,
                aoResponder: (_) async {},
                aoSolicitarEdicao: () => solicitouEdicao = true,
                aoSolicitarExclusao: () => solicitouExclusao = true,
              );
            },
            child: const Text('Abrir Meu Alerta'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir Meu Alerta'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('btn_editar_alerta_modal')), findsOneWidget);
    expect(find.byKey(const Key('btn_excluir_alerta_modal')), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_editar_alerta_modal')));
    await tester.pumpAndSettle();
    expect(solicitouEdicao, isTrue);

    await tester.tap(find.text('Abrir Meu Alerta'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_excluir_alerta_modal')));
    await tester.pumpAndSettle();
    expect(solicitouExclusao, isTrue);
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
