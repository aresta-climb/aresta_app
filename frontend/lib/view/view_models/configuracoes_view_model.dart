// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/controlador_interacoes_usuario.dart';
import '../../services/repositorio_dataset.dart';
import '../../services/editor_croqui.dart';
import '../function_library/funcoes_configuracoes.dart';

/// Modelo de apresentação e gerenciador de estado para a tela [SettingsPage] (MVVM).
///
/// Encapsula o controle das configurações do editor/modo experimental, preferências de
/// visibilidade de perfil/caderneta e a alternância de servidores serving, isolando a UI
/// de configurações de acessos diretos a singletons e repositórios.
class SettingsViewModel extends ChangeNotifier {
  /// Repositório de dados.
  final DatasetRepository datasetRepo;

  /// Gerenciador de configurações de editor e URLs de serving.
  final EditorDeCroqui editorDeCroqui;

  final ControladorInteracoesUsuario _controladorInteracoes;

  SettingsViewModel({
    required this.datasetRepo,
    required this.editorDeCroqui,
    ControladorInteracoesUsuario? controladorInteracoes,
  }) : _controladorInteracoes =
           controladorInteracoes ?? ControladorInteracoesUsuario.instancia {
    editorDeCroqui.isExperimentalMode.addListener(_aoAtualizar);
    editorDeCroqui.editorUrl.addListener(_aoAtualizar);
    _controladorInteracoes.interacoesAtivasNotifier.addListener(_aoAtualizar);
  }

  void _aoAtualizar() => notifyListeners();

  @override
  void dispose() {
    editorDeCroqui.isExperimentalMode.removeListener(_aoAtualizar);
    editorDeCroqui.editorUrl.removeListener(_aoAtualizar);
    _controladorInteracoes.interacoesAtivasNotifier.removeListener(
      _aoAtualizar,
    );
    super.dispose();
  }

  /// Indica se a seção de configuração de Perfil e Caderneta deve ser exibida no ambiente atual.
  bool get exibirSecaoInteracoesCaderneta =>
      _controladorInteracoes.recursoHabilitadoNoAmbiente;

  /// Notificador reativo da preferência de visibilidade de Perfil e Caderneta.
  ValueListenable<bool> get interacoesCadernetaAtivasNotifier =>
      _controladorInteracoes.interacoesAtivasNotifier;

  /// Indica se as interações de Perfil e Caderneta estão ativas nas preferências do usuário.
  bool get interacoesCadernetaAtivas => _controladorInteracoes.interacoesAtivas;

  /// Atualiza e persiste a preferência de visibilidade de Perfil e Caderneta.
  Future<void> definirInteracoesCadernetaAtivas(bool ativo) =>
      _controladorInteracoes.definirInteracoesAtivas(ativo);

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
