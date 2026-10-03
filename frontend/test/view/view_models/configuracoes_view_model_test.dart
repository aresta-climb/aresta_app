// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/view/view_models/configuracoes_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late EditorDeCroqui editor;
  late DatasetRepository repositorio;
  late SettingsViewModel viewModel;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('aresta_settings_vm_test_');
    editor = EditorDeCroqui();
    repositorio = DatasetRepository(editorDeCroqui: editor);
    viewModel = SettingsViewModel(
      datasetRepo: repositorio,
      editorDeCroqui: editor,
    );
  });

  tearDown(() {
    viewModel.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SettingsViewModel Tests', () {
    test('reflete estado de modoExperimental e editorUrl', () {
      expect(viewModel.modoExperimental, isFalse);
      expect(viewModel.editorUrl, isNull);

      viewModel.alterarModoExperimental(true);
      expect(viewModel.modoExperimental, isTrue);

      viewModel.alterarEditorUrl('http://192.168.1.10:8080');
      expect(viewModel.editorUrl, equals('http://192.168.1.10:8080'));
    });
  });
}
