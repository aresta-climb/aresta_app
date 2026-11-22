// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';

/// ViewModel (MVVM) responsável pelo estado de edição do nome esportivo e foto de perfil
/// exibido no `DialogoEditarPerfil`, mantendo o widget declarativo (Dumb UI).
class EdicaoPerfilViewModel extends ChangeNotifier {
  final Future<String?> Function()? _aoSelecionarNovaFoto;

  String _nomeDigitado;
  String? _fotoUrlExibida;

  /// Cria uma instância de [EdicaoPerfilViewModel].
  EdicaoPerfilViewModel({
    required String nomeInicial,
    String? fotoUrlInicial,
    Future<String?> Function()? aoSelecionarNovaFoto,
  }) : _nomeDigitado = nomeInicial,
       _fotoUrlExibida = fotoUrlInicial,
       _aoSelecionarNovaFoto = aoSelecionarNovaFoto;

  /// Texto atual do nome esportivo em edição.
  String get nomeDigitado => _nomeDigitado;

  /// URL ou Data URI atualmente exibida para o avatar no diálogo.
  String? get fotoUrlExibida => _fotoUrlExibida;

  /// Indica se a ação de trocar foto está habilitada no contexto atual.
  bool get permiteAlterarFoto => _aoSelecionarNovaFoto != null;

  /// Atualiza o texto digitado do nome sem disparar rebuild desnecessário do campo.
  void definirNome(String valor) {
    _nomeDigitado = valor;
  }

  /// Aciona o seletor de foto injetado e atualiza [fotoUrlExibida] quando uma nova imagem válida retorna.
  Future<void> selecionarNovaFoto() async {
    final seletor = _aoSelecionarNovaFoto;
    if (seletor == null) return;

    final novaFoto = await seletor();
    if (novaFoto != null && novaFoto.trim().isNotEmpty) {
      _fotoUrlExibida = novaFoto.trim();
      notifyListeners();
    }
  }

  /// Retorna o nome normalizado (`trim()`) pronto para persistência, ou `null` quando vazio.
  String? obterNomeNormalizadoParaSalvar() {
    final limpo = _nomeDigitado.trim();
    return limpo.isNotEmpty ? limpo : null;
  }
}
