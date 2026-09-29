// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../services/repositorio_dataset.dart';
import '../../services/editor_croqui.dart';
import '../function_library/funcoes_configuracoes.dart';

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
    editorDeCroqui.editorUrl.removeListener(_aoAtualizar);
    super.dispose();
  }

  /// Indica se o modo experimental está habilitado.
  bool get modoExperimental => editorDeCroqui.isExperimentalMode.value;

  /// URL de servidor local de desenvolvimento conectada, se houver.
  String? get editorUrl => editorDeCroqui.editorUrl.value;

  /// URL ativa utilizada para requisições de mídias e croquis.
  String get activeBaseUrl => editorDeCroqui.activeBaseUrl;

  /// Altera o estado do modo experimental.
  void alterarModoExperimental(bool ativado) {
    editorDeCroqui.isExperimentalMode.value = ativado;
  }

  /// Define uma nova URL de servidor local ou desconecta (quando nulo).
  void alterarEditorUrl(String? url) {
    editorDeCroqui.editorUrl.value = url;
  }

  /// Abre o diálogo de conexão com servidor via IP ou QR code.
  void abrirDialogConexao(BuildContext context) {
    mostrarDialogConexao(
      context,
      datasetRepo,
      titulo: 'Trocar serving',
    );
  }
}
