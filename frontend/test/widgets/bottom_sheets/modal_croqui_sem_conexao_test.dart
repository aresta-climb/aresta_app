// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/catalogo/repositorio_catalogo.dart';
import 'package:frontend/widgets/bottom_sheets/modal_croqui_sem_conexao.dart';

void main() {
  group('ModalCroquiSemConexao', () {
    testWidgets(
      'exibe dados da escalada, setor, grupo e croqui, mostra aviso inline quando a tentativa falha e fecha automaticamente quando a tentativa sucede',
      (tester) async {
        const itemVia = ItemCatalogoBusca(
          uid: 'v123',
          tipo: 'escalada',
          croquiUid: 'c123',
          idSlug: 'br_mg_igarape_pedra_grande',
          nome: 'Fenda da Paz',
          escaladaGrau: '6sup',
          escaladaTipo: 'tradicional',
          setorNome: 'Setor Principal',
          grupoNome: 'Grupo Sherpa',
          picoNome: 'Pedra Grande',
          cidade: 'Igarapé',
          estado: 'MG',
        );

        var tentativa = 0;
        final completerSegundaTentativa = Completer<bool>();
        bool? resultadoModal;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    resultadoModal = await ModalCroquiSemConexao.mostrar(
                      context: context,
                      item: itemVia,
                      aoTentarNovamente: () async {
                        tentativa++;
                        if (tentativa == 1) {
                          return false;
                        }
                        return completerSegundaTentativa.future;
                      },
                    );
                  },
                  child: const Text('Abrir Modal'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir Modal'));
        await tester.pumpAndSettle();

        expect(find.text('VOCÊ ESTÁ SEM CONEXÃO'), findsOneWidget);
        expect(find.text('Fenda da Paz (6sup)'), findsOneWidget);
        expect(
          find.text(
            'Setor Principal • Grupo Sherpa • Croqui Pedra Grande • Igarapé, MG',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('Este conteúdo faz parte do croqui Pedra Grande'),
          findsOneWidget,
        );

        // 1ª tentativa falha (continua sem internet): mantém modal aberto e exibe aviso inline
        await tester.tap(find.text('Tentar novamente'));
        await tester.pumpAndSettle();

        expect(tentativa, equals(1));
        expect(
          find.text(
            'Ainda sem conexão com a internet. Verifique sua rede e tente novamente.',
          ),
          findsOneWidget,
        );
        expect(find.byType(ModalCroquiSemConexao), findsOneWidget);

        // 2ª tentativa em andamento: exibe estado "Tentando conectar..."
        await tester.tap(find.text('Tentar novamente'));
        await tester.pump();

        expect(find.text('Tentando conectar...'), findsOneWidget);

        // Quando a 2ª tentativa conclui com sucesso, fecha o modal retornando true
        completerSegundaTentativa.complete(true);
        await tester.pumpAndSettle();

        expect(find.byType(ModalCroquiSemConexao), findsNothing);
        expect(resultadoModal, isTrue);
      },
    );

    testWidgets(
      'exibe dados de pico diretamente e permite fechar pelo botao Fechar',
      (tester) async {
        const itemPico = ItemCatalogoBusca(
          uid: 'c999',
          tipo: 'pico',
          croquiUid: 'c999',
          idSlug: 'br_sp_pedra_bau',
          nome: 'Pedra do Baú',
          picoNome: 'Pedra do Baú',
        );

        bool? resultadoModal;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    resultadoModal = await ModalCroquiSemConexao.mostrar(
                      context: context,
                      item: itemPico,
                      aoTentarNovamente: () async => false,
                    );
                  },
                  child: const Text('Abrir Modal Pico'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Abrir Modal Pico'));
        await tester.pumpAndSettle();

        expect(find.text('Pedra do Baú'), findsOneWidget);
        expect(find.text('Croqui Pedra do Baú'), findsOneWidget);

        await tester.tap(find.text('Fechar'));
        await tester.pumpAndSettle();

        expect(find.byType(ModalCroquiSemConexao), findsNothing);
        expect(resultadoModal, isFalse);
      },
    );
  });
}
