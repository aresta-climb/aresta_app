// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/via/modais_edicao_interacao_via.dart';

void main() {
  Widget envolver(Widget Function(BuildContext) construtor) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: Builder(builder: construtor)),
    );
  }

  testWidgets(
    'exibirModalEditarComentarioVia preenche texto atual, desabilita salvar vazio e submete texto editado ou cancela',
    (tester) async {
      String? textoSalvo;

      await tester.pumpWidget(
        envolver(
          (ctx) => ElevatedButton(
            onPressed: () => exibirModalEditarComentarioVia(
              ctx,
              textoInicial: 'Beta inicial',
              aoSalvar: (novo) async => textoSalvo = novo,
            ),
            child: const Text('Abrir Edicao Comentario'),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Edicao Comentario'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Comentário'), findsOneWidget);
      expect(find.text('Beta inicial'), findsOneWidget);

      // Limpar para espaços em branco desabilita o botão Salvar Alterações
      await tester.enterText(
        find.byKey(const Key('campo_editar_comentario_via')),
        '   ',
      );
      await tester.pump();
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const Key('btn_salvar_comentario_editado_via')),
            )
            .onPressed,
        isNull,
      );

      // Cancelar fecha sem disparar aoSalvar
      await tester.tap(find.byKey(const Key('btn_cancelar_edicao_comentario_via')));
      await tester.pumpAndSettle();
      expect(textoSalvo, isNull);

      // Reabre, edita e salva
      await tester.tap(find.text('Abrir Edicao Comentario'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('campo_editar_comentario_via')),
        '  Beta revisado sem spoiler  ',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('btn_salvar_comentario_editado_via')),
      );
      await tester.pumpAndSettle();

      expect(textoSalvo, 'Beta revisado sem spoiler');
    },
  );

  testWidgets(
    'exibirModalFormularioAlertaVia opera em modo criacao e modo edicao pre-preenchido',
    (tester) async {
      CategoriaAlertaSeguranca? catSalva;
      String? detSalvo;
      final alertaExistente = AlertaSegurancaVia.criar(
        uid: 'alertaAbelha01',
        escaladaUid: 'x8siJek3FiG3aB',
        categoria: CategoriaAlertaSeguranca.rochaAgarraInstavel,
        detalhe: 'Bloco oco',
        autorIdPublico: 'c3Lk9P1x4Vw8Mn',
        autorNomePublico: 'Mariana',
      );

      await tester.pumpWidget(
        envolver(
          (ctx) => ElevatedButton(
            onPressed: () => exibirModalFormularioAlertaVia(
              ctx,
              alertaInicial: alertaExistente,
              aoSubmeter: (cat, det) async {
                catSalva = cat;
                detSalvo = det;
              },
            ),
            child: const Text('Editar Alerta'),
          ),
        ),
      );

      await tester.tap(find.text('Editar Alerta'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Alerta na Via'), findsOneWidget);
      expect(find.text('Bloco oco'), findsOneWidget);
      expect(find.text('Salvar Alterações'), findsOneWidget);

      await tester.tap(find.byKey(const Key('opcao_alerta_PROTECAO_PRECARIA')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('campo_detalhe_alerta_via')),
        'Chapeleta 2 frouxa',
      );
      await tester.tap(find.byKey(const Key('btn_enviar_alerta_via')));
      await tester.pumpAndSettle();

      expect(catSalva, CategoriaAlertaSeguranca.protecaoPrecaria);
      expect(detSalvo, 'Chapeleta 2 frouxa');
    },
  );

  testWidgets(
    'exibirDialogoConfirmarExclusaoInteracao retorna false ao cancelar e true ao confirmar para comentario e alerta',
    (tester) async {
      bool? resultado;

      await tester.pumpWidget(
        envolver(
          (ctx) => Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  resultado = await exibirDialogoConfirmarExclusaoInteracao(
                    ctx,
                    ehAlerta: false,
                  );
                },
                child: const Text('Excluir Comentario'),
              ),
              ElevatedButton(
                onPressed: () async {
                  resultado = await exibirDialogoConfirmarExclusaoInteracao(
                    ctx,
                    ehAlerta: true,
                  );
                },
                child: const Text('Excluir Alerta'),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Excluir Comentario'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir Comentário?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(resultado, isFalse);

      await tester.tap(find.text('Excluir Alerta'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir Alerta?'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('btn_confirmar_exclusao_interacao_via')),
      );
      await tester.pumpAndSettle();
      expect(resultado, isTrue);
    },
  );
}
