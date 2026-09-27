// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/view_functions/view_models/settings_view_model.dart';

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
