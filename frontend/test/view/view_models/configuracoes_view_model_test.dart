// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/services/controlador_interacoes_usuario.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/view_models/configuracoes_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late EditorDeCroqui editor;
  late DatasetRepository repositorio;
  late ControladorInteracoesUsuario controladorInteracoes;
  late SettingsViewModel viewModel;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
    tempDir = Directory.systemTemp.createTempSync('aresta_settings_vm_test_');
    editor = EditorDeCroqui();
    repositorio = DatasetRepository(editorDeCroqui: editor);
    controladorInteracoes = ControladorInteracoesUsuario();
    await controladorInteracoes.inicializar();
    viewModel = SettingsViewModel(
      datasetRepo: repositorio,
      editorDeCroqui: editor,
      controladorInteracoes: controladorInteracoes,
    );
  });

  tearDown(() {
    viewModel.dispose();
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SettingsViewModel', () {
    test('reflete estado de modoExperimental, editorUrl e activeBaseUrl', () {
      expect(viewModel.modoExperimental, isFalse);
      expect(viewModel.editorUrl, isNull);
      expect(viewModel.activeBaseUrl, isNotEmpty);

      viewModel.alterarModoExperimental(true);
      expect(viewModel.modoExperimental, isTrue);

      viewModel.alterarEditorUrl('http://192.168.1.10:8080');
      expect(viewModel.editorUrl, equals('http://192.168.1.10:8080'));
    });

    test(
      'expõe visibilidade do recurso de perfil e alterna interações de caderneta notificando ouvintes',
      () async {
        expect(viewModel.exibirSecaoInteracoesCaderneta, isTrue);
        expect(viewModel.interacoesCadernetaAtivas, isTrue);
        expect(viewModel.interacoesCadernetaAtivasNotifier.value, isTrue);

        var notificacoes = 0;
        viewModel.addListener(() => notificacoes++);

        await viewModel.definirInteracoesCadernetaAtivas(false);
        expect(viewModel.interacoesCadernetaAtivas, isFalse);
        expect(controladorInteracoes.interacoesAtivas, isFalse);
        expect(notificacoes, equals(1));

        ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(false);
        expect(viewModel.exibirSecaoInteracoesCaderneta, isFalse);
      },
    );

    testWidgets('abrirDialogConexao exibe o diálogo de troca de servidor', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => viewModel.abrirDialogConexao(context),
                child: const Text('Trocar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trocar'));
      await tester.pumpAndSettle();

      expect(find.text('Trocar serving'), findsOneWidget);
    });
  });
}
