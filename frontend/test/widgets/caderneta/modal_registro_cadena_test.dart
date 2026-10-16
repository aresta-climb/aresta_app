// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/view_models/registro_cadena_view_model.dart';
import 'package:frontend/widgets/caderneta/modal_registro_cadena.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
  });

  Widget criarWidgetDeTeste({
    required String escaladaUid,
    required String nomeEscalada,
    TipoEscalada tipoEscaladaPadrao = TipoEscalada.guiado,
    void Function(Cadena)? onSalvo,
  }) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(
        body: ModalRegistroCadena(
          escaladaUid: escaladaUid,
          nomeEscalada: nomeEscalada,
          tipoEscaladaPadrao: tipoEscaladaPadrao,
          repositorio: repositorio,
          onSalvo: onSalvo,
        ),
      ),
    );
  }

  group('ModalRegistroCadena', () {
    testWidgets(
      'renderiza título, chips de estilo esportivo e botões principais',
      (tester) async {
        await tester.pumpWidget(
          criarWidgetDeTeste(
            escaladaUid: 'via-test-1234',
            nomeEscalada: 'Via do Macaco',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Registrar Ascensão'), findsOneWidget);
        expect(find.text('Via do Macaco'), findsOneWidget);

        // Chips de estilo esportivo
        expect(find.text('À Vista'), findsOneWidget);
        expect(find.text('Flash'), findsOneWidget);
        expect(find.text('Trabalhado'), findsOneWidget);
        expect(find.text('Tentativa'), findsOneWidget);

        // Botão de salvar
        expect(find.text('Salvar na Caderneta'), findsOneWidget);
      },
    );

    testWidgets(
      'permite selecionar estilo e ajustar quantidade de tentativas',
      (tester) async {
        await tester.pumpWidget(
          criarWidgetDeTeste(
            escaladaUid: 'via-test-1234',
            nomeEscalada: 'Via do Macaco',
          ),
        );
        await tester.pumpAndSettle();

        // Seleciona Flash
        await tester.tap(find.text('Flash'));
        await tester.pumpAndSettle();

        // Contador de tentativas inicial é 1
        expect(find.text('1'), findsOneWidget);

        // Toca em incrementar (+)
        final botaoMais = find.byKey(const Key('btn_incrementar_tentativas'));
        await tester.tap(botaoMais);
        await tester.pumpAndSettle();
        expect(find.text('2'), findsOneWidget);

        // Toca em decrementar (-)
        final botaoMenos = find.byKey(const Key('btn_decrementar_tentativas'));
        await tester.tap(botaoMenos);
        await tester.pumpAndSettle();
        expect(find.text('1'), findsOneWidget);

        // Tenta decrementar abaixo de 1 (deve permanecer 1)
        await tester.tap(botaoMenos);
        await tester.pumpAndSettle();
        expect(find.text('1'), findsOneWidget);
      },
    );

    testWidgets(
      'exibe contador de 200 caracteres para notas privadas e restringe texto',
      (tester) async {
        await tester.pumpWidget(
          criarWidgetDeTeste(
            escaladaUid: 'via-test-1234',
            nomeEscalada: 'Via do Macaco',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('0/200'), findsOneWidget);

        final campoNotas = find.byKey(const Key('campo_notas_privadas'));
        await tester.enterText(campoNotas, 'Agarras de reglete no crux');
        await tester.pumpAndSettle();

        expect(find.text('26/200'), findsOneWidget);

        // Digita exatamente 200 caracteres para atingir o limite visual
        final texto200 = 'A' * 200;
        await tester.enterText(campoNotas, texto200);
        await tester.pumpAndSettle();

        expect(find.text('200/200'), findsOneWidget);
      },
    );

    testWidgets('salva a ascensão na caderneta e executa o callback onSalvo', (
      tester,
    ) async {
      Cadena? cadenaSalva;

      await tester.pumpWidget(
        criarWidgetDeTeste(
          escaladaUid: 'via-salvar-uid',
          nomeEscalada: 'Paredão dos Sonhos',
          onSalvo: (c) {
            cadenaSalva = c;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Seleciona À Vista
      await tester.tap(find.text('À Vista'));
      await tester.pumpAndSettle();

      final campoNotas = find.byKey(const Key('campo_notas_privadas'));
      await tester.enterText(campoNotas, 'Sem quedas na primeira entrada');
      await tester.pumpAndSettle();

      // Toca em salvar
      await tester.tap(find.text('Salvar na Caderneta'));
      await tester.pumpAndSettle();

      expect(cadenaSalva, isNotNull);
      expect(cadenaSalva!.escaladaUid, 'via-salvar-uid');
      expect(cadenaSalva!.tipoAscensao, TipoAscensao.aVista);
      expect(cadenaSalva!.notasPrivadas, 'Sem quedas na primeira entrada');

      // Verifica se está no repositório
      expect(repositorio.cadenasNotifier.value.length, 1);
      expect(repositorio.cadenasNotifier.value.first.id, cadenaSalva!.id);
    });

    testWidgets(
      'exibirModalRegistroCadena abre o modal como bottom sheet e seleciona data',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: const [AppColors.dark],
            ),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => exibirModalRegistroCadena(
                    ctx,
                    escaladaUid: 'via-bottom-sheet',
                    nomeEscalada: 'Fenda da Ilusão',
                    repositorio: repositorio,
                  ),
                  child: const Text('Abrir Modal'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Abrir Modal'));
        await tester.pumpAndSettle();

        expect(find.text('Registrar Ascensão'), findsOneWidget);
        expect(find.text('Fenda da Ilusão'), findsOneWidget);

        // Abre date picker
        await tester.tap(find.byKey(const Key('btn_selecionar_data')));
        await tester.pumpAndSettle();

        // Confirma data de hoje no dialog
        expect(find.byType(DatePickerDialog), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Salva
        await tester.tap(find.text('Salvar na Caderneta'));
        await tester.pumpAndSettle();

        expect(find.text('Registrar Ascensão'), findsNothing);
        expect(repositorio.cadenasNotifier.value.length, 1);
        expect(
          repositorio.cadenasNotifier.value.first.escaladaUid,
          'via-bottom-sheet',
        );
      },
    );

    testWidgets(
      'renderiza e interage perfeitamente com RegistroCadenaViewModel injetado externamente',
      (tester) async {
        final vm = RegistroCadenaViewModel(
          escaladaUid: 'via-injetada-456',
          nomeEscalada: 'Fissura dos Sonhos',
          tipoAscensaoPadrao: TipoAscensao.aVista,
          tentativasIniciais: 2,
          repositorio: repositorio,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: const [AppColors.dark],
            ),
            home: Scaffold(body: ModalRegistroCadena(viewModel: vm)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Registrar Ascensão'), findsOneWidget);
        expect(find.text('Fissura dos Sonhos'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        // Decrementa tentativas
        await tester.tap(find.byKey(const Key('btn_decrementar_tentativas')));
        await tester.pumpAndSettle();
        expect(vm.tentativas, 1);
        expect(find.text('1'), findsOneWidget);

        // Salva
        await tester.tap(find.text('Salvar na Caderneta'));
        await tester.pumpAndSettle();

        expect(repositorio.cadenasNotifier.value.length, 1);
        expect(
          repositorio.cadenasNotifier.value.first.escaladaUid,
          'via-injetada-456',
        );
      },
    );
  });
}
