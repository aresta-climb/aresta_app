// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../services/dataset_repository.dart';
import '../../services/editor_croqui.dart';
import '../settings_functions.dart';

/// Modelo de apresentação e gerenciador de estado para a tela [SettingsPage] (MVVM).
///
/// Encapsula o controle das configurações do editor/modo experimental e a alternância de servidores serving,
/// isolando a UI de configurações de acessos diretos aos repositórios.
class SettingsViewModel extends ChangeNotifier {
  /// Repositório de dados.
  final DatasetRepository datasetRepo;

  /// Gerenciador de configurações de editor e URLs de serving.
  final EditorDeCroqui editorDeCroqui;

  SettingsViewModel({
    required this.datasetRepo,
    required this.editorDeCroqui,
  }) {
    editorDeCroqui.isExperimentalMode.addListener(_aoAtualizar);
    editorDeCroqui.editorUrl.addListener(_aoAtualizar);
  }

  void _aoAtualizar() => notifyListeners();

  @override
  void dispose() {
    editorDeCroqui.isExperimentalMode.removeListener(_aoAtualizar);
