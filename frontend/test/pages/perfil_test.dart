// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/pages/perfil.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/view_models/perfil_view_model.dart';
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

  Widget criarPerfilWidget({PerfilViewModel? viewModel}) {
    final vm =
        viewModel ??
        PerfilViewModel(
          repositorio: repositorio,
          obterGrauDaVia: (uid) => uid == 'via-1' ? '7a' : 'V4',
          obterNomeDaVia: (uid) =>
              uid == 'via-1' ? 'Fenda do Crepúsculo' : 'Bloco Lunar',
        );

    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: PerfilPage(viewModel: vm),
    );
  }

  group('PerfilPage', () {
    testWidgets(
      'renderiza cabeçalho com nome do atleta, autorIdPublico e métricas zeradas',
      (tester) async {
        await tester.pumpWidget(criarPerfilWidget());
        await tester.pumpAndSettle();

        expect(find.text('Escalador Aresta'), findsOneWidget);
        expect(find.byKey(const Key('chip_autor_id_publico')), findsOneWidget);
        expect(find.text('Total de Cadenas'), findsOneWidget);
        expect(find.text('0'), findsWidgets);
        expect(find.text('Pirâmide de Graduação'), findsOneWidget);
        expect(
          find.text('Nenhuma ascensão registrada nesta modalidade.'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Nenhuma ascensão registrada ainda'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'copia o autorIdPublico para a área de transferência ao tocar no chip',
      (tester) async {
        String? textoCopiado;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              final args = methodCall.arguments as Map<dynamic, dynamic>?;
              textoCopiado = args?['text'] as String?;
              return null;
            }
            return null;
          },
        );

        await tester.pumpWidget(criarPerfilWidget());
        await tester.pumpAndSettle();

        final chipFinder = find.byKey(const Key('chip_autor_id_publico'));
        await tester.tap(chipFinder);
        await tester.pumpAndSettle();

        expect(find.text('ID público copiado!'), findsOneWidget);
        expect(textoCopiado, isNotNull);
        expect(textoCopiado!.length, 14);
      },
    );

    testWidgets(
      'permite editar o nome esportivo do atleta ou cancelar o diálogo',
      (tester) async {
        await tester.pumpWidget(criarPerfilWidget());
        await tester.pumpAndSettle();

        final btnEditar = find.byKey(const Key('btn_editar_nome_atleta'));

        // Abre e cancela o diálogo
        await tester.tap(btnEditar);
        await tester.pumpAndSettle();
        expect(find.text('Editar Apelido'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(find.text('Editar Apelido'), findsNothing);

        // Abre novamente e salva novo apelido
        await tester.tap(btnEditar);
        await tester.pumpAndSettle();

        final campoNome = find.byKey(const Key('campo_novo_nome_atleta'));
        await tester.enterText(campoNome, 'Roberta Rocha');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();

        expect(find.text('Roberta Rocha'), findsOneWidget);
        expect(repositorio.obterPerfil().autorNomePublico, 'Roberta Rocha');
      },
    );

    testWidgets(
      'lista múltiplas ascensões no histórico com estilos distintos e permite cancelar ou confirmar exclusão',
      (tester) async {
        final c1 = Cadena.criar(
          escaladaUid: 'via-1',
          dataAscensao: DateTime(2026, 9, 20),
          tipoAscensao: TipoAscensao.flash,
          tipoEscalada: TipoEscalada.guiado,
          notasPrivadas: 'Super suave',
        );
        final c2 = Cadena.criar(
          escaladaUid: 'via-2',
          dataAscensao: DateTime(2026, 9, 15),
          tipoAscensao: TipoAscensao.tentativa,
          tipoEscalada: TipoEscalada.guiado,
        );

        await repositorio.salvarCadena(c1);
        await repositorio.salvarCadena(c2);

        await tester.pumpWidget(criarPerfilWidget());
        await tester.pumpAndSettle();

        // Rola a página para baixo para trazer o histórico para a tela
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        final btnExcluir = find.byKey(Key('btn_excluir_cadena_${c1.id}'));

        expect(find.text('Fenda do Crepúsculo'), findsOneWidget);
        expect(find.text('Flash'), findsOneWidget);
        expect(find.text('Tentativa'), findsOneWidget);
        expect(find.text('“Super suave”'), findsOneWidget);

        // Toca no botão de exclusão e cancela
        await tester.tap(btnExcluir);
        await tester.pumpAndSettle();
        expect(find.text('Excluir Ascensão?'), findsOneWidget);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(find.text('Excluir Ascensão?'), findsNothing);
        expect(find.text('Fenda do Crepúsculo'), findsOneWidget);

        // Toca novamente e confirma a exclusão
        await tester.tap(btnExcluir);
        await tester.pumpAndSettle();
        final btnConfirmar = find.byKey(const Key('btn_confirmar_exclusao'));
        await tester.tap(btnConfirmar);
        await tester.pumpAndSettle();

        expect(find.text('Fenda do Crepúsculo'), findsNothing);
        expect(repositorio.cadenasNotifier.value.length, 1);
      },
    );

    testWidgets(
      'PerfilPage instancia e descarta viewModel interno quando não injetado',
      (tester) async {
        RepositorioCadernetaLocal.instancia = repositorio;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: const [AppColors.dark],
            ),
            home: const PerfilPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('chip_autor_id_publico')), findsOneWidget);

        // Desmonta a página para exercitar o dispose do viewModel interno
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}
